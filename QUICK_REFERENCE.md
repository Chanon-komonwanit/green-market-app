# Quick Reference - Green Market

## 📁 ไฟล์สำคัญและตำแหน่ง

### 🚀 ต้องการทำอะไร → ไปที่ไฟล์ไหน

| ต้องการ | ไฟล์ | ตำแหน่ง |
|---------|------|---------|
| **เพิ่ม Route ใหม่** | `main.dart` | `/lib/main.dart` |
| **เปลี่ยน Bottom Nav** | `main_app_shell.dart` | `/lib/main_app_shell.dart` |
| **แก้ Firebase Config** | `firebase_options.dart` | `/lib/firebase_options.dart` |
| **เพิ่ม Provider** | `main.dart` | `/lib/main.dart` (ในส่วน MultiProvider) |
| **แก้สี/ธีม** | `app_theme.dart` | `/lib/theme/app_theme.dart` |
| **แก้ฟอนต์** | `app_theme.dart` | `/lib/theme/app_theme.dart` |
| **Constants** | `constants.dart` | `/lib/utils/constants.dart` |

---

## 🔄 Providers (State Management)

| Provider | ไฟล์ | ทำอะไร | ใช้งานที่ไหน |
|----------|------|--------|--------------|
| **AuthProvider** | `auth_provider.dart` | Login/Logout/Session | ทุกหน้าที่ต้องตรวจสอบ login |
| **CartProvider** | `cart_provider_enhanced.dart` | จัดการตะกร้า | Cart, Checkout |
| **UserProvider** | `user_provider.dart` | ข้อมูลผู้ใช้ | Profile, Settings |
| **EcoCoinsProvider** | `eco_coins_provider.dart` | Eco Coins System | Eco Coins, Missions |
| **ThemeProvider** | `theme_provider.dart` | Dark/Light Mode | Settings, ทุกหน้า |
| **CouponProvider** | `coupon_provider.dart` | คูปอง/โปรโมชั่น | Cart, Checkout |
| **AppConfigProvider** | `app_config_provider.dart` | App Configuration | ทั่วทั้งแอป |

### วิธีใช้ Provider ในหน้า Screen:

```dart
// 📖 วิธีที่ 1: อ่านค่า (ไม่ rebuild)
// ใช้เมื่อ: ต้องการเรียก method แต่ไม่ต้องการให้ widget rebuild
final cart = context.read<CartProvider>();
cart.addToCart(product);  // เรียกใช้ method

// 📖 วิธีที่ 2: ฟังการเปลี่ยนแปลง (rebuild อัตโนมัติ)
// ใช้เมื่อ: ต้องการให้ widget rebuild ทุกครั้งที่ state เปลี่ยน
final cart = context.watch<CartProvider>();
Text('จำนวน: ${cart.itemCount}');  // จะอัพเดทเมื่อ itemCount เปลี่ยน

// 📖 วิธีที่ 3: ใช้ Consumer (แนะนำ)
// ใช้เมื่อ: ต้องการ rebuild เฉพาะส่วนที่จำเป็น
Consumer<CartProvider>(
  builder: (context, cart, child) {
    // ส่วนนี้จะ rebuild เมื่อ cart เปลี่ยน
    return Text('จำนวน: ${cart.itemCount}');
  }
)
```

**💡 เคล็ดลับ:**
- ใช้ `read` เมื่อต้องการเรียก method (เช่น กดปุ่ม)
- ใช้ `watch` หรือ `Consumer` เมื่อต้องการแสดงข้อมูลที่เปลี่ยนแปลง

---

## 🔧 Services (Business Logic)

| Service | ไฟล์ | ทำอะไร | เรียกจาก |
|---------|------|--------|----------|
| **FirebaseService** ⭐ | `firebase_service.dart` | CRUD Firestore (หลัก) | ทุก Provider/Service |
| **AuthService** | `auth_service.dart` | Login/Register/Logout | AuthProvider |
| **ProductService** | `product_service.dart` | จัดการสินค้า | Product Screens |
| **PaymentService** | `payment_service.dart` | ชำระเงิน | Payment Screen |
| **NotificationService** | `notification_service.dart` | แจ้งเตือน | ทั่วทั้งแอป |
| **EcoCoinsService** | `eco_coins_service.dart` | Eco Coins Logic | EcoCoinsProvider |
| **PromotionService** | `promotion_service.dart` | โปรโมชั่น | CouponProvider |
| **FlashSaleService** | `flash_sale_service.dart` | Flash Sale | Flash Sale Screen |
| **InvestmentService** | `investment_service.dart` | ลงทุน (Green Hub) | Investment Screens |
| **ActivityService** | `activity_service.dart` | กิจกรรมยั่งยืน | Activity Screens |
| **StoryService** | `story_service.dart` | Stories | Home Screen |
| **FriendService** | `friend_service.dart` | เพื่อน | Friends Screen |
| **ShippingServiceManager** | `shipping/shipping_service_manager.dart` | จัดการจัดส่ง | Checkout, Tracking |

### วิธีเรียกใช้ Service:

```dart
// ใน Provider
class MyProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;
  
  MyProvider(this._firebaseService);
  
  Future<void> loadData() async {
    final data = await _firebaseService.getCollection('users');
    notifyListeners();
  }
}

// หรือเรียกตรงๆ (ไม่แนะนำ)
final service = FirebaseService();
await service.getCollection('products');
```

---

## 📦 Models สำคัญ

| Model | ไฟล์ | ใช้สำหรับ |
|-------|------|-----------|
| **Product** | `models/product.dart` | สินค้า |
| **Order** | `models/order.dart` | คำสั่งซื้อ |
| **UserModel** | `models/user_model.dart` | ผู้ใช้ |
| **CartItem** | `models/cart_item.dart` | สินค้าในตะกร้า |
| **Address** | `models/address.dart` | ที่อยู่ |
| **Category** | `models/category.dart` | หมวดหมู่ |
| **Review** | `models/review.dart` | รีวิว |
| **Coupon** | `models/coupon.dart` | คูปอง |

---

## 🎨 Theme & Styling

### สี

```dart
// ไฟล์: /lib/theme/app_colors.dart
class AppColors {
  static const primary = Color(0xFF2E7D32);
  static const secondary = Color(0xFF66BB6A);
  // ...
}
```

### ใช้งาน Theme

```dart
// ใน Widget
Theme.of(context).primaryColor
Theme.of(context).textTheme.headline1

// หรือ
context.theme.primaryColor
```

---

## 📱 Screens หลักๆ

### Auth
- `screens/auth/login_screen.dart` - เข้าสู่ระบบ
- `screens/auth/register_screen.dart` - สมัครสมาชิก

### Shop
- `screens/home_screen.dart` - หน้าแรก
- `screens/search_screen.dart` - ค้นหา
- `screens/category_screen.dart` - หมวดหมู่
- `screens/product_detail_screen.dart` - รายละเอียดสินค้า
- `screens/flash_sale_screen.dart` - Flash Sale

### Cart & Order
- `screens/cart_screen.dart` - ตะกร้า
- `screens/checkout_screen.dart` - ชำระเงิน
- `screens/payment_screen.dart` - ชำระเงิน
- `screens/orders_screen.dart` - คำสั่งซื้อ

### User
- `screens/profile_screen.dart` - โปรไฟล์
- `screens/edit_profile_screen.dart` - แก้ไขโปรไฟล์
- `screens/shipping_address_screen.dart` - ที่อยู่
- `screens/wishlist_screen.dart` - รายการโปรด

### Eco System
- `screens/eco_coins_screen.dart` - Eco Coins
- `screens/investment_hub_screen.dart` - ลงทุน
- `screens/sustainable_activities_hub_screen.dart` - กิจกรรม

### Seller
- `screens/seller/seller_dashboard_screen.dart` - Dashboard ผู้ขาย
- `screens/seller/add_product_screen.dart` - เพิ่มสินค้า
- `screens/seller/edit_product_screen.dart` - แก้ไขสินค้า
- `screens/seller/world_class_seller_dashboard.dart` - Dashboard ขั้นสูง

### Admin
- `screens/admin/admin_panel_screen.dart` - Admin Panel
- `screens/admin/admin_users_screen.dart` - จัดการผู้ใช้
- `screens/admin/admin_products_screen.dart` - จัดการสินค้า

---

## 🔥 Firebase Collections

| Collection | เก็บข้อมูล | ใช้โดย |
|-----------|-----------|---------|
| `users` | ข้อมูลผู้ใช้ | UserProvider, AuthService |
| `products` | สินค้า | ProductService |
| `orders` | คำสั่งซื้อ | OrderService |
| `categories` | หมวดหมู่ | CategoryService |
| `sellers` | ผู้ขาย | SellerService |
| `reviews` | รีวิว | ReviewService |
| `coupons` | คูปอง | CouponProvider |
| `promotions` | โปรโมชั่น | PromotionService |
| `flashSales` | Flash Sale | FlashSaleService |
| `ecoCoins` | Eco Coins | EcoCoinsService |
| `investments` | การลงทุน | InvestmentService |
| `activities` | กิจกรรม | ActivityService |
| `stories` | Stories | StoryService |
| `chats` | แชท | ChatService |
| `notifications` | การแจ้งเตือน | NotificationService |

---

## 🛠️ Utilities

| Utility | ไฟล์ | ใช้สำหรับ |
|---------|------|-----------|
| **Constants** | `utils/constants.dart` | ค่าคงที่ต่างๆ |
| **Validators** | `utils/validators.dart` | ตรวจสอบ input |
| **Formatters** | `utils/formatters.dart` | จัดรูปแบบข้อมูล |
| **Helpers** | `utils/helpers.dart` | ฟังก์ชันช่วยเหลือ |

---

## 🧩 Widgets ที่ใช้บ่อย

| Widget | ไฟล์ | ใช้สำหรับ |
|--------|------|-----------|
| **ProductCard** | `widgets/product_card.dart` | การ์ดสินค้า |
| **CustomButton** | `widgets/custom_button.dart` | ปุ่มกด |
| **LoadingWidget** | `widgets/loading_widget.dart` | แสดง loading |
| **EmptyState** | `widgets/empty_state.dart` | หน้าว่าง |
| **CustomBottomNav** | `widgets/custom_bottom_nav.dart` | Bottom Navigation |

---

## 🐛 Debug & Troubleshooting

### เช็คไฟล์ไหนเมื่อ...

| ปัญหา | ตรวจสอบไฟล์ |
|-------|-------------|
| **Login ไม่ได้** | `services/auth_service.dart`, `providers/auth_provider.dart` |
| **สินค้าไม่แสดง** | `services/product_service.dart`, `screens/home_screen.dart` |
| **ตะกร้าไม่อัพเดท** | `providers/cart_provider_enhanced.dart` |
| **ชำระเงินไม่ได้** | `services/payment_service.dart`, `screens/payment_screen.dart` |
| **Notification ไม่มา** | `services/notification_service.dart` |
| **Firebase Error** | `services/firebase_service.dart`, `firebase_options.dart` |
| **Theme ไม่เปลี่ยน** | `providers/theme_provider.dart`, `theme/app_theme.dart` |
| **Eco Coins ไม่อัพเดท** | `services/eco_coins_service.dart`, `providers/eco_coins_provider.dart` |

### คำสั่งที่ใช้บ่อย

```bash
# Run app
flutter run

# Run tests
flutter test

# Check code quality
dart analyze

# Format code
dart format lib/

# Clean build
flutter clean

# Get dependencies
flutter pub get

# Update dependencies
flutter pub upgrade
```

---

## 📝 Naming Conventions

### ไฟล์
- `snake_case.dart` - ชื่อไฟล์ใช้ snake_case
- `screens/` - หน้าจอต่างๆ ลงท้าย `_screen.dart`
- `widgets/` - Widgets ลงท้าย `_widget.dart` (optional)
- `providers/` - Providers ลงท้าย `_provider.dart`
- `services/` - Services ลงท้าย `_service.dart`
- `models/` - Models ใช้ชื่อตาม entity

### Classes
- `PascalCase` - Class names
- `camelCase` - Variables, functions
- `_privateVariable` - Private members
- `SCREAMING_SNAKE_CASE` - Constants

---

## 📚 เอกสารเพิ่มเติม

- [ARCHITECTURE.md](ARCHITECTURE.md) - สถาปัตยกรรมโครงสร้างแบบละเอียด
- [DEVELOPER_GUIDE_TH.md](docs/DEVELOPER_GUIDE_TH.md) - คู่มือ Developer
- [MAINTENANCE_GUIDE.md](docs/MAINTENANCE_GUIDE.md) - คู่มือการดูแลระบบ

---

## 💡 Tips

### Performance
- ใช้ `const` constructor เมื่อเป็นไปได้
- ใช้ `ListView.builder` แทน `ListView` สำหรับ list ยาวๆ
- Cache images ด้วย `CachedNetworkImage`
- ใช้ `select` ใน Provider เพื่อลด rebuild

### Best Practices
- ใช้ Provider สำหรับ State Management
- แยก Business Logic ไว้ใน Services
- ใช้ Models สำหรับ data structure
- เขียน Tests สำหรับ critical features
- ใช้ const widgets เมื่อทำได้

---

**อัพเดทล่าสุด:** 4 ธันวาคม 2025
