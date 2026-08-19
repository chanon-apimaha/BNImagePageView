import SwiftUI
import Kingfisher

// MARK: - UIKit Entry Point

public class BNImageGalleryView: UIView {

    private var hostingController: UIHostingController<BNGallerySwiftUIView>?
    private var onTapHandler: ((Int, CGRect) -> Void)?

    public init(imageURLs: [String], onTap: ((Int, CGRect) -> Void)? = nil) {
        super.init(frame: .zero)
        self.onTapHandler = onTap
        let swiftUIView = BNGallerySwiftUIView(imageURLs: imageURLs) { [weak self] index, swiftUIFrame in
            guard let self else { return }
            let windowFrame = self.convertSwiftUIFrame(swiftUIFrame)
            self.onTapHandler?(index, windowFrame)
        }
        let hc = UIHostingController(rootView: swiftUIView)
        hc.view.translatesAutoresizingMaskIntoConstraints = false
        hc.view.backgroundColor = .clear
        addSubview(hc.view)
        NSLayoutConstraint.activate([
            hc.view.topAnchor.constraint(equalTo: topAnchor),
            hc.view.bottomAnchor.constraint(equalTo: bottomAnchor),
            hc.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hc.view.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        hostingController = hc
    }

    required init?(coder: NSCoder) { fatalError() }

    public func imageView(at index: Int) -> UIImageView? {
        hostingController?.view.allSubviews.compactMap { $0 as? UIImageView }.first { $0.tag == index }
    }

    private func convertSwiftUIFrame(_ frame: CGRect) -> CGRect {
        // SwiftUI .global coordinate = UIKit window coordinate บน iOS
        return frame
    }
}

private extension UIView {
    var allSubviews: [UIView] {
        subviews + subviews.flatMap { $0.allSubviews }
    }
}

// MARK: - SwiftUI View

public struct BNGallerySwiftUIView: View {
    public let imageURLs: [String]
    public let captions: [String]
    public let onTap: ((Int, CGRect) -> Void)?

    @State private var aspectRatios: [Int: CGFloat] = [:]
    @State private var isLoaded = false
    @State private var globalFrames: [Int: CGRect] = [:]
    @State private var totalHeight: CGFloat = 0
    @State private var containerWidth: CGFloat = UIScreen.main.bounds.width
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
                            .overlay(
                                GeometryReader { itemGeo in
                                    Color.clear
                                        .onAppear { globalFrames[index] = itemGeo.frame(in: .global) }
                                        .onChange(of: itemGeo.frame(in: .global).minY) { _ in
                                            globalFrames[index] = itemGeo.frame(in: .global)
                                        }
                                }
                            )
                            .simultaneousGesture(
                                TapGesture().onEnded {
                                    let frame = globalFrames[index] ?? .zero
                                    onTap?(index, frame)
                                }
                            )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: isLoaded ? totalHeight : 44, maxHeight: isLoaded ? totalHeight : 44)
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { containerWidth = geo.size.width; recalculate() }
                    .onChange(of: geo.size.width) { containerWidth = $0; recalculate() }
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

        // Step 1: คำนวณ width ของแต่ละภาพที่ targetRowHeight
        let widths = imageURLs.indices.map { i -> CGFloat in
            let ratio = aspectRatios[i] ?? (16.0/9.0)
            return floor(targetRowHeight * ratio)
        }
        let totalWidth = widths.reduce(0, +)

        // Step 2: คำนวณจำนวน rows
        var numRows = Int(ceil(totalWidth / containerWidth))
        if numRows > imageURLs.count { numRows = imageURLs.count }
        if numRows < 1 { numRows = 1 }
        let finalRowWidth = totalWidth / CGFloat(numRows)

        // Step 3: แบ่งภาพเข้า rows
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

        // Step 4: คำนวณ position
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



