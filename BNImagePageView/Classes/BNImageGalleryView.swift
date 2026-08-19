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
        if containerWidth >= 768 { return 4 }
        if containerWidth >= 600 { return 3 }
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

    private func computeFrames(colWidth: CGFloat, columns: Int) -> [CGRect] {
        // Pattern: full width, then N columns, repeat
        // group: 1 full + (columns) items = columns+1 per group
        let groupSize = columns + 1
        var frames: [CGRect] = []
        var y: CGFloat = 0

        var i = 0
        while i < imageURLs.count {
            let posInGroup = i % groupSize

            if posInGroup == 0 {
                // full width
                let ratio = aspectRatios[i] ?? (16.0/9.0)
                let h = containerWidth / ratio
                frames.append(CGRect(x: 0, y: y, width: containerWidth, height: h))
                y += h + spacing
                i += 1
            } else {
                // N columns row
                var rowItems: [Int] = []
                while rowItems.count < columns && i < imageURLs.count && (i % groupSize) != 0 {
                    rowItems.append(i)
                    i += 1
                }
                let maxH = rowItems.map { idx -> CGFloat in
                    let ratio = aspectRatios[idx] ?? (16.0/9.0)
                    return colWidth / ratio
                }.max() ?? colWidth

                for (j, idx) in rowItems.enumerated() {
                    let x = CGFloat(j) * (colWidth + spacing)
                    frames.append(CGRect(x: x, y: y, width: colWidth, height: maxH))
                }
                // fill empty slots
                if rowItems.count < columns {
                    for j in rowItems.count..<columns {
                        let x = CGFloat(j) * (colWidth + spacing)
                        frames.append(CGRect(x: x, y: y, width: colWidth, height: 0))
                    }
                }
                y += maxH + spacing
            }
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



