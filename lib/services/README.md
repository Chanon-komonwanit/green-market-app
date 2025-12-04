# 📁 Services - Business Logic Layer

โฟลเดอร์นี้เก็บ **Services** ที่จัดการ Business Logic และเชื่อมต่อกับ Firebase

---

## 📄 ไฟล์สำคัญ

### ⭐ `firebase_service.dart` - SERVICE หลักที่สำคัญที่สุด
**คะแนนความสำคัญ: 🌟🌟🌟🌟🌟**

จัดการทุก CRUD operations กับ Firestore
- ✅ Create, Read, Update, Delete data
- ✅ Query data with filters
- ✅ Real-time listeners
- ✅ Batch operations
- ✅ Retry mechanism

**Collections ที่จัดการ:**
```
users, products, orders, categories, sellers, reviews,
coupons, promotions, flashSales, ecoCoins, investments,
activities, stories, chats, notifications
```

**ใช้โดย:** เกือบทุก Provider และ Service

---

### 🔐 `auth_service.dart`
จัดการ Authentication
- Login (Email, Google, Facebook, Phone)
- Register
- Logout
- Password reset

**ใช้โดย:** `AuthProvider`

---

### 📦 `product_service.dart`
จัดการสินค้า
- Get products (with filters)
- Search products
- Get product details
- Manage stock

**ใช้โดย:** Product Screens, Search Screen

---

### 💳 `payment_service.dart`
ระบบชำระเงิน
- Process payment
- Generate payment link
- Verify payment
- Multiple payment methods

**ใช้โดย:** Payment Screen, Checkout

---

### 🔔 `notification_service.dart`
การแจ้งเตือน
- Push notifications (FCM)
- Local notifications
- Topic subscription

**ใช้โดย:** ทั่วทั้งแอป

---

### 🪙 `eco_coins_service.dart`
ระบบ Eco Coins
- Calculate eco coins from orders
- Track transactions
- Manage missions
- Redeem rewards

**ใช้โดย:** `EcoCoinsProvider`

---

### 🎁 `promotion_service.dart`
โปรโมชั่นและส่วนลด
- Get active promotions
- Apply promotions
- Calculate discounts
- Validate promo codes

**ใช้โดย:** `CouponProvider`, Cart/Checkout

---

### ⚡ `flash_sale_service.dart`
Flash Sale
- Get flash sale products
- Check time-based availability
- Manage limited stock

**ใช้โดย:** Flash Sale Screen, Home Screen

---

### 💰 `investment_service.dart`
ระบบการลงทุน (Green World Hub)
- Manage investment projects
- Track user investments
- Calculate returns

**ใช้โดย:** Investment Hub Screen

---

### 🌱 `activity_service.dart`
กิจกรรมยั่งยืน
- List activities
- User participation
- Track completion

**ใช้โดย:** Sustainable Activities Screen

---

### 📖 `story_service.dart`
Stories (คล้าย Instagram Stories)
- Get stories
- Mark as viewed
- Create stories

**ใช้โดย:** Home Screen

---

### 👥 `friend_service.dart`
ระบบเพื่อน
- Add/Remove friends
- Friend requests
- Friend list

**ใช้โดย:** Friends Screen, Community

---

## 📁 โฟลเดอร์ย่อย

### `/shipping`
ระบบจัดส่ง
- `shipping_service_manager.dart` - จัดการ shipping providers
- `manual_shipping_provider.dart` - Manual shipping
- รองรับ multi-provider (Kerry, Flash, Thailand Post)

**ใช้โดย:** Checkout, Order Tracking

---

### `/providers`
Service Providers เพิ่มเติม
- Services เฉพาะทางที่ใช้ใน contexts พิเศษ

---

## 🔄 วิธีการใช้งาน Services

### Basic Usage

```dart
// 1. สร้าง instance (หรือ inject via constructor)
final firebaseService = FirebaseService();

// 2. เรียกใช้งาน
final products = await firebaseService.getCollection('products');

// 3. Add document
await firebaseService.addDocument('products', {
  'name': 'Product Name',
  'price': 99.0,
});

// 4. Update document
await firebaseService.updateDocument('products', productId, {
  'price': 79.0,
});

// 5. Delete document
await firebaseService.deleteDocument('products', productId);
```

### Real-time Listener

```dart
// Listen to changes
firebaseService.getCollectionStream('products').listen((snapshot) {
  final products = snapshot.docs.map((doc) => 
    Product.fromMap(doc.data())
  ).toList();
  // Update UI
});
```

---

## 🏗️ สถาปัตยกรรม

```
UI Layer (Screens/Widgets)
    ↓
Provider Layer (State Management)
    ↓
Service Layer (Business Logic) ← คุณอยู่ที่นี่
    ↓
Firebase (Backend)
```

---

## 📝 Best Practices

1. **อย่าเรียก Service ตรงจาก UI**
   - ใช้ Provider เป็นตัวกลาง

2. **Error Handling**
   - Services ควร throw exceptions
   - Provider จัดการและแปลงเป็น user-friendly messages

3. **Dependency Injection**
   - Inject services ใน Provider constructor
   - ทำให้ test ง่ายขึ้น

4. **Async/Await**
   - ใช้ `async/await` สำหรับ async operations
   - Handle timeout และ errors

---

## 🆘 Troubleshooting

| ปัญหา | แก้ไข |
|-------|-------|
| Firebase Error | ตรวจสอบ `firebase_service.dart` |
| Authentication Error | ตรวจสอบ `auth_service.dart` |
| Product ไม่โหลด | ตรวจสอบ `product_service.dart` |
| Payment ไม่ผ่าน | ตรวจสอบ `payment_service.dart` |
| Notification ไม่มา | ตรวจสอบ `notification_service.dart` |

---

**หมายเหตุ:** 
- ไฟล์ที่มี ⭐ คือไฟล์สำคัญมากที่ต้องระวังในการแก้ไข
- Service ใหม่ควรสร้างใน folder นี้
- ตั้งชื่อแบบ `xxx_service.dart`
