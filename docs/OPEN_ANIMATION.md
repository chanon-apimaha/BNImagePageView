# Open Animation — Flow ตั้งแต่ Tap จนภาพ Expand Fullscreen

## Overview

เมื่อ user tap บน cell ภาพจะ animate expand จาก UIImageView ต้นทางไปเป็น fullscreen  
โดยใช้ตำแหน่งและขนาดของ cell จริงเป็นจุดเริ่มต้น

---

## Step-by-Step Flow

### Step 1 — User Tap Cell

```
┌─────────────────────────┐
│  ┌──┐ ┌──┐ ┌──┐        │
│  │  │ │██│ │  │  ← tap │
│  └──┘ └──┘ └──┘        │
│                         │
└─────────────────────────┘
  collectionView didSelectItemAt
  guard cell.imageView.image != nil
```

---

### Step 2 — สร้าง BNImagePageGridView

```swift
BNImagePageGridViewBuilder.build(
    mImageView: cell.imageView,   // ← UIImageView จาก cell จริง
    pageData: pageData,
    indexPath: indexPath
) { index in
    return cell(at: index)?.imageView  // ← callback สำหรับ dismiss
}
```

```
present(gridVC, animated: false)  ← ไม่ใช้ system animation
                                     จัดการ animation เอง
```

---

### Step 3 — viewDidLoad: คำนวณ startingFrame

```
cell.imageView อยู่ใน collectionView
        │
        ▼
superview.convert(imageView.frame, to: nil)
        │
        ▼
startingFrame = CGRect ใน window coordinates

┌─────────────────────────┐  window
│  ┌──┐ ┌──┐ ┌──┐        │
│  │  │ │██│ │  │        │
│  └──┘ └──┘ └──┘        │  startingFrame = {x:130, y:200, w:100, h:75}
│       ↑↑↑↑             │
└─────────────────────────┘
```

ถ้า `superview == nil` (paging mode, thumbImageView ไม่ได้อยู่ใน hierarchy)  
→ ข้ามการ set frame ไป ภาพจะ appear จากตรงกลางแทน

---

### Step 4 — ตั้งค่า mZoomImageView เริ่มต้น

```
mZoomImageView.image       = mImageView.image   (thumbnail จาก cell)
mZoomImageView.contentMode = .scaleAspectFill
mZoomImageView.alpha       = 0                  (ซ่อนไว้ก่อน)
mZoomImageView.frame       = startingFrame      (ขนาดเท่า cell)
```

```
┌─────────────────────────┐
│  ┌──┐ ┌──┐ ┌──┐        │
│  │  │ │░░│ │  │        │  ← mZoomImageView alpha=0
│  └──┘ └──┘ └──┘        │     frame = cell frame
│                         │
└─────────────────────────┘
```

---

### Step 5 — เพิ่ม Blur Effect (ถ้ามี URL)

```swift
if sImageUrl != "" {
    mZoomImageView.BNaddBlurEffect()
}
```

```
┌──────────────┐
│ ░░░░░░░░░░░░ │  ← UIVisualEffectView (.extraLight)
│ ░░ [thumb] ░ │     ครอบบน thumbnail
│ ░░░░░░░░░░░░ │     จะ fade ออกเมื่อโหลดภาพเสร็จ
└──────────────┘
```

---

### Step 6 — bDoAnimate = true (single image, open animation)

```
UIView.animate(
    duration: 0.75,
    springDamping: 1.0,
    initialVelocity: 0.5,
    options: .curveEaseOut
)
```

```
Frame:   startingFrame  ──────────────▶  fullscreen frame
Alpha:   0              ──────────────▶  1
BG:      clear          ──────────────▶  black alpha 1.0
cell:    alpha 1        ──────────────▶  alpha 0 (ซ่อน cell)

┌─────────────────────────┐     ┌─────────────────────────┐
│  ┌──┐ ┌──┐ ┌──┐        │     │ ×                    ↑  │
│  │  │ │░░│ │  │        │ →→→ │                         │
│  └──┘ └──┘ └──┘        │     │      [  Image  ]        │
│                         │     │                         │
└─────────────────────────┘     └─────────────────────────┘
  t=0                             t=0.75s
```

---

### Step 7 — bDoAnimate = false (paging mode, no open animation)

ใน paging mode (`bDoAnimate = false`) ภาพจะ appear ทันทีโดยไม่มี animation:

```swift
setZoomImageFrame(imageSize: size)
mImageView.alpha = 0
mZoomImageView.alpha = 1
view.backgroundColor = .black
loadImage()
```

```
┌─────────────────────────┐
│ ×    2 / 5          ↑  │
│                         │
│      [  Image  ]        │  ← appear ทันที ไม่มี animation
│                         │
└─────────────────────────┘
```

---

### Step 8 — loadImage() โหลดภาพ full resolution

```
completion ของ animate → loadImage()
        │
        ▼
Kingfisher kf.setImage(
    with: URL,
    placeholder: mImageView.image,   ← thumbnail ระหว่างโหลด
    options: [
        .transition(.fade(0.15)),    ← fade เข้าเมื่อโหลดเสร็จ
        .diskCacheExpiration(.never),
        .memoryCacheExpiration(.never)
    ]
)
```

```
โหลดอยู่:                    โหลดเสร็จ:
┌─────────────────────────┐  ┌─────────────────────────┐
│ ×                    ↑  │  │ ×                    ↑  │
│         ◌             │  │                         │
│      [blur thumb]       │  │    [full resolution]    │
│                         │  │                         │
└─────────────────────────┘  └─────────────────────────┘
  loading indicator spinning    blur fades out (0.5s)
```

---

### Step 9 — setZoomImageFrame: คำนวณ frame fullscreen

```
portrait mode (width < height):
  width  = screenWidth
  height = screenWidth / imageWidth × imageHeight
  y      = screenHeight/2 - height/2  (center vertical)

  ถ้า height > screenHeight:
    height = screenHeight
    width  = screenHeight / imageHeight × imageWidth
    x      = screenWidth/2 - width/2   (center horizontal)

landscape mode (width > height):
  width  = screenHeight / imageHeight × imageWidth
  height = screenHeight
  x      = screenWidth/2 - width/2

  ถ้า width > screenWidth:
    height = screenWidth / imageWidth × imageHeight
    width  = screenWidth
    y      = screenHeight/2 - height/2
```

```
Portrait — ภาพกว้าง:          Portrait — ภาพสูง:
┌─────────┐                   ┌─────────┐
│█████████│ ← full width      │  ┌───┐  │
│█████████│                   │  │███│  │ ← center horizontal
│█████████│                   │  │███│  │
│         │ ← letterbox       │  └───┘  │
└─────────┘                   └─────────┘
```

---

### Step 10 — viewDidAppear: อัพเดต mImageView สำหรับ dismiss

```swift
override func viewDidAppear(_ animated: Bool) {
    delegate?.getVisiableViewController(self)
}
```

```
getVisiableViewController:
  1. ดึง live imageView จาก cell (ถ้า on-screen)
     → เก็บ dismissTargetFrame = cell frame ใน window
  2. ถ้า cell off-screen → ดึงจาก Kingfisher memory cache
  3. bind close/share button targets
```

---

## Timeline สรุป

```
t=0.00  tap cell
t=0.00  present(gridVC, animated: false)
t=0.00  viewDidLoad — คำนวณ startingFrame, ตั้งค่า mZoomImageView
t=0.00  animate เริ่ม (duration 0.75s)
t=0.75  animate เสร็จ — loadImage() เริ่มโหลด
t=0.75  viewDidAppear — เก็บ dismissTargetFrame
t=0.90  Kingfisher โหลดเสร็จ — fade in full image (0.15s)
t=0.90  blur effect fade out (0.5s)
t=1.40  blur หายหมด — พร้อมใช้งาน
```

---

## Navigation

[← Overview](OVERVIEW.md) | [Back to Index](README.md) | [Drag Dismiss →](DRAG_DISMISS.md)
