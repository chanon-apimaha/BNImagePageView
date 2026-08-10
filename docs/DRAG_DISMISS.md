# Drag to Dismiss — รายละเอียดทุกทิศทาง

## ข้อจำกัดเบื้องต้น

Gesture จะทำงานเฉพาะเมื่อ **แกน Y เคลื่อนที่มากกว่าแกน X** เท่านั้น  
(ป้องกันชนกับ swipe left/right ของ paging)

```
gestureRecognizerShouldBegin:
  |translation.y| > |translation.x|  →  รับ gesture ✓
  |translation.y| ≤ |translation.x|  →  ไม่รับ gesture ✗ (ปล่อยให้ paging ทำงาน)
```

และจะทำงานเฉพาะเมื่อ **zoom scale = minimum** (ไม่ได้ zoom เข้าอยู่)

---

## ระหว่าง Drag — ภาพขยับตาม finger

ภาพเคลื่อนที่ได้ทุกทิศทาง (X และ Y) ตาม finger

```
┌─────────────────────────┐
│                         │
│                         │
│       [  Image  ]  ←────┼── finger ลากไปทางไหนก็ได้
│            ↕            │
│                         │
└─────────────────────────┘
```

**Background alpha** เปลี่ยนตาม Y position ของภาพ:

```
ภาพอยู่กลางจอ (center = 50% ของหน้าจอ):
  alpha = 1.0  ████████████  เต็ม

ภาพลากขึ้น (center < 50%):
  alpha = 0.5 / centerY%   ลดลงเรื่อยๆ

ภาพลากลง (center > 50%):
  alpha = 0.5 + centerY%   ลดลงเรื่อยๆ

ภาพออกนอกจอ:
  alpha ≈ 0.0  □□□□□□□□□□□□  โปร่งใส
```

---

## เงื่อนไข Dismiss เมื่อปล่อยนิ้ว

มี **2 เงื่อนไข** ที่จะ trigger dismiss:

### เงื่อนไขที่ 1 — Velocity + Displacement > 40%

```
progressY = |displacement.y + velocity.y × 0.2| / screenHeight

progressY > 0.4  →  DISMISS ✓
progressY ≤ 0.4  →  ไปเช็คเงื่อนไขที่ 2
```

จำลอง: ลากเร็วแค่นิดเดียวก็ dismiss ได้

```
┌─────────────────────────┐     ┌─────────────────────────┐
│                         │     │                         │
│       [  Image  ]       │     │                         │
│            │            │     │                         │
│            │ flick ↑↑↑  │ →   │    dismiss ✓            │
│            ▼            │     │                         │
│                         │     │                         │
└─────────────────────────┘     └─────────────────────────┘
  velocity สูง → progressY > 0.4
```

---

### เงื่อนไขที่ 2 — Drag Distance > 20% ของหน้าจอ

ถ้า velocity ต่ำ (progressY ≤ 0.4) จะวัดระยะ drag จริงๆ

```
threshold = screenHeight / 10 × 2  =  20% ของหน้าจอ
           (เช่น iPhone 14: 844px × 20% = ~169px)

|startY - endY| > threshold  →  DISMISS ✓
|startY - endY| ≤ threshold  →  SNAP BACK ✗
```

---

## ทุกกรณีที่เป็นไปได้

### กรณีที่ 1 — ลากขึ้นเร็ว (flick up) → DISMISS

```
┌─────────────────────────┐
│         [Img]           │  ← ภาพลอยขึ้นไป
│           ↑↑↑           │
│      (velocity สูง)     │
│                         │
│                         │
│                         │
└─────────────────────────┘
  progressY > 0.4 → dismiss
  ภาพลอยกลับ cell ต้นทาง
```

---

### กรณีที่ 2 — ลากลงเร็ว (flick down) → DISMISS

```
┌─────────────────────────┐
│                         │
│                         │
│                         │
│      (velocity สูง)     │
│           ↓↓↓           │
│         [Img]           │  ← ภาพลอยลงไป
└─────────────────────────┘
  progressY > 0.4 → dismiss
  ภาพลอยกลับ cell ต้นทาง
```

---

### กรณีที่ 3 — ลากขึ้นช้า ระยะไกล (> 20%) → DISMISS

```
┌─────────────────────────┐
│  [Img]                  │  ← ลากขึ้นมาไกล > 169px
│    ↑                    │
│    │ ~200px             │
│    │                    │
│  (start)                │
│                         │
└─────────────────────────┘
  |startY - endY| > 20% → dismiss
```

---

### กรณีที่ 4 — ลากลงช้า ระยะไกล (> 20%) → DISMISS

```
┌─────────────────────────┐
│                         │
│  (start)                │
│    │                    │
│    │ ~200px             │
│    ↓                    │
│  [Img]                  │  ← ลากลงมาไกล > 169px
└─────────────────────────┘
  |endY - startY| > 20% → dismiss
```

---

### กรณีที่ 5 — ลากขึ้นช้า ระยะสั้น (< 20%) → SNAP BACK

```
┌─────────────────────────┐
│                         │
│  [Img]  ← ลากขึ้นนิดหน่อย
│    ↑                    │
│    │ ~50px (< 169px)    │
│  (start)                │
│                         │
└─────────────────────────┘
  ไม่ถึง threshold → snap back
  ภาพเด้งกลับตรงกลาง + background กลับมา alpha 1.0
```

---

### กรณีที่ 6 — ลากลงช้า ระยะสั้น (< 20%) → SNAP BACK

```
┌─────────────────────────┐
│                         │
│  (start)                │
│    │ ~50px (< 169px)    │
│    ↓                    │
│  [Img]  ← ลากลงนิดหน่อย
│                         │
└─────────────────────────┘
  ไม่ถึง threshold → snap back
```

---

### กรณีที่ 7 — ลากซ้าย/ขวา → ไม่รับ gesture (paging ทำงานแทน)

```
┌─────────────────────────┐
│                         │
│                         │
│  [Img] ←────────────    │  ← |translation.x| > |translation.y|
│                         │     gesture ถูก block
│                         │     UIPageViewController รับแทน
│                         │     → swipe ไปหน้าถัดไป
└─────────────────────────┘
```

---

### กรณีที่ 8 — ลากขณะ zoom in → ไม่รับ gesture

```
┌─────────────────────────┐
│                         │
│   ┌───────────────┐     │
│   │  [Img zoomed] │ ←── │── drag ขณะ zoom
│   │               │     │   zoomScale > minimumZoomScale
│   └───────────────┘     │   → gesture ถูก block
│                         │   → scroll view เลื่อนแทน
└─────────────────────────┘
```

---

## Snap Back Animation

เมื่อไม่ถึงเงื่อนไข dismiss ภาพจะเด้งกลับ:

```
┌─────────────────────────┐     ┌─────────────────────────┐
│  [Img]                  │     │                         │
│    ↑ (ลากขึ้นนิดหน่อย) │ →   │       [  Img  ]         │
│                         │     │    (กลับตรงกลาง)        │
│                         │     │  background alpha = 1.0 │
│                         │     │  buttons กลับมา alpha 1 │
└─────────────────────────┘     └─────────────────────────┘
  duration: 0.2s, easeInOut
```

---

## Dismiss Animation

เมื่อ dismiss ภาพจะลอยกลับ cell ต้นทาง:

```
┌─────────────────────────┐         ┌─────────────────────────┐
│                         │         │  ┌──┐ ┌──┐ ┌──┐        │
│       [  Image  ]       │  ────▶  │  │  │ │  │ │  │        │
│            │            │  fly    │  └──┘ └──┘ └──┘        │
│            ▼ dismiss    │         │         ↑               │
└─────────────────────────┘         └─────────────────────────┘
                                      ภาพลอยไปหา cell ที่กด
                                      duration: 0.55s
                                      spring damping: 0.75
                                      alpha fade to 0
```

---

## สรุป Decision Tree

```
finger เริ่ม drag
        │
        ▼
|translation.y| > |translation.x| ?
        │
   NO ──┴── YES
   │         │
paging    zoomScale = min ?
swipe         │
         NO ──┴── YES
         │         │
      scroll    คำนวณ progressY
      view           │
                progressY > 0.4 ?
                     │
               YES ──┴── NO
               │          │
           DISMISS    |startY-endY| > 20% ?
                           │
                     YES ──┴── NO
                     │          │
                 DISMISS    SNAP BACK
```
