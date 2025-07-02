# Green Market - Eco-friendly Marketplace

Green Market เป็นแอปพลิเคชัน E-commerce ที่เน้นการซื้อขายสินค้าที่เป็นมิตรต่อสิ่งแวดล้อม พัฒนาด้วย Flutter และ Firebase

## 🌟 จุดมุ่งหมายหลัก
ตลาดกลางสำหรับซื้อขายสินค้าที่เป็นมิตรต่อสิ่งแวดล้อม (คล้าย Shopee แต่เน้น Eco-friendly)

## 👥 บทบาทผู้ใช้
- **Buyer (ผู้ซื้อ)**: ซื้อสินค้า เข้าร่วมกิจกรรม ลงทุน
- **Seller (ผู้ขาย)**: ขายสินค้า จัดการร้านค้า
- **Admin (แอดมิน)**: ควบคุมระบบ อนุมัติสินค้า/ผู้ขาย/โครงการ

## 🎯 ฟีเจอร์หลัก

### 1. E-commerce Core (จุดหมายหลัก)
- ระบบซื้อขาย พร้อม Eco Score (1-100)
- หมวดหมู่สินค้า
- ตะกร้าสินค้า และการสั่งซื้อ
- รีวิวและเรตติ้ง

### 2. Green World Hub (โซนเสริม)
- **Sustainable Activities**: กิจกรรมเพื่อสิ่งแวดล้อม
- **Investment Hub**: โครงการลงทุนยั่งยืน
- **News & Articles**: ข่าวสารด้านสิ่งแวดล้อม

### 3. Admin Panel
- อนุมัติสินค้า/ผู้ขาย/โครงการ
- จัดการ Eco Score
- ควบคุมระบบทั้งหมด

## 🏗️ โครงสร้างโปรเจกต์

### Models หลัก
- `AppUser`: ข้อมูลผู้ใช้และบทบาท
- `Product`: สินค้าพร้อม Eco Score
- `Order`: คำสั่งซื้อ
- `SustainableActivity`: กิจกรรมเพื่อสิ่งแวดล้อม
- `InvestmentProject`: โครงการลงทุน
- `Seller`: ข้อมูลร้านค้า

### Services
- `FirebaseService`: จัดการ Firebase ทั้งหมด
- `AuthService`: การยืนยันตัวตน
- `NotificationService`: การแจ้งเตือน

### Providers (State Management)
- `AuthProvider`: สถานะการล็อกอิน
- `UserProvider`: ข้อมูลผู้ใช้
- `CartProvider`: ตะกร้าสินค้า
- `ThemeProvider`: ธีมแอป

### Screens
- **Buyer**: Home, Cart, Product Detail, Orders
- **Seller**: Dashboard, Add/Edit Products, Shop Management
- **Admin**: Dashboard, Approvals, User Management
- **Shared**: Chat, Profile, Activities, Investment

## 🐛 สถานะปัจจุบัน - หลังการตรวจสอบ July 2, 2025
✅ **พร้อมใช้งาน**: 
- E-commerce Core (ซื้อขาย, Eco Score, รีวิว)
- Green World Hub (Activities, Investment) 
- Admin Panel (ควบคุมระบบ)
- Notification System (สมบูรณ์)
- Chat System (พื้นฐาน)

⚠️ **ปัญหาที่แก้ไขแล้ว**:
1. ✅ Routes และ Navigation - แก้ไขแล้ว
2. ✅ Firebase Security Rules - กำหนดค่าเรียบร้อย
3. ✅ State management - ทำงานปกติ
4. ✅ Error handling - เสริมแล้ว

🚧 **กำลังพัฒนา**:
- Advanced Chat Features
- Analytics Dashboard
- Multi-language Support

## 📱 การรัน
```bash
flutter pub get
flutter run
```
