//
//  ViewController.swift
//  BNImagePageView
//

import UIKit
import BNImagePageView

class ViewController: UIViewController {

    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }

    private let imageURLs = [
        "https://picsum.photos/id/237/400/300.jpg",
        "https://picsum.photos/id/10/400/300.jpg",
        "https://picsum.photos/id/20/400/300.jpg",
        "https://picsum.photos/id/30/400/300.jpg",
        "https://picsum.photos/id/40/400/300.jpg",
        "https://picsum.photos/id/50/400/300.jpg"
    ]

    private var pageData: [ImgaePageData] = []
    private var collectionView: UICollectionView!
    private var currentLayout: LayoutType = .list

    enum LayoutType: Int { case list, grid, paging }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        pageData = imageURLs.enumerated().map {
            ImgaePageData(atIndex: IndexPath(row: $0.offset, section: 0), sImageUrl: $0.element, fWidth: 400, fHeight: 300)
        }

        setupSegment()
        setupCollectionView()
    }

    private func setupSegment() {
        let segment = UISegmentedControl(items: ["List", "Grid", "Paging"])
        segment.selectedSegmentIndex = 0
        segment.translatesAutoresizingMaskIntoConstraints = false
        segment.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        view.addSubview(segment)
        NSLayoutConstraint.activate([
            segment.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
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
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 56),
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
            layout.itemSize = CGSize(width: width, height: 200)
            layout.minimumLineSpacing = 1
        case .grid:
            let size = (width - 4) / 3
            layout.itemSize = CGSize(width: size, height: size)
            layout.minimumInteritemSpacing = 2
            layout.minimumLineSpacing = 2
        case .paging:
            layout.itemSize = CGSize(width: width - 32, height: 240)
            layout.minimumLineSpacing = 16
            layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            layout.scrollDirection = .horizontal
        }
        return layout
    }

    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        currentLayout = LayoutType(rawValue: sender.selectedSegmentIndex) ?? .list
        collectionView.setCollectionViewLayout(makeLayout(for: currentLayout), animated: true)
        collectionView.reloadData()
    }
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        imageURLs.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ImageCell
        cell.configure(url: imageURLs[indexPath.row])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? ImageCell else { return }
        self.navigationController?.BNImagePage(mImageViewShowFirst: cell.imageView, axImgaePageData: pageData, atIndexPath: indexPath)
    }
}

class ImageCell: UICollectionViewCell {
    let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(url: String) {
        imageView.image = nil
        guard let nsurl = NSURL(string: url) else { return }
        imageView.setImageFromURL(URL: nsurl)
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

    func setImageFromURL(URL: NSURL, errorImage: UIImage? = nil) {
        if activityIndicator == nil {
            activityIndicator = UIActivityIndicatorView(style: .medium)
            activityIndicator.hidesWhenStopped = true
            activityIndicator.center = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
            OperationQueue.main.addOperation {
                self.addSubview(self.activityIndicator)
                self.activityIndicator.startAnimating()
            }
        }
        URLSession.shared.dataTask(with: URL as URL) { data, _, error in
            OperationQueue.main.addOperation {
                self.activityIndicator.stopAnimating()
                if let data = data, error == nil {
                    self.image = UIImage(data: data)
                } else {
                    self.image = errorImage
                }
            }
        }.resume()
    }
}
