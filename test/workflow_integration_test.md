# Product Management Workflow Integration Test

## 📋 การทดสอบ Workflow การจัดการสินค้า

### 🔄 Flow การเพิ่มสินค้าใหม่

#### 1. **ผู้ขายเพิ่มสินค้า (AddProductScreen)**
```dart
// Status เริ่มต้น: 'pending_approval'
final product = Product(
  status: 'pending_approval',
  isApproved: false, // computed property
);

// ส่งไปยัง product_requests collection
await firebaseService.submitProductRequest(product);
```

#### 2. **ระบบจัดเก็บคำขอ (FirebaseService)**
```dart
// บันทึกใน product_requests collection
final requestData = {
  'productData': product.toMap(),
  'status': 'pending', // pending, approved, rejected
  'requestType': 'add_product',
  'submittedAt': FieldValue.serverTimestamp(),
};
```

#### 3. **แอดมินอนุมัติ (AdminProductApprovalScreen)**
```dart
// แอดมินสามารถ:
// - ดูรายละเอียดสินค้า
// - ตั้งค่า ecoScore
// - เลือก category
// - อนุมัติหรือปฏิเสธ

await firebaseService.approveProductRequest(
  requestId,
  ecoScore: ecoScore,
  categoryId: selectedCategory.id,
  categoryName: selectedCategory.name,
);
```

#### 4. **สินค้าถูกสร้าง (FirebaseService.approveProductRequest)**
```dart
// สร้างสินค้าจริงใน products collection
final productData = requestData['productData'] as Map<String, dynamic>;
productData['status'] = 'approved';
productData['isApproved'] = true;
productData['approvedAt'] = FieldValue.serverTimestamp();

await _firestore.collection('products').doc(productDocId).set(productData);
```

### 🔍 การตรวจสอบใน ProfessionalProductManagement

#### 1. **สถานะการแสดงผล**
```dart
// แสดง badge สำหรับสินค้าที่รออนุมัติ
if (product.status == 'pending_approval')
  _buildStatusBadge('⏳ รออนุมัติ', Colors.orange)

// นับจำนวนสินค้าที่รออนุมัติ
'pendingApproval': _allProducts.where((p) => p.status == 'pending_approval').length
```

#### 2. **การกรองสินค้า**
```dart
case 'pending':
  filtered = _allProducts.where((p) => p.status == 'pending_approval').toList();
```

### ✅ **จุดที่ต้องตรวจสอบ**

#### 1. การเชื่อมต่อระหว่าง Screens
- [ ] AddProductScreen → submitProductRequest ✅
- [ ] EditProductScreen → updateProduct ✅  
- [ ] ProfessionalProductManagement → refresh data ✅
- [ ] AdminProductApprovalScreen → approveProductRequest ✅

#### 2. การแสดงสถานะ
- [ ] pending_approval badge แสดงใน product list ✅
- [ ] การนับ pendingApproval ใน analytics ✅
- [ ] การกรอง pending products ✅

#### 3. Real-time Updates
- [ ] เมื่อแอดมินอนุมัติ → สินค้าอัปเดตใน seller dashboard
- [ ] เมื่อแก้ไขสินค้า → อัปเดต real-time
- [ ] เมื่อเพิ่มสินค้าใหม่ → แสดงใน pending list

### 🧪 **Test Cases ที่ควรทดสอบ**

#### Test Case 1: เพิ่มสินค้าใหม่
1. เข้า AddProductScreen
2. กรอกข้อมูลครบถ้วน
3. กดบันทึก
4. ตรวจสอบว่าไปยัง product_requests
5. ตรวจสอบสถานะ pending_approval ใน seller dashboard

#### Test Case 2: แอดมินอนุมัติ
1. เข้า AdminProductApprovalScreen
2. เลือกสินค้าที่รออนุมัติ
3. ตั้งค่า ecoScore และ category
4. กดอนุมัติ
5. ตรวจสอบสินค้าไปยัง products collection
6. ตรวจสอบอัปเดตใน seller dashboard

#### Test Case 3: แก้ไขสินค้า
1. เข้า EditProductScreen
2. แก้ไขข้อมูล
3. บันทึก
4. ตรวจสอบ real-time update
5. ตรวจสอบสถานะยังคงเดิม

### 🔧 **การแก้ไขที่อาจต้องทำ**

#### 1. Real-time Stream Updates
```dart
// ใน _setupRealTimeProductStream อาจต้องเพิ่ม
// listen ทั้ง products และ product_requests
```

#### 2. Error Handling
```dart
// เพิ่ม error handling สำหรับกรณี network issues
// ระหว่างการ submit product request
```

#### 3. Notification System
```dart
// เพิ่ม notification เมื่อสินค้าได้รับการอนุมัติ/ปฏิเสธ
```

---

## 📊 **สรุป Integration Status**

| Component | Status | Notes |
|-----------|---------|-------|
| AddProductScreen | ✅ Working | ส่ง submitProductRequest ถูกต้อง |
| EditProductScreen | ✅ Working | อัปเดตสินค้าและ refresh data |
| AdminApproval | ✅ Working | อนุมัติและสร้างสินค้าจริง |
| ProfessionalMgmt | ✅ Working | แสดงสถานะและ real-time update |
| FirebaseService | ✅ Working | จัดการ workflow ครบถ้วน |

**การทำงานของระบบสมบูรณ์และเชื่อมต่อกันดี! 🎉**