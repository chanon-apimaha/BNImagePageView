# Share — Short Press, Long Press, iPad Popover, Permission Flow

## Overview

BNImagePageView รองรับการแชร์ภาพ 2 วิธี:
- **Short press** บน share button (bottom-right)
- **Long press** ที่ใดก็ได้บนภาพ

---

## Share Button (Short Press)

```
┌─────────────────────────┐
│ ×                    ↑  │
│                         │
│      [  Image  ]        │
│                         │
│                      ⬆  │  ← กด share button
└─────────────────────────┘
```

```swift
@objc func pressShare(_ sender: UIButton) {
    if !bIsShowImage && (mZoomImageView.subviews.count <= 0) {
        fShareSourceRect = mButtonShare.frame
        requestAuthorizationIfNeeded()
    }
}
```

เงื่อนไขที่จะ share ได้:
- `bIsShowImage == false` → ภาพโหลดเสร็จแล้ว
- `mZoomImageView.subviews.count <= 0` → blur effect หายไปแล้ว

```
โหลดอยู่ → กด share → ไม่ทำงาน
โหลดเสร็จ → กด share → เปิด share sheet ✓
```

---

## Long Press (ที่ใดก็ได้บนภาพ)

```
┌─────────────────────────┐
│ ×                    ↑  │
│                         │
│      [  Image  ]        │
│           👆 (hold)     │  ← long press ที่ใดก็ได้
│                         │
└─────────────────────────┘
```

```swift
@objc func pressLongShare(_ gestureRecognizer: UIGestureRecognizer) {
    if presentedViewController == nil {  // ← ไม่มี sheet เปิดอยู่แล้ว
        if !bIsShowImage && (mZoomImageView.subviews.count <= 0) {
            if UIDevice.current.userInterfaceIdiom == .pad {
                // iPad: เก็บตำแหน่งที่ long press สำหรับ popover
                let location = gestureRecognizer.location(in: mScrollView)
                let coordinate = mScrollView.convert(location, to: mScrollView)
                fShareSourceRect = CGRect(x: coordinate.x, y: coordinate.y, width: 0, height: 0)
            }
            requestAuthorizationIfNeeded()
        }
    }
}
```

---

## Permission Flow

```
requestAuthorizationIfNeeded()
        │
        ▼
AVCaptureDevice.authorizationStatus(for: .audio)
        │
   ┌────┴────────────────────────────┐
   │                                 │
.authorized                    .notDetermined
   │                                 │
   ▼                                 ▼
okAuthorized()          PHPhotoLibrary.requestAuthorization
                                     │
                              ┌──────┴──────┐
                              │             │
                           .authorized   .denied
                              │             │
                              ▼             ▼
                         okAuthorized() alertPhotoPermission()
   │
.denied / .restricted
   │
   ▼
alertPhotoPermission()
```

**หมายเหตุ**: ใช้ `AVCaptureDevice` (audio) เพื่อ check permission แทน Photos  
เป็น legacy behavior จากโค้ดเดิม

---

## Share Sheet — iPhone

```
┌─────────────────────────┐
│ ×                    ↑  │
│                         │
│      [  Image  ]        │
│                         │
└─────────────────────────┘
            │
            ▼ share
┌─────────────────────────┐
│                         │
│  ┌───────────────────┐  │
│  │  Share Sheet      │  │
│  │  ┌──┐ ┌──┐ ┌──┐  │  │
│  │  │📋│ │💾│ │✉️│  │  │
│  │  └──┘ └──┘ └──┘  │  │
│  │  Copy  Save  Mail │  │
│  └───────────────────┘  │
└─────────────────────────┘
  UIActivityViewController
  presented from bottom
```

---

## Share Popover — iPad

บน iPad share จะแสดงเป็น popover แทน sheet

### Short press (share button):
```
┌──────────────────────────────────┐
│ ×                             ↑  │
│                          ┌──────┐│
│      [  Image  ]         │Share ││  ← popover จาก button
│                          │ Copy ││
│                          │ Save ││
│                       ⬆──│      ││
└──────────────────────────└──────┘┘
  sourceRect = mButtonShare.frame
```

### Long press (ที่ตำแหน่งที่กด):
```
┌──────────────────────────────────┐
│ ×                             ↑  │
│                                  │
│      [  Image  ]  ┌──────┐       │
│           👆──────│Share │       │  ← popover จากจุดที่ long press
│                   │ Copy │       │
│                   │ Save │       │
│                   └──────┘       │
└──────────────────────────────────┘
  sourceRect = CGRect(x: tapX, y: tapY, width: 0, height: 0)
```

---

## Excluded Activity Types

```swift
mShareActivity.excludedActivityTypes = [
    .addToReadingList,
    .airDrop,
    .assignToContact,
    .copyToPasteboard,
    .mail,
    .markupAsPDF,
    .message,
    .openInIBooks,
    .print,
    .postToWeibo,
    .postToTencentWeibo,
    .postToFlickr,
    .postToVimeo,
    .postToFacebook
]
```

```
แสดงเฉพาะ:
┌──────────────────────────┐
│  💾 Save to Photos       │  ✓ แสดง
│  📋 Copy                 │  ✗ ซ่อน (copyToPasteboard excluded)
│  ✉️ Mail                 │  ✗ ซ่อน (mail excluded)
│  💬 Message              │  ✗ ซ่อน (message excluded)
│  ...                     │
└──────────────────────────┘
```

---

## Rotation Handling

เมื่อหมุนหน้าจอขณะ share sheet เปิดอยู่ → dismiss sheet อัตโนมัติ

```swift
@objc private func rotationView(notification: NSNotification) {
    mShareActivity.dismiss(animated: true) {
        bIsShowShareActivity = false
    }
}
```

```
Portrait → Landscape:
┌─────────┐              ┌───────────────────┐
│         │              │                   │
│ ┌─────┐ │  rotate →   │  [  Image  ]      │
│ │Share│ │              │                   │
│ └─────┘ │              └───────────────────┘
└─────────┘                share sheet ปิด
```

---

## bIsShowShareActivity Flag

ป้องกัน share sheet เปิดซ้อนกัน:

```
กด share ครั้งแรก:
  bIsShowShareActivity = false → เปิด sheet → bIsShowShareActivity = true

กด share ขณะ sheet เปิดอยู่:
  presentedViewController != nil → ไม่ทำงาน (long press check)

ปิด sheet:
  completionWithItemsHandler → bIsShowShareActivity = false
```

---

## สรุป Share Flow

```
user action
    │
    ├── short press share button
    │       │
    │       ▼
    │   pressShare()
    │       │
    └── long press anywhere
            │
            ▼
        pressLongShare()
            │
            ▼
    image loaded? blur gone?
            │
           YES
            │
            ▼
    requestAuthorizationIfNeeded()
            │
            ▼
    permission check
            │
       authorized
            │
            ▼
    okAuthorized()
            │
            ▼
    UIActivityViewController
            │
      ┌─────┴─────┐
      │           │
   iPhone       iPad
   bottom       popover
   sheet        at sourceRect
```

---

## Navigation

[← Paging](PAGING.md) | [Back to Index](README.md) | [Customization →](CUSTOMIZATION.md)
