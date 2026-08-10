# SwiftUI Integration — BNImagePageViewRepresentable

## Overview

`BNImagePageViewRepresentable` เป็น `UIViewControllerRepresentable`  
ที่ wrap `BNImagePageGridView` ให้ใช้ใน SwiftUI ได้  
รองรับ iOS 15.0+

---

## Single Image

```swift
BNImagePageViewRepresentable(
    imageView: myUIImageView,
    imageURL: "https://example.com/image.jpg"
)
```

```
SwiftUI View:
┌─────────────────────────┐
│                         │
│  Image(...)             │
│    .onTapGesture {      │
│      showViewer = true  │
│    }                    │
│                         │
└─────────────────────────┘
        │ tap
        ▼
┌─────────────────────────┐
│ ×                    ↑  │
│                         │
│      [  Image  ]        │
│                         │
└─────────────────────────┘
```

### ตัวอย่างเต็ม

```swift
struct ContentView: View {
    @State private var showViewer = false
    private let imageView = UIImageView()

    var body: some View {
        AsyncImage(url: URL(string: "https://example.com/image.jpg")) { image in
            image
                .resizable()
                .scaledToFill()
                .onAppear {
                    // sync image ให้ UIImageView
                    imageView.image = image.asUIImage()
                }
        } placeholder: {
            ProgressView()
        }
        .onTapGesture { showViewer = true }
        .fullScreenCover(isPresented: $showViewer) {
            BNImagePageViewRepresentable(
                imageView: imageView,
                imageURL: "https://example.com/image.jpg"
            )
            .ignoresSafeArea()
        }
    }
}
```

---

## Multiple Images

```swift
BNImagePageViewRepresentable(
    imageView: myUIImageView,
    pageData: pageDataArray,
    atIndexPath: selectedIndexPath
)
```

### ตัวอย่างเต็ม

```swift
struct GalleryView: View {
    @State private var selectedIndex: Int? = nil
    private let imageViews: [UIImageView]

    let urls = [
        "https://picsum.photos/id/10/400/300.jpg",
        "https://picsum.photos/id/20/400/300.jpg",
        "https://picsum.photos/id/30/400/300.jpg",
    ]

    var pageData: [ImgaePageData] {
        urls.enumerated().map {
            ImgaePageData(
                atIndex: IndexPath(row: $0.offset, section: 0),
                sImageUrl: $0.element,
                fWidth: 400,
                fHeight: 300
            )
        }
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
            ForEach(urls.indices, id: \.self) { index in
                AsyncImage(url: URL(string: urls[index])) { image in
                    image.resizable().scaledToFill()
                        .onAppear { imageViews[index].image = image.asUIImage() }
                } placeholder: { Color.gray }
                .frame(width: 100, height: 100)
                .clipped()
                .onTapGesture { selectedIndex = index }
            }
        }
        .fullScreenCover(item: $selectedIndex) { index in
            BNImagePageViewRepresentable(
                imageView: imageViews[index],
                pageData: pageData,
                atIndexPath: IndexPath(row: index, section: 0)
            )
            .ignoresSafeArea()
        }
    }
}
```

---

## Hide Share Button

```swift
BNImagePageViewRepresentable(
    imageView: myUIImageView,
    imageURL: "https://example.com/image.jpg",
    hideShare: true
)
```

```
hideShare: false (default):       hideShare: true:
┌─────────────────────────┐       ┌─────────────────────────┐
│ ×                    ↑  │       │ ×                        │
│                         │       │  (no share button)       │
│      [  Image  ]        │       │      [  Image  ]         │
│                         │       │                          │
│                      ⬆  │       │                          │
└─────────────────────────┘       └─────────────────────────┘
  BNImagePageGridView               BNImagePageGridHideShareView
```

---

## makeUIViewController — Internal Flow

```swift
public func makeUIViewController(context: Context) -> UIViewController {
    let options = [interPageSpacing: pageSpacing]

    if hideShare {
        return BNImagePageGridHideShareView(...)  // ← HideShare variant
    } else {
        return BNImagePageGridView(...)           // ← Normal variant
    }
}

public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
// ← ไม่มี update logic (viewer จัดการ state เอง)
```

---

## Initializers

### Single Image Init

```swift
public init(
    imageView: UIImageView,
    imageURL: String,
    pageSpacing: Int = 20,
    hideShare: Bool = false
)
```

สร้าง `pageData` อัตโนมัติ 1 item:
```swift
pageData = [ImgaePageData(
    atIndex: IndexPath(row: 0, section: 0),
    sImageUrl: imageURL,
    fWidth: imageView.image?.size.width ?? 0,
    fHeight: imageView.image?.size.height ?? 0
)]
```

### Multiple Images Init

```swift
public init(
    imageView: UIImageView,
    pageData: [ImgaePageData],
    atIndexPath: IndexPath,
    pageSpacing: Int = 20,
    hideShare: Bool = false
)
```

---

## ข้อจำกัด SwiftUI

### 1. ต้องมี UIImageView ที่มี image อยู่แล้ว

```swift
// ✗ ไม่ได้ — imageView ยังไม่มี image
let imageView = UIImageView()
BNImagePageViewRepresentable(imageView: imageView, imageURL: url)

// ✓ ถูก — sync image ก่อน
imageView.image = loadedImage
BNImagePageViewRepresentable(imageView: imageView, imageURL: url)
```

### 2. ไม่รองรับ imageViewForIndex callback

`BNImagePageViewRepresentable` ไม่มี `imageViewForIndex` parameter  
ทำให้ dismiss animation อาจไม่ fly กลับ cell ที่ถูกต้องในบาง case

ถ้าต้องการ dismiss animation ที่สมบูรณ์ใน SwiftUI ให้ใช้ `UIViewControllerRepresentable` เอง:

```swift
struct FullBNImagePageView: UIViewControllerRepresentable {
    let imageView: UIImageView
    let pageData: [ImgaePageData]
    let indexPath: IndexPath
    let imageViewForIndex: (Int) -> UIImageView?

    func makeUIViewController(context: Context) -> BNImagePageGridView {
        BNImagePageGridViewBuilder.build(
            mImageView: imageView,
            pageData: pageData,
            indexPath: indexPath,
            imageViewForIndex: imageViewForIndex
        )
    }

    func updateUIViewController(_ uiViewController: BNImagePageGridView, context: Context) {}
}
```

### 3. iOS 15.0+ เท่านั้น

```swift
@available(iOS 15.0, *)
public struct BNImagePageViewRepresentable: UIViewControllerRepresentable
```

---

## pageSpacing Parameter

ระยะห่างระหว่างหน้าขณะ swipe:

```swift
BNImagePageViewRepresentable(
    imageView: imageView,
    pageData: pageData,
    atIndexPath: indexPath,
    pageSpacing: 40   // default = 20
)
```

```
pageSpacing: 20 (default):        pageSpacing: 40:
┌──────┬──┬──────┐                ┌──────┬────┬──────┐
│ Pg 1 │  │ Pg 2 │                │ Pg 1 │    │ Pg 2 │
│      │20│      │                │      │ 40 │      │
└──────┴──┴──────┘                └──────┴────┴──────┘
```

---

## Navigation

[← Customization](CUSTOMIZATION.md) | [Back to Index](README.md) | [Architecture →](ARCHITECTURE.md)
