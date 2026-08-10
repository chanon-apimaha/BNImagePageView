# BNSetting Customization

## Overview

`BNSetting` เป็น class สำหรับ customize UI ของ viewer  
ตั้งค่าได้ก่อน present viewer

```swift
open class BNSetting {
    public static var titlefont: UIFont
    public static var mButtonClose: UIButton
    public static var closeImage: UIImage?
}
```

---

## titlefont — Font ของ Page Counter

```swift
BNSetting.titlefont = .systemFont(ofSize: 14, weight: .medium)
```

```
Default (size 16):                Custom (size 12, bold):
┌─────────────────────────┐       ┌─────────────────────────┐
│ 3/10  ×              ↑  │       │ 3/10  ×              ↑  │
│ ↑                        │       │ ↑                        │
│ systemFont(16)           │       │ boldSystemFont(12)       │
└─────────────────────────┘       └─────────────────────────┘
```

ใช้กับ `mPageTitle` ซึ่งเป็น `UIButton` ที่แสดง "current/total"

```swift
// ตั้งค่าก่อน present
BNSetting.titlefont = UIFont(name: "Helvetica-Bold", size: 13)!

// present viewer
navigationController?.BNImagePage(...)
```

---

## closeImage — Icon ของ Close Button

```swift
BNSetting.closeImage = UIImage(named: "my-close-icon")?.withRenderingMode(.alwaysTemplate)
```

```
Default (icon-close):             Custom icon:
┌─────────────────────────┐       ┌─────────────────────────┐
│ [×]                  ↑  │       │ [←]                  ↑  │
│  ↑                       │       │  ↑                       │
│  icon-close bundle       │       │  custom back arrow       │
└─────────────────────────┘       └─────────────────────────┘
```

**หมายเหตุ**: ใช้ `.alwaysTemplate` เพื่อให้ `tintColor` ทำงานได้

```swift
BNSetting.closeImage = UIImage(systemName: "xmark.circle.fill")?
    .withRenderingMode(.alwaysTemplate)
```

---

## mButtonClose — Custom Close Button

แทนที่ close button ทั้งหมดด้วย UIButton ที่ custom เอง

```swift
let customButton = UIButton()
customButton.setTitle("Close", for: .normal)
customButton.setTitleColor(.white, for: .normal)
customButton.backgroundColor = UIColor.red.withAlphaComponent(0.8)
customButton.layer.cornerRadius = 8
BNSetting.mButtonClose = customButton
```

```
Default:                          Custom:
┌─────────────────────────┐       ┌─────────────────────────┐
│ ┌──┐                ↑   │       │ ┌───────┐            ↑  │
│ │ × │                   │       │ │ Close │               │
│ └──┘                    │       │ └───────┘               │
│  circle, black bg        │       │  red bg, rounded        │
└─────────────────────────┘       └─────────────────────────┘
```

**ข้อควรระวัง**: `mButtonClose` เป็น `static` — ถ้าแก้แล้วจะมีผลกับทุก instance  
ควร reset กลับหลังใช้งาน ถ้าต้องการ style ต่างกันในแต่ละ viewer

---

## HideShare Variant — BNSetting.closeImage

`BNImagePageGridHideShareView` ใช้ `BNSetting.closeImage` โดยตรง:

```swift
class BNImagePageGridHideShareView: BNImagePageGridView {
    override func viewDidLoad() {
        super.viewDidLoad()
        mButtonClose.setImage(BNSetting.closeImage, for: .normal)
        mButtonClose.backgroundColor = .clear   // ← ไม่มี background
        mButtonShare.backgroundColor = .clear   // ← ไม่มี share button bg
    }
}
```

```
Normal viewer:                    HideShare viewer:
┌─────────────────────────┐       ┌─────────────────────────┐
│ ┌──┐                ↑   │       │ ×                        │
│ │ × │  black bg          │       │  ↑ no background         │
│ └──┘                    │       │  no share button         │
│                      ┌──┤       │                          │
│                      │↑ │       │      [  Image  ]         │
│                      └──┘       │                          │
└─────────────────────────┘       └─────────────────────────┘
```

---

## ตัวอย่างการใช้งานจริง

### Dark Theme

```swift
// ตั้งค่า theme ก่อน present
BNSetting.titlefont = .systemFont(ofSize: 13, weight: .semibold)
BNSetting.closeImage = UIImage(systemName: "xmark")?
    .withRenderingMode(.alwaysTemplate)

let btn = UIButton()
btn.tintColor = .white
btn.backgroundColor = UIColor.white.withAlphaComponent(0.2)
btn.layer.cornerRadius = 20
BNSetting.mButtonClose = btn

navigationController?.BNImagePage(
    mImageViewShowFirst: imageView,
    sImageUrl: url
)
```

### Minimal (ไม่มี background)

```swift
BNSetting.closeImage = UIImage(systemName: "chevron.down")?
    .withRenderingMode(.alwaysTemplate)

navigationController?.BNImagePageHideShare(
    mImageViewShowFirst: imageView,
    sImageUrl: url
)
```

---

## Default Values

| Property | Type | Default Value |
|---|---|---|
| `titlefont` | `UIFont` | `.systemFont(ofSize: 16)` |
| `closeImage` | `UIImage?` | `UIImage(named: "icon-close")` tinted |
| `mButtonClose` | `UIButton` | `UIButton()` (empty, configured in viewDidLoad) |

---

## Button Layout (ตำแหน่งบนหน้าจอ)

```
┌─────────────────────────────┐
│ [pageTitle]        [close]  │  ← top: 34pt from top
│  left: 8/16pt      right: 8/16pt
│                             │
│                             │
│                             │
│                   [share]   │  ← bottom: 24/32pt from bottom
│                    right: 8/16pt
└─────────────────────────────┘
  iPhone: 8pt margin
  iPad:   16pt margin
```

ขนาด button: **40×40pt**, corner radius: **20pt** (วงกลม)
