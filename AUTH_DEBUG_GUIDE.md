# คู่มือแก้ไขปัญหาการเข้าสู่ระบบ Green Market

## ปัญหาการเด้งออกหลังเข้าสู่ระบบ - สาเหตุและวิธีแก้ไข

### 🔍 สาเหตุหลักที่พบ:

1. **Firebase Authentication Session หมดอายุ**
2. **ข้อมูลผู้ใช้ใน Firestore ไม่สมบูรณ์**
3. **Network connection ขาดหาย**
4. **Firebase rules ไม่อนุญาต**
5. **Memory leak ใน auth listeners**

---

## 🚨 การวินิจฉัยปัญหา

### ขั้นตอนที่ 1: ตรวจสอบ Firebase Console
```bash
# 1. เปิด Firebase Console
# 2. ไปที่ Authentication > Users
# 3. ตรวจสอบว่ามี user record หรือไม่
# 4. ตรวจสอบ lastSignInTime
```

### ขั้นตอนที่ 2: ตรวจสอบ Firestore
```bash
# 1. ไปที่ Firestore Database
# 2. ตรวจสอบ collection 'users'
# 3. ตรวจสอบว่ามี document ของ user หรือไม่
# 4. ตรวจสอบ fields: isAdmin, isSeller, isActive
```

### ขั้นตอนที่ 3: ตรวจสอบ Debug Output
```bash
# ดู debug messages ใน console:
flutter run --debug
# หา messages:
# - "Main.dart - Auth user: xxx"
# - "Main.dart - User loading: xxx"
# - "Failed to load user data"
```

---

## ⚡ วิธีแก้ไขทันที

### แก้ไขที่ 1: เพิ่ม Session Persistence
```dart
// ใน firebase_service.dart
Future<void> setPersistence() async {
  await _auth.setPersistence(Persistence.LOCAL);
}
```

### แก้ไขที่ 2: ปรับปรุง Error Handling
```dart
// ใน user_provider.dart - method loadUserData
Future<void> loadUserData(String uid) async {
  _isLoading = true;
  notifyListeners();
  
  int retryCount = 0;
  const maxRetries = 3;
  
  while (retryCount < maxRetries) {
    try {
      _currentUser = await _firebaseService.getAppUser(uid);
      if (_currentUser != null) {
        break; // สำเร็จ, ออกจาก loop
      }
    } catch (e) {
      retryCount++;
      _firebaseService.logger.e('Load user data attempt $retryCount failed', error: e);
      
      if (retryCount < maxRetries) {
        await Future.delayed(Duration(seconds: retryCount * 2)); // Exponential backoff
      } else {
        _currentUser = null; // ล้มเหลวหลังจากครบ retry
      }
    }
  }
  
  _isLoading = false;
  notifyListeners();
}
```

### แก้ไขที่ 3: เพิ่ม Connection Check
```dart
// สร้างไฟล์ lib/utils/connectivity_checker.dart
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityChecker {
  static Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }
}
```

---

## 🔧 การแก้ไขถาวร

### 1. ปรับปรุง main.dart
```dart
// เพิ่มการตรวจสอบ network
home: Consumer2<AuthProvider, UserProvider>(
  builder: (context, auth, user, _) {
    // เพิ่มการตรวจสอบ connection
    if (!auth.isInitializing && auth.user != null && user.currentUser == null) {
      // ตรวจสอบ network และ retry loading user data
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _retryLoadUserData(context, user, auth.user!.uid);
      });
    }
    
    // ส่วนที่เหลือเหมือนเดิม...
  },
)

void _retryLoadUserData(BuildContext context, UserProvider userProvider, String uid) async {
  if (await ConnectivityChecker.hasInternetConnection()) {
    await userProvider.loadUserData(uid);
  } else {
    // แสดง error message หรือ retry dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ไม่มีการเชื่อมต่ออินเทอร์เน็ต กรุณาตรวจสอบ'),
        action: SnackBarAction(
          label: 'ลองใหม่',
          onPressed: () => userProvider.loadUserData(uid),
        ),
      ),
    );
  }
}
```

### 2. เพิ่ม Auth State Persistence
```dart
// ใน firebase_service.dart
Future<void> initializeAuth() async {
  try {
    await _auth.setPersistence(Persistence.LOCAL);
    logger.i("Auth persistence set to LOCAL");
  } catch (e) {
    logger.e("Failed to set auth persistence: $e");
  }
}
```

### 3. ปรับปรุง User Provider
```dart
// เพิ่มใน user_provider.dart
Timer? _retryTimer;

void _listenToAuthChanges() {
  _authSubscription?.cancel();
  _authSubscription = _firebaseService.authStateChanges.listen((firebaseUser) {
    _retryTimer?.cancel(); // ยกเลิก timer เก่า
    
    if (firebaseUser != null) {
      loadUserData(firebaseUser.uid);
      
      // เพิ่ม retry mechanism
      _retryTimer = Timer.periodic(Duration(seconds: 30), (timer) {
        if (_currentUser == null && firebaseUser.uid.isNotEmpty) {
          logger.w("Retrying to load user data for ${firebaseUser.uid}");
          loadUserData(firebaseUser.uid);
        } else {
          timer.cancel();
        }
      });
    } else {
      clearUserData();
      _retryTimer?.cancel();
    }
  });
}

@override
void dispose() {
  _retryTimer?.cancel();
  _authSubscription?.cancel();
  super.dispose();
}
```

---

## 📋 Checklist การแก้ไข

### ✅ ขั้นตอนที่ควรทำทันที:
- [ ] ตรวจสอบ Firebase Console (Auth + Firestore)
- [ ] ตรวจสอบ internet connection
- [ ] เพิ่ม error handling ใน loadUserData
- [ ] เพิ่ม retry mechanism
- [ ] ตรวจสอบ Firebase rules

### ✅ ขั้นตอนแก้ไขระยะยาว:
- [ ] เพิ่ม connectivity checking
- [ ] ปรับปรุง session management
- [ ] เพิ่ม offline support
- [ ] เพิ่ม user experience (loading states)
- [ ] เพิ่ม analytics สำหรับ track ปัญหา

---

## 🔍 การ Debug เพิ่มเติม

### เพิ่ม Debug Logging:
```dart
// ใน user_provider.dart
Future<void> loadUserData(String uid) async {
  logger.i("🔄 Starting to load user data for: $uid");
  _isLoading = true;
  notifyListeners();
  
  try {
    logger.i("📡 Calling Firebase to get user: $uid");
    _currentUser = await _firebaseService.getAppUser(uid);
    
    if (_currentUser != null) {
      logger.i("✅ User data loaded successfully: ${_currentUser!.email}");
      logger.i("👤 User role - Admin: ${_currentUser!.isAdmin}, Seller: ${_currentUser!.isSeller}");
    } else {
      logger.w("⚠️ User data is null for UID: $uid");
    }
  } catch (e) {
    logger.e("❌ Failed to load user data for $uid", error: e);
    _currentUser = null;
  } finally {
    _isLoading = false;
    logger.i("🏁 Finished loading user data. Loading: $_isLoading");
    notifyListeners();
  }
}
```

---

## 📞 หากยังไม่ได้ผล

1. **ลบและติดตั้งแอพใหม่**
2. **ตรวจสอบ Firebase Project Settings**
3. **ตรวจสอบ API Keys**
4. **ตรวจสอบ Firebase Rules**

### Firebase Rules ที่แนะนำ:
```javascript
// ใน Firestore Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null && 
                  exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
                  get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
  }
}
```

---

**สร้างโดย:** คู่มือแก้ไขปัญหา Green Market  
**วันที่:** จัดทำเพื่อแก้ไขปัญหาการเข้าสู่ระบบ  
**เวอร์ชั่น:** 1.0
