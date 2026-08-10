# Paging — Page Cache, Prefetch, Counter, Transition

## Overview

เมื่อมีหลายภาพ `BNImagePageGridView` ใช้ `UIPageViewController` จัดการการ swipe  
พร้อม on-demand page cache และ Kingfisher prefetch เพื่อประสิทธิภาพสูงสุด

---

## UIPageViewController Setup

```
transitionStyle: .scroll          ← swipe แบบ scroll
navigationOrientation: .horizontal ← swipe ซ้าย/ขวา
interPageSpacing: 20              ← ช่องว่างระหว่างหน้า (default)
```

```
┌──────────────────────────────────────────┐
│  ┌────────┐  20px  ┌────────┐  20px  ┌──│
│  │ Page 1 │        │ Page 2 │        │Pa│
│  │        │        │        │        │  │
│  └────────┘        └────────┘        └──│
└──────────────────────────────────────────┘
              ← swipe →
```

---

## Page Cache — On-Demand

ไม่สร้าง VC ทั้งหมดตั้งแต่ต้น สร้างเฉพาะเมื่อต้องการ

```swift
fileprivate var pageCache: [Int: BNImagePageViewController] = [:]

func getViewController(index: Int) -> BNImagePageViewController {
    if let cached = pageCache[index] { return cached }  // ← คืน cache ถ้ามี
    // สร้างใหม่ถ้าไม่มี
    let vc = BNImagePageViewController()
    ...
    pageCache[index] = vc
    prefetchAdjacent(to: index)
    return vc
}
```

```
pageCache state ขณะดูหน้า 3:

index:  0    1    2    3    4    5    6
cache: [VC] [VC] [VC] [VC] [VC] [ ]  [ ]
                       ↑
                  กำลังดูอยู่
        └──────────────┘└──────┘
          สร้างแล้ว       prefetch
```

---

## Thumbnail ใน Page Cache

แต่ละ page ได้รับ thumbnail จาก 3 แหล่งตามลำดับ:

```
1. imageViewForIndex?(index)?.image
   → live cell ที่อยู่บนหน้าจอ (ดีที่สุด)
        │
        ▼ ถ้าไม่มี (cell off-screen)
2. ImageCache.default.retrieveImageInMemoryCache(forKey: url)
   → Kingfisher memory cache
        │
        ▼ ถ้าไม่มี
3. mImageView.image (เฉพาะ index แรกที่ tap)
   → thumbnail จาก cell ที่ tap
        │
        ▼ ถ้าไม่มีเลย
   nil → mZoomImageView.image = nil → โหลดจาก URL โดยตรง
```

---

## Prefetch Adjacent Pages

เมื่อสร้าง page ใหม่ จะ prefetch ภาพของหน้าข้างๆ ล่วงหน้า:

```swift
private func prefetchAdjacent(to index: Int) {
    let urls = [index - 1, index + 1]
        .filter { $0 >= 0 && $0 < axImgaePageData.count }
        .compactMap { URL(string: axImgaePageData[$0].sImageUrl) }
    ImagePrefetcher(urls: urls).start()
}
```

```
กำลังดูหน้า 3:
  prefetch หน้า 2 และ 4

  [1] [2] [3★] [4] [5]
       ↑        ↑
   prefetch  prefetch

swipe ไปหน้า 4:
  prefetch หน้า 3 และ 5

  [1] [2] [3] [4★] [5]
            ↑       ↑
        prefetch  prefetch
```

---

## UIPageViewControllerDataSource

```swift
// หน้าก่อนหน้า
func viewControllerBefore(_ viewController: UIViewController) -> UIViewController? {
    guard let index = pageCache.first(where: { $0.value === vc })?.key,
          index - 1 >= 0 else { return nil }
    return getViewController(index: index - 1)
}

// หน้าถัดไป
func viewControllerAfter(_ viewController: UIViewController) -> UIViewController? {
    guard let index = pageCache.first(where: { $0.value === vc })?.key,
          index + 1 < iNumOfPage else { return nil }
    return getViewController(index: index + 1)
}
```

```
swipe ซ้าย (ไปหน้าถัดไป):
┌────────┐        ┌────────┐
│ Page 3 │ ←←←   │ Page 4 │
│        │        │        │
└────────┘        └────────┘
  viewControllerAfter(page3) → getViewController(4)

swipe ขวา (ไปหน้าก่อนหน้า):
┌────────┐        ┌────────┐
│ Page 2 │   →→→ │ Page 3 │
│        │        │        │
└────────┘        └────────┘
  viewControllerBefore(page3) → getViewController(2)

ถึงหน้าแรก:
  viewControllerBefore(page0) → nil (ไม่มีหน้าก่อนหน้า)

ถึงหน้าสุดท้าย:
  viewControllerAfter(pageN) → nil (ไม่มีหน้าถัดไป)
```

---

## Page Counter

แสดงตำแหน่งปัจจุบัน เช่น "3 / 10"

```swift
// ตั้งค่าตอนเปิด
mPageTitle.setTitle("\(index + 1)/\(iNumOfPage)", for: .normal)

// อัพเดตเมื่อ swipe เสร็จ
func didFinishAnimating(...) {
    if completed,
       let index = pageCache.first(where: { $0.value === currentVC })?.key {
        iCurrentIndex = index
        mPageTitle.setTitle("\(index + 1)/\(iNumOfPage)", for: .normal)
    }
}
```

```
┌─────────────────────────┐
│ 3/10  ×              ↑  │  ← page title (top-left)
│                         │
│      [  Image 3  ]      │
│                         │
└─────────────────────────┘
  ● ● ★ ○ ○ ○ ○ ○ ○ ○
```

**หมายเหตุ**: page title แสดงเฉพาะเมื่อ `iNumOfPage > 1`

---

## iCurrentIndex Timing

`iCurrentIndex` อัพเดตใน `didFinishAnimating` ซึ่งเรียกหลัง `viewDidAppear`

```
timeline ของการ swipe:

t=0    เริ่ม swipe
t=0    viewControllerAfter เรียก → สร้าง page 4
t=0.3  animation เสร็จ
t=0.3  viewDidAppear(page4) → getVisiableViewController
         ↑ ตอนนี้ใช้ pageCache.first(where: { $0.value === vc })?.key
           เพื่อหา index จริง (ไม่ใช้ iCurrentIndex ที่ยังเก่าอยู่)
t=0.3  didFinishAnimating → iCurrentIndex = 4  ← อัพเดตทีหลัง
```

---

## Transition Between Pages

```
Page 3 → Page 4 (swipe ซ้าย):

t=0.0  ┌────────┬────────┐
       │ Page 3 │ Page 4 │  ← page 4 เริ่มเข้ามา
       └────────┴────────┘

t=0.15 ┌──────┬──────────┐
       │ Pg 3 │  Page 4  │
       └──────┴──────────┘

t=0.3  ┌────────────────┐
       │    Page 4      │  ← transition เสร็จ
       └────────────────┘
         viewDidAppear(page4)
         dismissTargetFrame อัพเดต
         button targets rebind
```

---

## Memory Management

```
pageCache เก็บ VC ทุกหน้าที่เคยเปิด
→ ไม่ deallocate ระหว่าง session
→ เมื่อ dismiss gridView → pageCache ถูก deallocate ทั้งหมด

Kingfisher memory cache:
→ clearMemoryCache() เรียกทุกครั้งที่โหลดภาพสำเร็จ
→ clearDiskCache() เรียกเมื่อ memory warning
```

---

## สรุป Page Flow

```
open viewer (index 3)
        │
        ▼
getViewController(3) → สร้าง VC3, prefetch [2,4]
        │
        ▼
setViewControllers([VC3])
        │
        ▼
viewDidAppear(VC3) → dismissTargetFrame = cell[3].frame
        │
        ▼
user swipe ซ้าย
        │
        ▼
viewControllerAfter(VC3) → getViewController(4) → สร้าง VC4, prefetch [3,5]
        │
        ▼
animation เสร็จ
        │
        ▼
viewDidAppear(VC4) → dismissTargetFrame = cell[4].frame
didFinishAnimating → iCurrentIndex = 4
mPageTitle = "5/10"
```

---

## Navigation

[← Zoom & Pan](ZOOM_PAN.md) | [Back to Index](README.md) | [Share →](SHARE.md)
