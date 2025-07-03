# 🔐 SECURITY SETUP GUIDE - ระบบความปลอดภัย Green Market

## ⚠️ แก้ไขปัญหา API Key Leak ด่วน!

### 🚨 ปัญหาที่เกิดขึ้น
- ไฟล์ `firebase_options.dart` ที่มี API Keys ถูก commit ลง Git repository
- Google Cloud Console เตือนเรื่อง KPI/ความปลอดภัย
- ข้อมูล sensitive อาจรั่วไหลออกไปภายนอก

### ✅ การแก้ไขที่ทำแล้ว
1. เพิ่ม `firebase_options.dart` ใน `.gitignore` ✅
2. ลบไฟล์ออกจาก Git tracking: `git rm --cached lib/firebase_options.dart` ✅
3. สร้าง Template ไฟล์: `firebase_options_template.dart` ✅
4. เพิ่ม `android/app/google-services.json` ใน `.gitignore` ✅
5. ลบ `google-services.json` ออกจาก Git tracking ✅

### 🔍 สถานะการป้องกันปัจจุบัน
- `lib/firebase_options.dart` - ✅ ถูก ignore แล้ว (`.gitignore:2`)
- `android/app/google-services.json` - ✅ ถูก ignore แล้ว 
- `ios/Runner/GoogleService-Info.plist` - ✅ ถูก ignore แล้ว
- Template file สำหรับ setup - ✅ มีแล้ว

## 🔧 ขั้นตอนการ Setup ระบบความปลอดภัย

### 1. **Setup Firebase Options (ทำทันที)**
```bash
# คัดลอก template เป็นไฟล์จริง
cp lib/firebase_options_template.dart lib/firebase_options.dart

# แก้ไขไฟล์ firebase_options.dart
# แทนที่ YOUR_XXX_HERE ด้วยค่าจริงจาก Firebase Console
```

### 2. **หมุน API Keys ใน Firebase Console (สำคัญ!)**
1. เข้า [Firebase Console](https://console.firebase.google.com/)
2. เลือกโปรเจกต์ `green-market-32046`
3. ไป Project Settings > General > Your apps
4. สำหรับแต่ละ platform (Web, Android, iOS):
   - คลิก "Regenerate" API Key
   - อัปเดตค่าใหม่ใน `firebase_options.dart`

### 3. **ตั้งค่า Firestore Security Rules**
```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User data protection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Eco Rewards - only authenticated users can read
    match /eco_rewards/{rewardId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
    
    // Reward Redemptions
    match /reward_redemptions/{redemptionId} {
      allow read, create: if request.auth != null && resource.data.userId == request.auth.uid;
      allow update: if request.auth != null && (
        resource.data.userId == request.auth.uid ||
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true
      );
    }
    
    // Admin only collections
    match /admin_logs/{logId} {
      allow read, write: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
  }
}
```

### 4. **Deploy Security Rules**
```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules  
firebase deploy --only storage
```

### 5. **Environment Variables Setup**
```bash
# สร้างไฟล์ .env (สำหรับ local development)
echo "FIREBASE_PROJECT_ID=green-market-32046" > .env
echo "FIREBASE_API_KEY=your_new_api_key_here" >> .env
```

## 🛡️ ระบบความปลอดภัย Eco Coins ที่มีอยู่

### Server-Side Security (8 ชั้นความปลอดภัย)
1. **Authentication Check** - ตรวจสอบ user login
2. **User Document Validation** - ตรวจสอบข้อมูล user ใน Firestore
3. **Time Validation** - ตรวจสอบเวลาล็อกอินล่าสุด
4. **Consecutive Days Logic** - ตรวจสอบจำนวนวันติดต่อกัน
5. **Anti-Cheat Protection** - ป้องกันการโกง
6. **Rate Limiting** - จำกัดการเรียกใช้
7. **Audit Logging** - บันทึก log การกระทำ
8. **Transaction Safety** - ความปลอดภัยของ transaction

### Client-Side Protection
- Input validation
- UI state management  
- Error handling
- User feedback

## ⚡ Actions ที่ต้องทำทันที

### 1. **หมุน API Keys (ลำดับความสำคัญสูงสุด)**
- [ ] Regenerate Web API Key
- [ ] Regenerate Android API Key  
- [ ] Regenerate iOS API Key
- [ ] อัปเดตค่าใหม่ใน `firebase_options.dart`

### 2. **ตรวจสอบ Google Cloud Console**
- [ ] ตรวจสอบ KPI warnings
- [ ] ตั้งค่า billing alerts
- [ ] เปิดใช้ Security Command Center (ถ้ามี)

### 3. **Monitor & Audit**
- [ ] ตั้งค่า Cloud Logging
- [ ] ตรวจสอบ unusual API usage
- [ ] Monitor authentication logs

### 4. **Team Security**
- [ ] แจ้งทีมเรื่องไม่ commit sensitive files
- [ ] Setup pre-commit hooks
- [ ] Code review process

## 🔍 การตรวจสอบและ Monitor

### Daily Checks
```bash
# ตรวจสอบ API usage
firebase functions:log

# ตรวจสอบ authentication logs  
firebase auth:export users.json

# ตรวจสอบ Firestore usage
firebase firestore:usage
```

### Weekly Reviews  
- ตรวจสอบ unusual patterns ใน logs
- Review API key usage
- Update security rules ตามความต้องการ

## 📞 Emergency Response

หากพบการละเมิดความปลอดภัย:

1. **หมุน API Keys ทันที**
2. **เปลี่ยน Firebase project ถ้าจำเป็น**  
3. **แจ้ง Google Cloud Support**
4. **Reset user passwords ที่เกี่ยวข้อง**
5. **บันทึก incident report**

## 📚 Resources

- [Firebase Security Best Practices](https://firebase.google.com/docs/projects/api-keys)
- [Flutter Security Guide](https://docs.flutter.dev/deployment/security)
- [Google Cloud Security](https://cloud.google.com/security)

---

**⚠️ หมายเหตุสำคัญ:**
ไฟล์นี้มีข้อมูลสำคัญ กรุณาอย่า commit ลง public repository!
