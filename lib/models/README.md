# 📁 Models - Data Models Layer

โฟลเดอร์นี้เก็บ **Data Models** ที่ใช้แทนโครงสร้างข้อมูลในแอป

---

## 📦 Models สำคัญ

### 🛍️ `product.dart`
**Model สำหรับสินค้า**

**Fields:**
- `id` - ID สินค้า
- `name` - ชื่อสินค้า
- `description` - รายละเอียด
- `price` - ราคา
- `images` - รูปภาพ (List)
- `category` - หมวดหมู่
- `stock` - จำนวนคงเหลือ
- `sellerId` - ID ผู้ขาย
- `rating` - คะแนน
- `reviews` - จำนวนรีวิว
- `isEcoFriendly` - เป็นสินค้าเป็นมิตรกับสิ่งแวดล้อมหรือไม่

**Methods:**
- `fromMap()` - สร้าง Product จาก Map
- `toMap()` - แปลง Product เป็น Map
- `copyWith()` - สร้าง copy พร้อมเปลี่ยนค่าบางตัว

**ใช้ที่:**
- Product Screens
- Cart
- Order

---

### 📦 `order.dart`
**Model สำหรับคำสั่งซื้อ**

**Fields:**
- `id` - ID คำสั่งซื้อ
- `userId` - ID ผู้ซื้อ
- `items` - รายการสินค้า (List<OrderItem>)
- `totalAmount` - ยอดรวม
- `status` - สถานะ (pending, confirmed, shipped, delivered)
- `shippingAddress` - ที่อยู่จัดส่ง
- `paymentMethod` - วิธีชำระเงิน
- `createdAt` - วันที่สั่งซื้อ
- `trackingNumber` - เลขพัสดุ

**Status:**
- `pending` - รอดำเนินการ
- `confirmed` - ยืนยันแล้ว
- `processing` - กำลังเตรียมของ
- `shipped` - จัดส่งแล้ว
- `delivered` - ส่งถึงแล้ว
- `cancelled` - ยกเลิก

**ใช้ที่:**
- Order History
- Order Detail
- Seller Dashboard

---

### 👤 `user_model.dart`
**Model สำหรับผู้ใช้**

**Fields:**
- `id` - User ID
- `email` - อีเมล
- `displayName` - ชื่อที่แสดง
- `phoneNumber` - เบอร์โทร
- `photoUrl` - รูปโปรไฟล์
- `addresses` - ที่อยู่ (List<Address>)
- `role` - บทบาท (user, seller, admin)
- `ecoCoins` - ยอด Eco Coins
- `createdAt` - วันที่สมัคร

**Roles:**
- `user` - ผู้ใช้ทั่วไป
- `seller` - ผู้ขาย
- `admin` - ผู้ดูแลระบบ

**ใช้ที่:**
- Profile Screen
- Auth
- User Management

---

### 🛒 `cart_item.dart`
**Model สำหรับสินค้าในตะกร้า**

**Fields:**
- `product` - สินค้า (Product)
- `quantity` - จำนวน
- `selectedOptions` - ตัวเลือกที่เลือก (เช่น สี, ไซส์)

**Calculated:**
- `totalPrice` - ราคารวม (price × quantity)

**ใช้ที่:**
- Cart Screen
- Checkout

---

### 📍 `address.dart`
**Model สำหรับที่อยู่**

**Fields:**
- `id` - ID ที่อยู่
- `name` - ชื่อผู้รับ
- `phoneNumber` - เบอร์โทรศัพท์
- `address` - ที่อยู่
- `province` - จังหวัด
- `district` - อำเภอ
- `subdistrict` - ตำบล
- `postalCode` - รหัสไปรษณีย์
- `isDefault` - เป็นที่อยู่ default หรือไม่

**ใช้ที่:**
- Address Management
- Checkout
- Order

---

### 🏷️ `category.dart`
**Model สำหรับหมวดหมู่**

**Fields:**
- `id` - ID หมวดหมู่
- `name` - ชื่อหมวดหมู่
- `icon` - ไอคอน
- `image` - รูปภาพ
- `productCount` - จำนวนสินค้าในหมวดหมู่

**ใช้ที่:**
- Category Screen
- Product Filter

---

### ⭐ `review.dart`
**Model สำหรับรีวิว**

**Fields:**
- `id` - ID รีวิว
- `userId` - ID ผู้รีวิว
- `productId` - ID สินค้า
- `rating` - คะแนน (1-5)
- `comment` - ความคิดเห็น
- `images` - รูปภาพประกอบ
- `createdAt` - วันที่รีวิว

**ใช้ที่:**
- Product Detail
- Review Screen

---

### 🎟️ `coupon.dart`
**Model สำหรับคูปอง**

**Fields:**
- `id` - ID คูปอง
- `code` - รหัสคูปอง
- `discount` - ส่วนลด (% หรือ บาท)
- `type` - ประเภท (percentage, fixed)
- `minPurchase` - ยอดซื้อขั้นต่ำ
- `maxDiscount` - ส่วนลดสูงสุด
- `expiryDate` - วันหมดอายุ
- `usageLimit` - จำนวนครั้งที่ใช้ได้

**ใช้ที่:**
- Cart
- Checkout
- Coupon List

---

### 🪙 `eco_coins_models.dart`
**Models สำหรับระบบ Eco Coins**

#### `EcoCoinBalance`
- `balance` - ยอด Eco Coins
- `pending` - ยอดรอการเข้า
- `lifetime` - ยอดสะสมตลอดชีวิต

#### `EcoCoinTransaction`
- `id` - ID ธุรกรรม
- `amount` - จำนวน
- `type` - ประเภท (earn, spend, refund)
- `description` - คำอธิบาย
- `createdAt` - วันที่

#### `EcoCoinMission`
- `id` - ID ภารกิจ
- `title` - ชื่อภารกิจ
- `description` - รายละเอียด
- `reward` - รางวัล (Eco Coins)
- `type` - ประเภท (daily, weekly, one-time)
- `progress` - ความคืบหน้า

**ใช้ที่:**
- Eco Coins Screen
- Mission Screen

---

### 💰 `investment_project.dart`
**Model สำหรับโครงการลงทุน**

**Fields:**
- `id` - ID โครงการ
- `title` - ชื่อโครงการ
- `description` - รายละเอียด
- `goalAmount` - เป้าหมายเงิน
- `currentAmount` - เงินที่ได้รับแล้ว
- `returns` - ผลตอบแทน (%)
- `duration` - ระยะเวลา
- `minInvestment` - เงินลงทุนขั้นต่ำ
- `images` - รูปภาพ
- `status` - สถานะ (active, funded, completed)

**ใช้ที่:**
- Investment Hub Screen
- Investment Detail

---

### 🌱 `sustainable_activity.dart`
**Model สำหรับกิจกรรมยั่งยืน**

**Fields:**
- `id` - ID กิจกรรม
- `title` - ชื่อกิจกรรม
- `description` - รายละเอียด
- `location` - สถานที่
- `date` - วันที่จัด
- `maxParticipants` - จำนวนผู้เข้าร่วมสูงสุด
- `currentParticipants` - จำนวนผู้เข้าร่วมปัจจุบัน
- `ecoCoinsReward` - รางวัล Eco Coins

**ใช้ที่:**
- Activities Screen
- Activity Detail

---

### 🏪 `seller.dart`
**Model สำหรับผู้ขาย**

**Fields:**
- `id` - ID ผู้ขาย
- `name` - ชื่อร้าน
- `description` - คำอธิบาย
- `logo` - โลโก้
- `rating` - คะแนน
- `followers` - ผู้ติดตาม
- `products` - จำนวนสินค้า
- `isVerified` - ยืนยันตัวตนแล้วหรือไม่

**ใช้ที่:**
- Seller Dashboard
- Shop Page

---

### 💬 `chat_model.dart`
**Model สำหรับแชท**

**Fields:**
- `id` - ID แชท
- `participants` - ผู้เข้าร่วม
- `lastMessage` - ข้อความล่าสุด
- `lastMessageTime` - เวลาข้อความล่าสุด
- `unreadCount` - จำนวนข้อความที่ยังไม่ได้อ่าน

**ใช้ที่:**
- Chat Screen
- Chat List

---

### 🔔 `app_notification.dart`
**Model สำหรับการแจ้งเตือน**

**Fields:**
- `id` - ID การแจ้งเตือน
- `title` - หัวข้อ
- `body` - เนื้อหา
- `type` - ประเภท
- `data` - ข้อมูลเพิ่มเติม
- `isRead` - อ่านแล้วหรือไม่
- `createdAt` - วันที่

**Types:**
- `order` - เกี่ยวกับคำสั่งซื้อ
- `promotion` - โปรโมชั่น
- `ecoCoins` - Eco Coins
- `system` - ระบบ

**ใช้ที่:**
- Notifications Screen

---

## 🔄 วิธีการใช้งาน Models

### 1. Create from Map (from Firestore)

```dart
final product = Product.fromMap(docSnapshot.data()!);
```

### 2. Convert to Map (to Firestore)

```dart
final productMap = product.toMap();
await firestore.collection('products').add(productMap);
```

### 3. Copy with changes

```dart
final updatedProduct = product.copyWith(
  price: 99.0,
  stock: 50,
);
```

### 4. JSON Serialization

```dart
// To JSON
final json = product.toJson();

// From JSON
final product = Product.fromJson(json);
```

---

## 📝 Best Practices

1. **Immutability**
   - ใช้ `final` สำหรับ fields
   - ใช้ `copyWith()` เพื่อสร้าง modified copy

2. **Null Safety**
   - ใช้ nullable types (`String?`) เมื่อเหมาะสม
   - ให้ default values

3. **Validation**
   - Validate data ใน constructor
   - Throw exceptions สำหรับ invalid data

4. **Documentation**
   - เขียน doc comments
   - อธิบาย fields และ methods

5. **Testing**
   - เขียน unit tests สำหรับ models
   - ทดสอบ serialization/deserialization

---

## 🏗️ Model Structure

```dart
class MyModel {
  // Fields
  final String id;
  final String name;
  
  // Constructor
  MyModel({
    required this.id,
    required this.name,
  });
  
  // fromMap (from Firestore)
  factory MyModel.fromMap(Map<String, dynamic> map) {
    return MyModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
    );
  }
  
  // toMap (to Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
  
  // copyWith
  MyModel copyWith({
    String? id,
    String? name,
  }) {
    return MyModel(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}
```

---

## 🆘 Troubleshooting

| ปัญหา | แก้ไข |
|-------|-------|
| Null error | เช็ค null safety ใน model |
| Serialization error | ตรวจสอบ fromMap/toMap |
| Type mismatch | ตรวจสอบ type ของ fields |
| Missing fields | เพิ่ม default values |

---

**หมายเหตุ:**
- Model ใหม่ควรสร้างใน folder นี้
- ควรมี `fromMap()` และ `toMap()`
- ควรมี `copyWith()` เพื่อ immutability
- ใช้ `final` สำหรับ fields
