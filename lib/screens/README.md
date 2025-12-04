# 📁 Screens - UI Layer

โฟลเดอร์นี้เก็บ **Screens** (หน้าจอต่างๆ) ของแอป

---

## 📱 โครงสร้างโฟลเดอร์

```
screens/
├── splash_screen.dart          # หน้า Splash (เริ่มต้นแอป)
├── home_screen.dart            # หน้าแรก
├── search_screen.dart          # ค้นหาสินค้า
├── category_screen.dart        # หมวดหมู่
├── flash_sale_screen.dart      # Flash Sale
├── product_detail_screen.dart  # รายละเอียดสินค้า
├── cart_screen.dart            # ตะกร้าสินค้า
├── checkout_screen.dart        # ชำระเงิน
├── payment_screen.dart         # ชำระเงิน
├── orders_screen.dart          # คำสั่งซื้อ
├── profile_screen.dart         # โปรไฟล์
├── wishlist_screen.dart        # รายการโปรด
├── notifications_screen.dart   # การแจ้งเตือน
├── chat_screen.dart            # แชท
│
├── auth/                       # 🔐 Authentication
│   ├── login_screen.dart
│   ├── register_screen.dart
│   └── forgot_password_screen.dart
│
├── seller/                     # 🏪 Seller Dashboard
│   ├── seller_dashboard_screen.dart
│   ├── add_product_screen.dart
│   ├── edit_product_screen.dart
│   └── world_class_seller_dashboard.dart
│
├── admin/                      # 👑 Admin Panel
│   ├── admin_panel_screen.dart
│   ├── admin_users_screen.dart
│   └── admin_products_screen.dart
│
└── eco/                        # 🌱 Eco System
    ├── eco_coins_screen.dart
    ├── investment_hub_screen.dart
    └── sustainable_activities_hub_screen.dart
```

---

## 🔑 หน้าจอสำคัญ

### 🏠 `home_screen.dart`
**หน้าแรกของแอป**

**แสดง:**
- Banner โปรโมชั่น
- Stories
- Categories
- Flash Sale
- สินค้าแนะนำ
- สินค้าใหม่

**Providers ที่ใช้:**
- ProductService
- FlashSaleService
- StoryService

---

### 🔍 `search_screen.dart`
**ค้นหาสินค้า**

**Features:**
- Search bar
- Filter (ราคา, หมวดหมู่, คะแนน)
- Sort (ราคา, ยอดขาย, ล่าสุด)
- Search history
- Suggested products

**Providers ที่ใช้:**
- SearchService
- ProductService

---

### 🛍️ `product_detail_screen.dart`
**รายละเอียดสินค้า**

**แสดง:**
- รูปสินค้า (gallery)
- ชื่อ, ราคา, รายละเอียด
- Reviews
- Similar products
- ปุ่มเพิ่มในตะกร้า
- ปุ่ม Wishlist

**Providers ที่ใช้:**
- ProductService
- CartProvider
- UserProvider (wishlist)

---

### 🛒 `cart_screen.dart`
**ตะกร้าสินค้า**

**แสดง:**
- รายการสินค้าในตะกร้า
- จำนวนและราคา
- ปุ่มเพิ่ม/ลด/ลบ
- ส่วนลดและคูปอง
- ปุ่มไปชำระเงิน

**Providers ที่ใช้:**
- CartProvider
- CouponProvider

---

### 💳 `checkout_screen.dart`
**หน้าชำระเงิน**

**แสดง:**
- สรุปคำสั่งซื้อ
- เลือกที่อยู่จัดส่ง
- เลือกวิธีจัดส่ง
- เลือกวิธีชำระเงิน
- ใช้ Eco Coins
- ยืนยันคำสั่งซื้อ

**Providers ที่ใช้:**
- CartProvider
- UserProvider
- PaymentService
- ShippingService
- EcoCoinsProvider

---

### 📦 `orders_screen.dart`
**ประวัติคำสั่งซื้อ**

**แสดง:**
- รายการคำสั่งซื้อ
- แท็บตามสถานะ (ทั้งหมด, รอชำระ, จัดส่ง, เสร็จสิ้น)
- Tracking
- รีวิวสินค้า

**Providers ที่ใช้:**
- OrderService
- ShippingService

---

### 👤 `profile_screen.dart`
**โปรไฟล์ผู้ใช้**

**แสดง:**
- ข้อมูลผู้ใช้
- เมนูต่างๆ:
  - แก้ไขโปรไฟล์
  - ที่อยู่จัดส่ง
  - คำสั่งซื้อ
  - Wishlist
  - Eco Coins
  - Settings
  - ออกจากระบบ

**Providers ที่ใช้:**
- AuthProvider
- UserProvider

---

## 🔐 Auth Screens

### `auth/login_screen.dart`
**เข้าสู่ระบบ**

**Features:**
- Email/Password login
- Google Sign In
- Facebook Sign In
- Phone Number login
- ลืมรหัสผ่าน

---

### `auth/register_screen.dart`
**สมัครสมาชิก**

**Features:**
- ฟอร์มสมัคร
- Validation
- Terms & Conditions

---

## 🏪 Seller Screens

### `seller/seller_dashboard_screen.dart`
**Dashboard ผู้ขาย**

**แสดง:**
- สถิติยอดขาย
- คำสั่งซื้อใหม่
- สินค้า
- รายได้
- กราฟ

**Features:**
- จัดการคำสั่งซื้อ
- จัดการสินค้า
- ดูสถิติ

---

### `seller/add_product_screen.dart`
**เพิ่มสินค้าใหม่**

**Features:**
- อัพโหลดรูป
- กรอกข้อมูลสินค้า
- ตั้งราคาและ stock
- เลือกหมวดหมู่

---

### `seller/edit_product_screen.dart`
**แก้ไขสินค้า**

**Features:**
- แก้ไขข้อมูล
- อัพเดทรูป
- เปลี่ยนราคา/stock

---

## 👑 Admin Screens

### `admin/admin_panel_screen.dart`
**Admin Dashboard**

**Features:**
- ภาพรวมระบบ
- สถิติทั้งหมด
- จัดการ users
- จัดการสินค้า
- จัดการคำสั่งซื้อ

---

## 🌱 Eco Screens

### `eco_coins_screen.dart`
**Eco Coins**

**แสดง:**
- ยอด Eco Coins
- ประวัติการใช้
- Missions
- Rewards

---

### `investment_hub_screen.dart`
**Investment Hub**

**แสดง:**
- โครงการลงทุน
- Portfolio
- Returns

---

### `sustainable_activities_hub_screen.dart`
**กิจกรรมยั่งยืน**

**แสดง:**
- กิจกรรมต่างๆ
- เข้าร่วมกิจกรรม
- รางวัล Eco Coins

---

## 🔄 วิธีสร้าง Screen ใหม่

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyScreen extends StatefulWidget {
  const MyScreen({Key? key}) : super(key: key);

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  @override
  void initState() {
    super.initState();
    // Load data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Screen'),
      ),
      body: Consumer<MyProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return ListView(
            children: [
              // Your content
            ],
          );
        },
      ),
    );
  }
}
```

---

## 📝 Best Practices

1. **StatefulWidget vs StatelessWidget**
   - ใช้ StatefulWidget เมื่อมี local state
   - ใช้ StatelessWidget เมื่อไม่มี local state

2. **Provider Usage**
   - ใช้ `Consumer` สำหรับ rebuild
   - ใช้ `context.read` สำหรับ actions
   - ใช้ `Selector` เพื่อ optimize

3. **Loading State**
   - แสดง loading indicator
   - Disable buttons ขณะโหลด

4. **Error Handling**
   - แสดง error messages
   - มี retry mechanism

5. **Navigation**
   - ใช้ named routes
   - Pass arguments อย่างถูกต้อง

---

## 🎨 UI Components

**แต่ละ Screen ควรมี:**
- AppBar (ถ้าจำเป็น)
- Loading indicator
- Error state
- Empty state
- Main content

**Example:**
```dart
if (isLoading) {
  return LoadingWidget();
}

if (error != null) {
  return ErrorWidget(error: error);
}

if (data.isEmpty) {
  return EmptyStateWidget();
}

return ContentWidget(data: data);
```

---

## 🆘 Troubleshooting

| ปัญหา | แก้ไข |
|-------|-------|
| Screen ไม่แสดง | ตรวจสอบ routes ใน main.dart |
| Data ไม่โหลด | ตรวจสอบ Provider/Service |
| Navigation Error | ตรวจสอบ context และ route name |
| Rebuild บ่อยเกิน | ใช้ Selector แทน Consumer |

---

**หมายเหตุ:**
- Screen ใหม่ควรสร้างใน folder นี้
- ตั้งชื่อแบบ `xxx_screen.dart`
- ควรมี AppBar, Loading, Error states
- ใช้ Provider สำหรับ data management
