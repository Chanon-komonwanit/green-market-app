// lib/utils/fix_user_permissions.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FixUserPermissions {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // static final FirebaseAuth _auth = FirebaseAuth.instance; // Unused field removed

  /// แก้ไขสิทธิ์ของผู้ใช้ heargofza1133@gmail.com ให้เป็นเฉพาะ Seller
  static Future<Map<String, dynamic>> fixHeargofzaPermissions() async {
    final email = 'heargofza1133@gmail.com';
    final results = <String, dynamic>{};

    try {
      print('🔧 กำลังแก้ไขสิทธิ์ผู้ใช้: $email');

      // หา UID ของผู้ใช้จากอีเมล
      String? userId;

      // ค้นหาจาก users collection
      final usersQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (usersQuery.docs.isNotEmpty) {
        userId = usersQuery.docs.first.id;
        print('✅ พบผู้ใช้: $userId');
      } else {
        throw Exception('ไม่พบผู้ใช้ที่มีอีเมล: $email');
      }

      // อัปเดตสิทธิ์ใน users collection
      await _firestore.collection('users').doc(userId).update({
        'isAdmin': false, // ไม่ใช่ admin
        'isSeller': true, // เป็น seller
        'updatedAt': Timestamp.now(),
      });
      results['users_updated'] = true;
      print('✅ อัปเดต users collection แล้ว');

      // ลบออกจาก admins collection (ถ้ามี)
      try {
        final adminDoc =
            await _firestore.collection('admins').doc(userId).get();
        if (adminDoc.exists) {
          await _firestore.collection('admins').doc(userId).delete();
          results['admin_removed'] = true;
          print('✅ ลบออกจาก admins collection แล้ว');
        } else {
          results['admin_removed'] = false;
          print('ℹ️ ไม่พบใน admins collection');
        }
      } catch (e) {
        print('⚠️ ไม่สามารถลบจาก admins collection: $e');
        results['admin_remove_error'] = e.toString();
      }

      // ตรวจสอบว่ามีใน sellers collection หรือไม่
      final sellerDoc =
          await _firestore.collection('sellers').doc(userId).get();
      if (!sellerDoc.exists) {
        // สร้างข้อมูล seller ใหม่
        await _firestore.collection('sellers').doc(userId).set({
          'id': userId,
          'shopName': 'Green Shop - $email',
          'contactEmail': email,
          'phoneNumber': '081-234-5678',
          'status': 'active',
          'rating': 4.5,
          'totalRatings': 0,
          'shopDescription': 'ร้านขายสินค้าเพื่อสิ่งแวดล้อม',
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
        results['seller_created'] = true;
        print('✅ สร้างข้อมูล seller ใหม่แล้ว');
      } else {
        results['seller_exists'] = true;
        print('ℹ️ มีข้อมูล seller อยู่แล้ว');
      }

      results['status'] = 'SUCCESS';
      results['message'] =
          'แก้ไขสิทธิ์ผู้ใช้สำเร็จ - ตอนนี้เป็น Seller เท่านั้น';
      results['user_id'] = userId;
      results['email'] = email;
    } catch (e) {
      results['status'] = 'ERROR';
      results['error'] = e.toString();
      print('❌ เกิดข้อผิดพลาด: $e');
    }

    return results;
  }

  /// ตรวจสอบสิทธิ์ปัจจุบันของผู้ใช้
  static Future<Map<String, dynamic>> checkUserPermissions(String email) async {
    final results = <String, dynamic>{};

    try {
      // หาผู้ใช้จากอีเมล
      final usersQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (usersQuery.docs.isEmpty) {
        results['user_found'] = false;
        results['message'] = 'ไม่พบผู้ใช้ที่มีอีเมล: $email';
        return results;
      }

      final userDoc = usersQuery.docs.first;
      final userId = userDoc.id;
      final userData = userDoc.data();

      results['user_found'] = true;
      results['user_id'] = userId;
      results['email'] = userData['email'];
      results['is_admin'] = userData['isAdmin'] ?? false;
      results['is_seller'] = userData['isSeller'] ?? false;
      results['is_suspended'] = userData['isSuspended'] ?? false;

      // ตรวจสอบใน admins collection
      final adminDoc = await _firestore.collection('admins').doc(userId).get();
      results['in_admins_collection'] = adminDoc.exists;

      // ตรวจสอบใน sellers collection
      final sellerDoc =
          await _firestore.collection('sellers').doc(userId).get();
      results['in_sellers_collection'] = sellerDoc.exists;

      if (sellerDoc.exists) {
        final sellerData = sellerDoc.data()!;
        results['shop_name'] = sellerData['shopName'];
        results['seller_status'] = sellerData['status'];
      }

      results['status'] = 'SUCCESS';
    } catch (e) {
      results['status'] = 'ERROR';
      results['error'] = e.toString();
    }

    return results;
  }

  /// แสดงรายงานสิทธิ์ผู้ใช้
  static Future<String> generatePermissionsReport(String email) async {
    final results = await checkUserPermissions(email);
    final buffer = StringBuffer();

    buffer.writeln('📋 รายงานสิทธิ์ผู้ใช้');
    buffer.writeln('=' * 40);
    buffer.writeln('📧 อีเมล: $email');

    if (results['user_found'] == true) {
      buffer.writeln('🆔 User ID: ${results['user_id']}');
      buffer.writeln('🔑 Admin: ${results['is_admin'] ? "✅ ใช่" : "❌ ไม่ใช่"}');
      buffer
          .writeln('🏪 Seller: ${results['is_seller'] ? "✅ ใช่" : "❌ ไม่ใช่"}');
      buffer.writeln(
          '⛔ Suspended: ${results['is_suspended'] ? "✅ ใช่" : "❌ ไม่ใช่"}');
      buffer.writeln();
      buffer.writeln('📦 Collections:');
      buffer.writeln(
          '  👑 In Admins: ${results['in_admins_collection'] ? "✅ ใช่" : "❌ ไม่ใช่"}');
      buffer.writeln(
          '  🏪 In Sellers: ${results['in_sellers_collection'] ? "✅ ใช่" : "❌ ไม่ใช่"}');

      if (results['shop_name'] != null) {
        buffer.writeln('  🏬 Shop Name: ${results['shop_name']}');
        buffer.writeln('  📊 Seller Status: ${results['seller_status']}');
      }
    } else {
      buffer.writeln('❌ ไม่พบผู้ใช้');
    }

    return buffer.toString();
  }
}
