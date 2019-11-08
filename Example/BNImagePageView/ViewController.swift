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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let mImageView: UIImageView = UIImageView(URL: NSURL(string: "https://homepages.cae.wisc.edu/~ece533/images/airplane.png")!)
        mImageView.isUserInteractionEnabled = true
        self.view.addSubview(mImageView)
        mImageView.translatesAutoresizingMaskIntoConstraints = false
        
        mImageView.widthAnchor.constraint(equalToConstant: 200.0).isActive = true
        mImageView.heightAnchor.constraint(equalToConstant: 100.0).isActive = true
        mImageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        mImageView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        let doubleTapGest = UITapGestureRecognizer(target: self, action: #selector(self.handleDoubleTapScrollView(recognizer:)))
        mImageView.addGestureRecognizer(doubleTapGest)
        BNSetting.titlefont = .systemFont(ofSize: 100)
        
        // mImageView.image = UIImage(
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc private func handleDoubleTapScrollView(recognizer: UITapGestureRecognizer) {
        if let mImageView = recognizer.view as? UIImageView {
        self.navigationController?.BNImagePageHideShare(mImageViewShowFirst: mImageView, sImageUrl: "https://homepages.cae.wisc.edu/~ece533/images/airplane.png")
        }
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
            self.activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
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
