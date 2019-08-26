//  Copyright (c) 2019 Banchai Nangpang <pong.np1@gmail.com>

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:

//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.

//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

//  Created by Banchai Nangpang on 18/02/2019 BE.
//

import UIKit
import Photos
import Kingfisher

protocol BNImagePageDelegate: NSObjectProtocol {
    func getVisiableViewController(_ viewController: UIViewController)
}

extension BNImagePageDelegate {
    func getVisiableViewController(_ viewController: UIViewController) {}
}

open class BNImagePageViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    var mImageView: UIImageView!//Require
    var sImageUrl: String!//Require
    fileprivate var fShareSourceRect: CGRect = CGRect.zero
    var mButtonShare: UIButton = UIButton()

    var bDoAnimate: Bool = true
    weak var delegate: BNImagePageDelegate?
    var bIsPagingEnabled: Bool = false

    public var mScrollView: UIScrollView = UIScrollView()
    public var mZoomImageView: UIImageView = UIImageView()
    fileprivate var mLoadingActivity: UIActivityIndicatorView = UIActivityIndicatorView(style: .whiteLarge)
    fileprivate var mShareActivity: UIActivityViewController = UIActivityViewController(activityItems: [], applicationActivities: nil)
    fileprivate var oRetrieveImageTask: DownloadTask!
    fileprivate var oldStatusbarColor: UIStatusBarStyle = UIApplication.shared.statusBarStyle
    fileprivate var panGesture: UIPanGestureRecognizer = UIPanGestureRecognizer()
    fileprivate var bIsShowImage: Bool = true
    fileprivate var iLoadImageCount: Int = 0
    fileprivate var bIsShowShareActivity: Bool = false

    fileprivate var fStartpointY: CGFloat = 0.0
    fileprivate var fEndpointY: CGFloat = 0.0
    fileprivate var fStartpointX: CGFloat = 0.0
    fileprivate var fEndpointX: CGFloat = 0.0
    fileprivate var bIsOut: Bool = false

    var work: DispatchWorkItem = DispatchWorkItem(block: {})

    override open func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black
        if self.oRetrieveImageTask != nil {
            self.oRetrieveImageTask.cancel()
        }

        if self.bIsPagingEnabled {
            self.clearCacheImage()
        }
        self.animateImageView()
        if self.bIsShowImage {
            self.mScrollView.setZoomScale(self.mScrollView.minimumZoomScale, animated: true)

            if let startingFrame = self.mImageView.superview?.convert(self.mImageView.frame, to: nil) {
                self.mZoomImageView.frame = startingFrame
                if self.sImageUrl != "" {
                    self.mZoomImageView.BNaddBlurEffect()
                }
                self.panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.draggedView))
                self.panGesture.delegate = self
                self.mScrollView.isUserInteractionEnabled = true
                self.mScrollView.addGestureRecognizer(self.panGesture)

                if self.bDoAnimate {
                    UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: { () -> Void in
                        self.setZoomImageFrame(imageSize: (self.mImageView.image?.size)!)
                        self.mImageView.alpha = 0
                        self.mZoomImageView.alpha = 1
                        self.view.backgroundColor = UIColor.black.withAlphaComponent(1.0)
                    }, completion: { (didComplete) -> Void in
                        self.loadImage()
                    })
                } else {
                    self.setZoomImageFrame(imageSize: (self.mImageView.image?.size)!)
                    self.mImageView.alpha = 0
                    self.mZoomImageView.alpha = 1
                    self.view.backgroundColor = UIColor.black.withAlphaComponent(1.0)
                    self.loadImage()
                }
            }
        }
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //UIApplication.shared.statusBarStyle = self.oldStatusbarColor
        if self.mImageView.alpha < 1 {
            self.resetZoomScaleToMinimum()
        }
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.delegate?.getVisiableViewController(self)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didChangeStatusBarOrientationNotification, object: nil);
    }

    public func loadImage() {
        self.iLoadImageCount = self.iLoadImageCount + 1
        if self.sImageUrl != "" {
            self.mScrollView.isUserInteractionEnabled = false
            self.mLoadingActivity.startAnimating()
            self.mLoadingActivity.center = self.mZoomImageView.center
            guard let bundleURL:URL = URL(string: self.sImageUrl)
                else {
                    self.faceOutBlurEffect()
                    self.mLoadingActivity.stopAnimating()
                    self.bIsShowImage = false
                    return
            }

            let resource = ImageResource(downloadURL: bundleURL, cacheKey: "overImage")
            
            self.oRetrieveImageTask = self.mZoomImageView.kf.setImage(with: resource, placeholder: self.mImageView.image, options: [.transition(.fade(0.15)), .cacheMemoryOnly], progressBlock: nil) { (result) in
                switch result {
                case .success(_):
                    self.setZoomImageFrame(imageSize: (self.mZoomImageView.image?.size)!)
                    self.mLoadingActivity.stopAnimating()
                    self.faceOutBlurEffect()
                    self.clearCacheImage()
                    self.bIsShowImage = false
                    break
                case .failure(_):
                    self.setZoomImageFrame(imageSize: (self.mImageView.image?.size)!)
                    if self.iLoadImageCount < 3 {
                        self.loadImage()
                    } else {
                        self.faceOutBlurEffect()
                        self.mLoadingActivity.stopAnimating()
                        self.bIsShowImage = false
                    }
                }
                 self.mScrollView.isUserInteractionEnabled = true
            }
            
            
//            self.oRetrieveImageTask = self.mZoomImageView.kf.setImage(with: resource, placeholder: self.mImageView.image, options: [.transition(.fade(0.15))], progressBlock: nil, completionHandler: { (image, error, cacheType, Url) in
//                if error == nil {
//                    self.setZoomImageFrame(imageSize: (self.mZoomImageView.image?.size)!)
//                    self.mLoadingActivity.stopAnimating()
//                    self.faceOutBlurEffect()
//                    self.clearCacheImage()
//                    self.bIsShowImage = false
//                } else {
//                    self.setZoomImageFrame(imageSize: (self.mImageView.image?.size)!)
//                    if self.iLoadImageCount < 3 {
//                        self.loadImage()
//                    } else {
//                        self.faceOutBlurEffect()
//                        self.mLoadingActivity.stopAnimating()
//                        self.bIsShowImage = false
//                    }
//                }
//                self.mScrollView.isUserInteractionEnabled = true
//            })
        } else {
            self.bIsShowImage = false
        }
    }

    private func faceOutBlurEffect() {
        UIView.animate(withDuration: 0.5, animations: {
            self.mZoomImageView.subviews.last?.alpha = 0.0
        }) { (didComplete) in
            self.mZoomImageView.subviews.last?.removeFromSuperview()
        }
    }

    private func clearCacheImage () {
        ImageCache.default.removeImage(forKey: "overImage")
    }

    @objc public func animateImageView() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.rotationView(notification:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        self.setUpScrollView()
        self.setUpIndicatorView()
    }

    private func setUpIndicatorView() {
        self.mLoadingActivity.center = self.view.center
        self.view.addSubview(self.mLoadingActivity)
    }

    private func setUpScrollView() {
        self.setUpmZoomImageView()
        self.mScrollView.delegate = self
        self.mScrollView.alwaysBounceVertical = false
        self.mScrollView.alwaysBounceHorizontal = false
        self.mScrollView.showsVerticalScrollIndicator = false
        self.mScrollView.showsHorizontalScrollIndicator = false
        self.mScrollView.flashScrollIndicators()
        self.mScrollView.contentSize = self.mZoomImageView.frame.size
        self.mScrollView.translatesAutoresizingMaskIntoConstraints = false
        self.mScrollView.addSubview(self.mZoomImageView)
        self.view.addSubview(self.mScrollView)

        self.mScrollView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.mScrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.mScrollView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.mScrollView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.setMaxMinZoomScalesForCurrentBounds()
        self.mScrollView.setZoomScale(self.mScrollView.minimumZoomScale, animated: true)

        let longTapGest = UILongPressGestureRecognizer(target: self, action: #selector(self.pressLongShare))
        let doubleTapGest = UITapGestureRecognizer(target: self, action: #selector(self.handleDoubleTapScrollView(recognizer:)))
        doubleTapGest.numberOfTapsRequired = 2
        self.mScrollView.addGestureRecognizer(longTapGest)
        self.mZoomImageView.addGestureRecognizer(doubleTapGest)
    }

    private func setUpmZoomImageView() {
        self.mZoomImageView.isUserInteractionEnabled = true
        self.mZoomImageView.image = self.mImageView.image
        self.mZoomImageView.contentMode = .scaleAspectFill
        self.mZoomImageView.clipsToBounds = true
        self.mZoomImageView.alpha = 0
        self.setZoomImageFrame(imageSize: (self.mImageView.image?.size)!)
    }

    private func setZoomImageFrame(imageSize: CGSize) {
        if let keyWindow = UIApplication.shared.keyWindow {
            var height: CGFloat = 0.0
            var width: CGFloat = 0.0
            var y: CGFloat = 0.0
            var x: CGFloat = 0.0
            if (keyWindow.frame.width) < (keyWindow.frame.height) {
                width = (keyWindow.frame.width)
                height  = ((keyWindow.frame.width) / imageSize.width) * imageSize.height
                y = (keyWindow.frame.height) / 2 - height / 2

                if height > keyWindow.frame.height {
                    width = (keyWindow.frame.height / imageSize.height) * imageSize.width
                    height = keyWindow.frame.height
                    x = (keyWindow.frame.width) / 2 - width / 2
                    y = 0.0
                }
            } else if (keyWindow.frame.width) > (keyWindow.frame.height) {
                width  = ((keyWindow.frame.height) / imageSize.height) * imageSize.width
                height = (keyWindow.frame.height)
                x = (keyWindow.frame.width) / 2 - width / 2

                if width > keyWindow.frame.width {
                    height = (keyWindow.frame.width / imageSize.width) * imageSize.height
                    width = keyWindow.frame.width
                    x = 0.0
                    y = (keyWindow.frame.height) / 2 - height / 2
                }
            }
            self.mZoomImageView.frame = CGRect(x: x, y: y, width: width, height: height)
        }
    }

    @objc private func handleDoubleTapScrollView(recognizer: UITapGestureRecognizer) {
        if self.mScrollView.zoomScale == self.mScrollView.minimumZoomScale {
            self.mScrollView.zoom(to: zoomRectForScale(scale: self.mScrollView.maximumZoomScale, center: recognizer.location(in: recognizer.view)), animated: true)

        } else {
            self.mScrollView.setZoomScale(self.mScrollView.minimumZoomScale, animated: true)
        }
    }

    private func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = self.mZoomImageView.frame.size.height / scale
        zoomRect.size.width  = self.mZoomImageView.frame.size.width  / scale
        let newCenter = self.mZoomImageView.convert(center, from: self.mScrollView)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }

    @objc public func zoomOut() {
        self.work.cancel()
        if self.oRetrieveImageTask != nil {
            self.oRetrieveImageTask.cancel()
        }

        if self.mLoadingActivity.isAnimating {
            self.mLoadingActivity.stopAnimating()
        }

        if !(UIDevice.current.userInterfaceIdiom == .pad) {
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        }
        self.mScrollView.setZoomScale(self.mScrollView.minimumZoomScale, animated: true)

        if let startingFrame = self.mImageView.superview?.convert(self.mImageView.frame, to: nil) {
            self.mImageView.alpha = 0
            if let oViewController = self.delegate as? BNImagePageGridView {
                oViewController.mButtonClose.alpha = 0.0
                oViewController.mButtonShare.alpha = oViewController.mButtonClose.alpha
                oViewController.mPageTitle.alpha = oViewController.mButtonClose.alpha
            }
            self.mZoomImageView.image = self.mImageView.image
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                self.mZoomImageView.frame = startingFrame
                self.mLoadingActivity.center = self.mZoomImageView.center
                self.view.backgroundColor = UIColor.black.withAlphaComponent(0.0)
            }, completion: { (didComplete) -> Void in
                self.mLoadingActivity.removeFromSuperview()
                self.mZoomImageView.subviews.last?.removeFromSuperview()
                self.mZoomImageView.removeFromSuperview()
                self.mScrollView.removeFromSuperview()
                self.clearCacheImage()
                self.mImageView.alpha = 1
                self.dismiss(animated: false, completion: nil)
                if let oViewController = self.delegate as? UIViewController {
                    oViewController.dismiss(animated: false, completion: nil)
                }
            })
        }
    }

    override open func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            self.view.backgroundColor = self.view.backgroundColor?.withAlphaComponent(1.0)
        }, completion:nil)
    }

    @objc private func rotationView(notification: NSNotification) {
        self.mLoadingActivity.center = self.view.center
        self.mScrollView.setZoomScale(self.mScrollView.minimumZoomScale, animated: true)
        self.setZoomImageFrame(imageSize: (self.mZoomImageView.image?.size)!)
        self.mScrollView.contentSize = self.mZoomImageView.frame.size
        self.setMaxMinZoomScalesForCurrentBounds()

        //ซ่อนปุ่มเมื่อ Rotation ตามเงื่อนไข
        self.mShareActivity.dismiss(animated: true) {
            self.bIsShowShareActivity = false
        }
    }

    @objc func pressShare(_ sender: UIButton) {
        if !self.bIsShowImage && (self.mZoomImageView.subviews.count <= 0) {
            self.fShareSourceRect = self.mButtonShare.frame
            self.requestAuthorizationIfNeeded()
        }
    }

    @objc func pressLongShare(_ gestureRecognizer: UIGestureRecognizer) {
        if self.presentedViewController == nil {
            if !self.bIsShowImage && (self.mZoomImageView.subviews.count <= 0) {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    let location = gestureRecognizer.location(in: self.mScrollView)
                    let coordinate = mScrollView.convert(location, to: self.mScrollView)
                    self.fShareSourceRect = CGRect(x: coordinate.x, y: (coordinate.y), width: 0, height: 0)
                }
                self.requestAuthorizationIfNeeded()
            }
        }
    }

    private func okAuthorized(){
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                if let mZoomView = self.mZoomImageView.image {
                    self.mShareActivity = UIActivityViewController(activityItems: [mZoomView], applicationActivities: nil)
                    if #available(iOS 11.0, *) {
                        self.mShareActivity.excludedActivityTypes = [.addToReadingList, .airDrop, .assignToContact, .copyToPasteboard, .mail, .markupAsPDF, .message, .openInIBooks, .print, .postToWeibo, .postToTencentWeibo, .postToFlickr, .postToVimeo, .postToFacebook]
                    } else {
                        self.mShareActivity.excludedActivityTypes = [.addToReadingList, .airDrop, .assignToContact, .copyToPasteboard, .mail, .message, .openInIBooks, .print, .postToWeibo, .postToTencentWeibo, .postToFlickr, .postToVimeo, .postToFacebook]
                    }
                    self.mShareActivity.popoverPresentationController?.sourceView = self.mScrollView
                    self.mShareActivity.popoverPresentationController?.delegate = self

                    // เมื่อปิด popOver เปลี่ยนค่า bIsShowShareActivity = false
                    self.mShareActivity.completionWithItemsHandler = { activity, success, items, error in
                        self.bIsShowShareActivity = false
                    }


                    if UIDevice.current.userInterfaceIdiom == .pad {
                        self.mShareActivity.popoverPresentationController?.sourceRect = self.fShareSourceRect
                    }

                    self.present(self.mShareActivity, animated: true, completion:{
                        self.bIsShowShareActivity = true
                    })
                }

            }
        }
    }

    private func requestAuthorizationIfNeeded() {
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)
        switch authorizationStatus {
        case .authorized:
            self.okAuthorized()
        case .denied:
            self.alertPhotoPermission()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (status) in
                if status == PHAuthorizationStatus.authorized {
                    self.okAuthorized()
                } else {
                    self.alertPhotoPermission()
                }
            })
        case .restricted:
            self.alertPhotoPermission()
        @unknown default:
            break
        }
    }

    private func alertPhotoPermission() {
//        DispatchQueue.main.async {
//            Util.dialog.multiNotice(
//                sTitle: "ALERT".stringLocalized(),
//                sMessage: "PHOTO_PERMISSION".stringLocalized(),
//                iMessageAlignMent: .center,
//                axAlertAction: [
//                    .decline : .red,
//                    .setting :  UIColor(sColor: PTConfig.customColor.ButtonColor.uiColorBgBlue)
//                ],
//                target: self,
//                callbackHandler:{ (action,_) in
//                    switch action {
//                    case .decline: break
//                    case .setting:
//                        let settingsUrl = NSURL(string: UIApplication.openSettingsURLString)
//                        if let url = settingsUrl as URL? {
//                            UIApplication.shared.openURL(url)
//                        }
//                        break
//                    default:
//                        break
//                    }
//            })
//        }
    }

    override  open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        ImageCache.default.clearDiskCache()
        ImageCache.default.clearMemoryCache()
        ImageCache.default.cleanExpiredDiskCache()
    }
}

extension BNImagePageViewController: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.mZoomImageView
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView){
        let scrollViewSize: CGSize = self.scrollViewVisibleSize();
        var imageCenter: CGPoint = CGPoint(x: self.mScrollView.contentSize.width/2.0, y:
            self.mScrollView.contentSize.height/2.0)
        let scrollViewCenter:CGPoint = self.scrollViewCenter()
        if (self.mScrollView.contentSize.width < scrollViewSize.width) {
            imageCenter.x = scrollViewCenter.x
        }

        if (self.mScrollView.contentSize.height < scrollViewSize.height) {
            imageCenter.y = scrollViewCenter.y
        }

        self.mZoomImageView.center = imageCenter
    }

    //return the scroll view center
    func scrollViewCenter() -> CGPoint {
        let scrollViewSize:CGSize = self.scrollViewVisibleSize()
        return CGPoint(x: scrollViewSize.width/2.0, y: scrollViewSize.height/2.0)
    }

    // Return scrollview size without the area overlapping with tab and nav bar.
    func scrollViewVisibleSize() -> CGSize{
        let contentInset:UIEdgeInsets = self.mScrollView.contentInset;
        let scrollViewSize:CGSize = self.mScrollView.bounds.standardized.size;
        let width:CGFloat = scrollViewSize.width - contentInset.left - contentInset.right;
        let height:CGFloat = scrollViewSize.height - contentInset.top - contentInset.bottom;
        return CGSize(width:width, height:height)
    }

    func setMaxMinZoomScalesForCurrentBounds() {
        if let keyWindow = UIApplication.shared.keyWindow {
            let scrollViewFrame = keyWindow.bounds
            let scaleWidth = scrollViewFrame.size.width / self.mScrollView.contentSize.width
            let scaleHeight = scrollViewFrame.size.height / self.mScrollView.contentSize.height
            var minScale = min(scaleWidth, scaleHeight)
            let maxScale = max(scaleWidth, scaleHeight)
            if minScale > maxScale {
                minScale = maxScale
            }
            self.mScrollView.maximumZoomScale = (maxScale < 3) ? 3.0 : maxScale
            self.mScrollView.minimumZoomScale =  (minScale < 1) ? 1.0 : minScale
        }
    }
}

extension BNImagePageViewController: UIGestureRecognizerDelegate {
     public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let oPanGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let translation = oPanGestureRecognizer.translation(in: self.view)
            if (fabsf(Float(translation.y)) > fabsf(Float(translation.x)))  {
                return true
            } else {
                return false
            }
        }
        return true
    }

     public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let oPanGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let translation = oPanGestureRecognizer.translation(in: self.view)
            if (fabsf(Float(translation.y)) > fabsf(Float(translation.x)))  {
                if (self.mScrollView.zoomScale <= self.mScrollView.minimumZoomScale) {
                    return false
                }
            }
        }
        return true
    }

    @objc func draggedView(_ sender:UIPanGestureRecognizer){
        if self.mScrollView.zoomScale <= self.mScrollView.minimumZoomScale {
            var topMostWindowController : UIViewController? {
                var topController: UIViewController? = UIApplication.shared.keyWindow?.rootViewController

                //  Getting topMost ViewController
                while ((topController?.presentedViewController) != nil) {
                    topController = topController?.presentedViewController
                }

                //  Returning topMost ViewController
                return topController
            }

            let oWindow = topMostWindowController
            oWindow?.view.bringSubviewToFront(self.mZoomImageView)
            let velocity = sender.velocity(in: self.mZoomImageView)
            let translation = sender.translation(in: oWindow?.view)
            self.mZoomImageView.center = CGPoint(x: self.mZoomImageView.center.x + translation.x, y: self.mZoomImageView.center.y + translation.y )

            self.mLoadingActivity.center = self.mZoomImageView.center
            sender.setTranslation(CGPoint.zero, in: oWindow?.view)

            var progressYPositionAfterShortTime = abs(translation.y + velocity.y * 0.2) / self.mScrollView.frame.height
            progressYPositionAfterShortTime = min(1, max(0, progressYPositionAfterShortTime))
            let point = sender.location(in: oWindow?.view)

            //set ZoomImage background alpha
            let fZoomImageCenterPositionOnScreen = ((self.mZoomImageView.frame.origin.y + (self.mZoomImageView.frame.height / 2 )) / UIScreen.main.bounds.height)
            if fZoomImageCenterPositionOnScreen >= 0.5 {
                //ลากรูปไปส่วนบน
                let fAlpha: CGFloat = {
                    var fAlpha: CGFloat = 0.5
                    if fZoomImageCenterPositionOnScreen <= 1.0 {
                        fAlpha = fAlpha / fZoomImageCenterPositionOnScreen
                    } else {
                        fAlpha = fAlpha / 1.0
                    }
                    return fAlpha }()
                self.view.backgroundColor = self.view.backgroundColor?.withAlphaComponent(fAlpha)
                if let oViewController = self.delegate as? BNImagePageGridView {
                    oViewController.view.backgroundColor = .clear
                    oViewController.mButtonClose.alpha = ((fAlpha) - 0.5) * 2
                    oViewController.mButtonShare.alpha = oViewController.mButtonClose.alpha
                    oViewController.mPageTitle.alpha = oViewController.mButtonClose.alpha
                }
            } else {
                //ลากรูปไปส่วนล่าง
                let fAlpha: CGFloat = {
                    var fAlpha: CGFloat = 0.5
                    if fZoomImageCenterPositionOnScreen > 0 {
                        fAlpha = fAlpha + fZoomImageCenterPositionOnScreen
                    }
                    return fAlpha }()
                self.view.backgroundColor = self.view.backgroundColor?.withAlphaComponent(fAlpha)
                if let oViewController = self.delegate as? BNImagePageGridView {
                    oViewController.view.backgroundColor = .clear
                    oViewController.mButtonClose.alpha = ((fAlpha) - 0.5) * 2
                    oViewController.mButtonShare.alpha = oViewController.mButtonClose.alpha
                    oViewController.mPageTitle.alpha = oViewController.mButtonClose.alpha
                }
            }

            switch sender.state {
            case .began:
                //จับจุดเริ่มต้นของการลากรูป
                self.fStartpointY = point.y
                self.fStartpointX = point.x
            case .ended:
                //เมื่อจบการลากรูป หากเข้าเงื่อไขปิดดูรูปก็จะปิดดูรูป ถ้ามไม่เข้าเงื่อไขการปิด รูปจะเด้งกลับไปตำแหน่งเดิม
                self.fEndpointY = point.y//จุดสิ้นสุดของการลากรูป แกน Y
                self.fEndpointX = point.x//จุดสิ้นสุดของการลากรูป แกน X

                if ( progressYPositionAfterShortTime > 0.4) {
                    //การลากรูปบวกกับความแรงของการลากมากกว่า 40%
                    //ปิดดูรูป
                    self.zoomOut()
                } else {
                    //หากการลากรูปบวกกับความแรงของการลากน้อยกว่า 40%
                    //จะเพิ่มเงื่อนไขการปล่อยนิ้วเพื่อปิดรูป โดยกำหนดเพิ่มที่สำหรับการปิด ด้านบนหน้าจอและด้านล่างหน้าจอ วัดการขอบ บน 20% และล่าง 20% ของหน้าจอ
                    self.bIsOut = false
                    if self.fStartpointY > self.fEndpointY {
                        self.bIsOut = ((self.fStartpointY - self.fEndpointY) > ((UIScreen.main.bounds.height / 10)*2)) ? true : false
                    } else if self.fStartpointY < self.fEndpointY {
                        self.bIsOut = ((self.fEndpointY - self.fStartpointY) > ((UIScreen.main.bounds.height / 10)*2)) ? true : false
                    }

                    //ตรวจสอบความเป็นไปได้ที่จะปิดดูรูป
                    if self.bIsOut {
                        //ปิดดูรูป
                        self.zoomOut()
                    } else {
                        self.resetZoomScaleToMinimum()
                    }
                }
            default:
                break
            }
        }
    }

    func resetZoomScaleToMinimum() {
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            self.view.backgroundColor = self.view.backgroundColor?.withAlphaComponent(1)
            self.mZoomImageView.center = self.view.center
            self.mLoadingActivity.center = self.mZoomImageView.center
            self.mScrollView.setZoomScale(self.mScrollView.minimumZoomScale, animated: true)
        }, completion: { (bool) in
            if let oViewController = self.delegate as? BNImagePageGridView {
                oViewController.view.backgroundColor = .black
                oViewController.mButtonClose.alpha = 1.0
                oViewController.mButtonShare.alpha = 1.0
                oViewController.mPageTitle.alpha = 1.0
            }
        })
    }
}

extension UIView {
    public func BNaddBlurEffect(Style: UIBlurEffect.Style = .extraLight) {
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.extraLight)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(blurEffectView)
    }
}
