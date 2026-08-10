//
//  ViewController.swift
//  BNImagePageView
//

import UIKit
import BNImagePageView

class ViewController: UIViewController {

    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }

    private let imageURLs = (1...20).map { _ in
        let ids = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100,
                   110, 120, 130, 140, 150, 160, 170, 180, 190, 200]
        return "https://picsum.photos/id/\(ids.randomElement()!)/400/300.jpg"
    }

    private lazy var uniqueURLs: [String] = {
        let ids = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100,
                   110, 120, 130, 140, 150, 160, 170, 180, 190, 200]
        return ids.map { "https://picsum.photos/id/\($0)/400/300.jpg" }
    }()

    private var pageData: [ImgaePageData] = []
    private var collectionView: UICollectionView!
    private var headerLabel: UILabel!
    private var currentLayout: LayoutType = .list

    enum LayoutType: Int { case list, grid, paging }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        pageData = uniqueURLs.enumerated().map {
            ImgaePageData(atIndex: IndexPath(row: $0.offset, section: 0), sImageUrl: $0.element, fWidth: 400, fHeight: 300)
        }

        setupHeader()
        setupSegment()
        setupCollectionView()
    }

    private func setupHeader() {
        headerLabel = UILabel()
        headerLabel.text = "\(uniqueURLs.count) Photos"
        headerLabel.font = .systemFont(ofSize: 13, weight: .medium)
        headerLabel.textColor = .secondaryLabel
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerLabel)
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
        ])
    }

    private func setupSegment() {
        let segment = UISegmentedControl(items: ["List", "Grid", "Paging"])
        segment.selectedSegmentIndex = 0
        segment.translatesAutoresizingMaskIntoConstraints = false
        segment.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        view.addSubview(segment)
        NSLayoutConstraint.activate([
            segment.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 36),
            segment.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            segment.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8)
        ])
    }

    private func setupCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout(for: .list))
        collectionView.backgroundColor = .systemBackground
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: "cell")
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 84),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func makeLayout(for type: LayoutType) -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        let width = UIScreen.main.bounds.width
        switch type {
        case .list:
            layout.itemSize = CGSize(width: width - 32, height: 200)
            layout.minimumLineSpacing = 12
            layout.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        case .grid:
            let size = (width - 4) / 3
            layout.itemSize = CGSize(width: size, height: size)
            layout.minimumInteritemSpacing = 2
            layout.minimumLineSpacing = 2
        case .paging:
            layout.itemSize = CGSize(width: width - 48, height: 280)
            layout.minimumLineSpacing = 16
            layout.sectionInset = UIEdgeInsets(top: 8, left: 24, bottom: 8, right: 24)
            layout.scrollDirection = .horizontal
        }
        return layout
    }

    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        currentLayout = LayoutType(rawValue: sender.selectedSegmentIndex) ?? .list
        let isPaging = currentLayout == .paging
        collectionView.isPagingEnabled = false
        collectionView.decelerationRate = isPaging ? .fast : .normal
        UIView.animate(withDuration: 0.3) {
            self.collectionView.setCollectionViewLayout(self.makeLayout(for: self.currentLayout), animated: false)
        }
        collectionView.reloadData()
    }
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate {
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard currentLayout == .paging else { return }
        let width = UIScreen.main.bounds.width
        let itemWidth = width - 48 + 16
        let offset = targetContentOffset.pointee.x
        let index = (offset + scrollView.contentInset.left) / itemWidth
        let roundedIndex = velocity.x > 0 ? ceil(index) : (velocity.x < 0 ? floor(index) : round(index))
        targetContentOffset.pointee.x = roundedIndex * itemWidth - scrollView.contentInset.left
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        uniqueURLs.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ImageCell
        let isGrid = currentLayout == .grid
        cell.configure(url: uniqueURLs[indexPath.row], showShadow: !isGrid, index: indexPath.row + 1, showIndex: currentLayout == .list)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? ImageCell else { return }
        self.navigationController?.BNImagePage(mImageViewShowFirst: cell.imageView, axImgaePageData: pageData, atIndexPath: indexPath)
    }
}

// MARK: - ImageCell

class ImageCell: UICollectionViewCell {

    let imageView = UIImageView()
    private let skeletonView = UIView()
    private let shimmerLayer = CAGradientLayer()
    private let indexLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        // Skeleton
        skeletonView.backgroundColor = .systemGray5
        skeletonView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(skeletonView)

        // ImageView
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.alpha = 0
        contentView.addSubview(imageView)

        // Index label
        indexLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        indexLabel.textColor = .white
        indexLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        indexLabel.textAlignment = .center
        indexLabel.layer.cornerRadius = 10
        indexLabel.clipsToBounds = true
        indexLabel.translatesAutoresizingMaskIntoConstraints = false
        indexLabel.isHidden = true
        contentView.addSubview(indexLabel)

        NSLayoutConstraint.activate([
            skeletonView.topAnchor.constraint(equalTo: contentView.topAnchor),
            skeletonView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            skeletonView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            skeletonView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            indexLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            indexLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            indexLabel.widthAnchor.constraint(equalToConstant: 28),
            indexLabel.heightAnchor.constraint(equalToConstant: 20)
        ])

        startShimmer()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        shimmerLayer.frame = skeletonView.bounds
    }

    func configure(url: String, showShadow: Bool, index: Int, showIndex: Bool) {
        imageView.image = nil
        imageView.alpha = 0
        skeletonView.isHidden = false
        indexLabel.isHidden = !showIndex
        indexLabel.text = "\(index)"

        // Shadow
        if showShadow {
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = 0.15
            layer.shadowOffset = CGSize(width: 0, height: 4)
            layer.shadowRadius = 8
            layer.cornerRadius = 12
            contentView.layer.cornerRadius = 12
            contentView.clipsToBounds = true
        } else {
            layer.shadowOpacity = 0
            layer.cornerRadius = 0
            contentView.layer.cornerRadius = 0
        }

        guard let nsurl = NSURL(string: url) else { return }
        imageView.setImageFromURL(URL: nsurl) { [weak self] in
            UIView.animate(withDuration: 0.3) {
                self?.imageView.alpha = 1
                self?.skeletonView.isHidden = true
            }
        }
    }

    private func startShimmer() {
        shimmerLayer.colors = [
            UIColor.systemGray5.cgColor,
            UIColor.systemGray4.cgColor,
            UIColor.systemGray5.cgColor
        ]
        shimmerLayer.startPoint = CGPoint(x: 0, y: 0.5)
        shimmerLayer.endPoint = CGPoint(x: 1, y: 0.5)
        shimmerLayer.locations = [0, 0.5, 1]
        skeletonView.layer.addSublayer(shimmerLayer)

        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1, -0.5, 0]
        animation.toValue = [1, 1.5, 2]
        animation.duration = 1.2
        animation.repeatCount = .infinity
        shimmerLayer.add(animation, forKey: "shimmer")
    }
}

// MARK: - UIImageView URL Extension

private var activityIndicatorAssociationKey: UInt8 = 0

extension UIImageView {

    var activityIndicator: UIActivityIndicatorView! {
        get { objc_getAssociatedObject(self, &activityIndicatorAssociationKey) as? UIActivityIndicatorView }
        set { objc_setAssociatedObject(self, &activityIndicatorAssociationKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }

    convenience init(URL: NSURL, errorImage: UIImage? = nil) {
        self.init()
        self.setImageFromURL(URL: URL)
    }

    func setImageFromURL(URL: NSURL, errorImage: UIImage? = nil, completion: (() -> Void)? = nil) {
        URLSession.shared.dataTask(with: URL as URL) { data, _, error in
            OperationQueue.main.addOperation {
                if let data = data, error == nil {
                    self.image = UIImage(data: data)
                } else {
                    self.image = errorImage
                }
                completion?()
            }
        }.resume()
    }
}
