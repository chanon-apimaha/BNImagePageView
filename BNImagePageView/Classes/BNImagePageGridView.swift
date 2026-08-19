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
import Kingfisher

open class BNSetting {
    public static var titlefont: UIFont = .systemFont(ofSize: 16)
    public static var mButtonClose: UIButton = UIButton()
    public static var closeImage: UIImage? = UIImage(systemName: "xmark")?.withRenderingMode(.alwaysTemplate)
}

open class BNImagePageGridView: UIPageViewController {
    private var mImageView: UIImageView!//Require
    private var axImgaePageData: [ImgaePageData]!
    private var atIndexPath: IndexPath!
    private var iNumOfPage: Int = 0
    public var imageViewForIndex: ((Int) -> UIImageView?)?
    
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
    
    open var mButtonClose: UIButton = BNSetting.mButtonClose
    fileprivate var mConsRightClose: NSLayoutConstraint = NSLayoutConstraint()
    fileprivate var mConsTopClose: NSLayoutConstraint = NSLayoutConstraint()
    fileprivate var mConsWidthClose: NSLayoutConstraint = NSLayoutConstraint()
    fileprivate var mConsHeightClose: NSLayoutConstraint = NSLayoutConstraint()
    
    internal var mButtonShare: UIButton = UIButton()
    public var isHideShare: Bool = false
    fileprivate var mConsRightShare: NSLayoutConstraint = NSLayoutConstraint()
    fileprivate var mConsBottomShare: NSLayoutConstraint = NSLayoutConstraint()
    fileprivate var mConsWidthShare: NSLayoutConstraint = NSLayoutConstraint()
    fileprivate var mConsHeightShare: NSLayoutConstraint = NSLayoutConstraint()
    
    // Arrow buttons
    private var mButtonPrev: UIButton = UIButton()
    private var mButtonNext: UIButton = UIButton()

    open var mPageTitle: UIButton = UIButton()
    private var mCaptionLabel: UILabel = UILabel()
    fileprivate var mConsLeftPageTitle: NSLayoutConstraint = NSLayoutConstraint()
    fileprivate var mConsTopPageTitle: NSLayoutConstraint = NSLayoutConstraint()
    fileprivate var mConsWidthPageTitle: NSLayoutConstraint = NSLayoutConstraint()
    fileprivate var mConsHeightPageTitle: NSLayoutConstraint = NSLayoutConstraint()
    
    fileprivate var pageCache: [Int: BNImagePageViewController] = [:]

    fileprivate func getViewController(index: Int) -> BNImagePageViewController {
        if let cached = pageCache[index] { return cached }
        let oViewController = BNImagePageViewController()
        let thumbImageView = UIImageView()
        thumbImageView.contentMode = mImageView.contentMode
        thumbImageView.frame = mImageView.frame
        // ดึง image จาก cell ที่อยู่บนหน้าจอก่อน ถ้าไม่มีค่อยดึงจาก Kingfisher cache
        if let liveImage = imageViewForIndex?(index)?.image {
            thumbImageView.image = liveImage
        } else if let url = URL(string: axImgaePageData[index].sImageUrl),
                  let cached = ImageCache.default.retrieveImageInMemoryCache(forKey: url.absoluteString) {
            thumbImageView.image = cached
        } else if index == atIndexPath.row {
            thumbImageView.image = mImageView.image
        }
        oViewController.mImageView = thumbImageView
        oViewController.sImageUrl = self.axImgaePageData[index].sImageUrl
        oViewController.delegate = self
        oViewController.bIsPagingEnabled = true
        oViewController.bDoAnimate = false
        pageCache[index] = oViewController
        prefetchAdjacent(to: index)
        return oViewController
    }

    private func prefetchAdjacent(to index: Int) {
        let urls = [index - 1, index + 1]
            .filter { $0 >= 0 && $0 < axImgaePageData.count }
            .compactMap { URL(string: axImgaePageData[$0].sImageUrl) }
        ImagePrefetcher(urls: urls).start()
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
        self.setUpArrowButtons()
        
        if self.iNumOfPage > 1 {
            self.setPageTitle()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.rotationView(notification:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        if let index = self.axImgaePageData.firstIndex(where: { $0.atIndex == self.atIndexPath }) {
            let firstVC = getViewController(index: index)
            self.iCurrentIndex = index
            setViewControllers([firstVC], direction: .forward, animated: false, completion: nil)
            self.mPageTitle.setTitle("\(index + 1)/\(self.iNumOfPage)", for: .normal)
            self.mCaptionLabel.text = self.axImgaePageData[index].caption
        }
        
        let oneTapGest = UITapGestureRecognizer(target: self, action: #selector(self.handleOneTapScrollView(recognizer:)))
        oneTapGest.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(oneTapGest)
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.post(name: NSNotification.Name("BNImagePageViewWillPresent"), object: nil)
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.post(name: NSNotification.Name("BNImagePageViewWillDismiss"), object: nil)
        BNOrientationHelper.lockPortrait()
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.view.backgroundColor = .black
        BNOrientationHelper.unlock()
    }
    
    private func setUpButtonClose() {
        self.mButtonClose.setImage(UIImage(systemName: "xmark")?.withRenderingMode(.alwaysTemplate), for: .normal)
        self.mButtonClose.tintColor = .white
        self.mButtonClose.contentEdgeInsets = UIEdgeInsets(top: 5,left: 5,bottom: 5,right: 5) 
        self.mButtonClose.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        self.mButtonClose.clipsToBounds = true
        self.mButtonClose.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.mButtonClose)
        
        self.mConsRightClose = NSLayoutConstraint(
            item: self.mButtonClose,
            attribute: .right,
            relatedBy: .equal,
            toItem: self.view.safeAreaLayoutGuide,
            attribute: .right,
            multiplier: 1,
            constant: 0)
        
        self.mConsTopClose = NSLayoutConstraint(
            item: self.mButtonClose,
            attribute: NSLayoutConstraint.Attribute.top,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: self.view.safeAreaLayoutGuide,
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
        self.mConsTopClose.constant = 8
        self.mConsRightClose.constant = -8
        self.mButtonClose.layer.cornerRadius = self.mConsWidthClose.constant / 2.0
    }

    private func setUpArrowButtons() {
        guard iNumOfPage > 1 else { return }

        func makeArrow(_ systemName: String) -> UIButton {
            let btn = UIButton()
            btn.setImage(UIImage(systemName: systemName)?.withRenderingMode(.alwaysTemplate), for: .normal)
            btn.tintColor = .white
            btn.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            btn.layer.cornerRadius = 20
            btn.clipsToBounds = true
            btn.translatesAutoresizingMaskIntoConstraints = false
            return btn
        }

        mButtonPrev = makeArrow("chevron.left")
        mButtonNext = makeArrow("chevron.right")

        view.addSubview(mButtonPrev)
        view.addSubview(mButtonNext)

        NSLayoutConstraint.activate([
            mButtonPrev.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            mButtonPrev.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            mButtonPrev.widthAnchor.constraint(equalToConstant: 40),
            mButtonPrev.heightAnchor.constraint(equalToConstant: 40),

            mButtonNext.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            mButtonNext.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            mButtonNext.widthAnchor.constraint(equalToConstant: 40),
            mButtonNext.heightAnchor.constraint(equalToConstant: 40),
        ])

        mButtonPrev.addTarget(self, action: #selector(tappedPrev), for: .touchUpInside)
        mButtonNext.addTarget(self, action: #selector(tappedNext), for: .touchUpInside)
        updateArrowVisibility()
    }

    @objc private func tappedPrev() {
        guard iCurrentIndex > 0 else { return }
        let prevIndex = iCurrentIndex - 1
        let vc = getViewController(index: prevIndex)
        setViewControllers([vc], direction: .reverse, animated: true) { [weak self] _ in
            self?.iCurrentIndex = prevIndex
            self?.updateTitleAndArrows(index: prevIndex)
        }
    }

    @objc private func tappedNext() {
        guard iCurrentIndex < iNumOfPage - 1 else { return }
        let nextIndex = iCurrentIndex + 1
        let vc = getViewController(index: nextIndex)
        setViewControllers([vc], direction: .forward, animated: true) { [weak self] _ in
            self?.iCurrentIndex = nextIndex
            self?.updateTitleAndArrows(index: nextIndex)
        }
    }

    private func updateArrowVisibility() {
        mButtonPrev.alpha = iCurrentIndex > 0 ? 1.0 : 0.3
        mButtonNext.alpha = iCurrentIndex < iNumOfPage - 1 ? 1.0 : 0.3
    }

    private func updateTitleAndArrows(index: Int) {
        mPageTitle.setTitle("\(index + 1)/\(iNumOfPage)", for: .normal)
        mCaptionLabel.text = axImgaePageData[index].caption
        updateArrowVisibility()
    }

    private func setUpButtonShare() {
        self.mButtonShare.setImage(UIImage(systemName: "square.and.arrow.up")?.withRenderingMode(.alwaysTemplate), for: .normal)
        self.mButtonShare.tintColor = .white
        self.mButtonShare.clipsToBounds = true
        self.mButtonShare.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        self.mButtonShare.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.mButtonShare)
        
        self.mConsRightShare = NSLayoutConstraint(
            item: self.mButtonShare,
            attribute: .right,
            relatedBy: .equal,
            toItem: self.view.safeAreaLayoutGuide,
            attribute: .right,
            multiplier: 1,
            constant: 0)
        
        self.mConsBottomShare = NSLayoutConstraint(
            item: self.mButtonShare,
            attribute: NSLayoutConstraint.Attribute.bottom,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: self.view.safeAreaLayoutGuide,
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
        
        self.mConsRightShare.constant = -8
        self.mConsBottomShare.constant = -8
        
        self.mConsWidthShare.constant = 40
        self.mConsHeightShare.constant = 40
        if !self.isHideShare { self.mButtonShare.isHidden = false }
        self.mButtonShare.layer.cornerRadius = self.mConsWidthShare.constant / 2.0
    }
    
    func setPageTitle() {
        self.mPageTitle.titleLabel?.font = BNSetting.titlefont
        self.mPageTitle.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        self.mPageTitle.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.mPageTitle)
        
        self.mConsLeftPageTitle = NSLayoutConstraint(
            item: self.mPageTitle,
            attribute: .left,
            relatedBy: .equal,
            toItem: self.view.safeAreaLayoutGuide,
            attribute: .left,
            multiplier: 1,
            constant: 0)
        
        self.mConsTopPageTitle = NSLayoutConstraint(
            item: self.mPageTitle,
            attribute: NSLayoutConstraint.Attribute.top,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: self.view.safeAreaLayoutGuide,
            attribute: NSLayoutConstraint.Attribute.top,
            multiplier: 1,
            constant: 0)
        
        NSLayoutConstraint.activate([self.mConsLeftPageTitle, self.mConsTopPageTitle])
        
        self.mConsTopPageTitle.constant = 8
        self.mConsLeftPageTitle.constant = 8
        self.mPageTitle.isHidden = false
        self.mPageTitle.layer.cornerRadius = 4.0
        self.mPageTitle.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

        // Caption label — center between page number and X button
        mCaptionLabel.textColor = .white
        mCaptionLabel.font = BNSetting.titlefont
        mCaptionLabel.numberOfLines = 0
        mCaptionLabel.textAlignment = .center
        mCaptionLabel.translatesAutoresizingMaskIntoConstraints = false
        mCaptionLabel.layer.shadowColor = UIColor.black.cgColor
        mCaptionLabel.layer.shadowOffset = .zero
        mCaptionLabel.layer.shadowRadius = 3
        mCaptionLabel.layer.shadowOpacity = 1
        mCaptionLabel.layer.shouldRasterize = true
        mCaptionLabel.layer.rasterizationScale = UIScreen.main.scale
        view.addSubview(mCaptionLabel)
        NSLayoutConstraint.activate([
            mCaptionLabel.leadingAnchor.constraint(equalTo: mPageTitle.trailingAnchor, constant: 8),
            mCaptionLabel.trailingAnchor.constraint(equalTo: mButtonClose.leadingAnchor, constant: -8),
            mCaptionLabel.centerYAnchor.constraint(equalTo: mPageTitle.centerYAnchor),
        ])
    }
    
    @objc open func handleOneTapScrollView(recognizer: UITapGestureRecognizer) {
        self.toggleBuutonCloseAndShare()
    }
    
    private func toggleBuutonCloseAndShare(iSecoundDelay: Int = 0) {
        self.work.cancel()
        self.work = DispatchWorkItem(block: {
            if !self.mButtonClose.isHidden && !self.mPageTitle.isHidden {
                self.buttonHide()
            } else {
                self.buttonShow()
            }
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(iSecoundDelay), execute: self.work)
    }
    
    func toggleBuutonCloseAndShareFinFIn(iSecoundDelay: Int = 0) {
        self.work.cancel()
        self.work = DispatchWorkItem(block: {
            if !self.mButtonClose.isHidden && !self.mPageTitle.isHidden {
                self.buttonFinFinHide()
            } else {
                self.buttonFinFInShow()
            }
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(iSecoundDelay), execute: self.work)
    }
    
    private func buttonHide() {
        self.mConsTopPageTitle.constant = 0
        self.mConsTopClose.constant = 0
        self.mConsBottomShare.constant = 0
        
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
        
        UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: {
            self.mPageTitle.alpha = 0
            self.mCaptionLabel.alpha = 0
            self.mButtonClose.alpha = 0
            self.mButtonShare.alpha = 0
            self.mButtonPrev.alpha = 0
            self.mButtonNext.alpha = 0
        }, completion: { _ in
            self.mPageTitle.isHidden = true
            self.mCaptionLabel.isHidden = true
            self.mButtonPrev.isHidden = true
            self.mButtonNext.isHidden = true
            self.mButtonShare.isHidden = true
            self.mButtonClose.isHidden = true
        })
        
        
    }
    
    private func buttonFinFinHide() {
        self.mConsTopPageTitle.constant = 0
        self.mConsTopClose.constant = 0
        self.mConsBottomShare.constant = 0
        
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
        
        UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: {
            self.mPageTitle.alpha = 0
            self.mCaptionLabel.alpha = 0
            self.mButtonClose.alpha = 0
            self.mButtonShare.alpha = 0
            self.mButtonPrev.alpha = 0
            self.mButtonNext.alpha = 0
        }, completion: { _ in
            self.mPageTitle.isHidden = true
            self.mCaptionLabel.isHidden = true
            self.mButtonPrev.isHidden = true
            self.mButtonNext.isHidden = true
            self.mButtonShare.isHidden = true
            self.mButtonClose.isHidden = true
        })
        
        
    }
    
    private func buttonShow() {
        self.mConsTopPageTitle.constant = 8.0
        self.mConsTopClose.constant = 8.0
        self.mConsBottomShare.constant = -8
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
        UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: {
            self.mPageTitle.isHidden = false
            self.mButtonClose.isHidden = false
            if !self.isHideShare { self.mButtonShare.isHidden = false }
            self.mPageTitle.alpha = 1
            self.mButtonClose.alpha = 1
            self.mButtonShare.alpha = 1
            self.mCaptionLabel.isHidden = false
            self.mCaptionLabel.alpha = 1
            self.mButtonPrev.isHidden = false
            self.mButtonNext.isHidden = false
            self.updateArrowVisibility()
        }, completion: { _ in })
    }

    private func buttonFinFInShow() {
        self.mConsTopPageTitle.constant = 8.0
        self.mConsTopClose.constant = 8.0
        self.mConsBottomShare.constant = -8
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
        UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: {
            self.mPageTitle.isHidden = false
            self.mButtonClose.isHidden = false
            if !self.isHideShare { self.mButtonShare.isHidden = false }
            self.mPageTitle.alpha = 1
            self.mButtonClose.alpha = 1
            self.mButtonShare.alpha = 0
            self.mCaptionLabel.isHidden = false
            self.mCaptionLabel.alpha = 1
            self.mButtonPrev.isHidden = false
            self.mButtonNext.isHidden = false
            self.updateArrowVisibility()
        }, completion: { _ in })
    }
    
    @objc private func rotationView(notification: NSNotification) {
    }
}

extension BNImagePageGridView: UIPageViewControllerDataSource, UIPageViewControllerDelegate{
    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed, let oCurrentVC = pageViewController.viewControllers?.first as? BNImagePageViewController,
           let index = pageCache.first(where: { $0.value === oCurrentVC })?.key {
            self.iCurrentIndex = index
            self.mPageTitle.setTitle("\(index + 1)/\(self.iNumOfPage)", for: .normal)
            self.mCaptionLabel.text = self.axImgaePageData[index].caption
            self.updateArrowVisibility()
        }
    }

    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? BNImagePageViewController,
              let index = pageCache.first(where: { $0.value === vc })?.key,
              index - 1 >= 0 else { return nil }
        return getViewController(index: index - 1)
    }

    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? BNImagePageViewController,
              let index = pageCache.first(where: { $0.value === vc })?.key,
              index + 1 < iNumOfPage else { return nil }
        return getViewController(index: index + 1)
    }
}

extension BNImagePageGridView : BNImagePageDelegate {
    func getVisiableViewController(_ viewController: UIViewController) {
        if let oViewController = viewController as? BNImagePageViewController,
           let index = pageCache.first(where: { $0.value === oViewController })?.key {
            if let realImageView = imageViewForIndex?(index) {
                oViewController.mImageView = realImageView
                if let frame = realImageView.superview?.convert(realImageView.frame, to: nil) {
                    oViewController.dismissTargetFrame = frame
                } else if realImageView.superview == nil, realImageView.frame != .zero {
                    // gallery case: UIImageView ไม่มี superview แต่ frame คือ window coordinates โดยตรง
                    oViewController.dismissTargetFrame = realImageView.frame
                } else {
                    oViewController.dismissTargetFrame = nil
                }
            } else if let url = URL(string: axImgaePageData[index].sImageUrl),
                      let cached = ImageCache.default.retrieveImageInMemoryCache(forKey: url.absoluteString) {
                oViewController.mImageView.image = cached
                oViewController.dismissTargetFrame = nil
            }
            oViewController.mButtonShare = self.mButtonShare
            self.mButtonClose.removeTarget(nil, action: nil, for: .allEvents)
            self.mButtonShare.removeTarget(nil, action: nil, for: .allEvents)
            self.mButtonClose.addTarget(oViewController, action: #selector(oViewController.zoomOut2), for: .touchUpInside)
            self.mButtonShare.addTarget(oViewController, action: #selector(oViewController.pressShare), for: .touchUpInside)
        }
    }
}

public struct BNImageBuilder {
    public static func build(
        mImageView: UIImageView,
        pageData: [ImgaePageData],
        indexPath: IndexPath,
        pageSpacing: Int = 20,
        transitionStyle: UIPageViewController.TransitionStyle = .scroll,
        imageViewForIndex: ((Int) -> UIImageView?)? = nil
    ) -> BNImagePageGridView {
        let optionsDict = [convertFromUIPageViewControllerOptionsKey(UIPageViewController.OptionsKey.interPageSpacing): pageSpacing]
        let vc = BNImagePageGridView(
            mImageView: mImageView,
            axImgaePageData: pageData,
            atIndexPath: indexPath,
            transitionStyle: transitionStyle,
            navigationOrientation: .horizontal,
            options: optionsDict)
        vc.imageViewForIndex = imageViewForIndex
        vc.modalPresentationStyle = .overFullScreen
        return vc
    }

    public static func build(
        imageURLs: [String],
        currentIndex: Int = 0,
        sourceImageView: UIImageView? = nil,
        pageSpacing: Int = 20,
        transitionStyle: UIPageViewController.TransitionStyle = .scroll,
        imageViewForIndex: ((Int) -> UIImageView?)? = nil
    ) -> BNImagePageGridView {
        let pageData = imageURLs.enumerated().map {
            ImgaePageData(atIndex: IndexPath(row: $0.offset, section: 0), sImageUrl: $0.element, fWidth: 1, fHeight: 1)
        }
        let safeIndex = max(0, min(currentIndex, imageURLs.count - 1))
        let indexPath = IndexPath(row: safeIndex, section: 0)
        let placeholder = sourceImageView ?? UIImageView()
        let optionsDict = [convertFromUIPageViewControllerOptionsKey(UIPageViewController.OptionsKey.interPageSpacing): pageSpacing]
        let vc = BNImagePageGridView(
            mImageView: placeholder,
            axImgaePageData: pageData,
            atIndexPath: indexPath,
            transitionStyle: transitionStyle,
            navigationOrientation: .horizontal,
            options: optionsDict)
        vc.imageViewForIndex = imageViewForIndex
        vc.modalPresentationStyle = .overFullScreen
        return vc
    }

    public static func build(
        imageURLs: [String],
        captions: [String] = [],
        currentIndex: Int = 0,
        dismissTargetFrame: CGRect,
        hideShare: Bool = false,
        pageSpacing: Int = 20,
        transitionStyle: UIPageViewController.TransitionStyle = .scroll,
        imageViewForIndex: ((Int) -> CGRect?)? = nil
    ) -> BNImagePageGridView {
        let pageData = imageURLs.enumerated().map { item in
            ImgaePageData(
                atIndex: IndexPath(row: item.offset, section: 0),
                sImageUrl: item.element,
                fWidth: 1,
                fHeight: 1,
                caption: captions.indices.contains(item.offset) ? captions[item.offset] : ""
            )
        }
        let safeIndex = max(0, min(currentIndex, imageURLs.count - 1))
        let indexPath = IndexPath(row: safeIndex, section: 0)
        let optionsDict = [convertFromUIPageViewControllerOptionsKey(UIPageViewController.OptionsKey.interPageSpacing): pageSpacing]
        let vc = BNImagePageGridView(
            mImageView: UIImageView(),
            axImgaePageData: pageData,
            atIndexPath: indexPath,
            transitionStyle: transitionStyle,
            navigationOrientation: .horizontal,
            options: optionsDict)
        vc.modalPresentationStyle = .overFullScreen
        if hideShare {
            vc.mButtonShare.isHidden = true
            vc.isHideShare = true
        }
        // set dismissTargetFrame ผ่าน imageViewForIndex
        vc.imageViewForIndex = { index in
            guard let frame = imageViewForIndex?(index) else {
                // ถ้าไม่มี callback ใช้ dismissTargetFrame ของ index แรกเท่านั้น
                return index == safeIndex ? UIImageView(frame: dismissTargetFrame) : nil
            }
            return UIImageView(frame: frame)
        }
        return vc
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
        let size = mImageView.image?.size ?? .zero
        let axImgaePageData = [ImgaePageData(atIndex: atIndexPath, sImageUrl: sImageUrl, fWidth: size.width, fHeight: size.height)]
        self.BNImagePage(mImageViewShowFirst: mImageView, axImgaePageData: axImgaePageData, atIndexPath: atIndexPath, PageSpacing: PageSpacing, transitionStyle: transitionStyle)
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
    
    func BNImagePageHideShare(mImageViewShowFirst mImageView: UIImageView, sImageUrl: String, PageSpacing: Int = 20, transitionStyle: UIPageViewController.TransitionStyle = .scroll) {
        let atIndexPath = IndexPath(row: 0, section: 0)
        let size = mImageView.image?.size ?? .zero
        let axImgaePageData = [ImgaePageData(atIndex: atIndexPath, sImageUrl: sImageUrl, fWidth: size.width, fHeight: size.height)]
        self.BNImagePageHideShare(mImageViewShowFirst: mImageView, axImgaePageData: axImgaePageData, atIndexPath: atIndexPath, PageSpacing: PageSpacing, transitionStyle: transitionStyle)
    }
    
    //แสดงรูป สำหรับแบ่งแสดงเป็นหน้าต่อหนึ่งรูป
    func BNImagePageHideShare(mImageViewShowFirst mImageView: UIImageView, axImgaePageData: [ImgaePageData] , atIndexPath: IndexPath, PageSpacing: Int = 20, transitionStyle: UIPageViewController.TransitionStyle = .scroll) {
        let optionsDict = [convertFromUIPageViewControllerOptionsKey(UIPageViewController.OptionsKey.interPageSpacing) : PageSpacing]
        let oPantipImagePageController = BNImagePageGridHideShareView(
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
