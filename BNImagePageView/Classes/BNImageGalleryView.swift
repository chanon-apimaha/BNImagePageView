import SwiftUI
import Kingfisher

// MARK: - UIKit Entry Point

public class BNGalleryViewController: UIViewController {
    private let imageURLs: [String]

    public init(imageURLs: [String]) {
        self.imageURLs = imageURLs
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.clipsToBounds = true

        let swiftUIView = BNGallerySwiftUIView(imageURLs: imageURLs) { [weak self] index, frame in
            guard let self else { return }
            let vc = BNImageBuilder.build(imageURLs: self.imageURLs, currentIndex: index)
            vc.imageViewForIndex = { _ in UIImageView(frame: frame) }
            self.present(vc, animated: false)
        }
        let hc = UIHostingController(rootView: swiftUIView)
        if #available(iOS 16.0, *) {
            hc.sizingOptions = .intrinsicContentSize
        }
        addChild(hc)
        hc.view.translatesAutoresizingMaskIntoConstraints = false
        hc.view.backgroundColor = .clear

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(hc.view)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            hc.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hc.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hc.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hc.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            hc.view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
        hc.didMove(toParent: self)
    }
}

// MARK: - SwiftUI View

final class BNFrameReportingView: UIView {
    var onFrame: ((CGRect) -> Void)?
    private var scrollObservations: [NSKeyValueObservation] = []

    override func layoutSubviews() {
        super.layoutSubviews()
        reportFrame()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        reportFrame()
        scrollObservations.removeAll()
        var v: UIView? = superview
        while let current = v {
            if let scrollView = current as? UIScrollView {
                let obs = scrollView.observe(\.contentOffset, options: [.new]) { [weak self] _, _ in
                    self?.reportFrame()
                }
                scrollObservations.append(obs)
            }
            v = current.superview
        }
    }

    private func reportFrame() {
        guard let window = window else { return }
        let frame = convert(bounds, to: window)
        onFrame?(frame)
    }
}

struct BNFrameReader: UIViewRepresentable {
    let onFrame: (CGRect) -> Void
    func makeUIView(context: Context) -> BNFrameReportingView {
        let v = BNFrameReportingView()
        v.backgroundColor = .clear
        v.onFrame = onFrame
        return v
    }
    func updateUIView(_ uiView: BNFrameReportingView, context: Context) {
        uiView.onFrame = onFrame
    }
}

public struct BNGallerySwiftUIView: View {
    public let imageURLs: [String]
    public let captions: [String]
    public let onTap: ((Int, CGRect) -> Void)?

    @State private var aspectRatios: [Int: CGFloat] = [:]
    @State private var isLoaded = false
    @State private var globalFrames: [Int: CGRect] = [:]
    @State private var totalHeight: CGFloat = 0
    @State private var containerWidth: CGFloat = UIScreen.main.bounds.width
    @State private var viewOrigin: CGPoint = .zero
    private let spacing: CGFloat = 2

    public init(imageURLs: [String], captions: [String] = [], onTap: ((Int, CGRect) -> Void)? = nil) {
        self.imageURLs = imageURLs
        self.captions = captions
        self.onTap = onTap
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            if !isLoaded {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .onAppear { preload() }
            } else {
                let frames = computeFrames(colWidth: colWidth, columns: columnCount)
                ZStack(alignment: .topLeading) {
                    Color.clear.frame(height: totalHeight)
                    ForEach(imageURLs.indices, id: \.self) { index in
                        KFImage(URL(string: imageURLs[index]))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: frames[index].width, height: frames[index].height)
                            .clipped()
                            .offset(x: frames[index].minX, y: frames[index].minY)
                            .simultaneousGesture(
                                TapGesture().onEnded {
                                    let screenFrame = CGRect(
                                        x: frames[index].minX + viewOrigin.x,
                                        y: frames[index].minY + viewOrigin.y,
                                        width: frames[index].width,
                                        height: frames[index].height
                                    )
                                    onTap?(index, screenFrame)
                                }
                            )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: isLoaded ? totalHeight : 44)
        .background(
            ZStack {
                BNFrameReader { frame in
                    viewOrigin = frame.origin
                }
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            containerWidth = geo.size.width
                            recalculate()
                        }
                        .onChange(of: geo.size.width) { containerWidth = $0; recalculate() }
                }
            }
        )
    }

    private var columnCount: Int {
        if containerWidth >= 390 { return 4 }
        return 2
    }

    private var colWidth: CGFloat {
        (containerWidth - spacing * CGFloat(columnCount - 1)) / CGFloat(columnCount)
    }

    private func recalculate() {
        guard isLoaded else { return }
        let frames = computeFrames(colWidth: colWidth, columns: columnCount)
        totalHeight = frames.map { $0.maxY }.max() ?? 0
    }

    private let targetRowHeight: CGFloat = 150

    private func computeFrames(colWidth: CGFloat, columns: Int) -> [CGRect] {
        guard !imageURLs.isEmpty else { return [] }
        var frames: [CGRect] = Array(repeating: .zero, count: imageURLs.count)

        let widths = imageURLs.indices.map { i -> CGFloat in
            let ratio = aspectRatios[i] ?? (16.0/9.0)
            return floor(targetRowHeight * ratio)
        }
        let totalWidth = widths.reduce(0, +)

        var numRows = Int(ceil(totalWidth / containerWidth))
        if numRows > imageURLs.count { numRows = imageURLs.count }
        if numRows < 1 { numRows = 1 }
        let finalRowWidth = totalWidth / CGFloat(numRows)

        var rows: [[Int]] = []
        var currentRow: [Int] = []
        var progressWidth: CGFloat = 0
        var eachRowWidth: CGFloat = 0
        var numRow = 0
        var rowsWidths: [CGFloat] = []

        for i in imageURLs.indices {
            let w = widths[i]
            if (progressWidth + w / 2) > CGFloat(numRow + 1) * finalRowWidth {
                rowsWidths.append(eachRowWidth)
                rows.append(currentRow)
                currentRow = []
                eachRowWidth = 0
                numRow += 1
            }
            progressWidth += w
            eachRowWidth += w
            currentRow.append(i)
        }
        rowsWidths.append(eachRowWidth)
        rows.append(currentRow)

        var y: CGFloat = 0
        for (rowIdx, row) in rows.enumerated() {
            let rowWidth = rowsWidths[rowIdx]
            let gapWidth = spacing * CGFloat(row.count - 1)
            let ratio = rowWidth > 0 ? (containerWidth - gapWidth) / rowWidth : 1.0
            let rowHeight = (targetRowHeight * ratio).rounded()

            var x: CGFloat = 0
            for i in row {
                let w = (widths[i] * ratio).rounded()
                frames[i] = CGRect(x: x, y: y, width: w, height: rowHeight)
                x += w + spacing
            }
            y += rowHeight + spacing
        }

        return frames
    }

    private func preload() {
        let group = DispatchGroup()
        for (index, urlString) in imageURLs.enumerated() {
            guard let url = URL(string: urlString) else {
                aspectRatios[index] = 1.0
                continue
            }
            group.enter()
            KingfisherManager.shared.retrieveImage(with: url, options: [.cacheOriginalImage]) { result in
                DispatchQueue.main.async {
                    if case .success(let value) = result {
                        let size = value.image.size
                        aspectRatios[index] = size.height > 0 ? size.width / size.height : 1.0
                    } else {
                        aspectRatios[index] = 1.0
                    }
                    group.leave()
                }
            }
        }
        group.notify(queue: .main) {
            let frames = self.computeFrames(colWidth: self.colWidth, columns: self.columnCount)
            self.totalHeight = frames.map { $0.maxY }.max() ?? 0
            self.isLoaded = true
        }
    }
}
