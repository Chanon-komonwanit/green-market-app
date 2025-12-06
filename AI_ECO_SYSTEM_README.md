# 🤖 AI Eco Verification System - คู่มือการใช้งาน

## 📋 ภาพรวมระบบ

ระบบ **AI-Powered Eco Verification** เป็นระบบที่ใช้ **Google Gemini AI (Free)** ช่วยวิเคราะห์ความเป็น Eco-friendly ของสินค้าอัตโนมัติ พร้อมระบบ Machine Learning ที่เรียนรู้จากการตัดสินใจของ Admin

## 🎯 จุดประสงค์

1. **ตรวจสอบความถูกต้อง** - ตรวจสอบว่าสินค้าที่ผู้ขายระบุเป็น Eco จริงหรือไม่
2. **ให้คำแนะนำ** - แนะนำวิธีปรับปรุงสินค้าให้เป็น Eco มากขึ้น
3. **เรียนรู้อัตโนมัติ** - AI เรียนรู้จากการ approve/reject ของ Admin
4. **เพิ่มความน่าเชื่อถือ** - ทำให้ลูกค้ามั่นใจว่าสินค้าเป็น Eco จริง

## 🏗️ สถาปัตยกรรมระบบ

```
┌─────────────────┐
│  ผู้ขาย         │
│  กรอกข้อมูล     │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────┐
│  AI Analysis Service        │
│  ─────────────────────────  │
│  1. รับข้อมูลสินค้า          │
│  2. เรียก Gemini API        │
│  3. วิเคราะห์ Eco Score     │
│  4. ให้คำแนะนำ              │
└────────┬────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│  Firestore                  │
│  ─────────────────────────  │
│  • ai_learning_data         │
│  • ai_feedback_training     │
│  • ai_statistics            │
└────────┬────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│  Admin Panel                │
│  ─────────────────────────  │
│  • เปรียบเทียบ AI vs Seller │
│  • Approve/Reject           │
│  • Feedback for ML          │
└─────────────────────────────┘
```

## 📦 ส่วนประกอบหลัก

### 1. **AI Eco Analysis Service** (`ai_eco_analysis_service.dart`)

#### Features:
- **AI Analysis**: ใช้ Gemini AI วิเคราะห์สินค้า
- **Score Calculation**: คำนวณ Eco Score 0-100
- **Recommendations**: ให้คำแนะนำปรับปรุง
- **ML Learning**: เรียนรู้จาก Admin feedback
- **Accuracy Tracking**: ติดตามความแม่นยำของ AI

#### คะแนนแยกตามหมวด:
```dart
{
  'materials': 25,        // คุณภาพวัสดุ
  'manufacturing': 25,    // กระบวนการผลิต
  'packaging': 20,        // บรรจุภัณฑ์
  'wasteManagement': 15,  // การจัดการขยะ
  'certificates': 15,     // ใบรับรอง
}
```

### 2. **Enhanced Add Product Form**

#### ฟิลด์ใหม่ที่เพิ่ม:
1. **ชื่อสินค้า** (เดิม)
2. **คำอธิบาย** (เดิม)
3. **วัสดุที่ใช้** (เดิม)
4. **เหตุผลความเป็น Eco** (เดิม)
5. **กระบวนการผลิต** 🆕
6. **ประเภทบรรจุภัณฑ์** 🆕
7. **การจัดการขยะ** 🆕
8. **ใบรับรอง** 🆕 (optional)
9. **Eco Score** (Seller's claim)

#### ปุ่ม "วิเคราะห์ด้วย AI":
- ส่งข้อมูลทั้งหมดไปยัง AI
- แสดงผลการวิเคราะห์แบบ real-time
- เปรียบเทียบคะแนน Seller vs AI
- ให้คำแนะนำปรับปรุง
- ตัวเลือก "ใช้คะแนนจาก AI"

## 🚀 วิธีการใช้งาน

### สำหรับผู้ขาย:

1. **กรอกข้อมูลสินค้าครบถ้วน**
   ```
   - ชื่อสินค้า
   - คำอธิบาย
   - วัสดุ
   - กระบวนการผลิต
   - บรรจุภัณฑ์
   - การจัดการขยะ
   ```

2. **ระบุ Eco Score**
   - ใช้ slider เลือก 0-100
   - เขียนเหตุผลอธิบาย

3. **กดปุ่ม "วิเคราะห์ด้วย AI"**
   - AI จะวิเคราะห์ใน 5-10 วินาที
   - แสดงผลคะแนนและเหตุผล

4. **ตรวจสอบผลลัพธ์**
   - เปรียบเทียบคะแนน
   - อ่านคำแนะนำ
   - ปรับปรุงข้อมูล (ถ้าต้องการ)

5. **ส่งคำขอ**
   - รอ Admin อนุมัติ

### สำหรับ Admin:

1. **ดูรายการสินค้ารออนุมัติ**
   ```
   ┌──────────────────────────┐
   │ Product: ไม้แปรงฟันไผ่     │
   │                          │
   │ Seller Score: 85         │
   │ AI Score: 72  ⚠️         │
   │ Difference: -13          │
   │                          │
   │ AI Reasoning:            │
   │ "สินค้านี้ใช้วัสดุธรรมชาติ │
   │  แต่ยังขาดข้อมูล..."     │
   │                          │
   │ [อนุมัติ] [ปฏิเสธ]       │
   └──────────────────────────┘
   ```

2. **ตรวจสอบรายละเอียด**
   - ดูคะแนนจาก Seller
   - ดูคะแนนจาก AI
   - ดูเหตุผลและคำแนะนำ

3. **ตัดสินใจ**
   - **Approve**: AI จะเรียนรู้ว่าถูกต้อง
   - **Reject**: AI จะเรียนรู้ว่าไม่ผ่าน
   - **Edit Score**: ปรับคะแนนให้ถูกต้อง

4. **ระบบเรียนรู้อัตโนมัติ**
   - บันทึก feedback ลง Firestore
   - ปรับปรุง AI model
   - เพิ่มความแม่นยำ

## 🔧 การติดตั้ง

### 1. เพิ่ม Gemini API Key

แก้ไขไฟล์ `ai_eco_analysis_service.dart`:

```dart
// เปลี่ยนจาก
static const String _geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';

// เป็น
static const String _geminiApiKey = 'YOUR_ACTUAL_API_KEY';
```

**วิธีขอ API Key:**
1. ไปที่ https://makersuite.google.com/app/apikey
2. กด "Create API Key"
3. Copy API Key
4. วาง key ในโค้ด

### 2. ตรวจสอบ Dependencies

ใน `pubspec.yaml`:
```yaml
dependencies:
  http: ^1.2.2  # ✅ มีแล้ว
  cloud_firestore: ^4.x.x  # ✅ มีแล้ว
```

### 3. Firestore Structure

สร้าง Collections:

```
green_market/
├── ai_learning_data/          # เก็บข้อมูลการเรียนรู้
│   └── {auto-id}
│       ├── productName
│       ├── category
│       ├── sellerClaimedScore
│       ├── aiEcoScore
│       ├── scoreDifference
│       ├── materials
│       └── timestamp
│
├── ai_feedback_training/      # เก็บ feedback จาก Admin
│   └── {auto-id}
│       ├── productId
│       ├── adminApprovedScore
│       ├── aiPredictedScore
│       ├── scoreDifference
│       ├── adminComments
│       └── timestamp
│
└── ai_statistics/             # สถิติความแม่นยำ
    └── accuracy
        ├── totalAnalysis
        ├── totalAccuracyPoints
        └── lastUpdated
```

## 📊 การคำนวณคะแนน

### AI Scoring Algorithm:

```python
Eco Score = 
  + Materials Score (0-25)        # วัสดุที่ใช้
  + Manufacturing Score (0-25)    # กระบวนการผลิต
  + Packaging Score (0-20)        # บรรจุภัณฑ์
  + Waste Management Score (0-15) # การจัดการขยะ
  + Certificates Score (0-15)     # ใบรับรอง
  ────────────────────────────
  Total: 0-100
```

### Eco Levels:

| Score | Level | สี | คำอธิบาย |
|-------|-------|-----|----------|
| 90-100 | Eco Champion | 🟣 Purple | มาตรฐานสูงสุด |
| 75-89 | Excellent | 🟢 Green | ดีมาก |
| 60-74 | Good | 🔵 Blue | ดี |
| 0-59 | Standard | ⚫ Grey | ปานกลาง |

## 🧠 Machine Learning System

### วิธีการเรียนรู้:

1. **เก็บข้อมูล**
   ```dart
   await _saveLearningData(productData, aiResult);
   ```

2. **รับ Feedback**
   ```dart
   await learnFromAdminFeedback(
     productId: 'xxx',
     adminApprovedScore: 80,
     aiPredictedScore: 72,
     adminComments: ['ขาดข้อมูลใบรับรอง'],
   );
   ```

3. **ปรับปรุง Model**
   - วิเคราะห์ความแตกต่าง
   - ปรับน้ำหนักการคำนวณ
   - เพิ่มความแม่นยำ

### ตัวอย่าง Learning Data:

```json
{
  "productName": "ไม้แปรงฟันไผ่",
  "category": "สุขภาพและความงาม",
  "sellerClaimedScore": 85,
  "aiEcoScore": 72,
  "scoreDifference": 13,
  "materials": ["bamboo", "nylon"],
  "confidence": "medium",
  "timestamp": "2025-12-06",
  "needsReview": true  // ถ้าแตกต่างมาก
}
```

## 📈 Analytics Dashboard

### Metrics ที่ติดตาม:

1. **AI Accuracy**
   - ความแม่นยำ %
   - จำนวนการวิเคราะห์ทั้งหมด

2. **Score Distribution**
   - Champion: X%
   - Excellent: Y%
   - Good: Z%
   - Standard: W%

3. **Top Categories**
   - หมวดหมู่ที่มี Eco score สูงสุด

4. **Learning Progress**
   - Accuracy เพิ่มขึ้นเมื่อเวลาผ่านไป

## 🔒 ข้อควรระวัง

### API Limits:
- **Gemini Free Tier**: 60 requests/minute
- แนะนำ: เพิ่ม rate limiting

### Privacy:
- ไม่ส่งข้อมูลส่วนตัวลูกค้า
- เก็บเฉพาะข้อมูลสินค้า

### Fallback System:
- ถ้า API ล้ม → ใช้คะแนนพื้นฐาน
- ยังใช้งานได้ปกติ

## 🎯 Roadmap

- [x] AI Analysis Service
- [x] Enhanced Add Product Form  
- [ ] Admin Review Panel
- [ ] Real-time Notification
- [ ] Analytics Dashboard
- [ ] Multi-language Support
- [ ] Image Recognition
- [ ] Certificate Verification

## 📞 Support

หากมีปัญหา:
1. เช็ค API Key ถูกต้อง
2. เช็ค Firestore Rules
3. ดู Console Logs
4. ติดต่อทีมพัฒนา

---

**พัฒนาโดย**: Green Market Development Team  
**เวอร์ชัน**: 1.0.0  
**อัพเดทล่าสุด**: 6 ธันวาคม 2025
