//
//  ViewController.swift
//  BNImagePageView
//

import UIKit
import BNImagePageView
import Kingfisher

class ViewController: UIViewController {

    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }

    private let imageURLs: [String] = [10,20,30,40,50,60,70,80,90,100,110,120,130,140,155,160,170,180,190,200]
        .map { "https://picsum.photos/id/\($0)/400/300.jpg" }

    private var pageData: [ImgaePageData] = []
    private var collectionView: UICollectionView!
    private var pageIndicator: UIPageControl!
    private var headerLabel: UILabel!
    private var currentLayout: LayoutType = .list
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    enum LayoutType: Int { case list, grid, paging }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        feedbackGenerator.prepare()

        pageData = imageURLs.enumerated().map {
            ImgaePageData(atIndex: IndexPath(row: $0.offset, section: 0), sImageUrl: $0.element, fWidth: 400, fHeight: 300)
        }

        setupHeader()
        setupSegment()
        setupCollectionView()
        setupPageIndicator()
        ImagePrefetcher(urls: imageURLs.compactMap { URL(string: $0) }).start()
    }

    private func setupHeader() {
        headerLabel = UILabel()
        headerLabel.text = "\(imageURLs.count) Photos"
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
        collectionView.prefetchDataSource = self
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.showsHorizontalScrollIndicator = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 84),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -60)
        ])
    }

    private func setupPageIndicator() {
        pageIndicator = UIPageControl()
        pageIndicator.numberOfPages = imageURLs.count
        pageIndicator.currentPage = 0
        pageIndicator.pageIndicatorTintColor = .systemGray4
        pageIndicator.currentPageIndicatorTintColor = .label
        pageIndicator.isHidden = true
        pageIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageIndicator)
        NSLayoutConstraint.activate([
            pageIndicator.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            pageIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor)
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
        collectionView.decelerationRate = isPaging ? .fast : .normal
        pageIndicator.isHidden = !isPaging
        UIView.animate(withDuration: 0.3) {
            self.collectionView.setCollectionViewLayout(self.makeLayout(for: self.currentLayout), animated: false)
        }
        collectionView.reloadData()
    }
}

// MARK: - UICollectionView

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        imageURLs.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ImageCell
        let isGrid = currentLayout == .grid
        cell.configure(url: imageURLs[indexPath.row], showShadow: !isGrid, index: indexPath.row + 1, showIndex: currentLayout == .list)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? ImageCell,
              cell.imageView.image != nil else { return }
        feedbackGenerator.impactOccurred()
        let gridVC = BNImagePageGridViewBuilder.build(
            mImageView: cell.imageView,
            pageData: pageData,
            indexPath: indexPath
        ) { [weak self] (index: Int) -> UIImageView? in
            let ip = IndexPath(row: index, section: 0)
            return (self?.collectionView.cellForItem(at: ip) as? ImageCell)?.imageView
        }
        navigationController?.present(gridVC, animated: false)
    }

    // Snap paging
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard currentLayout == .paging else { return }
        let itemWidth = UIScreen.main.bounds.width - 48 + 16
        let offset = targetContentOffset.pointee.x
        let index = (offset + scrollView.contentInset.left) / itemWidth
        let rounded = velocity.x > 0 ? ceil(index) : (velocity.x < 0 ? floor(index) : round(index))
        targetContentOffset.pointee.x = rounded * itemWidth - scrollView.contentInset.left
    }

    // Scale effect + page indicator
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard currentLayout == .paging else { return }
        let width = UIScreen.main.bounds.width - 48 + 16
        let centerX = scrollView.contentOffset.x + scrollView.bounds.width / 2

        for cell in collectionView.visibleCells {
            let offsetX = abs(cell.center.x - centerX)
            let scale = max(0.9, 1 - offsetX / scrollView.bounds.width * 0.3)
            UIView.animate(withDuration: 0.15) {
                cell.transform = CGAffineTransform(scaleX: scale, y: scale)
            }
        }

        let page = Int(round(scrollView.contentOffset.x / width))
        pageIndicator.currentPage = max(0, min(page, imageURLs.count - 1))
    }
}

// MARK: - Prefetch

extension ViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let urls = indexPaths.compactMap { URL(string: imageURLs[$0.row]) }
        ImagePrefetcher(urls: urls).start()
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        let urls = indexPaths.compactMap { URL(string: imageURLs[$0.row]) }
        ImagePrefetcher(urls: urls).stop()
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

        skeletonView.backgroundColor = .systemGray5
        skeletonView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(skeletonView)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.alpha = 0
        contentView.addSubview(imageView)

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
        setupLongPress()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        imageView.alpha = 0
        skeletonView.isHidden = false
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

        guard let url = URL(string: url) else { return }
        imageView.kf.cancelDownloadTask()
        imageView.kf.setImage(with: url, options: [.transition(.fade(0.2)), .cacheOriginalImage]) { [weak self] result in
            guard case .success = result else { return }
            UIView.animate(withDuration: 0.2) {
                self?.imageView.alpha = 1
                self?.skeletonView.isHidden = true
            }
        }
    }

    private func setupLongPress() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.4
        addGestureRecognizer(longPress)
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            UIView.animate(withDuration: 0.15, animations: {
                self.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                self.layer.shadowOpacity = 0.3
            })
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .ended, .cancelled:
            UIView.animate(withDuration: 0.15) {
                self.transform = .identity
                self.layer.shadowOpacity = 0.15
            }
        default: break
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

