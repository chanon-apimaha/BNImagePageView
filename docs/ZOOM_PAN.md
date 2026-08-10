# Zoom & Pan — Pinch, Double Tap, Scroll While Zoomed

## Overview

ภาพรองรับ zoom เข้า/ออกด้วย pinch gesture และ double tap  
เมื่อ zoom เข้าแล้วสามารถ pan (scroll) ดูส่วนต่างๆ ของภาพได้

---

## Zoom Scale Range

```
minimumZoomScale:
  scaleWidth  = screenWidth  / contentWidth
  scaleHeight = screenHeight / contentHeight
  minScale    = min(scaleWidth, scaleHeight)
  → ถ้า minScale < 1.0 → ใช้ 1.0 (ไม่ให้ zoom ออกเกินขนาดจริง)

maximumZoomScale:
  maxScale = max(scaleWidth, scaleHeight)
  → ถ้า maxScale < 3.0 → ใช้ 3.0 (zoom เข้าได้อย่างน้อย 3x)

ตัวอย่าง iPhone 14 (390×844) ภาพ 400×300:
  scaleWidth  = 390/390 = 1.0
  scaleHeight = 844/293 = 2.88
  minScale = 1.0
  maxScale = 3.0
```

```
zoom out max          normal          zoom in max
┌─────────┐        ┌─────────┐       ┌─────────┐
│█████████│        │         │       │▓▓▓▓▓▓▓▓▓│
│█████████│        │█████████│       │▓▓▓▓▓▓▓▓▓│  ← 3x
│█████████│        │█████████│       │▓▓▓▓▓▓▓▓▓│
│         │        │         │       │▓▓▓▓▓▓▓▓▓│
└─────────┘        └─────────┘       └─────────┘
  scale=1.0          scale=1.0         scale=3.0
  (minimum)          (default)         (maximum)
```

---

## Pinch to Zoom

UIScrollView จัดการ pinch gesture ให้อัตโนมัติผ่าน `viewForZooming`

```swift
func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return mZoomImageView
}
```

```
2 นิ้ว pinch out (zoom in):
┌─────────┐           ┌─────────┐
│         │           │▓▓▓▓▓▓▓▓▓│
│  [img]  │  🤏→→→   │▓▓▓[img]▓│
│         │           │▓▓▓▓▓▓▓▓▓│
└─────────┘           └─────────┘

2 นิ้ว pinch in (zoom out):
┌─────────┐           ┌─────────┐
│▓▓▓▓▓▓▓▓▓│           │         │
│▓▓▓[img]▓│  🤏←←←   │  [img]  │
│▓▓▓▓▓▓▓▓▓│           │         │
└─────────┘           └─────────┘
```

---

## Double Tap to Zoom

```swift
@objc private func handleDoubleTapScrollView(recognizer: UITapGestureRecognizer) {
    if mScrollView.zoomScale == mScrollView.minimumZoomScale {
        // zoom in ไปที่จุดที่ tap
        mScrollView.zoom(to: zoomRectForScale(
            scale: maximumZoomScale,
            center: recognizer.location(in: recognizer.view)
        ), animated: true)
    } else {
        // zoom out กลับ minimum
        mScrollView.setZoomScale(minimumZoomScale, animated: true)
    }
}
```

```
double tap ที่มุมขวาบน:          double tap อีกครั้ง:
┌─────────┐                      ┌─────────┐
│      👆👆│  →  zoom in 3x  →   │▓▓▓▓▓▓▓▓▓│  →  zoom out  →  กลับ normal
│  [img]  │     ที่จุดนั้น       │▓▓▓▓▓▓▓▓▓│
│         │                      │▓▓▓▓▓▓▓▓▓│
└─────────┘                      └─────────┘
```

### zoomRectForScale — คำนวณ rect ที่จะ zoom เข้า

```
zoomRect.size = imageView.size / scale
             = ขนาดของ "หน้าต่าง" ที่จะ zoom เข้า

center ใน imageView coordinates:
  newCenter = imageView.convert(tapPoint, from: scrollView)

origin:
  x = newCenter.x - zoomRect.width/2
  y = newCenter.y - zoomRect.height/2

ผลลัพธ์: zoom เข้าโดยให้จุดที่ tap อยู่ตรงกลาง
```

---

## Center Alignment ขณะ Zoom

เมื่อ zoom เข้า ภาพจะถูก center ใน scrollView เสมอ  
(ป้องกันภาพชิดมุมเมื่อ content size เล็กกว่า scrollView)

```swift
func scrollViewDidZoom(_ scrollView: UIScrollView) {
    var imageCenter = CGPoint(
        x: scrollView.contentSize.width / 2,
        y: scrollView.contentSize.height / 2
    )
    let scrollCenter = scrollViewCenter()

    if contentSize.width < scrollViewSize.width {
        imageCenter.x = scrollCenter.x   // center horizontal
    }
    if contentSize.height < scrollViewSize.height {
        imageCenter.y = scrollCenter.y   // center vertical
    }
    mZoomImageView.center = imageCenter
}
```

```
zoom scale น้อย (content < scrollView):    zoom scale มาก (content > scrollView):
┌─────────────────┐                        ┌─────────────────┐
│                 │                        │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
│    ┌───────┐    │  ← center              │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│  ← pan ได้
│    │  img  │    │    อัตโนมัติ           │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
│    └───────┘    │                        │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
│                 │                        └─────────────────┘
└─────────────────┘
```

---

## Pan While Zoomed

เมื่อ zoom เข้าแล้ว UIScrollView จัดการ pan ให้อัตโนมัติ

```
zoom in แล้ว pan:
┌─────────┐
│▓▓▓▓▓▓▓▓▓│
│▓▓▓[A]▓▓▓│  ← ดูส่วน A อยู่
│▓▓▓▓▓▓▓▓▓│
└─────────┘
     │ pan ขวา
     ▼
┌─────────┐
│▓▓▓▓▓▓▓▓▓│
│▓▓▓▓▓[B]▓│  ← เลื่อนไปดูส่วน B
│▓▓▓▓▓▓▓▓▓│
└─────────┘
```

**หมายเหตุ**: drag to dismiss จะถูก block ขณะ zoom in  
เพราะ `gestureRecognizerShouldBegin` check `zoomScale <= minimumZoomScale`

---

## Rotation Support

เมื่อหมุนหน้าจอ frame และ zoom scale จะถูก recalculate:

```swift
@objc private func rotationView(notification: NSNotification) {
    mScrollView.setZoomScale(minimumZoomScale, animated: true)  // reset zoom
    setZoomImageFrame(imageSize: mZoomImageView.image?.size)    // recalculate frame
    mScrollView.contentSize = mZoomImageView.frame.size
    setMaxMinZoomScalesForCurrentBounds()                        // recalculate min/max
}
```

```
Portrait:                    Landscape:
┌─────────┐                  ┌───────────────────┐
│         │                  │                   │
│█████████│  rotate →        │  ┌─────────────┐  │
│█████████│                  │  │█████████████│  │
│         │                  │  └─────────────┘  │
└─────────┘                  └───────────────────┘
  zoom reset to min             recalculate frame
```

---

## Memory Warning

เมื่อ memory warning ล้าง Kingfisher cache ทั้งหมด:

```swift
override func didReceiveMemoryWarning() {
    ImageCache.default.clearDiskCache()
    ImageCache.default.clearMemoryCache()
    ImageCache.default.cleanExpiredDiskCache()
}
```

---

## สรุป Gesture ทั้งหมด

| Gesture | Action | เงื่อนไข |
|---|---|---|
| Pinch out | Zoom in | zoomScale < max |
| Pinch in | Zoom out | zoomScale > min |
| Double tap | Zoom in to tap point | zoomScale = min |
| Double tap | Zoom out to min | zoomScale > min |
| Pan (1 finger) | Scroll image | zoomScale > min |
| Pan (1 finger, Y > X) | Drag to dismiss | zoomScale = min |
| Long press | Share sheet | image loaded |
