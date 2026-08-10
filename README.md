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

## Author

Banchai Nangpang, pong.np1@gmail.com

## License

BNImagePageView is available under the MIT license. See the [LICENSE](https://github.com/chanon-apimaha/BNImagePageView/blob/master/LICENSE) file for more info.
