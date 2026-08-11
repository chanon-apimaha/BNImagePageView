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

struct BNGallerySwiftUIView: View {
    let imageURLs: [String]
    let onTap: ((Int, CGRect) -> Void)?

    @State private var aspectRatios: [Int: CGFloat] = [:]
    @State private var isLoaded = false
    @State private var globalFrames: [Int: CGRect] = [:]
    private let spacing: CGFloat = 2

    var body: some View {
        GeometryReader { geo in
            if !isLoaded {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear { preload() }
            } else {
                let columns = columnCount(width: geo.size.width)
                let colWidth = (geo.size.width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
                let frames = computeFrames(colWidth: colWidth, columns: columns)
                let totalHeight = frames.map { $0.maxY }.max() ?? 0

                ScrollView {
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
                                        let frame = globalFrames[index] ?? .zero
                                        onTap?(index, frame)
                                    }
                                )
                                .background(
                                    GeometryReader { itemGeo in
                                        Color.clear
                                            .onAppear {
                                                globalFrames[index] = itemGeo.frame(in: .global)
                                            }
                                    }
                                )
                        }
                    }
                    .frame(width: geo.size.width, height: totalHeight, alignment: .topLeading)
                }
            }
        }
    }

    private func columnCount(width: CGFloat) -> Int {
        if width >= 768 { return 4 }
        if width >= 600 { return 3 }
        return 2
    }

    private func computeFrames(colWidth: CGFloat, columns: Int) -> [CGRect] {
        var colHeights = Array(repeating: CGFloat(0), count: columns)
        var frames: [CGRect] = []
        for index in imageURLs.indices {
            let ratio = aspectRatios[index] ?? 1.0
            let minIdx = colHeights.enumerated().min(by: { $0.element < $1.element })!.offset
            let x = CGFloat(minIdx) * (colWidth + spacing)
            let y = colHeights[minIdx] + (colHeights[minIdx] > 0 ? spacing : 0)
            let h = colWidth / ratio
            frames.append(CGRect(x: x, y: y, width: colWidth, height: h))
            colHeights[minIdx] = y + h
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
        group.notify(queue: .main) { isLoaded = true }
    }
}



