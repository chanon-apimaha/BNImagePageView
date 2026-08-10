# BNImagePageView — Documentation

## Overview

BNImagePageView เป็น iOS image viewer library ที่รองรับทั้ง **UIKit** และ **SwiftUI**  
ใช้สำหรับแสดงภาพแบบ fullscreen พร้อม gesture และ animation ที่ลื่นไหล

```
Swift 5.0+   iOS 10.0+   SwiftUI iOS 13.0+
```

---

## ความสามารถทั้งหมด

### 1. Single Image Viewer

เปิดภาพเดี่ยวแบบ fullscreen พร้อม animation zoom จาก UIImageView ต้นทาง

```
┌─────────────────────────┐
│  ┌───────────────────┐  │
│  │                   │  │
│  │    [ImageView]    │  │  ← tap
│  │                   │  │
│  └───────────────────┘  │
└─────────────────────────┘
            │
            ▼  animate expand
┌─────────────────────────┐
│ ×                    ↑  │  ← close button (top-right)
│                         │
│                         │
│      [Full Image]       │
│                         │
│                         │
│                      ⬆  │  ← share button (bottom-right)
└─────────────────────────┘
```

**UIKit**
```swift
navigationController?.BNImagePage(
    mImageViewShowFirst: imageView,
    sImageUrl: "https://example.com/image.jpg"
)
```

**SwiftUI**
```swift
BNImagePageViewRepresentable(
    imageView: myUIImageView,
    imageURL: "https://example.com/image.jpg"
)
```

---

### 2. Multiple Images (Paging Viewer)

แสดงหลายภาพแบบ swipe left/right พร้อม page indicator

```
┌─────────────────────────┐
│ ×    2 / 5          ↑  │
│                         │
│                         │
│ ◀   [  Image 2  ]   ▶  │  ← swipe left/right
│                         │
│                         │
│                      ⬆  │
└─────────────────────────┘
         ● ○ ○ ○ ○
```

**UIKit**
```swift
navigationController?.BNImagePage(
    mImageViewShowFirst: imageView,
    axImgaePageData: pageDataArray,
    atIndexPath: indexPath
)
```

**SwiftUI**
```swift
BNImagePageViewRepresentable(
    imageView: myUIImageView,
    pageData: pageDataArray,
    atIndexPath: selectedIndexPath
)
```

---

### 3. Hide Share Variant

เหมือน viewer ปกติ แต่ซ่อน share button และ close button มี style ต่างออกไป (ไม่มี background)

```
┌─────────────────────────┐
│ ×                       │  ← close (no background)
│                         │
│      [Full Image]       │
│                         │
│                         │  ← ไม่มี share button
└─────────────────────────┘
```

**UIKit**
```swift
navigationController?.BNImagePageHideShare(
    mImageViewShowFirst: imageView,
    sImageUrl: "https://example.com/image.jpg"
)
```

**SwiftUI**
```swift
BNImagePageViewRepresentable(
    imageView: myUIImageView,
    imageURL: "https://example.com/image.jpg",
    hideShare: true
)
```

---

### 4. Dismiss Animation — ลอยกลับหา Cell

ตอน dismiss ภาพจะ animate ลอยกลับไปหา UIImageView ต้นทาง (cell ที่ user กด)

```
┌─────────────────────────┐        ┌─────────────────────────┐
│                         │        │  ┌──┐ ┌──┐ ┌──┐        │
│      [Full Image]       │  ───▶  │  │  │ │██│ │  │        │
│                         │  fly   │  └──┘ └──┘ └──┘        │
│                         │        │                         │
└─────────────────────────┘        └─────────────────────────┘
                                          ↑ กลับมาที่ cell ที่กด
```

รองรับทั้ง:
- กด **close button** → ภาพลอยกลับ cell ปัจจุบัน
- **drag** ภาพแล้วปล่อย → ภาพลอยกลับ cell ปัจจุบัน

---

### 5. Drag to Dismiss

ลากภาพขึ้น/ลงเพื่อปิด พร้อม background fade ตาม position

```
┌─────────────────────────┐
│                         │
│                         │
│         [Image]         │  ← drag up/down
│            │            │
│            ▼            │
│                         │
└─────────────────────────┘
  background alpha ลดลงตาม
  ระยะที่ลาก
```

เงื่อนไข dismiss:
- velocity + displacement รวมกัน > 40% ของหน้าจอ
- หรือ drag ระยะ Y > 20% ของความสูงหน้าจอ

---

### 6. Pinch to Zoom

zoom เข้า/ออกด้วย 2 นิ้ว หรือ double tap

```
┌─────────────────────────┐
│                         │
│    🤏 pinch out         │  → zoom in (max 3x)
│    🤏 pinch in          │  → zoom out
│    👆👆 double tap      │  → zoom in/out toggle
│                         │
└─────────────────────────┘
```

---

### 7. Share Image

กด share button หรือ long press บนภาพเพื่อแชร์

```
┌─────────────────────────┐
│                         │
│      [Full Image]       │
│                         │
│   long press anywhere   │
│           ↓             │
│  ┌──────────────────┐   │
│  │  Share Sheet     │   │
│  │  Save / Copy ... │   │
│  └──────────────────┘   │
└─────────────────────────┘
```

---

### 8. Image Prefetching

โหลดภาพล่วงหน้าอัตโนมัติ ±1 หน้าจากหน้าปัจจุบัน ด้วย Kingfisher `ImagePrefetcher`

```
Page:  [1]  [2★]  [3]  [4]  [5]
              ↑
         กำลังดูอยู่
         prefetch [1] และ [3] ล่วงหน้า
```

---

### 9. Customization ผ่าน BNSetting

```swift
BNSetting.titlefont = .systemFont(ofSize: 14, weight: .medium)
BNSetting.closeImage = UIImage(named: "my-close-icon")
BNSetting.mButtonClose = myCustomButton
```

| Property | Type | Default |
|---|---|---|
| `titlefont` | `UIFont` | `.systemFont(ofSize: 16)` |
| `closeImage` | `UIImage?` | `icon-close` |
| `mButtonClose` | `UIButton` | default button |

---

### 10. BNImagePageGridViewBuilder

Helper สำหรับสร้าง viewer พร้อม `imageViewForIndex` callback เพื่อให้ dismiss animation ถูกต้อง

```swift
let gridVC = BNImagePageGridViewBuilder.build(
    mImageView: cell.imageView,
    pageData: pageData,
    indexPath: indexPath
) { [weak self] (index: Int) -> UIImageView? in
    let ip = IndexPath(row: index, section: 0)
    return (self?.collectionView.cellForItem(at: ip) as? ImageCell)?.imageView
}
navigationController?.present(gridVC, animated: false)
```

```
imageViewForIndex callback:
  index 0 → cell[0].imageView  ┐
  index 1 → cell[1].imageView  ├─ dismiss จะ animate กลับ cell ที่ถูกต้อง
  index 2 → cell[2].imageView  ┘
```

---

## ImgaePageData Model

```swift
ImgaePageData(
    atIndex: IndexPath(row: 0, section: 0),  // ตำแหน่งใน collection
    sImageUrl: "https://...",                 // URL ของภาพ
    fWidth: 400,                              // ความกว้างภาพ (สำหรับ aspect ratio)
    fHeight: 300                              // ความสูงภาพ
)
```

---

## Orientation Support

BNImagePageView รองรับทุก orientation รวมถึง portrait upside-down

ถ้า app ล็อคแนวตั้ง ให้เพิ่มใน `AppDelegate`:

```swift
func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
    var topController = window?.rootViewController
    while let presented = topController?.presentedViewController {
        topController = presented
    }
    switch topController {
    case is BNImagePageGridView, is BNImagePageGridHideShareView, is BNImagePageViewController:
        return .all
    default:
        return .portrait
    }
}
```

---

## Installation

### Swift Package Manager

```swift
// Package.swift
.package(url: "https://github.com/chanon-apimaha/BNImagePageView.git", from: "0.1.33")
```

หรือใน Xcode: **File > Add Packages** แล้วใส่ URL

### CocoaPods

```ruby
pod 'BNImagePageView'
```

---

## Requirements

| | Minimum |
|---|---|
| iOS | 10.0+ |
| SwiftUI | iOS 13.0+ |
| Swift | 5.0+ |
| Kingfisher | 8.x |

---

## Navigation

[← Back to Index](README.md) | [Open Animation →](OPEN_ANIMATION.md)
