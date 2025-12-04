# 🚀 คู่มือเริ่มต้นฉบับภาษาไทย - Green Market

เอกสารนี้จะช่วยให้คุณเริ่มต้นพัฒนาโปรเจค Green Market ได้อย่างรวดเร็ว

---

## 📚 ก่อนเริ่ม - อ่านเอกสารเหล่านี้

**สำหรับคนที่เริ่มใหม่ (อ่านตามลำดับ):**

1. **[README.md](README.md)** ← เริ่มที่นี่! - ภาพรวมโปรเจค
2. **[MAINTENANCE_GUIDE.md](MAINTENANCE_GUIDE.md)** ⭐ สำคัญมาก! - คู่มือดูแลรักษา
3. **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - อ้างอิงเร็ว
4. **[ARCHITECTURE.md](ARCHITECTURE.md)** - สถาปัตยกรรมแบบละเอียด

**สำหรับคนที่คุ้นเคยแล้ว:**
- [lib/services/README.md](lib/services/README.md)
- [lib/providers/README.md](lib/providers/README.md)
- [lib/models/README.md](lib/models/README.md)
- [lib/screens/README.md](lib/screens/README.md)

---

## 🎯 โปรเจคนี้คืออะไร?

**Green Market** = แอปขายของออนไลน์แบบ Shopee แต่เน้นสินค้าที่เป็นมิตรกับสิ่งแวดล้อม

### คุณสมบัติหลัก:
- 🛒 ซื้อ-ขายสินค้า Eco-friendly
- 🪙 ระบบ Eco Coins (คะแนนสะสม)
- 🌱 Green World Hub (ลงทุน, กิจกรรม)
- 👑 Admin Panel (จัดการทั้งระบบ)
- 💬 Chat (คุยกับผู้ขาย)
- 📦 ระบบจัดส่ง (Kerry, Flash, Thailand Post)

---

## 🏗️ โครงสร้างโปรเจค (อธิบายแบบง่ายๆ)

```
green_market/
│
├── lib/                          ← โค้ดหลักทั้งหมดอยู่ที่นี่
│   ├── main.dart                ← 🚀 จุดเริ่มต้นโปรแกรม (เปิดแอปตรงนี้)
│   ├── main_app_shell.dart      ← เมนูด้านล่าง (Bottom Navigation)
│   │
│   ├── models/                  ← 📦 โครงสร้างข้อมูล
│   │   ├── product.dart        ← ข้อมูลสินค้า (ชื่อ, ราคา, รูป)
│   │   ├── order.dart          ← ข้อมูลคำสั่งซื้อ
│   │   └── user_model.dart     ← ข้อมูลผู้ใช้
│   │
│   ├── providers/               ← 🔄 จัดการ State (ข้อมูลที่เปลี่ยนแปลง)
│   │   ├── auth_provider.dart  ← จัดการ login/logout
│   │   ├── cart_provider_enhanced.dart  ← จัดการตะกร้าสินค้า
│   │   └── user_provider.dart  ← จัดการข้อมูลผู้ใช้
│   │
│   ├── services/                ← 🔧 ติดต่อ Firebase (CRUD)
│   │   ├── firebase_service.dart  ← ⭐ SERVICE หลัก (สำคัญมาก!)
│   │   ├── auth_service.dart   ← login/register
│   │   └── product_service.dart  ← จัดการสินค้า
│   │
│   ├── screens/                 ← 📱 หน้าจอต่างๆ
│   │   ├── home_screen.dart    ← หน้าแรก
│   │   ├── cart_screen.dart    ← หน้าตะกร้า
│   │   └── auth/               ← หน้า login/register
│   │
│   ├── widgets/                 ← 🧩 ชิ้นส่วน UI ที่ใช้ซ้ำได้
│   ├── theme/                   ← 🎨 สี, ฟอนต์
│   └── utils/                   ← 🛠️ ฟังก์ชันช่วยเหลือ
│
├── test/                         ← 🧪 Tests (74 tests)
└── pubspec.yaml                  ← 📦 รายการ dependencies

```

---

## 🤔 แต่ละส่วนทำอะไร?

### 📦 Models - โครงสร้างข้อมูล
**คิดเป็น:** แบบฟอร์ม, template ของข้อมูล

```dart
// ตัวอย่าง: product.dart
class Product {
  final String id;          // รหัสสินค้า
  final String name;        // ชื่อสินค้า (เช่น "กระเป้าผ้าใบ")
  final double price;       // ราคา (เช่น 299.00)
  final List<String> images; // รูปภาพ
  final int stock;          // จำนวนคงเหลือ
}
```

**เมื่อไหร่ใช้:** เก็บข้อมูลทุกอย่าง (สินค้า, ผู้ใช้, คำสั่งซื้อ)

---

### 🔄 Providers - จัดการ State
**คิดเป็น:** พนักงานที่จัดการข้อมูลและแจ้ง UI เมื่อมีการเปลี่ยนแปลง

```dart
// ตัวอย่าง: cart_provider_enhanced.dart
class CartProvider extends ChangeNotifier {
  List<Product> _items = [];  // สินค้าในตะกร้า
  
  void addToCart(Product product) {
    _items.add(product);        // เพิ่มสินค้า
    notifyListeners();          // แจ้ง UI ให้อัพเดท
  }
}
```

**เมื่อไหร่ใช้:** เมื่อข้อมูลเปลี่ยนแล้วต้องการให้หน้าจอแสดงผลใหม่

---

### 🔧 Services - ติดต่อ Firebase
**คิดเป็น:** เชฟที่ทำอาหาร (ประมวลผล logic, ติดต่อ database)

```dart
// ตัวอย่าง: product_service.dart
class ProductService {
  Future<List<Product>> getProducts() async {
    // ดึงข้อมูลจาก Firebase
    final data = await firebaseService.getCollection('products');
    // แปลงเป็น Product objects
    return data.map((item) => Product.fromMap(item)).toList();
  }
}
```

**เมื่อไหร่ใช้:** เมื่อต้องการอ่าน/เขียนข้อมูลจาก Firebase

---

### 📱 Screens - หน้าจอที่ผู้ใช้เห็น
**คิดเป็น:** โต๊ะอาหารที่เสิร์ฟให้ลูกค้า (แสดงผล UI)

```dart
// ตัวอย่าง: home_screen.dart
class HomeScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    // ใช้ Consumer เพื่อฟัง Provider
    return Consumer<ProductService>(
      builder: (context, products, child) {
        // แสดงรายการสินค้า
        return ListView.builder(...);
      }
    );
  }
}
```

**เมื่อไหร่ใช้:** ทุกหน้าที่ผู้ใช้มองเห็น

---

## 🔄 Data Flow - ข้อมูลไหลยังไง?

**เปรียบเทียบกับร้านอาหาร:**

```
1. ลูกค้าสั่งอาหาร (User กดปุ่ม)
   ↓
2. พนักงานรับออเดอร์ (Widget เรียก Provider)
   ↓
3. พนักงานส่งออเดอร์เข้าครัว (Provider เรียก Service)
   ↓
4. เชฟทำอาหาร (Service ติดต่อ Firebase)
   ↓
5. อาหารเสร็จ (Firebase ส่งข้อมูลกลับ)
   ↓
6. เชฟส่งออกจากครัว (Service ส่งข้อมูลกลับ)
   ↓
7. พนักงานเอาอาหารออกมา (Provider อัพเดท state)
   ↓
8. เสิร์ฟให้ลูกค้า (UI rebuild และแสดงผล)
   ↓
9. ลูกค้าได้อาหาร (User เห็นผลลัพธ์)
```

---

## 🛠️ คำสั่งพื้นฐานที่ต้องใช้

### รันโปรเจค
```bash
# ติดตั้ง dependencies
flutter pub get

# รันแอป (เลือก device ก่อน)
flutter run

# รันบน Chrome
flutter run -d chrome

# รัน tests
flutter test

# ตรวจสอบ code quality
dart analyze

# จัดรูปแบบ code
dart format lib/
```

---

## 🎯 สถานการณ์จริง - ทำอย่างไร?

### 1️⃣ อยากเพิ่มสินค้าในตะกร้า

**ขั้นตอน:**
1. ผู้ใช้กดปุ่ม "เพิ่มในตะกร้า" → `screens/product_detail_screen.dart`
2. เรียก Provider → `providers/cart_provider_enhanced.dart`
3. Provider อัพเดท state → `notifyListeners()`
4. UI rebuild อัตโนมัติ → ไอคอนตะกร้าแสดงจำนวนใหม่

**โค้ดตัวอย่าง:**
```dart
// ใน product_detail_screen.dart
ElevatedButton(
  child: Text('เพิ่มในตะกร้า'),
  onPressed: () {
    // อ่าน CartProvider (ไม่ rebuild)
    final cart = context.read<CartProvider>();
    // เพิ่มสินค้า
    cart.addToCart(product);
    // แสดง snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('เพิ่มสินค้าในตะกร้าแล้ว'))
    );
  }
)
```

---

### 2️⃣ อยากเปลี่ยนสีแอป

**ขั้นตอน:**
1. ไปที่ `lib/theme/app_theme.dart`
2. แก้ค่าสี

```dart
// ตัวอย่าง
class AppColors {
  static const primary = Color(0xFF2E7D32);    // เขียว → แก้เป็นสีที่ชอบ
  static const secondary = Color(0xFF66BB6A);  // เขียวอ่อน
  static const accent = Color(0xFFFFAB00);     // เหลือง
}
```

3. Hot reload (กด `r` ใน terminal) → เห็นผลทันที!

---

### 3️⃣ อยากเพิ่มหน้าจอใหม่

**ขั้นตอน:**
1. สร้างไฟล์ใหม่ใน `lib/screens/`
```dart
// lib/screens/my_new_screen.dart
import 'package:flutter/material.dart';

class MyNewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('หน้าจอใหม่')),
      body: Center(child: Text('สวัสดี!')),
    );
  }
}
```

2. เพิ่ม route ใน `lib/main.dart`
```dart
MaterialApp(
  routes: {
    // ...existing routes...
    '/my-new-screen': (context) => MyNewScreen(),
  }
)
```

3. Navigate ไปหน้าใหม่
```dart
Navigator.pushNamed(context, '/my-new-screen');
```

---

## 🐛 เจอปัญหา? แก้ยังไง?

### ❌ ปัญหา: แอปไม่รัน
```bash
# ลองคำสั่งนี้
flutter clean
flutter pub get
flutter run
```

### ❌ ปัญหา: Widget ไม่อัพเดท
```dart
// ตรวจสอบว่าใช้ watch หรือ Consumer
// ❌ ผิด
final cart = context.read<CartProvider>();

// ✅ ถูก
final cart = context.watch<CartProvider>();

// หรือ
Consumer<CartProvider>(...)
```

### ❌ ปัญหา: Firebase Error
1. ตรวจสอบ `lib/firebase_options.dart` → API keys ถูกหรือไม่?
2. เปิด Firebase Console → ตรวจสอบ Firestore Rules
3. ตรวจสอบ internet connection

### ❌ ปัญหา: Build Error
```bash
# ดู error message แล้ว Google!
# หรือถาม ChatGPT พร้อม error message

# ตัวอย่าง error ที่เจอบ่อย:
# - Missing import → เพิ่ม import statement
# - Undefined variable → ตรวจสอบชื่อตัวแปร
# - Type mismatch → ตรวจสอบ type ของตัวแปร
```

---

## 💡 เคล็ดลับสำหรับมือใหม่

### ✅ ควรทำ
1. **อ่านเอกสารก่อนเขียนโค้ด** - เข้าใจภาพรวมก่อน
2. **ใช้ print() debug** - ง่ายและได้ผลดี
   ```dart
   print('🐛 ค่าของตัวแปร: $myVariable');
   ```
3. **Test บ่อยๆ** - รัน `flutter test` ก่อน commit
4. **Commit บ่อยๆ** - เผื่อต้อง revert
5. **Hot Reload คือเพื่อน** - กด `r` ใน terminal
6. **Google เป็นเพื่อน** - copy error message ไป search
7. **อย่ากลัวผิด** - ลองทำดู ผิดก็แก้ได้

### ❌ ไม่ควรทำ
1. **อย่าแก้หลายที่พร้อมกัน** - แก้ทีละเล็กทีละน้อย
2. **อย่าข้าม Test** - อาจทำให้ระบบพัง
3. **อย่า commit firebase_options.dart** - มี API keys
4. **อย่าใช้ context.read เมื่อต้องการ rebuild** - ใช้ watch
5. **อย่าลืม notifyListeners()** - ใน Provider

---

## 📖 คำศัพท์ที่ควรรู้

| คำศัพท์ | ความหมาย | ตัวอย่าง |
|---------|----------|----------|
| **Widget** | ชิ้นส่วน UI | Text, Button, Container |
| **Provider** | จัดการ State | CartProvider, AuthProvider |
| **Service** | Business Logic | ProductService, AuthService |
| **Model** | โครงสร้างข้อมูล | Product, User, Order |
| **State** | ข้อมูลที่เปลี่ยนแปลงได้ | จำนวนสินค้าในตะกร้า |
| **CRUD** | Create, Read, Update, Delete | เพิ่ม/อ่าน/แก้/ลบข้อมูล |
| **Firebase** | Backend service | Firestore, Auth, Storage |
| **Hot Reload** | รีเฟรชแอปแบบเร็ว | กด `r` ใน terminal |
| **Rebuild** | สร้าง UI ใหม่ | เมื่อ state เปลี่ยน |
| **notifyListeners** | แจ้ง UI ให้ rebuild | หลังเปลี่ยน state |

---

## 🚀 ขั้นตอนถัดไป

1. ✅ อ่านเอกสารนี้จบแล้ว → อ่าน [MAINTENANCE_GUIDE.md](MAINTENANCE_GUIDE.md)
2. ✅ เข้าใจภาพรวมแล้ว → ดู [ARCHITECTURE.md](ARCHITECTURE.md)
3. ✅ พร้อมเขียนโค้ด → ลองแก้ไขอะไรง่ายๆ (เช่น เปลี่ยนสี)
4. ✅ เขียนโค้ดได้แล้ว → ลองเพิ่มฟีเจอร์เล็กๆ
5. ✅ มั่นใจแล้ว → เริ่มพัฒนาฟีเจอร์ใหม่!

---

## 🆘 ติดปัญหาหนักๆ?

1. **อ่าน Error Message** - ส่วนใหญ่บอกปัญหาอยู่แล้ว
2. **Google Error Message** - copy paste ไป search
3. **ถาม ChatGPT** - ส่ง error message พร้อม code
4. **ดู Documentation** - [Flutter Docs](https://docs.flutter.dev)
5. **ดู Stack Trace** - หาว่า error เกิดที่ไหน

---

## 🎓 แหล่งเรียนรู้เพิ่มเติม

### ภาษาไทย
- [Flutter Thailand Community](https://www.facebook.com/groups/flutterth)
- YouTube: ค้นหา "Flutter Tutorial Thai"

### ภาษาอังกฤษ
- [Flutter Documentation](https://docs.flutter.dev)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Provider Package](https://pub.dev/packages/provider)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)

---

## 📝 สรุป

**จำไว้ว่า:**
- 📦 **Models** = โครงสร้างข้อมูล
- 🔄 **Providers** = จัดการ State
- 🔧 **Services** = ติดต่อ Firebase
- 📱 **Screens** = หน้าจอที่เห็น

**Data Flow:**
User กดปุ่ม → Widget → Provider → Service → Firebase → กลับมา → UI อัพเดท

**เมื่อเจอปัญหา:**
อ่าน error → Google → ถาม ChatGPT → ถามเพื่อน → อ่านเอกสาร

---

**สนุกกับการ coding นะครับ! 🎉**

**หมายเหตุ:** เอกสารนี้เขียนขึ้นเพื่อช่วยนักพัฒนาไทยโดยเฉพาะ หากมีคำถามหรือข้อสงสัย สามารถเปิด issue หรือถามใน team chat ได้เลย!

---

**อัพเดทล่าสุด:** 4 ธันวาคม 2025
