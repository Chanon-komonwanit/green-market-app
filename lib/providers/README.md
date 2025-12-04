# 📁 Providers - State Management Layer

โฟลเดอร์นี้เก็บ **Providers** ที่จัดการ State ของแอปด้วย Provider Pattern

---

## 🔄 Providers ทั้งหมด

### 🔐 `auth_provider.dart`
**คะแนนความสำคัญ: 🌟🌟🌟🌟🌟**

จัดการสถานะการเข้าสู่ระบบ

**หน้าที่:**
- Login/Logout/Register
- Check authentication state
- User session management
- Multiple login methods (Email, Google, Facebook, Phone)
- Network connectivity monitoring

**State:**
- `user` - ข้อมูลผู้ใช้ปัจจุบัน
- `authState` - สถานะ auth (authenticated/unauthenticated)
- `isLoading` - กำลังโหลดหรือไม่
- `errorMessage` - ข้อความ error

**ใช้งานที่:** ทุกหน้าที่ต้องตรวจสอบการเข้าสู่ระบบ

**วิธีใช้:**
```dart
// อ่านค่า
final auth = context.read<AuthProvider>();

// Login
await auth.signInWithEmailAndPassword(email, password);

// Check status
if (auth.isAuthenticated) {
  // User is logged in
}

// Logout
await auth.signOut();
```

---

### 🛒 `cart_provider_enhanced.dart`
**คะแนนความสำคัญ: 🌟🌟🌟🌟🌟**

จัดการตะกร้าสินค้า

**หน้าที่:**
- Add/Remove items
- Update quantities
- Calculate totals (product + shipping + discount)
- Apply coupons
- Validate stock

**State:**
- `items` - รายการสินค้าในตะกร้า
- `itemCount` - จำนวนชนิดสินค้า
- `totalItemsInCart` - จำนวนสินค้าทั้งหมด (รวม quantity)
- `totalAmount` - ราคารวม
- `discount` - ส่วนลด
- `shippingFee` - ค่าจัดส่ง

**ใช้งานที่:**
- Product Detail Screen
- Cart Screen
- Checkout Screen

**วิธีใช้:**
```dart
final cart = context.watch<CartProvider>();

// เพิ่มสินค้า
cart.addToCart(product);

// ลบสินค้า
cart.removeFromCart(productId);

// อัพเดทจำนวน
cart.updateQuantity(productId, 5);

// Clear cart
cart.clearCart();
```

---

### 👤 `user_provider.dart`
**คะแนนความสำคัญ: 🌟🌟🌟🌟**

จัดการข้อมูลผู้ใช้

**หน้าที่:**
- Load user profile
- Update user data
- Manage addresses
- Manage favorite products
- Order history

**State:**
- `user` - ข้อมูลผู้ใช้
- `addresses` - รายการที่อยู่
- `favoriteProducts` - สินค้าที่ชอบ
- `orders` - คำสั่งซื้อ

**ใช้งานที่:**
- Profile Screen
- Edit Profile Screen
- Address Management
- Order History

**วิธีใช้:**
```dart
final user = context.watch<UserProvider>();

// โหลดข้อมูล
await user.loadUserData(userId);

// อัพเดทโปรไฟล์
await user.updateProfile(userData);

// เพิ่มที่อยู่
await user.addAddress(address);
```

---

### 🪙 `eco_coins_provider.dart`
**คะแนนความสำคัญ: 🌟🌟🌟🌟**

จัดการระบบ Eco Coins

**หน้าที่:**
- Get balance
- Track transactions
- Manage missions
- Redeem rewards
- Calculate eco coins from activities

**State:**
- `balance` - ยอด Eco Coins ปัจจุบัน
- `transactions` - ประวัติการทำธุรกรรม
- `missions` - ภารกิจที่มี
- `progress` - ความคืบหน้าภารกิจ

**ใช้งานที่:**
- Eco Coins Screen
- Mission Screen
- Redeem Screen
- Order completion

**วิธีใช้:**
```dart
final ecoCoins = context.watch<EcoCoinsProvider>();

// โหลดข้อมูล
await ecoCoins.initialize(userId);

// แลกรางวัล
await ecoCoins.redeemReward(rewardId, cost);

// ทำภารกิจ
await ecoCoins.completeMission(missionId);
```

---

### 🎨 `theme_provider.dart`
**คะแนนความสำคัญ: 🌟🌟🌟**

จัดการธีมของแอป

**หน้าที่:**
- Toggle Dark/Light mode
- Save theme preference
- Apply theme across app

**State:**
- `isDarkMode` - เป็น Dark mode หรือไม่
- `themeData` - ThemeData object

**ใช้งานที่:**
- Settings Screen
- ทุกหน้าที่ใช้ Theme

**วิธีใช้:**
```dart
final theme = context.watch<ThemeProvider>();

// สลับธีม
theme.toggleTheme();

// ตั้งค่าธีม
theme.setDarkMode(true);

// ใช้งาน
Theme.of(context).primaryColor
```

---

### 🎁 `coupon_provider.dart`
**คะแนนความสำคัญ: 🌟🌟🌟**

จัดการคูปองส่วนลด

**หน้าที่:**
- List available coupons
- Apply coupon
- Remove coupon
- Validate coupon
- Calculate discount

**State:**
- `availableCoupons` - คูปองที่ใช้ได้
- `appliedCoupon` - คูปองที่ใช้อยู่
- `discount` - ส่วนลดที่ได้รับ

**ใช้งานที่:**
- Cart Screen
- Checkout Screen
- Coupon List Screen

**วิธีใช้:**
```dart
final coupon = context.watch<CouponProvider>();

// โหลดคูปอง
await coupon.loadAvailableCoupons();

// ใช้คูปอง
await coupon.applyCoupon(couponCode);

// ลบคูปอง
coupon.removeCoupon();
```

---

### ⚙️ `app_config_provider.dart`
**คะแนนความสำคัญ: 🌟🌟🌟**

จัดการการตั้งค่าแอป

**หน้าที่:**
- App-wide configuration
- Feature flags
- Remote config
- App settings

**State:**
- `config` - การตั้งค่าแอป
- `features` - Features ที่เปิดใช้

**ใช้งานที่:** ทั่วทั้งแอป

---

## 🔄 วิธีการใช้งาน Providers

### 1. ใน main.dart (Setup)

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider(firebaseService)),
    ChangeNotifierProvider(create: (_) => CartProvider()),
    ChangeNotifierProvider(create: (_) => UserProvider(firebaseService)),
    // ...
  ],
  child: MyApp(),
)
```

### 2. ใน Widget (Read only - ไม่ rebuild)

```dart
final cart = context.read<CartProvider>();
cart.addToCart(product);
```

### 3. ใน Widget (Watch - rebuild เมื่อเปลี่ยน)

```dart
final cart = context.watch<CartProvider>();
Text('Items: ${cart.itemCount}');
```

### 4. ใช้ Consumer (แนะนำ)

```dart
Consumer<CartProvider>(
  builder: (context, cart, child) {
    return Text('Items: ${cart.itemCount}');
  }
)
```

### 5. ใช้ Selector (optimize rebuild)

```dart
Selector<CartProvider, int>(
  selector: (_, cart) => cart.itemCount,
  builder: (_, count, __) {
    return Text('Items: $count');
  }
)
```

---

## 🏗️ สถาปัตยกรรม

```
UI Layer (Screens/Widgets)
    ↓
Provider Layer (State Management) ← คุณอยู่ที่นี่
    ↓
Service Layer (Business Logic)
    ↓
Firebase (Backend)
```

---

## 📝 Best Practices

1. **ใช้ `notifyListeners()`**
   - เรียกหลังจากเปลี่ยน state
   - UI จะ rebuild อัตโนมัติ

2. **Dependency Injection**
   - Inject services ใน Provider constructor
   ```dart
   class MyProvider extends ChangeNotifier {
     final FirebaseService _service;
     MyProvider(this._service);
   }
   ```

3. **Loading State**
   - มี `isLoading` flag
   - แสดง loading indicator ในขณะโหลด

4. **Error Handling**
   - มี `errorMessage` variable
   - แสดง error ให้ user เห็น

5. **Clean Up**
   - Override `dispose()` เพื่อ cancel subscriptions
   ```dart
   @override
   void dispose() {
     _subscription?.cancel();
     super.dispose();
   }
   ```

---

## 🔄 Provider Lifecycle

```
1. Create Provider (ใน main.dart)
   ↓
2. Widget อ่านค่า (read/watch)
   ↓
3. User interaction
   ↓
4. Provider อัพเดท state
   ↓
5. notifyListeners() เรียก
   ↓
6. Widget rebuild อัตโนมัติ
```

---

## 🆘 Troubleshooting

| ปัญหา | แก้ไข |
|-------|-------|
| Widget ไม่ rebuild | ใช้ `watch` แทน `read` |
| Provider ไม่มี | ตรวจสอบ MultiProvider ใน main.dart |
| Error: Provider not found | ตรวจสอบ context และ provider tree |
| Memory leak | ตรวจสอบ dispose() และ cancel subscriptions |

---

## 📚 เอกสารเพิ่มเติม

- [Provider Package Documentation](https://pub.dev/packages/provider)
- [ARCHITECTURE.md](../../ARCHITECTURE.md)
- [QUICK_REFERENCE.md](../../QUICK_REFERENCE.md)

---

**หมายเหตุ:**
- Provider ใหม่ควรสร้างใน folder นี้
- ตั้งชื่อแบบ `xxx_provider.dart`
- ควร extend `ChangeNotifier`
- อย่าลืม `notifyListeners()` หลังเปลี่ยน state
