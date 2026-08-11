# BNImagePageView — Documentation Index

## Quick Start

```swift
// UIKit
navigationController?.BNImagePage(mImageViewShowFirst: imageView, sImageUrl: url)

// SwiftUI
BNImagePageViewRepresentable(imageView: imageView, imageURL: url)
```

---

## Table of Contents

### 📖 Overview
- [OVERVIEW.md](OVERVIEW.md) — ภาพรวมทุก feature พร้อม UI mockup

### 🎬 Animations
- [OPEN_ANIMATION.md](OPEN_ANIMATION.md) — flow ตั้งแต่ tap cell จนภาพ expand fullscreen
- [DRAG_DISMISS.md](DRAG_DISMISS.md) — ทุกทิศทาง drag dismiss + decision tree

### 🖼️ Viewer Behavior
- [ZOOM_PAN.md](ZOOM_PAN.md) — pinch to zoom, double tap, pan, rotation
- [PAGING.md](PAGING.md) — page cache, prefetch, counter, transition
- [SHARE.md](SHARE.md) — short press, long press, iPad popover, permission flow

### ⚙️ Configuration
- [CUSTOMIZATION.md](CUSTOMIZATION.md) — BNSetting: font, icon, button
- [SWIFTUI.md](SWIFTUI.md) — BNImagePageViewRepresentable ทุก variant

### 🏗️ Internals
- [ARCHITECTURE.md](ARCHITECTURE.md) — class diagram, data flow, lifecycle

### 🎨 UI/UX
- [UI_UX.md](UI_UX.md) — layout ปัจจุบัน, ปัญหา, แนวทางปรับปรุง

---

## Feature Map

```
BNImagePageView
│
├── UIKit API
│   ├── UINavigationController.BNImagePage(sImageUrl:)          → OVERVIEW.md
│   ├── UINavigationController.BNImagePage(axImgaePageData:)    → PAGING.md
│   ├── UINavigationController.BNImagePageHideShare(...)        → CUSTOMIZATION.md
│   └── BNImagePageBuilder.build(...)                   → ARCHITECTURE.md
│
├── SwiftUI API
│   └── BNImagePageViewRepresentable                            → SWIFTUI.md
│
├── Animations
│   ├── Open (expand from cell)                                 → OPEN_ANIMATION.md
│   ├── Dismiss (fly back to cell)                              → DRAG_DISMISS.md
│   └── Drag to dismiss (all directions)                        → DRAG_DISMISS.md
│
├── Gestures
│   ├── Pinch to zoom                                           → ZOOM_PAN.md
│   ├── Double tap zoom                                         → ZOOM_PAN.md
│   ├── Pan while zoomed                                        → ZOOM_PAN.md
│   ├── Swipe left/right (paging)                               → PAGING.md
│   ├── Drag up/down (dismiss)                                  → DRAG_DISMISS.md
│   └── Long press (share)                                      → SHARE.md
│
├── Customization
│   ├── BNSetting.titlefont                                     → CUSTOMIZATION.md
│   ├── BNSetting.closeImage                                    → CUSTOMIZATION.md
│   └── BNSetting.mButtonClose                                  → CUSTOMIZATION.md
│
└── Internals
    ├── BNImagePageViewController                               → ARCHITECTURE.md
    ├── BNImagePageGridView                                     → ARCHITECTURE.md
    ├── pageCache                                               → PAGING.md
    ├── dismissTargetFrame                                      → DRAG_DISMISS.md
    └── Kingfisher integration                                  → ARCHITECTURE.md
```
