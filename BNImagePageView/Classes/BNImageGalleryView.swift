import UIKit
import Kingfisher

public class BNImageGalleryView: UIScrollView {

    // MARK: - Config
    public var spacing: CGFloat = 2
    public var landscapeRatio: CGFloat = 1.8  // threshold สำหรับ full-width

    // MARK: - Private
    private var imageURLs: [String] = []
    private var aspectRatios: [CGFloat] = []
    private var loadedImages: [Int: UIImage] = [:]
    private var loadAttempts: Int = 0
    private let contentView = UIView()
    public private(set) var imageViews: [UIImageView] = []
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private var onTap: ((Int, UIImageView) -> Void)?
    private var didLayout = false

    // MARK: - Init
    public init(imageURLs: [String], onTap: ((Int, UIImageView) -> Void)? = nil) {
        super.init(frame: .zero)
        self.imageURLs = imageURLs
        self.aspectRatios = Array(repeating: 1.0, count: imageURLs.count)
        self.onTap = onTap
        setup()
        preloadImages()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup
    private func setup() {
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        addSubview(contentView)
    }

    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard let superview else { return }
        // loading indicator อยู่ใน superview ไม่ใช่ scrollView
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        superview.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: superview.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: superview.centerYAnchor)
        ])
        loadingIndicator.startAnimating()
    }

    // MARK: - Preload
    private func preloadImages() {
        let group = DispatchGroup()
        for (index, urlString) in imageURLs.enumerated() {
            guard let url = URL(string: urlString) else {
                loadedImages[index] = UIImage()
                continue
            }
            group.enter()
            KingfisherManager.shared.retrieveImage(with: url, options: [.cacheOriginalImage]) { [weak self] result in
                if case .success(let value) = result {
                    let size = value.image.size
                    if size.height > 0 {
                        self?.aspectRatios[index] = size.width / size.height
                    }
                    self?.loadedImages[index] = value.image
                } else {
                    // โหลดไม่สำเร็จ ใช้ aspect ratio 1:1 แทน
                    self?.loadedImages[index] = UIImage()
                }
                group.leave()
            }
        }
        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            print("[BNGallery] preload done loaded=\(self.loadedImages.count)/\(self.imageURLs.count)")
            self.loadingIndicator.stopAnimating()
            self.loadingIndicator.removeFromSuperview()
            self.didLayout = false
            self.setNeedsLayout()
        }
    }

    // MARK: - Layout
    public override func layoutSubviews() {
        super.layoutSubviews()
        print("[BNGallery] layoutSubviews bounds=\(bounds.width) loaded=\(loadedImages.count)/\(imageURLs.count) didLayout=\(didLayout)")
        guard bounds.width > 0,
              loadedImages.count == imageURLs.count,
              !didLayout else { return }
        didLayout = true
        layoutMasonry()
    }

    private func layoutMasonry() {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        imageViews.removeAll()

        let columns = columnCount()
        let totalSpacing = spacing * CGFloat(columns - 1)
        let colWidth = (bounds.width - totalSpacing) / CGFloat(columns)
        var colHeights = Array(repeating: CGFloat(0), count: columns)

        print("[BNGallery] aspectRatios: \(aspectRatios.map { String(format: "%.2f", $0) })")
        for (index, _) in imageURLs.enumerated() {
            let ratio = aspectRatios[index]
            let iv = makeImageView(index: index)
            contentView.addSubview(iv)
            imageViews.append(iv)

            if ratio >= landscapeRatio {
                // ดึงทุก column ให้เท่ากับ column ที่สูงที่สุดก่อน ไม่ให้มีช่องว่าง
                let maxHeight = colHeights.max() ?? 0
                for i in 0..<columns { colHeights[i] = maxHeight }
                let y = maxHeight + (maxHeight > 0 ? spacing : 0)
                let imgHeight = bounds.width / ratio
                iv.frame = CGRect(x: 0, y: y, width: bounds.width, height: imgHeight)
                for i in 0..<columns { colHeights[i] = iv.frame.maxY }
            } else {
                let minIdx = colHeights.enumerated().min(by: { $0.element < $1.element })!.offset
                let x = CGFloat(minIdx) * (colWidth + spacing)
                let y = colHeights[minIdx] + (colHeights[minIdx] > 0 ? spacing : 0)
                let imgHeight = colWidth / ratio
                iv.frame = CGRect(x: x, y: y, width: colWidth, height: imgHeight)
                colHeights[minIdx] = iv.frame.maxY
            }
        }

        let totalHeight = colHeights.max() ?? 0
        contentView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: totalHeight)
        contentSize = CGSize(width: bounds.width, height: totalHeight)
    }

    // MARK: - Column Count
    private func columnCount() -> Int {
        if bounds.width >= 768 { return 4 }
        if bounds.width >= 600 { return 3 }
        return 2
    }

    // MARK: - ImageView Factory
    private func makeImageView(index: Int) -> UIImageView {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray5
        iv.isUserInteractionEnabled = true
        iv.tag = index
        iv.image = loadedImages[index]
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        iv.addGestureRecognizer(tap)
        return iv
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let iv = gesture.view as? UIImageView else { return }
        onTap?(iv.tag, iv)
    }
}
