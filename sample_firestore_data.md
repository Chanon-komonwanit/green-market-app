# สำหรับการทดสอบ ข้อมูลตัวอย่างที่ควรมีใน Firestore

## Categories Collection
```
categories/
  - cat1: {
    name: "ผักผลไม้อินทรีย์",
    imageUrl: "",
    isActive: true
  }
  - cat2: {
    name: "สินค้าเพื่อสุขภาพ",
    imageUrl: "",
    isActive: true
  }
```

## Products Collection  
```
products/
  - prod1: {
    name: "มะเขือเทศอินทรีย์",
    description: "มะเขือเทศปลอดสารพิษ",
    price: 50,
    categoryId: "cat1",
    sellerId: "seller1",
    status: "approved",
    isApproved: true,
    ecoLevel: "moderate",
    imageUrls: [],
    createdAt: "2024-01-01T00:00:00Z"
  }
```

## Promotions Collection
```
promotions/
  - promo1: {
    title: "ลดราคาสินค้าอินทรีย์",
    description: "ลด 20% สำหรับสินค้าอินทรีย์ทุกชิ้น",
    image: "",
    isActive: true,
    startDate: "2024-01-01T00:00:00Z",
    endDate: "2025-12-31T23:59:59Z"
  }
```
