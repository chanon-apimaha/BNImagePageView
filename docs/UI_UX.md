# UI/UX — ปัจจุบันและแนวทางปรับปรุง

---

## UI ปัจจุบัน — Viewer

### Layout หลัก

```
┌─────────────────────────────┐  ← status bar
│                             │
│ ┌──────┐           ┌──────┐ │  top: 34pt
│ │ 3/10 │           │  ×   │ │  ← pageTitle (left 8pt) | close (right 8pt)
│ └──────┘           └──────┘ │    size: auto            | size: 40×40pt
│                             │    bg: black 60%         | bg: black 60%
│                             │    cornerRadius: 4pt     | cornerRadius: 20pt
│                             │
│                             │
│       [ Full Image ]        │  ← mZoomImageView
│                             │    contentMode: scaleAspectFill
│                             │    zoom: 1x–3x
│                             │
│                             │
│                   ┌──────┐  │  bottom: 24pt (iPhone) / 32pt (iPad)
│                   │  ↑   │  │  ← share button (right 8pt)
│                   └──────┘  │    size: 40×40pt
│                             │    bg: black 60%
└─────────────────────────────┘    cornerRadius: 20pt
```

### ตำแหน่ง Elements ทั้งหมด

| Element | Position | Size | Style |
|---|---|---|---|
| pageTitle | top-left, safeArea.top + 8pt, safeArea.left + 8pt | auto width, auto height | black 60%, radius 4pt |
| close button | top-right, safeArea.top + 8pt, safeArea.right - 8pt | 40×40pt | black 60%, radius 20pt (วงกลม) |
| share button | bottom-right, 24pt from bottom, 8pt from right | 40×40pt | black 60%, radius 20pt (วงกลม) |
| image | center | aspect fit to screen | scaleAspectFill |

### iPad ต่างจาก iPhone

| | iPhone | iPad |
|---|---|---|
| left/right margin | 8pt | 16pt |
| share bottom | 24pt | 32pt |

---

## UI ปัจจุบัน — Toggle Buttons (Tap to Show/Hide)

### Normal Viewer — tap 1 ครั้ง

```
แสดง (show):                      ซ่อน (hide):
┌─────────────────────────┐        ┌─────────────────────────┐
│ 3/10              [×]   │        │                         │
│                         │  tap   │                         │
│      [  Image  ]        │ ────▶  │      [  Image  ]        │
│                         │        │                         │
│                   [↑]   │        │                         │
└─────────────────────────┘        └─────────────────────────┘
  alpha=1, visible                   alpha=0, isHidden=true
  constraint top=34pt                constraint top=0pt (slide out)
```

Animation:
- slide: `duration 0.25s`, constraint เปลี่ยน top/bottom
- fade: `duration 0.2s`, alpha 0↔1

### HideShare Viewer — tap 1 ครั้ง

```
แสดง:                             ซ่อน:
┌─────────────────────────┐        ┌─────────────────────────┐
│ 3/10              [×]   │        │                         │
│                         │  tap   │                         │
│      [  Image  ]        │ ────▶  │      [  Image  ]        │
│                         │        │                         │
│                         │        │                         │  ← ไม่มี share
└─────────────────────────┘        └─────────────────────────┘
  share alpha=0 เสมอ
```

---

## UI ปัจจุบัน — Example App (ViewController)

```
┌─────────────────────────┐
│ 20 Photos               │  ← headerLabel (top-left, size 13)
│ ┌─────────────────────┐ │
│ │  List │ Grid │ Paging│ │  ← UISegmentedControl (80% width, center)
│ └─────────────────────┘ │
│                         │
│  ┌───────────────────┐  │  List mode:
│  │ [shimmer loading] │  │  ← cell: width-32 × 200pt
│  └───────────────────┘  │    cornerRadius: 12pt
│  ┌───────────────────┐  │    shadow: black 15%, offset(0,4), radius 8
│  │ [    image      ] │  │    index label: bottom-right
│  └───────────────────┘  │
│                         │
└─────────────────────────┘
```

```
Grid mode:                        Paging mode:
┌─────────────────────────┐       ┌─────────────────────────┐
│ ┌───┐ ┌───┐ ┌───┐       │       │                         │
│ │img│ │img│ │img│       │       │  ┌─────────────────┐    │
│ └───┘ └───┘ └───┘       │       │  │                 │    │
│ ┌───┐ ┌───┐ ┌───┐       │       │  │    [  image  ]  │    │
│ │img│ │img│ │img│       │       │  │                 │    │
│ └───┘ └───┘ └───┘       │       │  └─────────────────┘    │
│                         │       │  ● ● ○ ○ ○ ○ ○ ○ ○ ○   │
└─────────────────────────┘       └─────────────────────────┘
  3 columns, 2pt gap                width-48 × 280pt
  no shadow, no radius              scale effect on scroll
                                    page indicator bottom
```

### Cell Loading State (Shimmer)

```
โหลดอยู่:                          โหลดเสร็จ:
┌───────────────────────────┐      ┌───────────────────────────┐
│░░░░░░░░░░░░░░░░░░░░░░░░░░░│      │                           │
│░░░░░░ shimmer ░░░░░░░░░░░░│  →   │      [  image  ]      [3] │
│░░░░░░░░░░░░░░░░░░░░░░░░░░░│      │                           │
└───────────────────────────┘      └───────────────────────────┘
  gradient: gray5→gray4→gray5        fade in 0.2s
  animation: slide left→right        index label bottom-right
  duration: 1.2s, repeat             (list mode only)
```

---

## ปัญหา UI/UX ปัจจุบัน

### 1. Close button ชนกับ Dynamic Island / Notch

```
แก้แล้ว (fix/close-button-dynamic-island):
┌─────────────────────────┐
│    [Dynamic Island]     │
│                         │
│               [×]       │  ← safeAreaLayoutGuide.top + 8pt
└─────────────────────────┘
  รองรับทุก device อัตโนมัติ
```

### 2. Share button ไม่ safe area aware

```
ปัจจุบัน:                          ปัญหา:
┌─────────────────────────┐        ┌─────────────────────────┐
│                         │        │                         │
│                   [↑]   │        │                   [↑]   │
│  bottom: 24pt (fixed)   │        │ ─────────────────────── │
└─────────────────────────┘        │  home indicator area    │
                                   └─────────────────────────┘
                                     button อาจทับ home indicator
```

### 3. pageTitle ไม่ center

```
ปัจจุบัน:                          ควรเป็น:
┌─────────────────────────┐        ┌─────────────────────────┐
│ 3/10              [×]   │        │ [×]       3/10      [↑] │
│ ↑ left-aligned          │        │           ↑ center      │
└─────────────────────────┘        └─────────────────────────┘
  ดูไม่ balanced                     สมดุลกว่า
```

### 4. ไม่มี visual feedback ตอน tap close/share

```
ปัจจุบัน:                          ควรเป็น:
กด close → dismiss ทันที            กด close → scale down 0.9x → dismiss
ไม่มี haptic feedback               haptic feedback (light impact)
```

### 5. Buttons ไม่ auto-hide หลังจากเวลาผ่านไป

```
ปัจจุบัน:
  buttons แสดงตลอด จนกว่า user จะ tap เพื่อซ่อน

ควรเป็น:
  หลังจาก 3 วินาที → auto-hide buttons
  เมื่อ user interact → show อีกครั้ง → auto-hide อีก 3 วินาที
```

### 6. Loading indicator ไม่มี progress

```
ปัจจุบัน:                          ควรเป็น:
◌ spinning (indeterminate)          ▓▓▓▓░░░░ progress bar
ไม่รู้ว่าโหลดไปถึงไหน              หรือ circular progress
```

### 7. ไม่มี error state

```
ปัจจุบัน:                          ควรเป็น:
โหลดไม่สำเร็จ → retry 3 ครั้ง      ┌─────────────────────────┐
→ blur fade out → ไม่มีอะไรแสดง    │                         │
                                   │    🖼️ ไม่สามารถโหลดภาพ  │
                                   │    [ลองใหม่]             │
                                   └─────────────────────────┘
```

---

## แนวทางปรับปรุง UI/UX

### 1. Safe Area Aware Buttons

```swift
// แทนที่ fixed constant
mConsTopClose.constant = 34

// ใช้ safeAreaLayoutGuide
mButtonClose.topAnchor.constraint(
    equalTo: view.safeAreaLayoutGuide.topAnchor,
    constant: 8
)
mButtonShare.bottomAnchor.constraint(
    equalTo: view.safeAreaLayoutGuide.bottomAnchor,
    constant: -8
)
```

```
ก่อน:                              หลัง:
┌─────────────────────────┐        ┌─────────────────────────┐
│    [Dynamic Island]     │        │    [Dynamic Island]     │
│               [×]       │        │                         │
│  top: 34pt              │        │               [×]       │
└─────────────────────────┘        │  safeArea + 8pt         │
                                   └─────────────────────────┘
```

### 2. Page Counter ย้ายไป Center

```
ก่อน:                              หลัง:
┌─────────────────────────┐        ┌─────────────────────────┐
│ 3/10              [×]   │        │ [×]       3/10      [↑] │
└─────────────────────────┘        └─────────────────────────┘
  pageTitle: top-left                close: top-left
                                     pageTitle: top-center
                                     share: top-right
```

### 3. Auto-hide Buttons

```
t=0    open viewer → buttons แสดง
t=3s   auto-hide (fade out)
t=3s+  user tap → buttons แสดง → reset timer
t=6s   auto-hide อีกครั้ง

implementation:
  var autoHideTimer: Timer?

  func resetAutoHideTimer() {
      autoHideTimer?.invalidate()
      autoHideTimer = Timer.scheduledTimer(
          withTimeInterval: 3.0,
          repeats: false
      ) { _ in self.buttonHide() }
  }
```

### 4. Haptic Feedback

```
close button tap    → UIImpactFeedbackGenerator(.light)
share button tap    → UIImpactFeedbackGenerator(.light)
dismiss complete    → UIImpactFeedbackGenerator(.medium)
zoom in (double tap)→ UIImpactFeedbackGenerator(.soft)
```

### 5. Button Press Animation

```swift
// เพิ่ม highlight animation
button.addTarget(self, action: #selector(buttonTouchDown), for: .touchDown)
button.addTarget(self, action: #selector(buttonTouchUp), for: [.touchUpInside, .touchUpOutside])

@objc func buttonTouchDown(_ sender: UIButton) {
    UIView.animate(withDuration: 0.1) {
        sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
    }
}

@objc func buttonTouchUp(_ sender: UIButton) {
    UIView.animate(withDuration: 0.1) {
        sender.transform = .identity
    }
}
```

```
ก่อน:                              หลัง:
[×] → tap → dismiss                [×] → scale 0.9x → scale 1.0x → dismiss
  ไม่มี feedback                     มี visual feedback
```

### 6. Error State UI

```
โหลดไม่สำเร็จหลัง retry 3 ครั้ง:

┌─────────────────────────┐
│ ×                    ↑  │
│                         │
│                         │
│    ┌───────────────┐    │
│    │  🖼️           │    │
│    │  โหลดไม่สำเร็จ│    │
│    │               │    │
│    │  [  ลองใหม่  ]│    │
│    └───────────────┘    │
│                         │
└─────────────────────────┘
```

### 7. Thumbnail Blur ที่ดีขึ้น

```
ปัจจุบัน:                          ปรับปรุง:
blur style: .extraLight             blur style: .dark (เข้ากับ black bg)
blur ครอบทั้งภาพ                    blur + dim overlay (black 30%)
                                   ทำให้ loading indicator เห็นชัดขึ้น

┌─────────────────────────┐        ┌─────────────────────────┐
│ ░░░░░░░░░░░░░░░░░░░░░░░ │        │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │
│ ░░░ [bright blur] ░░░░░ │   →    │ ▓▓▓ [dark blur]  ▓▓▓▓▓ │
│ ░░░░░░░░░░░░░░░░░░░░░░░ │        │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │
└─────────────────────────┘        └─────────────────────────┘
  .extraLight บน black bg            .dark เข้ากับ black bg
  ดูแปลก                             ดูเป็นธรรมชาติกว่า
```

### 8. Swipe Indicator (Paging)

```
ปัจจุบัน:                          ปรับปรุง:
ไม่มี indicator ว่ามีหน้าอื่น       เพิ่ม edge peek

┌─────────────────────────┐        ┌─────────────────────────┐
│                         │        │                    ┌────│
│      [  Image  ]        │   →    │      [  Image  ]   │next│
│                         │        │                    └────│
└─────────────────────────┘        └─────────────────────────┘
  ไม่รู้ว่า swipe ได้                 เห็นขอบหน้าถัดไป
                                     (interPageSpacing ลดลง)
```

### 9. Dismiss Gesture Indicator

```
ปัจจุบัน:                          ปรับปรุง:
ไม่มี hint ว่า drag ได้             เพิ่ม pill indicator ด้านบน

┌─────────────────────────┐        ┌─────────────────────────┐
│ ×                    ↑  │        │ ×      ▬▬▬          ↑  │
│                         │        │        ↑                │
│      [  Image  ]        │   →    │   drag indicator        │
│                         │        │      [  Image  ]        │
└─────────────────────────┘        └─────────────────────────┘
                                     เหมือน sheet modal
```

---

## สรุปเปรียบเทียบ

| Feature | ปัจจุบัน | ปรับปรุง | Priority |
|---|---|---|---|
| Safe area buttons | ~~fixed 34pt~~ | safeAreaLayoutGuide | ✅ Done |
| Page counter position | top-left | top-center | 🟡 Medium |
| Auto-hide buttons | ไม่มี | 3s timer | 🟡 Medium |
| Haptic feedback | ไม่มี | light/medium | 🟡 Medium |
| Button press animation | ไม่มี | scale 0.9x | 🟢 Low |
| Error state UI | ไม่มี | retry button | 🔴 High |
| Blur style | .extraLight | .dark | 🟢 Low |
| Swipe indicator | ไม่มี | edge peek | 🟢 Low |
| Drag indicator | ไม่มี | pill view | 🟢 Low |
| Loading progress | indeterminate | progress bar | 🟢 Low |

---

## Navigation

[← Architecture](ARCHITECTURE.md) | [Back to Index](README.md)
