# 🔴 Live Streaming System Documentation
## Green Market - ระบบไลฟ์สตรีม มืออาชีพ

---

## 📋 สารบัญ
1. [ภาพรวมระบบ](#ภาพรวมระบบ)
2. [นโยบายการจัดเก็บข้อมูล](#นโยบายการจัดเก็บข้อมูล)
3. [เทคโนโลยีที่ใช้](#เทคโนโลยีที่ใช้)
4. [วิธีการใช้งาน](#วิธีการใช้งาน)
5. [การบำรุงรักษา](#การบำรุงรักษา)

---

## 🎯 ภาพรวมระบบ

### **คุณสมบัติหลัก:**
- ✅ **Real-time Streaming** - ถ่ายทอดสดคุณภาพ HD (720p)
- ✅ **Auto Recording** - บันทึกอัตโนมัติขณะไลฟ์
- ✅ **Comments & Reactions** - แสดงความคิดเห็นและกดไลค์แบบ real-time
- ✅ **Viewer Counter** - นับจำนวนผู้ชมแบบ real-time
- ✅ **Auto Compression** - บีบอัดวิดีโอเป็น SD หลังจบไลฟ์
- ✅ **Auto Deletion** - ลบอัตโนมัติตามระยะเวลาที่กำหนด
- ✅ **Scheduled Streams** - กำหนดเวลาไลฟ์ล่วงหน้า

---

## 📦 นโยบายการจัดเก็บข้อมูล

### **เปรียบเทียบกับแพลตฟอร์มใหญ่:**

| Platform | During Live | After Live | Auto-Delete | Archive |
|----------|-------------|------------|-------------|---------|
| **Facebook** | Full HD (1080p) | Save to profile | 60 days | ✅ Optional |
| **Instagram** | HD (720p) | Save to IGTV | 30 days | ✅ Optional |
| **TikTok** | HD (720p) | Auto-save | 30 days | ❌ No |
| **YouTube** | Full HD+ | Forever | Never | ✅ Forever |
| **Twitter/X** | HD (720p) | 30 days | 30 days | ❌ No |
| **Green Market** 🟢 | **HD (720p)** | **7 days (SD)** | **7 days** | **✅ Optional** |

---

### **นโยบาย Green Market (ประหยัดพื้นที่):**

#### **1. ขณะไลฟ์ (During Live)**
- **คุณภาพ**: HD (720p, 30fps)
- **Bitrate**: 2-3 Mbps
- **บันทึก**: ✅ อัตโนมัติ (ถ้าเปิด recording)
- **พื้นที่**: ~900 MB/ชั่วโมง

#### **2. หลังจบไลฟ์ (After Live)**
- **คุณภาพ**: SD (480p, 30fps) - บีบอัดอัตโนมัติ
- **Bitrate**: 1 Mbps
- **พื้นที่**: ~450 MB/ชั่วโมง (ประหยัด 50%)
- **เก็บไว้**: 7 วัน

#### **3. Auto-Delete Schedule**
```
Day 0: Live สด (HD 720p)
Day 0-1: Processing → Compress to SD 480p
Day 1-7: Available (SD 480p)
Day 7: Auto-delete (ถ้าไม่ archive)
```

#### **4. Archive (เลือกได้)**
- **คุณภาพ**: SD (480p)
- **เก็บไว้**: ไม่จำกัด (จนกว่าจะลบเอง)
- **Comments**: เก็บแค่ 100 comments ล่าสุด
- **Auto-delete**: ❌ ปิดใช้งาน

---

## 🛠️ เทคโนโลยีที่ใช้

### **Frontend (Flutter)**
- `agora_rtc_engine` - Live streaming (แนะนำ)
- `video_player` - เล่นวิดีโอที่บันทึกไว้
- `cloud_firestore` - Real-time comments & stats
- `firebase_storage` - เก็บวิดีโอที่บันทึก

### **Backend (Firebase)**
- **Firestore** - เก็บข้อมูล live streams
- **Storage** - เก็บวิดีโอและ thumbnails
- **Cloud Functions** - Auto-cleanup, compression
- **Realtime Database** - Real-time viewer count

### **Third-Party Services**
- **Agora.io** - WebRTC streaming infrastructure
  - Free: 10,000 minutes/month
  - HD quality support
  - Low latency (< 300ms)

---

## 📱 วิธีการใช้งาน

### **1. สร้าง Live Stream**

```dart
import 'package:green_market/services/live_stream_service.dart';

final liveService = LiveStreamService();

// สร้าง live stream
final streamId = await liveService.createLiveStream(
  streamerId: currentUser.id,
  streamerName: currentUser.displayName,
  streamerPhoto: currentUser.photoUrl,
  title: 'ปลูกผักอินทรีย์ กับสวนครัวพอเพียง',
  description: 'สอนวิธีปลูกผักอินทรีย์ง่ายๆ ไม่ง้อสารเคมี',
  tags: ['ปลูกผัก', 'อินทรีย์', 'สวนครัว'],
  scheduledTime: null, // ไลฟ์ทันที หรือกำหนดเวลา
  retentionDays: 7, // เก็บไว้ 7 วัน
);

// เริ่มไลฟ์
await liveService.startLiveStream(streamId);
```

### **2. ดูจำนวนผู้ชม Real-time**

```dart
// Subscribe to viewer count
liveService.getLiveStream(streamId).listen((stream) {
  print('ผู้ชมปัจจุบัน: ${stream?.currentViewers}');
  print('ผู้ชมรวม: ${stream?.totalViewers}');
  print('สูงสุด: ${stream?.peakViewers}');
});
```

### **3. จบการไลฟ์**

```dart
// จบไลฟ์ → จะ trigger auto-compression
await liveService.endLiveStream(streamId);

// ระบบจะ:
// 1. หยุดบันทึก
// 2. Compress เป็น SD (480p) 
// 3. กำหนด deleteAt = now + 7 days
// 4. ลบ HD version ต้นฉบับ
```

### **4. Archive (เก็บถาวร)**

```dart
// เก็บไว้ถาวร (ไม่ลบอัตโนมัติ)
await liveService.archiveLiveStream(streamId);

// จะเปลี่ยน:
// - status: archived
// - autoDeleteEnabled: false
// - ลบ comments เก่า (เหลือ 100 ล่าสุด)
```

---

## 🔧 การบำรุงรักษา

### **1. Auto-Cleanup (Cloud Functions)**

#### **ทำงานอัตโนมัติทุกวัน 03:00 AM:**

```javascript
// functions/index.js
exports.cleanupExpiredStreams = functions.pubsub
  .schedule('0 3 * * *')
  .timeZone('Asia/Bangkok')
  .onRun(async (context) => {
    // ลบ streams ที่หมดอายุ (> 7 วัน)
    // ลบวิดีโอจาก Storage
    // ลบ comments, viewers, likes
  });
```

### **2. Storage Monitoring**

```javascript
exports.monitorStorageSize = functions.pubsub
  .schedule('0 0 * * *')
  .onRun(async (context) => {
    // เช็คขนาด Storage
    // ถ้าเกิน 4.5GB → แจ้งเตือน admin
    // บันทึกสถิติการใช้งาน
  });
```

### **3. Manual Cleanup**

```dart
// ทำความสะอาดด้วยตัวเอง
await liveService.cleanupExpiredStreams();
```

---

## 📊 ประมาณการพื้นที่ Storage

### **สมมติฐาน:**
- ไลฟ์เฉลี่ย 30 นาที/ครั้ง
- ไลฟ์ 10 ครั้ง/วัน
- เก็บไว้ 7 วัน

### **คำนวณ:**
```
1 ไลฟ์ (30 นาที):
- HD: 450 MB (ขณะไลฟ์)
- SD: 225 MB (หลังบีบอัด)

10 ไลฟ์/วัน × 225 MB = 2.25 GB/วัน
2.25 GB × 7 วัน = 15.75 GB/สัปดาห์

💡 Firebase Storage Free: 5 GB
💰 ต้อง upgrade Blaze Plan
```

### **แนวทางประหยัด:**
1. ✅ เก็บแค่ **3 วัน** แทน 7 วัน → **6.75 GB**
2. ✅ บีบอัดเป็น **360p** (ultra-light) → **3.5 GB**
3. ✅ จำกัด **5 ไลฟ์/วัน** → **7.87 GB**
4. ✅ ส่งเสริม **Archive เฉพาะไลฟ์ดี** → ประหยัดพื้นที่

---

## ⚙️ การติดตั้ง

### **1. เพิ่ม Dependencies**

```yaml
# pubspec.yaml
dependencies:
  agora_rtc_engine: ^6.3.2  # Live streaming
  permission_handler: ^11.0.1  # Permissions
```

```bash
flutter pub get
```

### **2. Setup Agora**

1. สมัคร Agora: https://console.agora.io
2. สร้าง Project → รับ App ID
3. เพิ่ม App ID ใน `lib/utils/constants.dart`:

```dart
class AgoraConfig {
  static const String appId = 'YOUR_AGORA_APP_ID';
}
```

### **3. Deploy Cloud Functions**

```bash
cd functions
npm install
firebase deploy --only functions
```

---

## 📈 สถิติและ Analytics

### **Dashboard สำหรับ Admin:**

```dart
final stats = await liveService.getStreamingStats();

print('''
📊 สถิติ Live Streaming (30 วันล่าสุด):
- ไลฟ์ทั้งหมด: ${stats['totalStreams']}
- กำลังไลฟ์: ${stats['liveNow']}
- ผู้ชมรวม: ${stats['totalViewers']}
- เฉลี่ย: ${stats['averageViewers']} คน/ไลฟ์
- ระยะเวลารวม: ${stats['totalDurationMinutes']} นาที
''');
```

---

## 🚀 Best Practices

### **สำหรับ Streamers:**
1. ✅ ตั้งชื่อไลฟ์ที่ชัดเจน มี keyword
2. ✅ เพิ่ม hashtags ที่เกี่ยวข้อง
3. ✅ Archive ไลฟ์ที่ดี มีคุณค่า
4. ✅ ลบไลฟ์ทดสอบเอง (ไม่รอ auto-delete)

### **สำหรับ Admins:**
1. ✅ ติดตาม Storage ใช้งานทุกวัน
2. ✅ รัน cleanup manual ถ้า Storage ใกล้เต็ม
3. ✅ ตรวจสอบ logs ของ Cloud Functions
4. ✅ ปรับ retentionDays ตามการใช้งานจริง

---

## 🔒 Security & Privacy

### **Firestore Rules:**

```javascript
// firestore.rules
match /live_streams/{streamId} {
  // อ่านได้ทุกคน ถ้าเป็น public
  allow read: if resource.data.isPublic == true 
                 || request.auth.uid == resource.data.streamerId;
  
  // สร้างได้เฉพาะเจ้าของ
  allow create: if request.auth != null 
                   && request.auth.uid == request.resource.data.streamerId;
  
  // แก้ไขได้เฉพาะเจ้าของ
  allow update: if request.auth.uid == resource.data.streamerId;
  
  // ลบได้เฉพาะเจ้าของหรือ admin
  allow delete: if request.auth.uid == resource.data.streamerId
                   || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}
```

---

## 📞 Support & Troubleshooting

### **ปัญหาที่พบบ่อย:**

**Q: ไลฟ์ติดขัด/lag**
- ✅ เช็คอินเทอร์เน็ต (ต้อง > 5 Mbps upload)
- ✅ ลดคุณภาพเป็น SD (480p)
- ✅ ปิด apps อื่นๆ ที่ใช้เน็ต

**Q: วิดีโอไม่บีบอัดอัตโนมัติ**
- ✅ เช็ค Cloud Functions logs
- ✅ ตรวจสอบ compression_jobs collection
- ✅ Redeploy functions

**Q: Storage เต็ม**
- ✅ รัน `cleanupExpiredStreams` ทันที
- ✅ ลด retentionDays เป็น 3-5 วัน
- ✅ บีบอัดเป็น 360p แทน 480p

---

## 📝 Changelog

### **Version 1.0.0** (2025-12-05)
- ✅ เพิ่มระบบ Live Streaming
- ✅ Auto-compression & deletion
- ✅ Real-time comments & viewers
- ✅ Archive system
- ✅ Cloud Functions auto-cleanup
- ✅ Storage monitoring

---

**🌱 Made with ❤️ by Green Market Team**
