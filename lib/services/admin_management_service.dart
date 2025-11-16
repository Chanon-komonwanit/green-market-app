// lib/services/admin_management_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/utils/debug_config.dart';

class AdminManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ตรวจสอบข้อมูลผู้ใช้ Admin ทั้งหมดในระบบ
  Future<List<Map<String, dynamic>>> getAllAdminUsers() async {
    try {
      // Query จาก users collection ที่มี isAdmin = true
      final usersQuery = await _firestore
          .collection('users')
          .where('isAdmin', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> adminUsers = [];

      for (var doc in usersQuery.docs) {
        adminUsers.add({
          'uid': doc.id,
          'email': doc.data()['email'],
          'displayName': doc.data()['displayName'],
          'isAdmin': doc.data()['isAdmin'],
          'createdAt': doc.data()['createdAt'],
          'source': 'users_collection'
        });
      }

      // ตรวจสอบใน admins collection ด้วย (ถ้ามี)
      try {
        final adminsQuery = await _firestore.collection('admins').get();
        for (var doc in adminsQuery.docs) {
          adminUsers.add({
            'uid': doc.id,
            'email': doc.data()['email'] ?? 'N/A',
            'displayName': doc.data()['displayName'] ?? 'N/A',
            'isAdmin': true,
            'createdAt': doc.data()['createdAt'],
            'source': 'admins_collection'
          });
        }
      } catch (e) {
        ProductionLogger.w('Admins collection not found or empty');
      }

      return adminUsers;
    } catch (e) {
      ProductionLogger.e('Error getting admin users: $e');
      return [];
    }
  }

  /// ลบสิทธิ์ Admin จากผู้ใช้
  Future<bool> removeAdminRights(String userEmail) async {
    try {
      // ค้นหาผู้ใช้จาก email
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .get();

      if (userQuery.docs.isEmpty) {
        print('User not found with email: $userEmail');
        return false;
      }

      final userDoc = userQuery.docs.first;
      final userId = userDoc.id;

      // อัพเดต isAdmin เป็น false ใน users collection
      await _firestore.collection('users').doc(userId).update({
        'isAdmin': false,
        'adminRevokedAt': FieldValue.serverTimestamp(),
      });

      // ลบจาก admins collection ถ้ามี
      try {
        await _firestore.collection('admins').doc(userId).delete();
      } catch (e) {
        print('Admin document not found in admins collection');
      }

      print('Admin rights removed for user: $userEmail');
      return true;
    } catch (e) {
      print('Error removing admin rights: $e');
      return false;
    }
  }

  /// เปลี่ยนผู้ใช้จาก Admin เป็น Seller
  Future<bool> convertAdminToSeller(String userEmail) async {
    try {
      // ค้นหาผู้ใช้จาก email
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .get();

      if (userQuery.docs.isEmpty) {
        print('User not found with email: $userEmail');
        return false;
      }

      final userDoc = userQuery.docs.first;
      final userId = userDoc.id;
      final userData = userDoc.data();

      // อัพเดตสิทธิ์ใน users collection
      await _firestore.collection('users').doc(userId).update({
        'isAdmin': false,
        'isSeller': true,
        'sellerStatus': 'approved',
        'adminRevokedAt': FieldValue.serverTimestamp(),
        'sellerConvertedAt': FieldValue.serverTimestamp(),
      });

      // ลบจาก admins collection ถ้ามี
      try {
        await _firestore.collection('admins').doc(userId).delete();
      } catch (e) {
        print('Admin document not found in admins collection');
      }

      // สร้างข้อมูลผู้ขายใน sellers collection
      await _firestore.collection('sellers').doc(userId).set({
        'userId': userId,
        'email': userEmail,
        'displayName': userData['displayName'] ?? 'ผู้ขาย',
        'shopName': userData['shopName'] ?? 'ร้านค้าของฉัน',
        'shopDescription': userData['shopDescription'] ?? 'ร้านค้าที่น่าสนใจ',
        'isActive': true,
        'joinedAt': FieldValue.serverTimestamp(),
        'convertedFromAdmin': true,
        'contactEmail': userEmail,
        'phoneNumber': userData['phoneNumber'] ?? '',
      });

      print('Successfully converted $userEmail from Admin to Seller');
      return true;
    } catch (e) {
      print('Error converting admin to seller: $e');
      return false;
    }
  }

  /// ตรวจสอบว่าผู้ใช้เป็น Admin หรือไม่
  Future<bool> checkIsAdmin(String email) async {
    try {
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userQuery.docs.isEmpty) return false;

      final userData = userQuery.docs.first.data();
      return userData['isAdmin'] ?? false;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  /// ลบผู้ใช้ออกจาก Firebase Authentication (ต้องระวัง!)
  Future<bool> deleteUserFromAuth(String email) async {
    try {
      print(
          '⚠️  WARNING: This will permanently delete user from Firebase Auth!');
      print('User email: $email');

      // สำหรับการลบผู้ใช้จาก Firebase Auth ต้องใช้ Admin SDK
      // ใน Flutter app ไม่สามารถลบผู้ใช้คนอื่นได้โดยตรง
      // ต้องทำผ่าน Firebase Admin SDK หรือ Firebase Console

      print('To delete user from Firebase Auth:');
      print('1. Go to Firebase Console');
      print('2. Authentication > Users');
      print('3. Find user: $email');
      print('4. Click delete');

      return false; // ไม่สามารถลบจาก Flutter app ได้
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }

  /// แสดงคำแนะนำสำหรับการจัดการ Admin user
  void showAdminManagementInstructions(String problemEmail) {
    print('\n=== การจัดการผู้ใช้ Admin: $problemEmail ===');
    print('');
    print('ตัวเลือกที่ 1: ลบสิทธิ์ Admin (แนะนำ)');
    print('- เก็บผู้ใช้ไว้ใน Firebase Auth');
    print('- แต่ลบสิทธิ์ Admin ออกจากระบบ');
    print('- ผู้ใช้สามารถใช้แอพได้ปกติแต่ไม่มีสิทธิ์ Admin');
    print('');
    print('ตัวเลือกที่ 2: ลบผู้ใช้ทั้งหมด');
    print('- ลบออกจาก Firebase Authentication');
    print('- ลบข้อมูลใน Firestore');
    print('- ผู้ใช้ต้องสมัครใหม่หากต้องการใช้แอพ');
    print('');
    print('คำแนะนำ: ใช้ตัวเลือกที่ 1 ก่อน เพราะปลอดภัยกว่า');
    print('==========================================\n');
  }
}
