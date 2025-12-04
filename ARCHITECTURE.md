  # Green Market - สถาปัตยกรรมระบบ

## 📋 สารบัญ
- [ภาพรวมโครงสร้าง](#ภาพรวมโครงสร้าง)
- [โครงสร้างโฟลเดอร์](#โครงสร้างโฟลเดอร์)
- [Data Flow](#data-flow)
- [ไฟล์สำคัญและหน้าที่](#ไฟล์สำคัญและหน้าที่)

---

## 🏗️ ภาพรวมโครงสร้าง

Green Market ใช้สถาปัตยกรรมแบบ **Provider Pattern** ร่วมกับ **Firebase Backend**

```
┌─────────────┐
│   UI Layer  │  ← Screens & Widgets
└──────┬──────┘
       │
┌──────▼──────┐
│  Providers  │  ← State Management (Provider)
└──────┬──────┘
       │
┌──────▼──────┐
│  Services   │  ← Business Logic & Firebase Integration
└──────┬──────┘
       │
┌──────▼──────┐
│   Models    │  ← Data Models
└─────────────┘
```

---

## 📁 โครงสร้างโฟลเดอร์

### `/lib` - โค้ดหลักของแอป

```
lib/
├── main.dart                    # จุดเริ่มต้นของแอป
├── main_app_shell.dart          # Shell หลักของแอป (Bottom Navigation)
├── firebase_options.dart        # Firebase Configuration
│
├── models/                      # 📦 Data Models
│   ├── product.dart            # โมเดลสินค้า
│   ├── order.dart              # โมเดลคำสั่งซื้อ
│   ├── user_model.dart         # โมเดลผู้ใช้
│   └── ...
│
├── providers/                   # 🔄 State Management
│   ├── auth_provider.dart      # จัดการ Authentication State
│   ├── cart_provider_enhanced.dart  # จัดการตะกร้าสินค้า
│   ├── user_provider.dart      # จัดการข้อมูลผู้ใช้
│   ├── eco_coins_provider.dart # จัดการ Eco Coins
│   ├── theme_provider.dart     # จัดการธีม
│   └── coupon_provider.dart    # จัดการคูปอง
│
├── services/                    # 🔧 Business Logic & Firebase
│   ├── firebase_service.dart   # Service หลัก (Firestore CRUD)
│   ├── auth_service.dart       # Authentication
│   ├── product_service.dart    # จัดการสินค้า
│   ├── payment_service.dart    # ระบบชำระเงิน
│   ├── notification_service.dart  # การแจ้งเตือน
│   ├── eco_coins_service.dart  # ระบบ Eco Coins
│   ├── promotion_service.dart  # โปรโมชั่น
│   ├── flash_sale_service.dart # Flash Sale
│   ├── investment_service.dart # การลงทุน
│   ├── activity_service.dart   # กิจกรรม
│   ├── story_service.dart      # Stories
│   ├── friend_service.dart     # เพื่อน
│   └── shipping/               # ระบบจัดส่ง
│       ├── shipping_service_manager.dart
│       ├── manual_shipping_provider.dart
│       └── ...
│
├── screens/                     # 📱 UI Screens
│   ├── splash_screen.dart
│   ├── auth/                   # หน้าเข้าสู่ระบบ
│   ├── seller/                 # หน้าสำหรับผู้ขาย
│   ├── admin/                  # หน้า Admin Panel
│   └── ...
│
├── widgets/                     # 🧩 Reusable Widgets
│   ├── product_card.dart
│   ├── custom_bottom_nav.dart
│   └── ...
│
├── theme/                       # 🎨 Theme Configuration
│   ├── app_theme.dart
│   └── app_colors.dart
│
└── utils/                       # 🛠️ Helper Functions
    ├── constants.dart
    ├── validators.dart
    └── ...
```

---

## 🔄 Data Flow (การไหลของข้อมูล)

### การไหลของข้อมูลในแอป

**อธิบาย:** เมื่อผู้ใช้กระทำอะไรในแอป (เช่น กดปุ่ม) ข้อมูลจะไหลผ่านชั้นต่างๆ แบบนี้:

```
1. User Action (UI)                      ← ผู้ใช้กดปุ่มหรือทำอะไรในหน้าจอ
    ↓
2. Widget calls Provider method          ← Widget เรียกฟังก์ชันใน Provider
    ↓
3. Provider calls Service                ← Provider ส่งต่อให้ Service ทำงาน
    ↓
4. Service calls Firebase                ← Service ติดต่อ Firebase
    ↓
5. Firebase returns data                 ← Firebase ส่งข้อมูลกลับมา
    ↓
6. Service processes data                ← Service ประมวลผลข้อมูล
    ↓
7. Provider updates state                ← Provider อัพเดท state
    (notifyListeners)                    ← แจ้ง Widget ทั้งหมดที่ฟังอยู่
    ↓
8. UI rebuilds automatically             ← หน้าจออัพเดทอัตโนมัติ
```

### ตัวอย่าง: การเพิ่มสินค้าในตะกร้า (แบบละเอียด)

```dart
// ขั้นตอนที่ 1: User กดปุ่ม "เพิ่มในตะกร้า" (UI Layer)
// ตำแหน่ง: screens/product_detail_screen.dart
onPressed: () {
  // เรียก Provider เพื่อเพิ่มสินค้า
  cartProvider.addToCart(product);
}

// ขั้นตอนที่ 2: Provider รับคำสั่ง (providers/cart_provider_enhanced.dart)
void addToCart(Product product) {
  _cartItems.add(product);        // เพิ่มสินค้าเข้า list
  notifyListeners();              // แจ้ง UI ทุกตัวที่ฟังอยู่ให้ rebuild
}

// ขั้นตอนที่ 3: UI rebuild อัตโนมัติ (Consumer Widget)
// ตำแหน่ง: widgets/cart_badge.dart หรือ screens/cart_screen.dart
Consumer<CartProvider>(
  builder: (context, cart, child) {
    // ทุกครั้งที่ cart เปลี่ยน function นี้จะถูกเรียกใหม่
    return Text('สินค้าในตะกร้า: ${cart.itemCount}');
  }
)
```

---

## 📄 ไฟล์สำคัญและหน้าที่

### 🚀 Core Files

#### `main.dart`
**หน้าที่:** จุดเริ่มต้นของแอป
- Initialize Firebase
- Setup Providers (MultiProvider)
- Define Routes
- Start App

**ควรแก้ไขเมื่อ:** 
- เพิ่ม Provider ใหม่
- เพิ่ม Route ใหม่
- เปลี่ยน Firebase Config

---

#### `main_app_shell.dart`
**หน้าที่:** Shell หลักของแอป
- Bottom Navigation Bar
- Page Navigation Management
- Floating Action Button (ถ้ามี)

**ควรแก้ไขเมื่อ:**
- เพิ่ม/ลด Tab ใน Bottom Nav
- เปลี่ยนหน้าหลัก

---

### 🔄 Providers (State Management)

#### `auth_provider.dart`
**หน้าที่:** จัดการสถานะการเข้าสู่ระบบ
- Login/Logout
- Check Authentication State
- User Session Management

**เชื่อมต่อกับ:**
- `auth_service.dart`
- `firebase_service.dart`

**ใช้งานใน:** ทุกหน้าที่ต้องตรวจสอบการเข้าสู่ระบบ

---

#### `cart_provider_enhanced.dart`
**หน้าที่:** จัดการตะกร้าสินค้า
- Add/Remove items
- Calculate total
- Apply coupons
- Calculate shipping

**เชื่อมต่อกับ:**
- `coupon_provider.dart`
- `firebase_service.dart`

**ใช้งานใน:**
- Product Detail Screen
- Cart Screen
- Checkout Screen

---

#### `user_provider.dart`
**หน้าที่:** จัดการข้อมูลผู้ใช้
- Load user profile
- Update user data
- Manage addresses
- Manage favorite products

**เชื่อมต่อกับ:**
- `firebase_service.dart`

**ใช้งานใน:**
- Profile Screen
- Edit Profile Screen
- Address Management

---

#### `eco_coins_provider.dart`
**หน้าที่:** จัดการระบบ Eco Coins
- Get balance
- Track transactions
- Manage missions
- Redeem rewards

**เชื่อมต่อกับ:**
- `eco_coins_service.dart`

**ใช้งานใน:**
- Eco Coins Screen
- Mission Screen
- Redeem Screen

---

#### `theme_provider.dart`
**หน้าที่:** จัดการธีมของแอป
- Toggle Dark/Light Mode
- Save theme preference

**ใช้งานใน:**
- Settings Screen
- ทุกหน้าที่ใช้ Theme

---

#### `coupon_provider.dart`
**หน้าที่:** จัดการคูปองส่วนลด
- List available coupons
- Apply/Remove coupon
- Validate coupon

**เชื่อมต่อกับ:**
- `promotion_service.dart`
- `firebase_service.dart`

**ใช้งานใน:**
- Cart Screen
- Checkout Screen
- Coupon List Screen

---

### 🔧 Services (Business Logic)

#### `firebase_service.dart` ⭐ **SERVICE หลักที่สำคัญที่สุด**
**หน้าที่:** Service หลักสำหรับทำงานกับ Firestore
- CRUD operations (Create, Read, Update, Delete)
- Query data from collections
- Real-time listeners

**Collections ที่จัดการ:**
- `users` - ข้อมูลผู้ใช้
- `products` - สินค้า
- `orders` - คำสั่งซื้อ
- `categories` - หมวดหมู่
- `sellers` - ผู้ขาย
- `reviews` - รีวิว
- และอีกมากมาย...

**ใช้โดย:** เกือบทุก Service และ Provider

---

#### `auth_service.dart`
**หน้าที่:** จัดการ Authentication
- Login (Email/Password, Google, Facebook)
- Register
- Logout
- Password Reset
- Phone Authentication

**ใช้โดย:** `auth_provider.dart`

---

#### `product_service.dart`
**หน้าที่:** จัดการสินค้า
- Get products (with filters)
- Search products
- Get product details
- Manage product stock

**ใช้โดย:**
- Product List Screens
- Search Screen
- Category Screen

---

#### `payment_service.dart`
**หน้าที่:** ระบบชำระเงิน
- Process payment
- Generate payment link
- Verify payment
- Support multiple payment methods

**ใช้โดย:**
- Payment Screen
- Checkout Flow

---

#### `notification_service.dart`
**หน้าที่:** การแจ้งเตือน
- Push notifications (Firebase Cloud Messaging)
- Local notifications
- Notification permissions
- Topic subscription

**ใช้โดย:** `main.dart` (Initialize) และทุกที่ที่ต้องแจ้งเตือน

---

#### `eco_coins_service.dart`
**หน้าที่:** ระบบ Eco Coins
- Calculate eco coins from orders
- Track transactions
- Manage missions
- Redeem rewards

**ใช้โดย:** `eco_coins_provider.dart`

---

#### `promotion_service.dart`
**หน้าที่:** จัดการโปรโมชั่น
- Get active promotions
- Apply promotions
- Calculate discounts
- Validate promo codes

**ใช้โดย:**
- `coupon_provider.dart`
- Cart/Checkout Screens

---

#### `flash_sale_service.dart`
**หน้าที่:** Flash Sale
- Get flash sale products
- Check time-based availability
- Manage limited stock

**ใช้โดย:**
- Flash Sale Screen
- Home Screen

---

#### `investment_service.dart`
**หน้าที่:** ระบบการลงทุน (Green World Hub)
- Manage investment projects
- Track user investments
- Calculate returns

**ใช้โดย:**
- Investment Hub Screen
- Investment Detail Screen

---

#### `activity_service.dart`
**หน้าที่:** กิจกรรมยั่งยืน
- List activities
- User participation
- Track activity completion

**ใช้โดย:**
- Sustainable Activities Screen
- Activity Detail Screen

---

#### `story_service.dart`
**หน้าที่:** Stories (คล้าย Instagram/Facebook Stories)
- Get stories
- Mark as viewed
- Create stories

**ใช้โดย:**
- Home Screen (Stories section)

---

#### `friend_service.dart`
**หน้าที่:** ระบบเพื่อน
- Add/Remove friends
- Friend requests
- Friend list

**ใช้โดย:**
- Friends Screen
- Community Features

---

#### `shipping/` folder
**หน้าที่:** ระบบจัดส่ง
- `shipping_service_manager.dart` - จัดการ shipping providers
- `manual_shipping_provider.dart` - Manual shipping
- รองรับ multi-provider (Kerry, Flash, Thailand Post)

**ใช้โดย:**
- Checkout Screen
- Order Tracking Screen

---

### 📦 Models

#### สำคัญที่ควรรู้จัก:

- **`product.dart`** - โมเดลสินค้า (ชื่อ, ราคา, รูป, stock)
- **`order.dart`** - โมเดลคำสั่งซื้อ (สินค้า, ที่อยู่, สถานะ)
- **`user_model.dart`** - โมเดลผู้ใช้ (ชื่อ, email, ที่อยู่, role)
- **`cart_item.dart`** - สินค้าในตะกร้า
- **`address.dart`** - ที่อยู่จัดส่ง
- **`category.dart`** - หมวดหมู่สินค้า

---

## 🔍 วิธีหาไฟล์ที่ต้องแก้

### เพิ่มฟีเจอร์ใหม่

1. **UI ใหม่** → สร้างใน `/screens`
2. **Widget ที่ใช้ซ้ำ** → สร้างใน `/widgets`
3. **State Management** → สร้าง Provider ใน `/providers`
4. **Business Logic** → สร้าง Service ใน `/services`
5. **Data Model** → สร้างใน `/models`

### แก้ Bug

1. **หน้าจอแสดงผิด** → ตรวจสอบ `/screens/ชื่อหน้า`
2. **Data ไม่อัพเดท** → ตรวจสอบ Provider → Service
3. **Firebase Error** → ตรวจสอบ `/services/firebase_service.dart`
4. **Auth Error** → ตรวจสอบ `/services/auth_service.dart`

### ปรับแต่ง UI

1. **สี/ธีม** → `/theme/app_theme.dart` และ `app_colors.dart`
2. **ฟอนต์** → `/theme/app_theme.dart`
3. **Layout** → `/screens` หรือ `/widgets`

---

## 📚 เอกสารเพิ่มเติม

- [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - Quick reference ไฟล์สำคัญ
- [DEVELOPER_GUIDE_TH.md](docs/DEVELOPER_GUIDE_TH.md) - คู่มือ Developer แบบละเอียด
- [MAINTENANCE_GUIDE.md](docs/MAINTENANCE_GUIDE.md) - คู่มือการดูแลระบบ

---

## 🆘 ติดปัญหา?

1. ตรวจสอบ logs ใน Debug Console
2. ตรวจสอบ Firebase Console
3. ดู error stack trace
4. ตรวจสอบ Provider state
5. ตรวจสอบ Service methods

---

**อัพเดทล่าสุด:** 4 ธันวาคม 2025
