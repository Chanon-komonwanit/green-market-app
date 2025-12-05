# Firestore Indexes Configuration
# สำหรับการ query ที่ซับซ้อนใน Green Market App

# ===== COMMUNITY POSTS =====
# Index สำหรับ feed หลักที่มีการ filter blocked users
community_posts:
  - collectionGroup: community_posts
    fields:
      - fieldPath: isActive
        order: ASCENDING
      - fieldPath: userId
        order: ASCENDING  
      - fieldPath: createdAt
        order: DESCENDING

  # Index สำหรับ posts ที่มี tags
  - collectionGroup: community_posts
    fields:
      - fieldPath: isActive
        order: ASCENDING
      - fieldPath: tags
        arrayConfig: CONTAINS
      - fieldPath: createdAt
        order: DESCENDING

  # Index สำหรับ cleanup - หาโพสต์เก่าที่ engagement ต่ำ
  - collectionGroup: community_posts
    fields:
      - fieldPath: isActive
        order: ASCENDING
      - fieldPath: createdAt
        order: ASCENDING
      - fieldPath: likes
        order: ASCENDING

# ===== NOTIFICATIONS =====
# Index สำหรับลบ notifications เก่า
notifications:
  - collectionGroup: notifications
    fields:
      - fieldPath: isRead
        order: ASCENDING
      - fieldPath: createdAt
        order: ASCENDING

  # Index สำหรับ query notifications ของผู้ใช้
  - collectionGroup: notifications
    fields:
      - fieldPath: recipientId
        order: ASCENDING
      - fieldPath: isRead
        order: ASCENDING
      - fieldPath: createdAt
        order: DESCENDING

# ===== COMMENTS =====
# Index สำหรับ comments ของแต่ละโพสต์
community_comments:
  - collectionGroup: community_comments
    fields:
      - fieldPath: postId
        order: ASCENDING
      - fieldPath: isActive
        order: ASCENDING
      - fieldPath: createdAt
        order: DESCENDING

# ===== REPORTS =====
# Index สำหรับ admin dashboard
reports:
  - collectionGroup: reports
    fields:
      - fieldPath: status
        order: ASCENDING
      - fieldPath: createdAt
        order: DESCENDING

  # Index สำหรับหา reports ของผู้ใช้คนเดียวกัน
  - collectionGroup: reports
    fields:
      - fieldPath: reportedUserId
        order: ASCENDING
      - fieldPath: status
        order: ASCENDING
      - fieldPath: createdAt
        order: DESCENDING

# ===== PRODUCTS (Existing) =====
# Index สำหรับค้นหาสินค้า
products:
  - collectionGroup: products
    fields:
      - fieldPath: isActive
        order: ASCENDING
      - fieldPath: categoryId
        order: ASCENDING
      - fieldPath: createdAt
        order: DESCENDING

  # Index สำหรับเรียงตามยอดขาย
  - collectionGroup: products
    fields:
      - fieldPath: isActive
        order: ASCENDING
      - fieldPath: soldCount
        order: DESCENDING

# ===== ORDERS (Existing) =====
# Index สำหรับคำสั่งซื้อของผู้ใช้
orders:
  - collectionGroup: orders
    fields:
      - fieldPath: buyerId
        order: ASCENDING
      - fieldPath: status
        order: ASCENDING
      - fieldPath: createdAt
        order: DESCENDING

# ===== วิธีการสร้าง Indexes =====
# 
# Option 1: ใช้ Firebase Console
# 1. ไปที่ Firebase Console > Firestore > Indexes
# 2. คลิก "Create Index"
# 3. กรอกข้อมูลตาม configuration ด้านบน
#
# Option 2: ใช้ Firebase CLI
# 1. สร้างไฟล์ firestore.indexes.json
# 2. Run: firebase deploy --only firestore:indexes
#
# Option 3: Auto-create จาก error message
# - เมื่อ query ต้องการ index ที่ยังไม่มี
# - Firebase จะ throw error พร้อม link สร้าง index
# - คลิก link แล้ว Firebase จะสร้างให้อัตโนมัติ

# ===== Index Management Best Practices =====
# 
# 1. สร้าง index เฉพาะที่จำเป็น (ประหยัดค่าใช้จ่าย)
# 2. ลบ index ที่ไม่ได้ใช้แล้ว
# 3. ใช้ composite index สำหรับ query ที่ซับซ้อน
# 4. ตรวจสอบ index usage ใน Firebase Console
# 5. Monitor query performance ด้วย Cloud Monitoring
