# Green Market - Backup และการบำรุงรักษา

## 📂 ไฟล์สำคัญที่ควร Backup

### 1. ไฟล์ Configuration หลัก
```
├── pubspec.yaml                    # Dependencies
├── firebase.json                   # Firebase config
├── firestore.rules                 # Database rules
├── storage.rules                   # Storage rules
├── lib/firebase_options.dart       # Firebase options
└── android/app/google-services.json # Android config
```

### 2. ไฟล์ Source Code หลัก
```
lib/
├── main.dart                       # Entry point
├── main_app_shell.dart            # App navigation
├── models/                        # Data models
├── providers/                     # State management
├── services/                      # Backend services
├── screens/                       # UI screens
└── widgets/                       # Reusable components
```

### 3. Assets และ Resources
```
assets/
├── logo.jpg                       # App logo
└── fonts/                         # Custom fonts
```

## 🔄 คำสั่งที่สำคัญ

### Development Commands
```bash
# เริ่มต้นโปรเจค
flutter pub get
flutter clean
flutter run -d chrome

# ตรวจสอบปัญหา
flutter doctor -v
flutter pub deps

# Build สำหรับ production
flutter build web
flutter build apk
flutter build ios
flutter build windows
```

### Firebase Commands (ถ้าใช้ Firebase CLI)
```bash
# Login
firebase login

# Deploy rules
firebase deploy --only firestore:rules
firebase deploy --only storage

# Deploy cloud functions (ถ้ามี)
firebase deploy --only functions
```

## 🐛 การแก้ปัญหาที่พบบ่อย

### 1. ปัญหา Hot Reload ไม่ทำงาน
```bash
# วิธีแก้
flutter clean
flutter pub get
flutter run
```

### 2. ปัญหา Firebase Connection
- ตรวจสอบ internet connection
- ตรวจสอบ Firebase configuration
- ตรวจสอบ Firestore rules

### 3. ปัญหา Build ใน Platform ต่างๆ

#### Windows
```bash
# ต้องมี Visual Studio
flutter doctor -v
# ติดตั้ง Visual Studio with C++ workload
```

#### Web
```bash
# ตรวจสอบ web support
flutter config --enable-web
flutter devices
```

#### Android
```bash
# ตรวจสอบ Android SDK
flutter doctor --android-licenses
```

### 4. ปัญหา Dependencies
```bash
# อัปเดต dependencies
flutter pub upgrade
flutter pub get

# แก้ไข conflicts
flutter pub deps
```

## 📋 Checklist ก่อน Deploy

### Development
- [ ] `flutter doctor` ไม่มี error
- [ ] ทุก screen ทำงานปกติ
- [ ] ไม่มี console errors
- [ ] Hot reload ทำงาน
- [ ] Data loading จาก Firebase

### Testing
- [ ] ทดสอบ login/logout
- [ ] ทดสอบ CRUD operations
- [ ] ทดสอบ notifications
- [ ] ทดสอบบน multiple devices
- [ ] ทดสอบ offline/online modes

### Security
- [ ] Firestore rules ถูกต้อง
- [ ] API keys ปลอดภัย
- [ ] User permissions ถูกต้อง
- [ ] Input validation ครบถ้วน

### Performance
- [ ] Image optimization
- [ ] Lazy loading
- [ ] Caching strategies
- [ ] Bundle size reasonable

## 🔐 Environment Variables

### Development
```
FLUTTER_ENV=development
FIREBASE_PROJECT_ID=your-dev-project
```

### Production
```
FLUTTER_ENV=production
FIREBASE_PROJECT_ID=your-prod-project
```

## 📊 Monitoring และ Analytics

### Firebase Console
- **Authentication**: ติดตาม user signups
- **Firestore**: ติดตามการใช้ database
- **Storage**: ติดตามการใช้ storage
- **Analytics**: ติดตาม user behavior

### Performance Monitoring
- App loading times
- Screen transition times
- Firebase query performance
- Error rates

## 🔄 Update และ Maintenance

### Weekly Tasks
- [ ] ตรวจสอบ Firebase usage
- [ ] Review error logs
- [ ] ตรวจสอบ app performance
- [ ] Update dependencies (ถ้าจำเป็น)

### Monthly Tasks
- [ ] Backup database
- [ ] Review security rules
- [ ] Update Firebase SDK
- [ ] Performance optimization

### Quarterly Tasks
- [ ] Major dependency updates
- [ ] Security audit
- [ ] Feature planning
- [ ] Architecture review

## 📞 Contact และ Support

### Technical Issues
- Flutter documentation: https://docs.flutter.dev
- Firebase documentation: https://firebase.google.com/docs
- Stack Overflow: flutter + firebase tags

### Emergency Contacts
- Firebase Support: console.firebase.google.com
- Flutter Team: github.com/flutter/flutter/issues

---

**Last Updated**: 3 กรกฎาคม 2025  
**Version**: 1.0.0  
**Maintainer**: Development Team
