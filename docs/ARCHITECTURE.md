# Architecture Overview — Class Diagram & Relationships

## Class Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        BNImagePageView SPM                       │
│                                                                  │
│  ┌──────────────┐     ┌──────────────────────────────────────┐  │
│  │  BNSetting   │     │         BNImagePageGridView           │  │
│  │  (open class)│     │         (open class)                  │  │
│  │              │     │         UIPageViewController          │  │
│  │ + titlefont  │◄────│                                       │  │
│  │ + mButtonClose│    │ - mImageView: UIImageView             │  │
│  │ + closeImage │     │ - axImgaePageData: [ImgaePageData]    │  │
│  └──────────────┘     │ - atIndexPath: IndexPath              │  │
│                        │ - pageCache: [Int: BNImagePageVC]    │  │
│                        │ + imageViewForIndex: ((Int)->UIImageView?)│
│                        │ + mButtonClose: UIButton             │  │
│                        │ + mButtonShare: UIButton             │  │
│                        │ + mPageTitle: UIButton               │  │
│                        │                                       │  │
│                        │ + getViewController(index:)          │  │
│                        │ + prefetchAdjacent(to:)              │  │
│                        └──────────────┬───────────────────────┘  │
│                                       │ inherits                  │
│                        ┌──────────────▼───────────────────────┐  │
│                        │    BNImagePageGridHideShareView       │  │
│                        │    (open class)                       │  │
│                        │                                       │  │
│                        │ override viewDidLoad()                │  │
│                        │ override handleOneTapScrollView()     │  │
│                        └──────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              BNImagePageViewController                    │   │
│  │              (open class) UIViewController                │   │
│  │                                                           │   │
│  │ + mImageView: UIImageView        (thumbnail / cell ref)  │   │
│  │ + sImageUrl: String              (URL to load)           │   │
│  │ + mScrollView: UIScrollView                              │   │
│  │ + mZoomImageView: UIImageView    (full res display)      │   │
│  │ + bDoAnimate: Bool               (open animation)        │   │
│  │ + bIsPagingEnabled: Bool                                 │   │
│  │ + dismissTargetFrame: CGRect?    (for dismiss animation) │   │
│  │ + delegate: BNImagePageDelegate?                         │   │
│  │                                                           │   │
│  │ + loadImage()                                            │   │
│  │ + zoomOut()    (drag dismiss)                            │   │
│  │ + zoomOut2()   (button dismiss)                          │   │
│  │ + animateImageView()                                     │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────┐   ┌──────────────────────────────┐   │
│  │    ImgaePageData     │   │  BNImagePageBuilder   │   │
│  │    (class)           │   │  (public struct)              │   │
│  │                      │   │                               │   │
│  │ + atIndex: IndexPath │   │ + build(                      │   │
│  │ + sImageUrl: String  │   │     mImageView:               │   │
│  │ + fWidth: CGFloat    │   │     pageData:                 │   │
│  │ + fHeight: CGFloat   │   │     indexPath:                │   │
│  └──────────────────────┘   │     pageSpacing:              │   │
│                              │     transitionStyle:          │   │
│  ┌──────────────────────┐   │     imageViewForIndex:        │   │
│  │BNImagePageViewRepre- │   │   ) -> BNImagePageGridView    │   │
│  │sentable              │   └──────────────────────────────┘   │
│  │(public struct)       │                                       │
│  │UIViewControllerRepre-│                                       │
│  │sentable              │                                       │
│  │@available(iOS 15.0+) │                                       │
│  └──────────────────────┘                                       │
└─────────────────────────────────────────────────────────────────┘
```

---

## Protocol Relationships

```
BNImagePageDelegate (protocol)
        │
        │ conforms
        ▼
BNImagePageGridView
        │
        │ holds weak ref
        ▼
BNImagePageViewController.delegate: BNImagePageDelegate?

flow:
  BNImagePageViewController.viewDidAppear
    → delegate?.getVisiableViewController(self)
    → BNImagePageGridView.getVisiableViewController(_:)
    → อัพเดต mImageView, dismissTargetFrame, button targets
```

---

## Data Flow

```
ViewController (App)
        │
        │ สร้าง pageData: [ImgaePageData]
        │ สร้าง imageViewForIndex callback
        │
        ▼
BNImagePageBuilder.build(...)
        │
        ▼
BNImagePageGridView (UIPageViewController)
        │
        ├── pageCache: [Int: BNImagePageViewController]
        │       │
        │       ▼
        │   BNImagePageViewController (per page)
        │       │
        │       ├── mImageView (thumbnail)
        │       ├── mZoomImageView (full res display)
        │       ├── mScrollView (zoom/pan)
        │       └── dismissTargetFrame (for dismiss)
        │
        ├── imageViewForIndex callback
        │       │
        │       ▼
        │   cell.imageView (live reference)
        │
        └── Kingfisher ImagePrefetcher
                │
                ▼
            URL → memory/disk cache
```

---

## Inheritance Chain

```
UIViewController
    └── BNImagePageViewController
            (single page viewer)

UIPageViewController
    └── BNImagePageGridView
            (multi-page container)
            └── BNImagePageGridHideShareView (open class)
                    (hide share variant)

UIViewControllerRepresentable
    └── BNImagePageViewRepresentable
            (SwiftUI wrapper)
```

---

## File Structure

```
BNImagePageView/Classes/
├── BNImagePageView.swift
│   ├── protocol BNImagePageDelegate
│   ├── open class BNImagePageViewController
│   └── extension UIView (BNaddBlurEffect)
│
├── BNImagePageGridView.swift
│   ├── open class BNSetting
│   ├── open class BNImagePageGridView
│   ├── extension BNImagePageGridView: UIPageViewControllerDataSource
│   ├── extension BNImagePageGridView: UIPageViewControllerDelegate
│   ├── extension BNImagePageGridView: BNImagePageDelegate
│   ├── public struct BNImagePageBuilder
│   └── public extension UINavigationController
│       ├── BNImagePage(sImageUrl:)
│       ├── BNImagePage(axImgaePageData:)
│       ├── BNImagePageHideShare(sImageUrl:)
│       └── BNImagePageHideShare(axImgaePageData:)
│
├── BNImagePageGridHideShareView.swift
│   └── open class BNImagePageGridHideShareView: BNImagePageGridView
│
├── BNImagePageViewRepresentable.swift
│   └── public struct BNImagePageViewRepresentable
│
└── ImgaePageData.swift
    └── public class ImgaePageData
```

---

## Lifecycle ของ BNImagePageViewController

```
init
  │
  ▼
viewDidLoad
  ├── animateImageView() → setUpScrollView() → setUpmZoomImageView()
  ├── setUpIndicatorView()
  ├── คำนวณ startingFrame
  ├── BNaddBlurEffect (ถ้ามี URL)
  └── animate open → loadImage()
  │
  ▼
viewDidAppear
  └── delegate?.getVisiableViewController(self)
        └── อัพเดต mImageView, dismissTargetFrame, button targets
  │
  ▼
[user interaction]
  ├── pinch/double tap → zoom
  ├── pan (Y > X, zoom=min) → drag to dismiss
  ├── tap → toggle buttons
  ├── long press → share
  └── close button → zoomOut2()
  │
  ▼
viewWillDisappear
  └── ถ้า mImageView.alpha < 1 → resetZoomScaleToMinimum()
  │
  ▼
deinit
  └── removeObserver (rotation notification)
```

---

## Kingfisher Integration Points

```
BNImagePageViewController.loadImage()
  └── mZoomImageView.kf.setImage(with: URL, ...)
        options: [
          .transition(.fade(0.15)),
          .diskCacheExpiration(.never),
          .memoryCacheExpiration(.never)
        ]

BNImagePageGridView.prefetchAdjacent(to:)
  └── ImagePrefetcher(urls: [URL]).start()

BNImagePageGridView.getViewController(index:)
  └── ImageCache.default.retrieveImageInMemoryCache(forKey: url)
        ← ดึง thumbnail จาก cache สำหรับ off-screen cells

BNImagePageViewController.clearCacheImage()
  └── ImageCache.default.clearMemoryCache()
        ← เรียกหลังโหลดภาพสำเร็จ และตอน dismiss

BNImagePageViewController.didReceiveMemoryWarning()
  └── ImageCache.default.clearDiskCache()
      ImageCache.default.clearMemoryCache()
      ImageCache.default.cleanExpiredDiskCache()
```

---

## UINavigationController Extensions

```swift
// 4 convenience methods บน UINavigationController:

navigationController?.BNImagePage(
    mImageViewShowFirst: imageView,
    sImageUrl: url
)
// → สร้าง pageData 1 item → BNImagePage(axImgaePageData:)

navigationController?.BNImagePage(
    mImageViewShowFirst: imageView,
    axImgaePageData: pageData,
    atIndexPath: indexPath
)
// → สร้าง BNImagePageGridView → present

navigationController?.BNImagePageHideShare(
    mImageViewShowFirst: imageView,
    sImageUrl: url
)
// → สร้าง pageData 1 item → BNImagePageHideShare(axImgaePageData:)

navigationController?.BNImagePageHideShare(
    mImageViewShowFirst: imageView,
    axImgaePageData: pageData,
    atIndexPath: indexPath
)
// → สร้าง BNImagePageGridHideShareView → present
```

**หมายเหตุ**: methods เหล่านี้ไม่รองรับ `imageViewForIndex` callback  
ถ้าต้องการ dismiss animation ที่สมบูรณ์ ให้ใช้ `BNImagePageBuilder.build()`

---

## Navigation

[← SwiftUI](SWIFTUI.md) | [Back to Index](README.md) | [UI/UX →](UI_UX.md)
