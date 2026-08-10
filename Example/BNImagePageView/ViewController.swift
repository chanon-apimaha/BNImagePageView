//
//  ViewController.swift
//  BNImagePageView
//
//  Created by ban nan on 02/18/2019.
//  Copyright (c) 2019 ban nan. All rights reserved.
//

import UIKit
import BNImagePageView

class ViewController: UIViewController {
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    private let imageURLs = [
        "https://picsum.photos/id/237/400/300.jpg",
        "https://picsum.photos/id/10/400/300.jpg",
        "https://picsum.photos/id/20/400/300.jpg",
        "https://picsum.photos/id/30/400/300.jpg"
    ]
    private var pageData: [ImgaePageData] = []
    private var imageViews: [UIImageView] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        for (i, url) in imageURLs.enumerated() {
            let iv = UIImageView(URL: NSURL(string: url)!)
            iv.isUserInteractionEnabled = true
            iv.contentMode = .scaleAspectFill
            iv.clipsToBounds = true
            iv.translatesAutoresizingMaskIntoConstraints = false
            iv.widthAnchor.constraint(equalToConstant: 200).isActive = true
            iv.heightAnchor.constraint(equalToConstant: 120).isActive = true
            iv.tag = i
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            iv.addGestureRecognizer(tap)
            stack.addArrangedSubview(iv)
            imageViews.append(iv)
            pageData.append(ImgaePageData(atIndex: IndexPath(row: i, section: 0), sImageUrl: url, fWidth: 400, fHeight: 300))
        }
    }

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard let iv = recognizer.view as? UIImageView else { return }
        let indexPath = IndexPath(row: iv.tag, section: 0)
        self.navigationController?.BNImagePage(mImageViewShowFirst: iv, axImgaePageData: pageData, atIndexPath: indexPath)
    }
    
}

import Foundation
import UIKit
import ObjectiveC

private var activityIndicatorAssociationKey: UInt8 = 0

extension UIImageView {
    
    var activityIndicator: UIActivityIndicatorView! {
        get {
            return objc_getAssociatedObject(self, &activityIndicatorAssociationKey) as? UIActivityIndicatorView
        }
        set(newValue) {//OBJC_ASSOCIATION_RETAIN
            objc_setAssociatedObject(self, &activityIndicatorAssociationKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    private func ensureActivityIndicatorIsAnimating() {
        if (self.activityIndicator == nil) {
            self.activityIndicator = UIActivityIndicatorView(style: .medium)
            self.activityIndicator.hidesWhenStopped = true
            let size = self.frame.size;
            self.activityIndicator.center = CGPoint(x: size.width/2, y: size.height/2);
            OperationQueue.main.addOperation({ () -> Void in
                self.addSubview(self.activityIndicator)
                self.activityIndicator.startAnimating()
            })
        }
    }
    
    convenience init(URL: NSURL, errorImage: UIImage? = nil) {
        self.init()
        self.setImageFromURL(URL: URL)
    }
    
    func setImageFromURL(URL: NSURL, errorImage: UIImage? = nil) {
        self.ensureActivityIndicatorIsAnimating()
        let downloadTask = URLSession.shared.dataTask(with: URL as URL) {(data, response, error) in
            if (error == nil) {
                OperationQueue.main.addOperation({ () -> Void in
                    self.activityIndicator.stopAnimating()
                    self.image = UIImage(data: data!)
                })
            }
            else {
                self.image = errorImage
            }
        }
        downloadTask.resume()
    }
}
