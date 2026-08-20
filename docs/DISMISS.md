# Dismiss — ทุกวิธีที่ปิดภาพได้

ตอนนี้มี 3 ทางที่ปิด viewer ได้ แต่ละทางเรียก code path ต่างกัน

---

## วิธีที่ 1 — กด X Button (Close Button)

ปุ่ม X มุมขวาบน กด 1 ครั้งปิดทันที

```
┌─────────────────────────┐
│                    [X]  │  ← กดตรงนี้
│                         │
│       [  Image  ]       │
│                         │
└─────────────────────────┘
```

**Code path:**

```
mButtonClose.addTarget(oViewController, action: #selector(zoomOut2), ...)
    ↓
BNImagePageViewController.zoomOut2()
    ↓
animate: mZoomImageView → dismissTargetFrame, alpha → 0
    ↓
dismiss(animated: false) { mImageView.alpha = 1 }
```

`zoomOut2` ต่างจาก `zoomOut` ตรงที่ไม่ได้ถูกเรียกจาก drag gesture — animation เหมือนกันทุกอย่าง (spring 0.55s, damping 0.75) ภาพลอยกลับ cell ต้นทาง

---

## วิธีที่ 2 — Drag to Dismiss

ลากภาพขึ้นหรือลงจนถึง threshold แล้วปล่อยนิ้ว

```
┌─────────────────────────┐
│                         │
│       [  Image  ]       │
│            │            │
│            ↓ ลากลง      │
│                         │
└─────────────────────────┘
```

**เงื่อนไข dismiss** (ต้องผ่านอย่างน้อย 1 ข้อ):

| เงื่อนไข | สูตร | ค่า |
| --- | --- | --- |
| Velocity + displacement | `\|displacement.y + velocity.y × 0.2\| / screenHeight > 0.4` | > 40% ของหน้าจอ |
| Drag distance | `\|startY - endY\| > screenHeight / 10 × 2` | > 20% ของหน้าจอ |

**Code path:**

```
UIPanGestureRecognizer.draggedView()
    ↓
sender.state == .ended
    ↓
progressYPositionAfterShortTime > 0.4 หรือ bIsOut == true
    ↓
BNImagePageViewController.zoomOut()
    ↓
animate: mZoomImageView → dismissTargetFrame, alpha → 0
    ↓
dismiss(animated: false) { mImageView.alpha = 1 }
```

ถ้าไม่ถึง threshold → `resetZoomScaleToMinimum()` ภาพเด้งกลับตรงกลาง

ดูรายละเอียดทุกกรณีได้ที่ [DRAG_DISMISS.md](DRAG_DISMISS.md)

---

## วิธีที่ 3 — Tap เพื่อ Toggle UI (ไม่ปิด viewer)

Tap 1 ครั้งบนหน้าจอ — **ไม่ปิด viewer** แต่ซ่อน/แสดง UI controls

```
┌─────────────────────────┐     ┌─────────────────────────┐
│ [1/5]    caption   [X]  │     │                         │
│                         │ tap │                         │
│       [  Image  ]       │ ──▶ │       [  Image  ]       │
│                         │     │                         │
│                    [↑]  │     │                         │
└─────────────────────────┘     └─────────────────────────┘
  UI แสดงอยู่                     UI ซ่อนหมด (fullscreen)
```

**Code path:**

```
UITapGestureRecognizer.handleOneTapScrollView()
    ↓
toggleBuutonCloseAndShare()
    ↓
mButtonClose.isHidden ?
  → false: buttonHide()   ← ซ่อน X, share, page number, caption, arrows
  → true:  buttonShow()   ← แสดงกลับมาทั้งหมด
```

animation: fade 0.2s + constraint slide 0.25s

---

## สรุปเปรียบเทียบ

| วิธี | ปิด viewer | animation | เรียก func |
| --- | --- | --- | --- |
| กด X | ✅ | ภาพลอยกลับ cell | `zoomOut2()` |
| Drag dismiss | ✅ | ภาพลอยกลับ cell | `zoomOut()` |
| Tap once | ❌ | toggle UI fade | `toggleBuutonCloseAndShare()` |

---

## dismissTargetFrame

ทั้ง `zoomOut` และ `zoomOut2` ใช้ `dismissTargetFrame` เป็น target ของ animation

```swift
// ถ้ามี dismissTargetFrame → ภาพลอยกลับตำแหน่งนั้น
// ถ้าไม่มี → ลอยกลับ mImageView.superview?.convert(mImageView.frame, to: nil)
let targetFrame = dismissTargetFrame ?? mImageView.superview?.convert(mImageView.frame, to: nil)
```

`dismissTargetFrame` ถูก set จาก `BNImageBuilder.build(dismissTargetFrame:)` หรือจาก `imageViewForIndex` callback ใน `getVisiableViewController`

---

## Navigation

[← Drag Dismiss](DRAG_DISMISS.md) | [Back to Index](README.md) | [Zoom & Pan →](ZOOM_PAN.md)
