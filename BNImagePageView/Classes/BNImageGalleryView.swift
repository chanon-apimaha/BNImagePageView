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
    public let onTap: ((Int, CGRect) -> Void)?

    @State private var aspectRatios: [Int: CGFloat] = [:]
    @State private var isLoaded = false
    @State private var globalFrames: [Int: CGRect] = [:]
    @State private var totalHeight: CGFloat = 0
    @State private var containerWidth: CGFloat = UIScreen.main.bounds.width
    private let spacing: CGFloat = 2

    public init(imageURLs: [String], onTap: ((Int, CGRect) -> Void)? = nil) {
        self.imageURLs = imageURLs
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
                    .onAppear { containerWidth = geo.size.width; recalculate(); print("[BNGallery] containerWidth: \(geo.size.width)") }
                    .onChange(of: geo.size.width) { containerWidth = $0; recalculate(); print("[BNGallery] containerWidth changed: \($0)") }
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
        var frames: [CGRect] = Array(repeating: .zero, count: imageURLs.count)
        var y: CGFloat = 0
        var rowStart = 0

        while rowStart < imageURLs.count {
            var rowWidth: CGFloat = 0
            var rowEnd = rowStart

            // เพิ่มภาพเข้า row จนเกิน containerWidth
            while rowEnd < imageURLs.count {
                let ratio = aspectRatios[rowEnd] ?? 1.0
                let w = targetRowHeight * ratio
                if rowWidth + w + spacing * CGFloat(rowEnd - rowStart) > containerWidth && rowEnd > rowStart {
                    break
                }
                rowWidth += w
                rowEnd += 1
            }

            let count = rowEnd - rowStart
            let totalSpacing = spacing * CGFloat(count - 1)
            let totalRatio = (rowStart..<rowEnd).reduce(0.0) { $0 + (aspectRatios[$1] ?? 1.0) }
            let rowHeight = totalRatio > 0 ? (containerWidth - totalSpacing) / totalRatio : targetRowHeight

            var x: CGFloat = 0
            for i in rowStart..<rowEnd {
                let ratio = aspectRatios[i] ?? 1.0
                let w = rowHeight * ratio
                frames[i] = CGRect(x: x, y: y, width: w, height: rowHeight)
                x += w + spacing
            }

            y += rowHeight + spacing
            rowStart = rowEnd
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
            print("[BNGallery] loaded, totalHeight: \(self.totalHeight), containerWidth: \(self.containerWidth)")
            self.isLoaded = true
        }
    }
}



