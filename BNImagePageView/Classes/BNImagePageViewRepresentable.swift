import SwiftUI
import UIKit

@available(iOS 15.0, *)
public struct BNImagePageViewRepresentable: UIViewControllerRepresentable {
    let imageView: UIImageView
    let imageURL: String
    let pageData: [ImgaePageData]
    let indexPath: IndexPath
    let pageSpacing: Int
    let hideShare: Bool

    public init(
        imageView: UIImageView,
        imageURL: String,
        pageSpacing: Int = 20,
        hideShare: Bool = false
    ) {
        self.imageView = imageView
        self.imageURL = imageURL
        self.pageSpacing = pageSpacing
        self.hideShare = hideShare
        self.indexPath = IndexPath(row: 0, section: 0)
        self.pageData = [ImgaePageData(
            atIndex: self.indexPath,
            sImageUrl: imageURL,
            fWidth: imageView.image?.size.width ?? 0,
            fHeight: imageView.image?.size.height ?? 0
        )]
    }

    public init(
        imageView: UIImageView,
        pageData: [ImgaePageData],
        atIndexPath: IndexPath,
        pageSpacing: Int = 20,
        hideShare: Bool = false
    ) {
        self.imageView = imageView
        self.imageURL = ""
        self.pageData = pageData
        self.indexPath = atIndexPath
        self.pageSpacing = pageSpacing
        self.hideShare = hideShare
    }

    public func makeUIViewController(context: Context) -> UIViewController {
        let options = [convertFromUIPageViewControllerOptionsKey(UIPageViewController.OptionsKey.interPageSpacing): pageSpacing]
        if hideShare {
            let vc = BNImagePageGridHideShareView(
                mImageView: imageView,
                axImgaePageData: pageData,
                atIndexPath: indexPath,
                transitionStyle: .scroll,
                navigationOrientation: .horizontal,
                options: options
            )
            vc.modalPresentationStyle = .overFullScreen
            return vc
        } else {
            let vc = BNImagePageGridView(
                mImageView: imageView,
                axImgaePageData: pageData,
                atIndexPath: indexPath,
                transitionStyle: .scroll,
                navigationOrientation: .horizontal,
                options: options
            )
            vc.modalPresentationStyle = .overFullScreen
            return vc
        }
    }

    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

fileprivate func convertFromUIPageViewControllerOptionsKey(_ input: UIPageViewController.OptionsKey) -> String {
    return input.rawValue
}
