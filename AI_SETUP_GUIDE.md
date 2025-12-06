# 🚀 AI Eco System - Setup & Configuration Guide

## 📋 Table of Contents
1. [Quick Start](#quick-start)
2. [Gemini API Setup](#gemini-api-setup)
3. [Testing the System](#testing-the-system)
4. [Admin Panel Usage](#admin-panel-usage)
5. [Analytics & Monitoring](#analytics--monitoring)
6. [Troubleshooting](#troubleshooting)
7. [Best Practices](#best-practices)

---

## 🎯 Quick Start

### Prerequisites
- ✅ Flutter project running
- ✅ Firebase configured
- ✅ All files created:
  - `lib/services/ai_eco_analysis_service.dart`
  - `lib/screens/seller/add_product_screen.dart` (enhanced)
  - `lib/screens/admin/ai_product_review_screen.dart`
  - `lib/models/product.dart` (enhanced with AI fields)

### System Components
```
┌─────────────────────────────────────────────┐
│           AI Eco Analysis System            │
├─────────────────────────────────────────────┤
│                                             │
│  1. Seller adds product + AI analysis       │
│          ↓                                  │
│  2. AI analyzes & saves to Firestore        │
│          ↓                                  │
│  3. Admin reviews AI vs Seller scores       │
│          ↓                                  │
│  4. Admin decision → ML Learning            │
│          ↓                                  │
│  5. AI improves accuracy over time          │
│                                             │
└─────────────────────────────────────────────┘
```

---

## 🔑 Gemini API Setup

### Step 1: Get Your Free API Key

1. **Visit Google AI Studio**
   ```
   https://makersuite.google.com/app/apikey
   ```

2. **Sign in with Google Account**

3. **Click "Create API Key"**
   - Choose "Create API key in new project" (recommended)
   - Or select existing Google Cloud project

4. **Copy Your API Key**
   - Format: `AIzaSy...` (40 characters)
   - ⚠️ **Keep it secret!** Don't commit to Git

### Step 2: Configure the API Key

Open `lib/services/ai_eco_analysis_service.dart`:

```dart
// Line 66 - Replace with your actual API key
static const String _geminiApiKey = 'YOUR_ACTUAL_API_KEY_HERE';
```

**Example:**
```dart
static const String _geminiApiKey = 'AIzaSyC1234567890abcdefghijklmnopqrstuvwx';
```

### Step 3: Verify Configuration

Run this test to check if API key works:

```dart
// In any test screen or main.dart
final aiService = AIEcoAnalysisService();
final testData = ProductEcoData(
  productName: 'Test Product',
  description: 'Eco-friendly test',
  sellerClaimedScore: 80,
  sellerJustification: 'Made from recycled materials',
  materials: ['Recycled plastic', 'Organic cotton'],
  certificates: [],
  manufacturingProcess: 'Low energy process',
  packagingType: 'Biodegradable',
  wasteManagement: 'Fully recyclable',
);

try {
  final result = await aiService.analyzeProduct(testData);
  print('✅ AI Score: ${result.aiEcoScore}');
  print('✅ Reasoning: ${result.aiReasoning}');
} catch (e) {
  print('❌ Error: $e');
}
```

### Step 4: Environment Variables (Production)

For production, use environment variables:

1. **Create `.env` file:**
```env
GEMINI_API_KEY=AIzaSyC1234567890abcdefghijklmnopqrstuvwx
```

2. **Add to `.gitignore`:**
```
.env
*.env
```

3. **Use `flutter_dotenv` package:**
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

static String get _geminiApiKey => 
  dotenv.env['GEMINI_API_KEY'] ?? '';
```

---

## 🧪 Testing the System

### Test 1: Seller Product Analysis

1. **Login as Seller**
2. **Navigate to "Add Product"**
3. **Fill in basic info:**
   - Product name
   - Description
   - Price, Stock
   - Upload images
4. **Scroll to Eco Score Section**
5. **Fill AI analysis fields:**
   - Manufacturing Process: "Low-energy solar-powered factory"
   - Packaging Type: "100% biodegradable paper"
   - Waste Management: "Compostable at end-of-life"
6. **Set your Eco Score:** 85
7. **Click "วิเคราะห์ด้วย AI (ฟรี)"**
8. **Check Results:**
   - AI Score displayed
   - Reasoning shown
   - Suggestions listed
   - Compare with your score
9. **Click "ใช้คะแนนนี้"** (optional)
10. **Submit product**

### Test 2: Admin Review

1. **Login as Admin**
2. **Go to Admin Dashboard**
3. **Click "AI Product Review" card**
4. **Check filters:**
   - "ทั้งหมด" - All analyzed products
   - "รอตรวจสอบ" - Pending verification
   - "คะแนนต่างกัน" - Discrepancy > 10 points
5. **Review a product:**
   - See Seller Score vs AI Score
   - Read AI reasoning
   - Check score breakdown
   - View suggestions
6. **Make decision:**
   - "ใช้คะแนน AI" - Approve AI score
   - "ใช้คะแนนผู้ขาย" - Approve seller score
   - Custom score icon - Set manually
7. **Add feedback** (for ML learning)
8. **Verify badge appears** ✅

### Test 3: ML Learning

After 5-10 admin reviews:

1. **Click Analytics icon** (top-right in AI Review)
2. **Check stats:**
   - Total Analyzed
   - Admin Verified
   - Accuracy %
   - Avg Score Difference
3. **Verify accuracy improves over time**

---

## 👨‍💼 Admin Panel Usage

### Dashboard Access

```
Admin Dashboard → AI Product Review card
OR
Navigate to: /admin/ai-review
```

### Features Overview

#### 1. **Filter Bar**
- **ทั้งหมด**: All AI-analyzed products
- **รอตรวจสอบ**: Not yet verified by admin
- **ผ่านการตรวจ**: Already verified
- **คะแนนต่างกัน**: Score difference ≥ 10

#### 2. **Product Card**
```
┌─────────────────────────────────────────┐
│  [Product Image]  Product Name          │
│                   Price: ฿XXX            │
│                   Analyzed: 2h ago       │
├─────────────────────────────────────────┤
│  Score Comparison                       │
│  [Seller: 85] ⚠️ [AI: 72]              │
│  Difference: 13 (Warning!)              │
├─────────────────────────────────────────┤
│  AI Reasoning:                          │
│  "Product uses recycled materials..."   │
├─────────────────────────────────────────┤
│  AI Suggestions:                        │
│  • Add eco certifications               │
│  • Improve packaging details            │
├─────────────────────────────────────────┤
│  Score Breakdown:                       │
│  Materials: 85%  ████████░░             │
│  Manufacturing: 70%  ███████░░░         │
│  Packaging: 60%  ██████░░░░             │
├─────────────────────────────────────────┤
│  [ใช้คะแนน AI] [ใช้คะแนนผู้ขาย] [✏️]  │
└─────────────────────────────────────────┘
```

#### 3. **Action Buttons**
- **ใช้คะแนน AI**: Accept AI's analysis
- **ใช้คะแนนผู้ขาย**: Trust seller's score
- **✏️ Edit**: Set custom score

#### 4. **Feedback Dialog**
Always appears after action:
```
┌──────────────────────────┐
│ เพิ่มความคิดเห็น         │
├──────────────────────────┤
│ [Text Input]             │
│ "AI ถูกต้อง..."          │
│                          │
│ [ยกเลิก]  [ยืนยัน]       │
└──────────────────────────┘
```

#### 5. **Statistics Button**
Click 📊 icon to see:
- Total products analyzed
- Verification count
- AI accuracy percentage
- Average score difference
- Learning progress bar

---

## 📊 Analytics & Monitoring

### Firestore Collections

#### 1. **products** (Enhanced)
```javascript
{
  // Existing fields...
  
  // AI Analysis fields
  "aiEcoScore": 72,
  "aiReasoning": "Product uses 60% recycled materials...",
  "aiSuggestions": ["Add organic certification", "..."],
  "aiScoreBreakdown": {
    "materials": 18,
    "manufacturing": 20,
    "packaging": 15,
    "wasteManagement": 12,
    "certificates": 7
  },
  "aiEcoLevel": "good",
  "aiConfidence": "high",
  "aiAnalyzed": true,
  "aiAnalyzedAt": Timestamp,
  
  // Admin verification
  "adminVerified": true,
  "adminApprovedScore": 72,
  "adminFeedback": "AI analysis is accurate"
}
```

#### 2. **ai_learning_data**
```javascript
{
  "productId": "prod123",
  "productName": "Eco Bottle",
  "analysisData": {...},
  "aiResult": {...},
  "timestamp": Timestamp,
  "accuracy": null  // Set after admin review
}
```

#### 3. **ai_feedback_training**
```javascript
{
  "productId": "prod123",
  "aiScore": 72,
  "adminScore": 75,
  "scoreDifference": 3,
  "feedback": "Good analysis, slight underestimate",
  "timestamp": Timestamp
}
```

#### 4. **ai_statistics**
```javascript
{
  "totalAnalyzed": 150,
  "totalVerified": 120,
  "correctPredictions": 95,
  "accuracy": 79.17,
  "avgScoreDifference": 5.2,
  "lastUpdated": Timestamp
}
```

### Query Examples

**Get pending reviews:**
```javascript
db.collection('products')
  .where('aiAnalyzed', '==', true)
  .where('adminVerified', '==', false)
  .orderBy('aiAnalyzedAt', 'desc')
```

**Get discrepancies:**
```javascript
// Client-side filter (no compound index needed)
products.where((p) => 
  p.aiEcoScore != null && 
  (p.ecoScore - p.aiEcoScore!).abs() >= 10
)
```

**Calculate accuracy:**
```javascript
const correct = feedbacks.filter(f => 
  Math.abs(f.aiScore - f.adminScore) <= 5
).length;
const accuracy = (correct / feedbacks.length) * 100;
```

---

## 🔧 Troubleshooting

### Issue 1: "Invalid API Key"

**Error:**
```
Exception: API Error: 400 - API key not valid
```

**Solutions:**
1. Check API key format (should start with `AIzaSy`)
2. Verify key is active in Google AI Studio
3. Check API key restrictions (if any)
4. Try generating a new key

**Test command:**
```bash
curl -X POST \
  https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=YOUR_KEY \
  -H 'Content-Type: application/json' \
  -d '{"contents":[{"parts":[{"text":"Hello"}]}]}'
```

### Issue 2: "Rate Limit Exceeded"

**Error:**
```
Exception: API Error: 429 - Resource exhausted
```

**Free Tier Limits:**
- 60 requests per minute
- 1,500 requests per day

**Solutions:**
1. Add rate limiting:
```dart
static DateTime? _lastApiCall;
static const _minInterval = Duration(seconds: 1);

Future<EcoAnalysisResult> analyzeProduct(...) async {
  // Rate limiting
  if (_lastApiCall != null) {
    final elapsed = DateTime.now().difference(_lastApiCall!);
    if (elapsed < _minInterval) {
      await Future.delayed(_minInterval - elapsed);
    }
  }
  _lastApiCall = DateTime.now();
  
  // Continue with analysis...
}
```

2. Show queue to sellers:
```dart
showDialog(
  context: context,
  builder: (_) => AlertDialog(
    title: Text('คำขอเกินกำหนด'),
    content: Text('กรุณารอ 1 นาที แล้วลองอีกครั้ง'),
  ),
);
```

### Issue 3: "No AI Analysis Results"

**Symptoms:**
- Button clicked but no dialog appears
- Loading forever

**Debug steps:**
```dart
// Add debug prints in _analyzeWithAI()
print('1. Starting analysis...');
print('2. Product data: ${productData.toMap()}');
print('3. Calling AI service...');
final result = await _aiService.analyzeProduct(productData);
print('4. Got result: ${result.aiEcoScore}');
```

**Check:**
1. Internet connection
2. Firebase rules allow writes
3. All required fields filled
4. No exceptions in console

### Issue 4: "Admin Panel Not Showing Products"

**Symptoms:**
- Empty list in admin panel
- "ยังไม่มีสินค้า" message

**Solutions:**
1. Check Firestore query:
```dart
// Test in Firebase Console
db.collection('products')
  .where('aiAnalyzed', '==', true)
  .get()
```

2. Verify Firestore indexes:
```
products
  - aiAnalyzed ASC
  - aiAnalyzedAt DESC
```

3. Check security rules:
```javascript
match /products/{productId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null;
}
```

### Issue 5: "ML Learning Not Working"

**Symptoms:**
- Accuracy stays at 0%
- No data in ai_statistics

**Debug:**
```dart
// In learnFromAdminFeedback()
print('Saving feedback for: $productId');
print('AI Score: $aiScore, Admin Score: $adminScore');
print('Difference: ${(adminScore - aiScore).abs()}');

// Check if documents created
await Future.delayed(Duration(seconds: 2));
final feedback = await FirebaseFirestore.instance
  .collection('ai_feedback_training')
  .doc(productId)
  .get();
print('Feedback saved: ${feedback.exists}');
```

---

## ✅ Best Practices

### For Sellers

1. **Be Honest**
   - Don't inflate Eco Score
   - AI will verify claims
   - Admin reviews mismatches

2. **Provide Details**
   - Fill all AI fields thoroughly
   - Add specific manufacturing processes
   - List all certifications

3. **Use AI Suggestions**
   - Read AI's improvement ideas
   - Implement before resubmitting
   - Document changes made

4. **Upload Proof**
   - Add certificate images
   - Include verification videos
   - Link to supplier websites

### For Admins

1. **Review Carefully**
   - Read both seller and AI reasoning
   - Check product images/videos
   - Consider score breakdown

2. **Provide Feedback**
   - Always add comments
   - Be specific about accuracy
   - Help AI learn faster

3. **Handle Discrepancies**
   - Investigate large differences (>20)
   - Contact seller if needed
   - Document decision rationale

4. **Monitor Accuracy**
   - Check analytics weekly
   - Track improvement trends
   - Adjust thresholds if needed

### For Developers

1. **Security**
   - Never commit API keys
   - Use environment variables
   - Rotate keys regularly

2. **Error Handling**
   - Show user-friendly messages
   - Log errors for debugging
   - Implement retry logic

3. **Performance**
   - Cache AI results
   - Implement rate limiting
   - Use Firestore indexes

4. **Testing**
   - Test with various products
   - Verify ML learning works
   - Check edge cases

---

## 🎓 Learning Resources

### Gemini API Documentation
- **Quick Start**: https://ai.google.dev/tutorials/get_started_dart
- **API Reference**: https://ai.google.dev/api/rest
- **Best Practices**: https://ai.google.dev/docs/best_practices

### Firebase Resources
- **Firestore Queries**: https://firebase.google.com/docs/firestore/query-data/queries
- **Security Rules**: https://firebase.google.com/docs/firestore/security/get-started
- **Cloud Functions**: https://firebase.google.com/docs/functions

### Flutter Resources
- **Provider Pattern**: https://pub.dev/packages/provider
- **State Management**: https://flutter.dev/docs/development/data-and-backend/state-mgmt
- **Performance**: https://flutter.dev/docs/perf/best-practices

---

## 📞 Support

### Getting Help

1. **Check Documentation**
   - Read this guide thoroughly
   - Review code comments
   - Check AI_ECO_SYSTEM_README.md

2. **Debug Logs**
   - Enable Flutter DevTools
   - Check Firebase console
   - Review Firestore logs

3. **Common Issues**
   - See Troubleshooting section
   - Search GitHub issues
   - Check Stack Overflow

4. **Contact Team**
   - Email: support@greenmarket.app
   - Slack: #ai-eco-system
   - GitHub Issues: Create detailed bug report

---

## 🚀 Next Steps

### Phase 1: Initial Setup ✅
- [x] Configure API key
- [x] Test basic analysis
- [x] Verify admin panel works

### Phase 2: Production (Next)
- [ ] Set up environment variables
- [ ] Configure Firestore indexes
- [ ] Add monitoring/alerting
- [ ] Train AI with 50+ reviews

### Phase 3: Enhancement (Future)
- [ ] Multi-language support (EN/TH)
- [ ] Image analysis (product photos)
- [ ] Certificate OCR verification
- [ ] Automated re-analysis triggers

### Phase 4: Scale (Future)
- [ ] Upgrade to paid Gemini tier
- [ ] Implement caching layer
- [ ] Add A/B testing
- [ ] Build analytics dashboard

---

## 📝 Changelog

### v1.0.0 (Current)
- ✅ AI Analysis Service with Gemini Pro
- ✅ Enhanced Add Product Form
- ✅ Admin Review Panel
- ✅ ML Learning System
- ✅ Product Model with AI fields
- ✅ Complete documentation

### Roadmap
- **v1.1**: Real-time notifications
- **v1.2**: Analytics dashboard
- **v1.3**: Batch analysis
- **v2.0**: Image recognition

---

## 🎉 Success Metrics

Track these KPIs:

1. **AI Accuracy**: Target 85%+
2. **Analysis Time**: < 5 seconds
3. **Admin Review Time**: < 2 minutes
4. **Seller Satisfaction**: 4.5+ stars
5. **System Uptime**: 99.5%+

---

**Last Updated**: December 6, 2024  
**Version**: 1.0.0  
**Status**: Production Ready 🚀
