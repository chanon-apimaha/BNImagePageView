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

open class BNImagePageGridView: UIPageViewController {
    private var mImageView: UIImageView!//Require
    private var axImgaePageData: [ImgaePageData]!
    private var atIndexPath: IndexPath!
    private var iNumOfPage: Int = 0
    
    init(mImageView: UIImageView, axImgaePageData: [ImgaePageData], atIndexPath: IndexPath, transitionStyle: UIPageViewController.TransitionStyle, navigationOrientation: UIPageViewController.NavigationOrientation, options: [String : Any]?) {
        super.init(
            transitionStyle: transitionStyle,
            navigationOrientation: navigationOrientation,
            options: convertToOptionalUIPageViewControllerOptionsKeyDictionary(options)
        )
        self.mImageView = mImageView
        self.axImgaePageData = axImgaePageData
        self.atIndexPath = atIndexPath
        self.iNumOfPage = self.axImgaePageData.count
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    var work: DispatchWorkItem = DispatchWorkItem(block: {})
    
    fileprivate var iCurrentIndex: Int = 0
    
    internal var mButtonClose: UIButton = UIButton()
    fileprivate var mConsRightClose: NSLayoutConstraint = NSLayoutConstraint()
    fileprivate var mConsTopClose: NSLayoutConstraint = NSLayoutConstraint()
    fileprivate var mConsWidthClose: NSLayoutConstraint = NSLayoutConstraint()
    fileprivate var mConsHeightClose: NSLayoutConstraint = NSLayoutConstraint()
    
    internal var mButtonShare: UIButton = UIButton()
    fileprivate var mConsRightShare: NSLayoutConstraint = NSLayoutConstraint()
    fileprivate var mConsBottomShare: NSLayoutConstraint = NSLayoutConstraint()
    fileprivate var mConsWidthShare: NSLayoutConstraint = NSLayoutConstraint()
    fileprivate var mConsHeightShare: NSLayoutConstraint = NSLayoutConstraint()
    
    internal var mPageTitle: UIButton = UIButton()
    fileprivate var mConsLeftPageTitle: NSLayoutConstraint = NSLayoutConstraint()
    fileprivate var mConsTopPageTitle: NSLayoutConstraint = NSLayoutConstraint()
    fileprivate var mConsWidthPageTitle: NSLayoutConstraint = NSLayoutConstraint()
    fileprivate var mConsHeightPageTitle: NSLayoutConstraint = NSLayoutConstraint()
    
    fileprivate lazy var pages: [UIViewController] = {
        var axViewController: [UIViewController] = []
        for index in 0 ..< self.axImgaePageData.endIndex {
            axViewController.append(self.getViewController(index: index))
        }
        return axViewController
    }()
    
    fileprivate func getViewController(index: Int) -> UIViewController
    {
        let oViewController = BNImagePageViewController()
        oViewController.mImageView = mImageView
        oViewController.sImageUrl = self.axImgaePageData[index].sImageUrl
        oViewController.delegate = self
        oViewController.bIsPagingEnabled = true
        oViewController.bDoAnimate = false
        return oViewController
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didChangeStatusBarOrientationNotification, object: nil);
    }
    
    override open func viewDidLoad()
    {
        super.viewDidLoad()
        self.dataSource = self
        self.delegate = self
        self.setUpButtonClose()
        self.setUpButtonShare()
        
        if self.iNumOfPage > 1 {
            self.setPageTitle()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.rotationView(notification:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        if let index = self.axImgaePageData.firstIndex(where: { (item) -> Bool in
            item.atIndex == self.atIndexPath
        }) {
            let firstVC = pages[index] as UIViewController
            self.iCurrentIndex = index
            setViewControllers([firstVC], direction: .forward, animated: false, completion: nil)
            self.mPageTitle.setTitle("\(index + 1)/\(self.iNumOfPage)", for: .normal)
        }
        
        let oneTapGest = UITapGestureRecognizer(target: self, action: #selector(self.handleOneTapScrollView(recognizer:)))
        oneTapGest.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(oneTapGest)
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.view.backgroundColor = .black
    }
    
    private func setUpButtonClose() {
        self.mButtonClose.setImage(UIImage(named:"icon-close")?.withRenderingMode(.alwaysTemplate), for: .normal)
        self.mButtonClose.tintColor = .white
        self.mButtonClose.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        self.mButtonClose.clipsToBounds = true
        self.mButtonClose.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.mButtonClose)
        
        self.mConsRightClose = NSLayoutConstraint(
            item: self.mButtonClose,
            attribute: .right,
            relatedBy: .equal,
            toItem: self.view,
            attribute: .right,
            multiplier: 1,
            constant: 0)
        
        self.mConsTopClose = NSLayoutConstraint(
            item: self.mButtonClose,
            attribute: NSLayoutConstraint.Attribute.top,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: self.view,
            attribute: NSLayoutConstraint.Attribute.top,
            multiplier: 1,
            constant: 0)
        
        self.mConsWidthClose = NSLayoutConstraint(
            item: self.mButtonClose,
            attribute: NSLayoutConstraint.Attribute.width,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: nil,
            attribute: NSLayoutConstraint.Attribute.notAnAttribute,
            multiplier: 1,
            constant: 0)
        
        self.mConsHeightClose = NSLayoutConstraint(
            item: self.mButtonClose,
            attribute: NSLayoutConstraint.Attribute.height,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: nil,
            attribute: NSLayoutConstraint.Attribute.notAnAttribute,
            multiplier: 1,
            constant: 0)
        
        NSLayoutConstraint.activate([self.mConsRightClose, self.mConsTopClose, self.mConsWidthClose, self.mConsHeightClose])
        
        self.mConsWidthClose.constant = 40.0
        self.mConsHeightClose.constant = 40.0
        self.mConsTopClose.constant = 34
        self.mConsRightClose.constant =  (UIDevice.current.userInterfaceIdiom == .pad ) ? -16 : -8
        self.mButtonClose.layer.cornerRadius = self.mConsWidthClose.constant / 2.0
    }
    
    private func setUpButtonShare() {
        self.mButtonShare.setImage(UIImage(named:"icon-share")?.withRenderingMode(.alwaysTemplate), for: .normal)
        self.mButtonShare.tintColor = .white
        self.mButtonShare.clipsToBounds = true
        self.mButtonShare.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        self.mButtonShare.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.mButtonShare)
        
        self.mConsRightShare = NSLayoutConstraint(
            item: self.mButtonShare,
            attribute: .right,
            relatedBy: .equal,
            toItem: self.view,
            attribute: .right,
            multiplier: 1,
            constant: 0)
        
        self.mConsBottomShare = NSLayoutConstraint(
            item: self.mButtonShare,
            attribute: NSLayoutConstraint.Attribute.bottom,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: self.view,
            attribute: NSLayoutConstraint.Attribute.bottom,
            multiplier: 1,
            constant: 0)
        
        self.mConsWidthShare = NSLayoutConstraint(
            item: self.mButtonShare,
            attribute: NSLayoutConstraint.Attribute.width,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: nil,
            attribute: NSLayoutConstraint.Attribute.notAnAttribute,
            multiplier: 1,
            constant: 0)
        
        self.mConsHeightShare = NSLayoutConstraint(
            item: self.mButtonShare,
            attribute: NSLayoutConstraint.Attribute.height,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: nil,
            attribute: NSLayoutConstraint.Attribute.notAnAttribute,
            multiplier: 1,
            constant: 0)
        
        NSLayoutConstraint.activate([self.mConsRightShare, self.mConsBottomShare, self.mConsWidthShare, self.mConsHeightShare])
        
        self.mConsRightShare.constant =  (UIDevice.current.userInterfaceIdiom == .pad) ? -16 : -8
        
        if #available(iOS 11.0, *) {
            self.mConsBottomShare.constant =  (UIDevice.current.userInterfaceIdiom == .pad ) ? -32 : -24
        } else {
            self.mConsBottomShare.constant =  (UIDevice.current.userInterfaceIdiom == .pad ) ? -16 : -8
        }
        
        self.mConsWidthShare.constant = 40
        self.mConsHeightShare.constant = 40
        self.mButtonShare.isHidden = false
        self.mButtonShare.layer.cornerRadius = self.mConsWidthShare.constant / 2.0
    }
    
    func setPageTitle() {
        self.mPageTitle.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        self.mPageTitle.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.mPageTitle)
        
        self.mConsLeftPageTitle = NSLayoutConstraint(
            item: self.mPageTitle,
            attribute: .left,
            relatedBy: .equal,
            toItem: self.view,
            attribute: .left,
            multiplier: 1,
            constant: 0)
        
        self.mConsTopPageTitle = NSLayoutConstraint(
            item: self.mPageTitle,
            attribute: NSLayoutConstraint.Attribute.top,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: self.view,
            attribute: NSLayoutConstraint.Attribute.top,
            multiplier: 1,
            constant: 0)
        
        NSLayoutConstraint.activate([self.mConsLeftPageTitle, self.mConsTopPageTitle])
        
        self.mConsTopPageTitle.constant = 34
        self.mConsLeftPageTitle.constant =  (UIDevice.current.userInterfaceIdiom == .pad ) ? 16 : 8
        self.mPageTitle.isHidden = false
        self.mPageTitle.layer.cornerRadius = 4.0//PTConfig.layerStyle.fCornerRadius
        self.mPageTitle.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
    }
    
    @objc private func handleOneTapScrollView(recognizer: UITapGestureRecognizer) {
        self.toggleBuutonCloseAndShare()
    }
    
    private func toggleBuutonCloseAndShare(iSecoundDelay: Int = 0) {
        self.work.cancel()
        self.work = DispatchWorkItem(block: {
            if !self.mButtonClose.isHidden && !self.mButtonShare.isHidden && !self.mPageTitle.isHidden {
                self.buttonHide()
            } else {
                self.buttonShow()
            }
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(iSecoundDelay), execute: self.work)
    }
    
    private func buttonHide() {
        self.mConsTopPageTitle.constant = self.mConsTopPageTitle.constant * 0.5
        self.mConsTopClose.constant = self.mConsTopClose.constant * 0.5
        self.mConsBottomShare.constant =  self.mConsBottomShare.constant * 0.5
        
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
        
        UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: {
            self.mPageTitle.alpha = 0
            self.mButtonClose.alpha = 0
            self.mButtonShare.alpha = 0
        }, completion: { _ in
            self.mPageTitle.isHidden = true
            self.mButtonShare.isHidden = true
            self.mButtonClose.isHidden = true
        })
        
        
    }
    
    private func buttonShow() {
        self.mConsTopPageTitle.constant = 34.0
        self.mConsTopClose.constant = 34.0
        
        
        if #available(iOS 11.0, *) {
            self.mConsBottomShare.constant =  (UIDevice.current.userInterfaceIdiom == .pad) ? -32 : -24
        } else {
            self.mConsBottomShare.constant =  (UIDevice.current.userInterfaceIdiom == .pad) ? -16 : -8
        }
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
        UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: {
            self.mPageTitle.isHidden = false
            self.mButtonClose.isHidden = false
            self.mButtonShare.isHidden = false
            self.mPageTitle.alpha = 1
            self.mButtonClose.alpha = 1
            self.mButtonShare.alpha = 1
        }, completion: { (didComplete) -> Void in
        })
    }
    
    @objc private func rotationView(notification: NSNotification) {
        self.buttonHide()
    }
}

extension BNImagePageGridView: UIPageViewControllerDataSource, UIPageViewControllerDelegate{
    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            if let axChildVC = pageViewController.viewControllers,
                let oCurrentVC = axChildVC.first as? BNImagePageViewController, let index = self.pages.firstIndex(of: oCurrentVC) {
                self.iCurrentIndex = index
                self.mPageTitle.setTitle("\(index + 1)/\(self.iNumOfPage)", for: .normal)
            }
        }
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = pages.firstIndex(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard pages.count > previousIndex else {
            return nil
        }
        
        return pages[previousIndex]
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = pages.firstIndex(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        let pagesCount = pages.count
        
        guard pagesCount != nextIndex else {
            return nil
        }
        
        guard pagesCount > nextIndex else {
            return nil
        }
        
        return pages[nextIndex]
    }
}

extension BNImagePageGridView : BNImagePageDelegate {
    func getVisiableViewController(_ viewController: UIViewController) {
        if let oViewController = viewController as? BNImagePageViewController {
            oViewController.mButtonShare = self.mButtonShare
            self.mButtonClose.removeTarget(nil, action: nil, for: .allEvents)
            self.mButtonShare.removeTarget(nil, action: nil, for: .allEvents)
            self.mButtonClose.addTarget(oViewController, action: #selector(oViewController.zoomOut2), for: .touchUpInside)
            self.mButtonShare.addTarget(oViewController, action: #selector(oViewController.pressShare), for: .touchUpInside)
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalUIPageViewControllerOptionsKeyDictionary(_ input: [String: Any]?) -> [UIPageViewController.OptionsKey: Any]? {
    guard let input = input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIPageViewController.OptionsKey(rawValue: key), value)})
}


public extension UINavigationController {
    //แสดงรูป สำหรับรูปเดียว  ไม่เกี่ยวกับหน้าอ่านกระทุ้
    func BNImagePage(mImageViewShowFirst mImageView: UIImageView, sImageUrl: String, PageSpacing: Int = 20, transitionStyle: UIPageViewController.TransitionStyle = .scroll) {
        let atIndexPath = IndexPath(row: 0, section: 0)
        var axImgaePageData: [ImgaePageData] = []
        let axInfomation = NSMutableAttributedString()
        axInfomation.append(NSAttributedString(string:""))
        axImgaePageData.append(ImgaePageData(
            atIndex: atIndexPath,
            sImageUrl: sImageUrl,
            fWidth: (mImageView.image?.size.width)!,
            fHeight: (mImageView.image?.size.height)!))
        self.BNImagePage(mImageViewShowFirst: mImageView, axImgaePageData: axImgaePageData, atIndexPath: atIndexPath,PageSpacing: PageSpacing, transitionStyle: transitionStyle)
    }
    
    //แสดงรูป สำหรับแบ่งแสดงเป็นหน้าต่อหนึ่งรูป
    func BNImagePage(mImageViewShowFirst mImageView: UIImageView, axImgaePageData: [ImgaePageData] , atIndexPath: IndexPath, PageSpacing: Int = 20, transitionStyle: UIPageViewController.TransitionStyle = .scroll) {
        let optionsDict = [convertFromUIPageViewControllerOptionsKey(UIPageViewController.OptionsKey.interPageSpacing) : PageSpacing]
        let oPantipImagePageController = BNImagePageGridView(
            mImageView:  mImageView,
            axImgaePageData: axImgaePageData,
            atIndexPath: atIndexPath,
            transitionStyle: transitionStyle,
            navigationOrientation: .horizontal,
            options: optionsDict)
        oPantipImagePageController.modalPresentationStyle = .overFullScreen
        self.present(oPantipImagePageController, animated: false, completion: nil)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIPageViewControllerOptionsKey(_ input: UIPageViewController.OptionsKey) -> String {
    return input.rawValue
}
