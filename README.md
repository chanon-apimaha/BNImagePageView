# BNImagePageView

[![Version](https://img.shields.io/cocoapods/v/BNImagePageView.svg?style=flat)](https://cocoapods.org/pods/BNImagePageView)
[![License](https://img.shields.io/cocoapods/l/BNImagePageView.svg?style=flat)](https://github.com/chanon-apimaha/BNImagePageView/blob/master/LICENSE)
[![Platform](https://img.shields.io/cocoapods/p/BNImagePageView.svg?style=flat)](https://cocoapods.org/pods/BNImagePageView)

## Example

![Screenshot](http://g.recordit.co/VuMp165R8w.gif)

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

```
Swift 5.0, iOS 10.0+
SwiftUI support requires iOS 13.0+
```

## Privacy

If your app uses the share button, add the following to your app's `Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Used to save images to your photo library</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Used to save images to your photo library</string>
```

> **Note:** Without this, the app will crash when the user attempts to save an image.

## Installation

### Swift Package Manager

Add the following to your `Package.swift` dependencies:

```swift
.package(url: "https://github.com/chanon-apimaha/BNImagePageView.git", from: "0.1.33")
```

Or in Xcode: **File > Add Packages** and enter the repository URL.

### CocoaPods

```ruby
pod 'BNImagePageView'
```

## Usage

### UIKit

```swift
// Single image
navigationController?.BNImagePage(mImageViewShowFirst: imageView, sImageUrl: "https://example.com/image.jpg")

// Multiple images
navigationController?.BNImagePage(mImageViewShowFirst: imageView, axImgaePageData: pageDataArray, atIndexPath: indexPath)

// Hide share button variant
navigationController?.BNImagePageHideShare(mImageViewShowFirst: imageView, sImageUrl: "https://example.com/image.jpg")
```

### UIKit — BNImageBuilder (แนะนำ)

```swift
// ส่งแค่ URLs ไม่ต้องสร้าง ImgaePageData เอง
let vc = BNImageBuilder.build(
    imageURLs: ["https://example.com/1.jpg", "https://example.com/2.jpg"],
    currentIndex: indexPath.row,
    sourceImageView: cell.imageView
) { index in
    (collectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? MyCell)?.imageView
}
present(vc, animated: false)
```

### SwiftUI

```swift
// Single image
BNImagePageViewRepresentable(
    imageView: myUIImageView,
    imageURL: "https://example.com/image.jpg"
)

// Multiple images
BNImagePageViewRepresentable(
    imageView: myUIImageView,
    pageData: pageDataArray,
    atIndexPath: selectedIndexPath
)

// Hide share button
BNImagePageViewRepresentable(
    imageView: myUIImageView,
    imageURL: "https://example.com/image.jpg",
    hideShare: true
)
```

## Orientation Support

BNImagePageView supports all orientations including landscape and portrait upside-down.

If your app is locked to portrait only, add this to your `AppDelegate` to allow BNImagePageView to rotate freely while keeping the rest of your app in portrait:

```swift
func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
    var topController = window?.rootViewController
    var allControllers: [UIViewController] = []
    while let presented = topController?.presentedViewController {
        allControllers.append(presented)
        topController = presented
    }
    let isBNPresent = allControllers.contains {
        $0 is BNImagePageGridView || $0 is BNImagePageGridHideShareView || $0 is BNImagePageViewController
    }
    if isBNPresent { return .all }
    let isBNDismissing = allControllers.contains { $0.isBeingDismissed &&
        ($0 is BNImagePageGridView || $0 is BNImagePageGridHideShareView || $0 is BNImagePageViewController)
    }
    if isBNDismissing { return .all }
    return .portrait
}
```

> **Note:** Without this, iOS will ignore the library's orientation support and the viewer will stay locked to your app's orientation setting.

## Author

Banchai Nangpang, pong.np1@gmail.com

## Documentation

ดู [docs/README.md](docs/README.md) สำหรับรายละเอียดทุก feature

| | |
|---|---|
| [Overview](docs/OVERVIEW.md) | ภาพรวมทุก feature |
| [Open Animation](docs/OPEN_ANIMATION.md) | flow ตั้งแต่ tap จนภาพ expand |
| [Drag Dismiss](docs/DRAG_DISMISS.md) | ทุกทิศทาง drag dismiss |
| [Zoom & Pan](docs/ZOOM_PAN.md) | pinch, double tap, pan |
| [Paging](docs/PAGING.md) | page cache, prefetch, counter |
| [Share](docs/SHARE.md) | share sheet, popover, permission |
| [Customization](docs/CUSTOMIZATION.md) | BNSetting |
| [SwiftUI](docs/SWIFTUI.md) | BNImagePageViewRepresentable |
| [Architecture](docs/ARCHITECTURE.md) | class diagram, data flow |
| [UI/UX](docs/UI_UX.md) | layout ปัจจุบัน และแนวทางปรับปรุง |
| [Roadmap](docs/ROADMAP.md) | แผนงาน builder improvement และ gallery cell |

## Author

Banchai Nangpang, pong.np1@gmail.com

## License

BNImagePageView is available under the MIT license. See the [LICENSE](https://github.com/chanon-apimaha/BNImagePageView/blob/master/LICENSE) file for more info.
