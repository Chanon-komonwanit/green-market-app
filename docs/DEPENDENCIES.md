# 📦 Green Market - Dependencies Guide

## 🎯 Overview
นี่คือคู่มือการจัดการ dependencies สำหรับแอป Green Market - แอปพลิเคชันตลาดออนไลน์เพื่อสิ่งแวดล้อม

## 📋 Current Dependencies Status

### 🔥 Firebase Services
- **firebase_core**: `^2.32.0` - Core Firebase functionality
- **firebase_auth**: `^4.16.0` - User authentication  
- **cloud_firestore**: `^4.17.5` - NoSQL database
- **firebase_storage**: `^11.6.5` - File storage
- **firebase_messaging**: `^14.7.10` - Push notifications

### 🎨 UI & User Experience
- **provider**: `^6.1.2` - State management
- **cached_network_image**: `^3.4.1` - Image caching
- **shimmer**: `^3.0.0` - Loading animations
- **fl_chart**: `^1.0.0` - Charts and graphs
- **carousel_slider**: `^5.0.0` - Image carousels

### 📱 Platform Integration
- **connectivity_plus**: `^6.0.5` - Network monitoring
- **device_info_plus**: `^10.1.2` - Device information
- **shared_preferences**: `^2.2.2` - Local storage
- **url_launcher**: `^6.3.0` - External app launching

## 🔧 Maintenance Schedule

### 📅 Weekly Tasks
```bash
# ตรวจสอบ dependencies ที่ล้าสมัย
flutter pub outdated

# ตรวจสอบความปลอดภัย
dart run scripts/manage_dependencies.dart audit
```

### 📅 Monthly Tasks
```bash
# อัพเดต dependencies ที่ปลอดภัย
dart run scripts/manage_dependencies.dart update

# ทำความสะอาดโปรเจค
dart run scripts/manage_dependencies.dart clean
```

### 📅 Quarterly Tasks
- Review และอัพเดต major versions
- ตรวจสอบ changelog ของ packages สำคัญ
- ทดสอบการทำงานใน platforms ทั้งหมด

## ⚡ Quick Commands

### 🚀 Setup Project
```bash
flutter clean
flutter pub get
```

### 🔍 Check Dependencies
```bash
flutter pub deps
flutter pub outdated
```

### 🛠️ Fix Common Issues
```bash
# ล้าง cache หาก dependencies ขัดแย้ง
flutter clean
flutter pub cache clean
flutter pub get

# ตรวจสอบและแก้ไข version conflicts
flutter pub deps
```

## 📊 Compatibility Matrix

| Package Category | Flutter 3.32+ | Dart 3.8+ | Web | Windows | Android | iOS |
|------------------|---------------|------------|-----|---------|---------|-----|
| Firebase         | ✅            | ✅         | ✅  | ⚠️      | ✅      | ✅  |
| UI Components    | ✅            | ✅         | ✅  | ✅      | ✅      | ✅  |
| Platform APIs    | ✅            | ✅         | ⚠️  | ✅      | ✅      | ✅  |

**Legend:**
- ✅ Full support
- ⚠️ Partial support
- ❌ Not supported

## 🚨 Security Considerations

### 🔒 Regular Security Checks
1. **Monthly vulnerability scan**
   ```bash
   dart run scripts/manage_dependencies.dart audit
   ```

2. **Deprecated packages monitoring**
   - flutter_markdown (discontinued) - Monitor for alternatives
   - js package (discontinued) - Firebase web dependencies

3. **Version pinning strategy**
   - Pin critical packages (Firebase) to tested versions
   - Allow minor updates for UI packages
   - Review major updates carefully

### 🛡️ Best Practices
- Always backup before major updates
- Test all platforms after updates
- Monitor Firebase console for breaking changes
- Keep local environment up to date

## 🔄 Update Workflow

### 1. Preparation
```bash
git checkout -b dependencies-update
git add .
git commit -m "Before dependencies update"
```

### 2. Update Process
```bash
dart run scripts/manage_dependencies.dart check
dart run scripts/manage_dependencies.dart update
```

### 3. Testing
```bash
flutter test
flutter run --debug
flutter run --release
```

### 4. Platform Testing
- Test on actual devices
- Verify Firebase connections
- Check all major user flows

### 5. Documentation
- Update this README
- Document any breaking changes
- Update CHANGELOG.md

## 🐛 Common Issues & Solutions

### Firebase Web Issues
**Problem**: Firebase packages don't work on web
**Solution**: Use compatible versions, check Firebase web configuration

### Windows Build Issues
**Problem**: Some packages don't support Windows
**Solution**: Check platform support matrix, use alternatives

### Version Conflicts
**Problem**: Dependencies have conflicting requirements
**Solution**: Use dependency_overrides or downgrade versions

### Performance Issues
**Problem**: App startup is slow
**Solution**: Implement lazy loading, optimize Firebase initialization

## 📞 Support & Resources

- **Flutter Docs**: https://flutter.dev/docs
- **Firebase Docs**: https://firebase.google.com/docs
- **Package Repository**: https://pub.dev
- **Issue Tracking**: Use GitHub issues for dependency-related problems

---

**Last Updated**: August 2025  
**Maintainer**: Green Market Development Team  
**Flutter Version**: 3.32.4  
**Dart Version**: 3.8.1
