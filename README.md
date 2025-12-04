# Green Market - Eco-friendly Marketplace

Green Market เป็นแอปพลิเคชัน E-commerce ที่เน้นการซื้อขายสินค้าที่เป็นมิตรต่อสิ่งแวดล้อม พัฒนาด้วย Flutter และ Firebase

---

## 🇹🇭 สำหรับนักพัฒนาไทย

**🚀 เริ่มที่นี่เลย!** → **[START_HERE_TH.md](START_HERE_TH.md)** - คู่มือเริ่มต้นฉบับภาษาไทย

เอกสารที่เขียนเป็นภาษาไทยทั้งหมด อธิบายแบบละเอียดและเข้าใจง่าย เหมาะสำหรับคนที่เริ่มใหม่!

---

## 🚀 เริ่มต้นใช้งาน

### สำหรับ Developer ใหม่ (มือใหม่หัดขับ)
**อ่านเอกสารเหล่านี้ตามลำดับ:**
1. **[START_HERE_TH.md](START_HERE_TH.md)** 🇹🇭 **เริ่มที่นี่!** - คู่มือเริ่มต้นภาษาไทย
2. **[MAINTENANCE_GUIDE.md](MAINTENANCE_GUIDE.md)** ⭐ - คู่มือการดูแลรักษาและเข้าใจโปรเจค
3. **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Quick reference หาไฟล์ได้เร็ว
4. **[ARCHITECTURE.md](ARCHITECTURE.md)** - สถาปัตยกรรมโครงสร้างแบบละเอียด

### สำหรับ Developer ที่คุ้นเคย (รู้จักโปรเจคแล้ว)
ดูเอกสารใน `/lib` folders:
- [lib/services/README.md](lib/services/README.md) - อธิบาย Services (Business Logic)
- [lib/providers/README.md](lib/providers/README.md) - อธิบาย Providers (State Management)
- [lib/models/README.md](lib/models/README.md) - อธิบาย Models (Data Structure)
- [lib/screens/README.md](lib/screens/README.md) - อธิบาย Screens (UI Layer)

---

## 🌟 จุดมุ่งหมายหลัก
ตลาดกลางสำหรับซื้อขายสินค้าที่เป็นมิตรต่อสิ่งแวดล้อม (คล้าย Shopee แต่เน้น Eco-friendly)

## 👥 บทบาทผู้ใช้
- **Buyer (ผู้ซื้อ)**: ซื้อสินค้า เข้าร่วมกิจกรรม ลงทุน
- **Seller (ผู้ขาย)**: ขายสินค้า จัดการร้านค้า
- **Admin (แอดมิน)**: ควบคุมระบบ อนุมัติสินค้า/ผู้ขาย/โครงการ

---

## 🎯 ฟีเจอร์หลัก

### 1. E-commerce Core (100% ✅)
- ระบบซื้อขาย พร้อม Eco Score (1-100)
- หมวดหมู่สินค้า
- ตะกร้าสินค้า และการสั่งซื้อ
- รีวิวและเรตติ้ง
- ระบบคูปอง/โปรโมชั่น
- Flash Sale

### 2. User Management (95% ✅)
- Login/Register (Email, Google, Facebook, Phone)
- Profile Management
- Address Management
- Order History
- Wishlist

### 3. Green World Hub (90% ✅)
- **Sustainable Activities**: กิจกรรมเพื่อสิ่งแวดล้อม
- **Investment Hub**: โครงการลงทุนยั่งยืน
- **News & Articles**: ข่าวสารด้านสิ่งแวดล้อม

### 4. Eco Coins System (100% ✅)
- Earn coins from purchases
- Missions & Rewards
- Redeem system

### 5. Seller Dashboard (95% ✅)
- จัดการสินค้า
- ดูยอดขาย
- จัดการคำสั่งซื้อ
- สถิติและกราฟ

### 6. Admin Panel (95% ✅)
- อนุมัติสินค้า/ผู้ขาย/โครงการ
- จัดการ Eco Score
- จัดการผู้ใช้
- ควบคุมระบบทั้งหมด

### 7. Notification System (100% ✅)
- Push Notifications (FCM)
- Local Notifications
- In-app Notifications

### 8. Chat System (85% ✅)
- Real-time chat
- Image sharing
- 🚧 File sharing (upcoming)
- 🚧 Voice messages (upcoming)

### 9. Shipping System (100% ✅)
- Manual shipping
- Multi-provider support
- Tracking system

---

## 🏗️ สถาปัตยกรรม

```
┌─────────────┐
│   UI Layer  │  ← Screens & Widgets
└──────┬──────┘
       │
┌──────▼──────┐
│  Providers  │  ← State Management (Provider Pattern)
└──────┬──────┘
       │
┌──────▼──────┐
│  Services   │  ← Business Logic & Firebase Integration
└──────┬──────┘
       │
┌──────▼──────┐
│   Models    │  ← Data Models
└──────┬──────┘
       │
┌──────▼──────┐
│  Firebase   │  ← Backend (Firestore, Auth, Storage, FCM)
└─────────────┘
```

### โครงสร้างโฟลเดอร์สำคัญ

```
lib/
├── main.dart                    # 🚀 จุดเริ่มต้น (Setup providers, routes)
├── main_app_shell.dart          # Shell หลัก (Bottom Navigation)
├── models/                      # 📦 Data Models
├── providers/                   # 🔄 State Management
├── services/                    # 🔧 Business Logic & Firebase
│   └── firebase_service.dart    # ⭐ SERVICE หลักที่สำคัญที่สุด
├── screens/                     # 📱 UI Screens
├── widgets/                     # 🧩 Reusable Widgets
├── theme/                       # 🎨 Theme Configuration
└── utils/                       # 🛠️ Helper Functions
```

---

## 📊 สถิติโปรเจค

- **Flutter Version:** 3.32.4
- **Dart Version:** 3.8.1
- **Total Files:** 263 files in lib/
- **Total Tests:** 74 tests (✅ All passing)
- **Test Coverage:** ~80%
- **Dependencies:** 30+ packages
- **Code Quality:** ⭐⭐⭐⭐⭐ (0 errors, 0 warnings)
- **Overall Completion:** 94%

---

## 🔧 Dependencies สำคัญ

### Core
- `flutter_sdk: 3.32.4`
- `provider: ^6.1.2` - State Management

### Firebase
- `firebase_core: ^4.0.0`
- `firebase_auth: ^6.0.0`
- `cloud_firestore: ^6.0.0`
- `firebase_storage: ^13.0.0`
- `firebase_messaging: ^16.0.0`

### UI/UX
- `flutter_localizations` - Localization
- `intl: ^0.20.2` - Date/Time formatting
- `cached_network_image: ^3.4.1` - Image caching

### Testing
- `flutter_test` - Testing framework
- `mockito: ^5.4.4` - Mocking
- `fake_cloud_firestore: ^4.0.0` - Firestore testing

---

## 📱 การรัน

### Development
```bash
# Get dependencies
flutter pub get

# Run on default device
flutter run

# Run on Chrome
flutter run -d chrome

# Run with hot reload
flutter run --hot
```

### Testing
```bash
# Run all tests
flutter test

# Check code quality
dart analyze

# Format code
dart format lib/
```

### Build
```bash
# Build APK (Android)
flutter build apk --release

# Build iOS
flutter build ios --release
```

---

## ✅ สถานะปัจจุบัน

### ✨ พร้อมใช้งาน (94%)
- ✅ E-commerce Core (100%)
- ✅ User Management (95%)
- ✅ Green World Hub (90%)
- ✅ Eco Coins System (100%)
- ✅ Seller Dashboard (95%)
- ✅ Admin Panel (95%)
- ✅ Notification System (100%)
- ✅ Chat System (85%)
- ✅ Shipping System (100%)
- ✅ UI/UX (90%)

### 🎨 Theme System
- ✅ Light/Dark mode
- ✅ Custom colors
- ✅ Responsive design

### 🔐 Security
- ✅ Firebase Security Rules configured
- ✅ Authentication properly implemented
- ✅ Data validation

### 🧪 Testing
- ✅ 74 tests passing
- ✅ Unit tests
- ✅ Integration tests
- ✅ Widget tests

---

## 🐛 การแก้ไขปัญหาที่ผ่านมา

### ✅ แก้ไขแล้ว (December 2025)
1. ✅ Routes และ Navigation
2. ✅ Firebase Security Rules
3. ✅ State management
4. ✅ Error handling
5. ✅ ปัญหาการล็อกอินเด้งออก
   - Session Persistence
   - Retry Mechanism
   - Auto User Creation
   - Error Handling
6. ✅ Stream synchronization in tests
7. ✅ Code duplication removed
8. ✅ Unused files deleted

---

## 🚧 กำลังพัฒนา (6% remaining)

- 🔄 Advanced Chat Features (file sharing, voice)
- 🔄 Analytics Dashboard
- 🔄 Multi-language Support
- 🔄 Advanced search filters

---

## 📚 เอกสารประกอบ

### 📖 เอกสารหลัก (อ่านตามลำดับ)
1. **[START_HERE_TH.md](START_HERE_TH.md)** 🇹🇭 - คู่มือเริ่มต้นภาษาไทย (สำหรับมือใหม่)
2. **[MAINTENANCE_GUIDE.md](MAINTENANCE_GUIDE.md)** - คู่มือการดูแลรักษาโปรเจค
3. **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - อ้างอิงเร็ว หาไฟล์ได้ทันใจ
4. **[ARCHITECTURE.md](ARCHITECTURE.md)** - สถาปัตยกรรมโครงสร้างแบบละเอียด

### 📂 เอกสารเฉพาะด้าน (ใน `/docs`)
- **[DEVELOPER_GUIDE.md](docs/DEVELOPER_GUIDE.md)** - คู่มือ Developer ฉบับภาษาอังกฤษ
- **[DEPENDENCIES.md](docs/DEPENDENCIES.md)** - รายการ Dependencies และ Packages
- **[ECO_COINS_SYSTEM_COMPLETE_GUIDE.md](docs/ECO_COINS_SYSTEM_COMPLETE_GUIDE.md)** - ระบบ Eco Coins
- **[SHIPPING_SYSTEM_DOCUMENTATION.md](docs/SHIPPING_SYSTEM_DOCUMENTATION.md)** - ระบบจัดส่ง
- **[SMART_ECO_HERO_SYSTEM_GUIDE.md](docs/SMART_ECO_HERO_SYSTEM_GUIDE.md)** - ระบบ Eco Hero

### 📱 เอกสารใน `/lib` folders
- **[lib/services/README.md](lib/services/README.md)** - อธิบาย Services
- **[lib/providers/README.md](lib/providers/README.md)** - อธิบาย Providers
- **[lib/models/README.md](lib/models/README.md)** - อธิบาย Models
- **[lib/screens/README.md](lib/screens/README.md)** - อธิบาย Screens

---

## 🤝 Contributing

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License

---

## 👨‍💻 Maintainers

Green Market Team

**อัพเดทล่าสุด:** 4 ธันวาคม 2025
