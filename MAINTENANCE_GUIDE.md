# 📖 คู่มือการดูแลรักษาโปรเจค Green Market

เอกสารนี้จะช่วยให้คุณเข้าใจโครงสร้างโปรเจคและรู้ว่าจะไปแก้ไขไฟล์ไหนเมื่อต้องการทำอะไร

---

## 📚 เอกสารที่ควรอ่าน

1. **[ARCHITECTURE.md](ARCHITECTURE.md)** - สถาปัตยกรรมโครงสร้างแบบละเอียด
2. **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Quick reference ค้นหาไฟล์ได้เร็ว
3. **[DEVELOPER_GUIDE_TH.md](docs/DEVELOPER_GUIDE_TH.md)** - คู่มือ Developer แบบสมบูรณ์

---

## 🗂️ โครงสร้างโปรเจคแบบเข้าใจง่าย

```
green_market/
│
├── lib/                        # โค้ดหลักของแอป
│   ├── main.dart              # 🚀 จุดเริ่มต้น (Setup providers, routes)
│   ├── main_app_shell.dart    # Shell หลัก (Bottom Navigation)
│   │
│   ├── models/                # 📦 Data Models
│   │   ├── product.dart       # โมเดลสินค้า
│   │   ├── order.dart         # โมเดลคำสั่งซื้อ
│   │   ├── user_model.dart    # โมเดลผู้ใช้
│   │   └── README.md          # 📖 อธิบายแต่ละ model
│   │
│   ├── providers/             # 🔄 State Management
│   │   ├── auth_provider.dart         # จัดการ Login/Logout
│   │   ├── cart_provider_enhanced.dart # จัดการตะกร้า
│   │   ├── user_provider.dart         # จัดการข้อมูลผู้ใช้
│   │   ├── eco_coins_provider.dart    # จัดการ Eco Coins
│   │   ├── theme_provider.dart        # จัดการธีม
│   │   ├── coupon_provider.dart       # จัดการคูปอง
│   │   └── README.md                  # 📖 อธิบายแต่ละ provider
│   │
│   ├── services/              # 🔧 Business Logic & Firebase
│   │   ├── firebase_service.dart ⭐    # SERVICE หลักที่สำคัญที่สุด
│   │   ├── auth_service.dart          # Authentication
│   │   ├── product_service.dart       # จัดการสินค้า
│   │   ├── payment_service.dart       # ชำระเงิน
│   │   ├── notification_service.dart  # แจ้งเตือน
│   │   ├── eco_coins_service.dart     # Eco Coins
│   │   ├── promotion_service.dart     # โปรโมชั่น
│   │   ├── shipping/                  # ระบบจัดส่ง
│   │   └── README.md                  # 📖 อธิบายแต่ละ service
│   │
│   ├── screens/               # 📱 UI Screens (หน้าจอต่างๆ)
│   │   ├── home_screen.dart
│   │   ├── cart_screen.dart
│   │   ├── auth/              # หน้าเข้าสู่ระบบ
│   │   ├── seller/            # หน้าผู้ขาย
│   │   ├── admin/             # หน้า Admin
│   │   └── README.md          # 📖 อธิบายแต่ละหน้าจอ
│   │
│   ├── widgets/               # 🧩 Reusable Widgets
│   ├── theme/                 # 🎨 Theme Configuration
│   └── utils/                 # 🛠️ Helper Functions
│
├── test/                      # 🧪 Tests (74 tests)
├── docs/                      # 📚 เอกสารเพิ่มเติม
└── pubspec.yaml              # 📦 Dependencies
```

---

## 🎯 สถานการณ์และวิธีแก้

### 1. ต้องการเพิ่มฟีเจอร์ใหม่

#### 📝 ขั้นตอน:

1. **สร้าง Model** (ถ้าจำเป็น)
   - สร้างใน `lib/models/`
   - ตั้งชื่อ `xxx.dart`
   - มี `fromMap()`, `toMap()`, `copyWith()`

2. **สร้าง Service** (Business Logic)
   - สร้างใน `lib/services/`
   - ตั้งชื่อ `xxx_service.dart`
   - ใช้ `FirebaseService` สำหรับ CRUD

3. **สร้าง Provider** (State Management)
   - สร้างใน `lib/providers/`
   - ตั้งชื่อ `xxx_provider.dart`
   - Extend `ChangeNotifier`
   - เรียกใช้ Service

4. **สร้าง Screen** (UI)
   - สร้างใน `lib/screens/`
   - ตั้งชื่อ `xxx_screen.dart`
   - ใช้ `Consumer` หรือ `Selector`

5. **เพิ่ม Provider ใน main.dart**
   ```dart
   MultiProvider(
     providers: [
       // ...existing providers...
       ChangeNotifierProvider(create: (_) => NewProvider()),
     ],
   )
   ```

6. **เพิ่ม Route ใน main.dart**
   ```dart
   '/new-screen': (context) => NewScreen(),
   ```

---

### 2. แก้ไขสี/ธีมของแอป

**🎨 ไปที่:** `lib/theme/app_theme.dart`

```dart
// แก้สีหลัก (Primary Color)
static const Color primary = Color(0xFF2E7D32);  // สีเขียวหลัก

// แก้สีรอง (Secondary Color)
static const Color secondary = Color(0xFF66BB6A);  // สีเขียวอ่อน

// แก้ฟอนต์ (Font Family)
static const String fontFamily = 'Prompt';  // ใช้ฟอนต์ Prompt

// เพิ่มสีใหม่
static const Color accent = Color(0xFFFFAB00);  // สีเหลือง
```

**💡 เคล็ดลับ:** ใช้ [Material Color Tool](https://material.io/resources/color/) เลือกสี

---

### 3. แก้ไข Firebase Configuration

**🔥 ไปที่:** `lib/firebase_options.dart`

```dart
// อัพเดท Firebase config
// ⚠️ ระวัง: ไฟล์นี้มี API keys อย่า commit ลง Git!
static const FirebaseOptions currentPlatform = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',        // API Key จาก Firebase Console
  appId: 'YOUR_APP_ID',          // App ID จาก Firebase Console
  messagingSenderId: 'XXX',      // Sender ID
  projectId: 'your-project-id',  // Project ID
  // ...
);
```

**📝 หมายเหตุ:** ดู API Keys ได้ที่ Firebase Console → Project Settings

---

### 4. เพิ่ม/ลด Tab ใน Bottom Navigation

**🧭 ไปที่:** `lib/main_app_shell.dart`

```dart
// เพิ่ม Tab ใหม่
bottomNavigationBar: BottomNavigationBar(
  items: [
    // ...existing items...
    BottomNavigationBarItem(
      icon: Icon(Icons.new_icon),      // ไอคอนของ Tab
      label: 'New Tab',                // ชื่อที่แสดง
    ),
  ],
)

// อย่าลืม: เพิ่ม Screen ที่ตรงกับ Tab นี้ด้วย!
final List<Widget> _screens = [
  // ...existing screens...
  NewScreen(),  // Screen สำหรับ Tab ใหม่
];
```

**💡 เคล็ดลับ:** ถ้าลด Tab ต้องลบทั้ง `BottomNavigationBarItem` และ Screen

---

### 5. แก้ปัญหา Login ไม่ได้

**🔍 ตรวจสอบไฟล์เหล่านี้:**
1. `lib/services/auth_service.dart` - ตรวจสอบ logic การ login
2. `lib/providers/auth_provider.dart` - ตรวจสอบ state management
3. `lib/screens/auth/login_screen.dart` - ตรวจสอบ UI

**🛠️ Debug Steps:**
```dart
// ใน auth_service.dart
print('🐛 กำลังพยายาม login ด้วย email: $email');

// ใน auth_provider.dart
print('🐛 Auth state ตอนนี้: $_authState');
print('🐛 Error message: $_errorMessage');

// ตรวจสอบ Firebase Console:
// - ไป Authentication → Users
// - ตรวจสอบว่า user มีอยู่จริงหรือไม่
// - ตรวจสอบ Sign-in methods ที่เปิดใช้
```

**🔥 สาเหตุที่เจอบ่อย:**
- ❌ Email/Password ผิด
- ❌ User ถูกปิดการใช้งาน (disabled)
- ❌ Sign-in method ไม่ได้เปิดใน Firebase Console
- ❌ Network ไม่มี

---

### 6. แก้ปัญหาสินค้าไม่แสดง

**🔍 ตรวจสอบไฟล์:**
1. `lib/services/product_service.dart` - ตรวจสอบ query
2. `lib/screens/home_screen.dart` - ตรวจสอบ UI

**🛠️ Debug Steps:**
```dart
// ใน product_service.dart
final products = await firebaseService.getCollection('products');
print('🐛 จำนวนสินค้าที่ได้: ${products.length} ชิ้น');

// ลองอ่านข้อมูลตัวแรก
if (products.isNotEmpty) {
  print('🐛 สินค้าแรก: ${products.first}');
}
```

**🔥 ตรวจสอบ Firebase Console:**
1. ไป Firestore Database
2. เข้า collection `products`
3. ตรวจสอบว่ามีข้อมูลหรือไม่?
4. ตรวจสอบ Rules: อนุญาตให้อ่านได้หรือไม่?

```javascript
// ตัวอย่าง Firestore Rules ที่ถูกต้อง
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /products/{productId} {
      allow read: if true;  // อนุญาตให้ทุกคนอ่านได้
    }
  }
}
```

**🔥 สาเหตุที่เจอบ่อย:**
- ❌ ไม่มีข้อมูลใน Firestore
- ❌ Collection name ผิด (ตรวจสอบตัวพิมพ์เล็ก-ใหญ่)
- ❌ Firestore Rules ไม่อนุญาตให้อ่าน
- ❌ Model parsing ผิด (ตรวจสอบ `fromMap()`)

---

### 7. แก้ปัญหาตะกร้าไม่อัพเดท

**ตรวจสอบไฟล์:**
- `lib/providers/cart_provider_enhanced.dart`

**ตรวจสอบ:**
```dart
// หลังจากเปลี่ยน state ต้องเรียก
notifyListeners();

// ใน Widget ต้องใช้ watch หรือ Consumer
final cart = context.watch<CartProvider>();
```

---

### 8. เพิ่มวิธีชำระเงินใหม่

**ไปที่:** `lib/services/payment_service.dart`

```dart
Future<void> processNewPaymentMethod(/* params */) async {
  // Add your logic here
}
```

---

### 9. เพิ่ม Shipping Provider ใหม่

**ไปที่:** `lib/services/shipping/`

1. สร้าง `new_shipping_provider.dart`
2. Implement interface
3. Register ใน `shipping_service_manager.dart`

---

### 10. แก้ไข Push Notification

**ไปที่:** `lib/services/notification_service.dart`

```dart
// ตรวจสอบ FCM token
final token = await getToken();
print('FCM Token: $token');

// ตรวจสอบ permissions
final hasPermission = await requestPermission();
```

---

## 🔍 เทคนิคการหาไฟล์ที่ต้องแก้

### 1. ใช้ VS Code Search

**กด** `Ctrl+Shift+F` (Windows) หรือ `Cmd+Shift+F` (Mac)

**ค้นหา:**
- Class name: `class ProductService`
- Function name: `Future<void> addProduct`
- String: `'Error loading products'`

---

### 2. ใช้ QUICK_REFERENCE.md

เปิดไฟล์ `QUICK_REFERENCE.md` แล้วค้นหาด้วย `Ctrl+F`

**ตัวอย่าง:**
- ค้นหา "login" → จะเจอ `auth_service.dart`, `auth_provider.dart`
- ค้นหา "cart" → จะเจอ `cart_provider_enhanced.dart`

---

### 3. ดูโครงสร้างใน ARCHITECTURE.md

เปิด `ARCHITECTURE.md` เพื่อดูภาพรวมและความสัมพันธ์

---

## 🏗️ Data Flow - เข้าใจง่าย

**เปรียบเทียบ:** เหมือนการสั่งอาหารในร้าน

```
1. User กดปุ่ม (UI)                      เหมือน: ลูกค้าสั่งอาหาร
    ↓
2. Widget เรียก Provider                 เหมือน: พนักงานรับออเดอร์
    ↓
3. Provider เรียก Service                เหมือน: ส่งออเดอร์เข้าครัว
    ↓
4. Service เรียก Firebase                เหมือน: เชฟทำอาหาร
    ↓
5. Firebase ส่งข้อมูลกลับ                เหมือน: อาหารเสร็จ
    ↓
6. Service ประมวลผล                      เหมือน: จัดเสิร์ฟอาหาร
    ↓
7. Provider อัพเดท State                 เหมือน: พนักงานเอาอาหารออกไป
    (notifyListeners)                    เหมือน: เรียกลูกค้าว่าพร้อมแล้ว
    ↓
8. Widget rebuild อัตโนมัติ              เหมือน: โต๊ะอาหารอัพเดท
    ↓
9. User เห็นผลลัพธ์                       เหมือน: ลูกค้าได้อาหาร
```

**💡 ทำไมต้องแยกชั้นแบบนี้?**
- **UI Layer**: แสดงผลเท่านั้น ไม่ต้องรู้ว่าข้อมูลมาจากไหน
- **Provider**: จัดการ state เพื่อให้ UI ใช้งาน
- **Service**: จัดการ logic ที่ซับซ้อน ติดต่อ Firebase
- **Firebase**: เก็บข้อมูลจริงๆ

แยกชัดเจนแบบนี้ = แก้ไขง่าย, test ง่าย, maintain ง่าย!

---

## 🐛 Debug Checklist (เช็คลิสต์ตรวจสอบหาข้อผิดพลาด)

**เมื่อเจอปัญหา ตรวจสอบตามลำดับ:**

### ✅ 1. UI Layer (Screens) - ชั้นหน้าจอ
**ตรวจสอบ:**
- ❓ Widget แสดงผลถูกต้องหรือไม่?
- ❓ ใช้ Provider ถูกต้องหรือไม่? (`watch` vs `read`)
- ❓ มี error boundary หรือไม่? (ตรวจจับ error)
- ❓ มีการแสดง loading state หรือไม่?

**🛠️ วิธีแก้:**
```dart
// ตรวจสอบว่าใช้ watch เพื่อ rebuild
final cart = context.watch<CartProvider>();  // ถูกต้อง!
```

---

### ✅ 2. Provider Layer - ชั้นจัดการ State
**ตรวจสอบ:**
- ❓ `notifyListeners()` ถูกเรียกหรือไม่? (หลังเปลี่ยน state)
- ❓ State เปลี่ยนถูกต้องหรือไม่?
- ❓ Error handling มีหรือไม่? (จับ error ได้ไหม)
- ❓ Loading state ถูกต้องหรือไม่?

**🛠️ วิธีแก้:**
```dart
// ใน Provider - อย่าลืมเรียก notifyListeners!
void addToCart(Product product) {
  _items.add(product);
  notifyListeners();  // ต้องมีบรรทัดนี้!
}
```

---

### ✅ 3. Service Layer - ชั้น Business Logic
**ตรวจสอบ:**
- ❓ Logic ถูกต้องหรือไม่?
- ❓ Firebase query ถูกหรือไม่? (ตรวจสอบ collection, field names)
- ❓ Error handling มีหรือไม่? (try-catch)
- ❓ Timeout เกิดหรือไม่? (ตรวจสอบ network)

**🛠️ วิธีแก้:**
```dart
// เพิ่ม print เพื่อ debug
final products = await firebaseService.getCollection('products');
print('🐛 Debug: ได้สินค้า ${products.length} ชิ้น');
```

---

### ✅ 4. Firebase - ฐานข้อมูล
**ตรวจสอบ:**
- ❓ Rules อนุญาตหรือไม่? (เข้า Firebase Console)
- ❓ มีข้อมูลใน Firestore หรือไม่?
- ❓ Collection/Document names ถูกต้องหรือไม่?
- ❓ Network ติดต่อได้หรือไม่? (ลอง ping)

**🛠️ วิธีแก้:**
1. เข้า Firebase Console
2. ไป Firestore Database
3. ตรวจสอบ collection แลว documents
4. ตรวจสอบ Rules ที่ Firestore Rules

---

**💡 เคล็ดลับ Debug:**
```dart
// ใช้ print สำหรับ debug
print('🐛 Step 1: User clicked button');
print('🐛 Step 2: Cart items = ${_items.length}');
print('🐛 Step 3: Firebase response = $data');

// หรือดู logs ใน Terminal
flutter logs
```

---

## 🛠️ คำสั่งที่ใช้บ่อย

```bash
# รันแอป
flutter run

# รันบน Chrome
flutter run -d chrome

# รัน Tests
flutter test

# ตรวจสอบ Code Quality
dart analyze

# Format Code
dart format lib/

# Clean Build
flutter clean
flutter pub get

# ดู Dependencies
flutter pub deps

# Update Dependencies
flutter pub upgrade

# ดู Flutter Doctor
flutter doctor
```

---

## 📊 สถิติโปรเจค (ปัจจุบัน)

- **Flutter Version:** 3.32.4
- **Dart Version:** 3.8.1
- **Total Files:** 263 files in lib/
- **Total Tests:** 74 tests (✅ All passing)
- **Test Coverage:** ~80%
- **Dependencies:** 30+ packages
- **Code Quality:** ⭐⭐⭐⭐⭐ (0 errors, 0 warnings)
- **Completion:** 94%

---

## 📝 Best Practices

### 1. ก่อนแก้โค้ด
- อ่านเอกสารก่อน
- ทำความเข้าใจ data flow
- ตรวจสอบ dependencies

### 2. ขณะแก้โค้ด
- แก้ทีละเล็กทีละน้อย
- รัน tests บ่อยๆ
- Comment code ที่ซับซ้อน

### 3. หลังแก้โค้ด
- รัน `dart analyze`
- รัน `flutter test`
- ทดสอบบน emulator/device
- อัพเดทเอกสาร (ถ้าจำเป็น)

---

## 🔐 ความปลอดภัย

### ไฟล์ที่ไม่ควร commit
- `lib/firebase_options.dart` (มี API keys)
- `.env` files
- Private keys

### Firebase Rules
- ตรวจสอบ `firestore.rules`
- ตรวจสอบ `storage.rules`
- Test rules ใน Firebase Console

---

## 🚀 Deployment Checklist

### ก่อน Deploy
- ✅ All tests passing
- ✅ No errors/warnings
- ✅ Firebase rules ถูกต้อง
- ✅ Environment variables ถูกต้อง
- ✅ ทดสอบบนอุปกรณ์จริง
- ✅ อัพเดท version number
- ✅ เขียน release notes

### Deploy Steps
1. Build app
   ```bash
   flutter build apk --release  # Android
   flutter build ios --release  # iOS
   ```
2. Test build
3. Upload to store
4. Monitor errors (Firebase Crashlytics)

---

## 🆘 ติดปัญหา?

### 1. ตรวจสอบเอกสาร
- [ARCHITECTURE.md](ARCHITECTURE.md)
- [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
- [DEVELOPER_GUIDE_TH.md](docs/DEVELOPER_GUIDE_TH.md)

### 2. ตรวจสอบ Logs
```bash
flutter logs
```

### 3. ตรวจสอบ Firebase Console
- Firestore data
- Authentication
- Storage
- Functions logs

### 4. Search Issues
- ใช้ VS Code search (`Ctrl+Shift+F`)
- ดู error stack trace
- Search ใน GitHub Issues (ถ้ามี)

---

## 📚 แหล่งเรียนรู้เพิ่มเติม

- [Flutter Documentation](https://docs.flutter.dev)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Provider Package](https://pub.dev/packages/provider)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)

---

## 📅 Maintenance Schedule

### ทุกวัน
- ตรวจสอบ errors ใน Firebase Console
- Monitor app performance

### ทุกสัปดาห์
- รัน `flutter pub upgrade`
- ตรวจสอบ security updates
- Review user feedback

### ทุกเดือน
- อัพเดท dependencies
- ตรวจสอบ code quality
- Cleanup unused code
- ปรับปรุงเอกสาร

---

## 🎓 Tips สำหรับ Maintainer ใหม่

1. **อ่านเอกสารทั้งหมดก่อน** - อย่าข้าม!
2. **ใช้ QUICK_REFERENCE.md บ่อยๆ** - ช่วยหาไฟล์ได้เร็ว
3. **ทำความเข้าใจ Data Flow** - สำคัญมาก!
4. **อย่ากลัวที่จะ Debug** - ใช้ print statements
5. **รัน Tests ก่อนเสมอ** - ก่อนแก้และหลังแก้
6. **Git Commit บ่อยๆ** - เพื่อสามารถ revert ได้
7. **เขียน Comment ที่ดี** - ช่วยคนอื่นและตัวเองในอนาคต

---

**อัพเดทล่าสุด:** 4 ธันวาคม 2025

**Maintainer:** Green Market Team

**License:** MIT
