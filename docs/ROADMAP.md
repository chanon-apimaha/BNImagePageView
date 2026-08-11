# Roadmap

## Phase 1 — Builder Improvement (กำลังทำ)

### 1.1 เพิ่ม overload `imageURLs`
เพิ่ม method ใหม่ใน `BNImageBuilder` ให้รับ `[String]` โดยตรง แทนที่จะต้องสร้าง `[ImgaePageData]` + `IndexPath` เอง

```swift
// แบบเดิม (ยังใช้ได้)
BNImageBuilder.build(
    mImageView: cell.imageView,
    pageData: pageData,
    indexPath: indexPath,
    imageViewForIndex: { index in ... }
)

// แบบใหม่
BNImageBuilder.build(
    imageURLs: ["https://...", "https://..."],
    currentIndex: 2,
    sourceImageView: cell.imageView,
    imageViewForIndex: { index in ... }
)
```

**Files ที่แก้**: `BNImagePageGridView.swift`

---

### 1.2 Rename `BNImagePageGridViewBuilder` → `BNImageBuilder`
ชื่อเดิมยาวและสื่อถึง Grid เท่านั้น ทั้งที่ใช้ได้กับทุก use case

```swift
// ก่อน
BNImageBuilder.build(...)

// หลัง
BNImageBuilder.build(...)
```

**Files ที่แก้**:
- `BNImagePageGridView.swift` — rename struct
- `Example/ViewController.swift` — อัพเดต call site
- `README.md` — อัพเดต snippet
- `docs/OVERVIEW.md`, `docs/OPEN_ANIMATION.md` — อัพเดต snippet

> **Note:** Breaking change — ผู้ใช้ library ต้องอัพเดต call site ด้วย

---

## Phase 2 — Built-in Gallery Cell (ทำหลัง Phase 1)

สร้าง built-in `UICollectionView` + Cell ใน library ให้ภายนอกแค่ส่ง `[String]` URLs มา แล้ว library จัดการ render + tap + open viewer ให้ทั้งหมด

```swift
// UIKit
let gallery = BNImageGalleryView(imageURLs: urls)
view.addSubview(gallery)

// SwiftUI
BNImageGalleryRepresentable(imageURLs: urls)
```

**รายละเอียด**:
- built-in cell พร้อม shimmer loading
- tap cell → open viewer พร้อม animation อัตโนมัติ
- `imageViewForIndex` จัดการภายใน ไม่ต้อง implement เอง
- layout: grid 3 คอลัมน์ (default), config ได้

**Files ที่เพิ่ม**: `BNImageGalleryView.swift`

---

## Status

| Task | Status |
|---|---|
| 1.1 เพิ่ม overload `imageURLs` | ✅ Done |
| 1.2 Rename → `BNImageBuilder` | ✅ Done |
| 2.0 Built-in Gallery Cell | 🔲 Todo |
