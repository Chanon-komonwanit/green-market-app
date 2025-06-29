// lib/services/activity_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:green_market/models/activity.dart';

class ActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ชื่อ Collection
  static const String _activitiesCollection = 'activities';

  /// สร้างกิจกรรมใหม่
  Future<String> createActivity({
    required String title,
    required String description,
    required String imageUrl,
    required String province,
    required String locationDetails,
    required DateTime activityDateTime,
    required String contactInfo,
    required List<String> tags,
    required String activityType,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('กรุณาเข้าสู่ระบบก่อนสร้างกิจกรรม');
      }

      // สร้าง Activity object
      final activity = Activity(
        id: '', // จะถูกกำหนดโดย Firestore
        organizerId: user.uid,
        organizerName: user.displayName ?? 'ผู้ใช้',
        title: title,
        description: description,
        imageUrl: imageUrl,
        province: province,
        locationDetails: locationDetails,
        activityDateTime: activityDateTime,
        contactInfo: contactInfo,
        isApproved: false, // รอการอนุมัติ
        createdAt: DateTime.now(),
        tags: tags,
        activityType: activityType,
      );

      // บันทึกลง Firestore
      final docRef = await _firestore
          .collection(_activitiesCollection)
          .add(activity.toFirestore());

      print('✅ สร้างกิจกรรมสำเร็จ ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการสร้างกิจกรรม: $e');
      rethrow;
    }
  }

  /// ดึงกิจกรรมที่รออนุมัติ (สำหรับแอดมิน)
  Stream<List<Activity>> getPendingActivities() {
    return _firestore
        .collection(_activitiesCollection)
        .where('isApproved', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Activity.fromFirestore(doc)).toList());
  }

  /// ดึงกิจกรรมที่อนุมัติแล้วตามจังหวัด
  Stream<List<Activity>> getActivitiesByProvince(String province) {
    return _firestore
        .collection(_activitiesCollection)
        .where('isApproved', isEqualTo: true)
        .where('province', isEqualTo: province)
        .where('activityDateTime',
            isGreaterThan: Timestamp.now()) // เฉพาะกิจกรรมที่ยังมาไม่ถึง
        .orderBy('activityDateTime',
            descending: false) // เรียงตามวันที่ใกล้ที่สุดก่อน
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Activity.fromFirestore(doc)).toList());
  }

  /// ดึงกิจกรรมทั้งหมดที่อนุมัติแล้ว (สำหรับหน้าแรก)
  Stream<List<Activity>> getAllApprovedActivities() {
    return _firestore
        .collection(_activitiesCollection)
        .where('isApproved', isEqualTo: true)
        .where('activityDateTime', isGreaterThan: Timestamp.now())
        .orderBy('activityDateTime', descending: false)
        .limit(10) // จำกัดแค่ 10 รายการแรก
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Activity.fromFirestore(doc)).toList());
  }

  /// ดึงกิจกรรมที่ใกล้จะเริ่ม (ใน 24 ชั่วโมงข้างหน้า)
  Stream<List<Activity>> getUpcomingActivities() {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    return _firestore
        .collection(_activitiesCollection)
        .where('isApproved', isEqualTo: true)
        .where('activityDateTime', isGreaterThan: Timestamp.fromDate(now))
        .where('activityDateTime', isLessThan: Timestamp.fromDate(tomorrow))
        .orderBy('activityDateTime', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Activity.fromFirestore(doc)).toList());
  }

  /// ดึงกิจกรรมของผู้ใช้ปัจจุบัน
  Stream<List<Activity>> getMyActivities() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_activitiesCollection)
        .where('organizerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Activity.fromFirestore(doc)).toList());
  }

  /// อนุมัติกิจกรรม (สำหรับแอดมิน)
  Future<void> approveActivity(String activityId) async {
    try {
      await _firestore
          .collection(_activitiesCollection)
          .doc(activityId)
          .update({'isApproved': true});

      print('✅ อนุมัติกิจกรรมสำเร็จ ID: $activityId');
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการอนุมัติกิจกรรม: $e');
      rethrow;
    }
  }

  /// ปฏิเสธกิจกรรม (สำหรับแอดมิน)
  Future<void> rejectActivity(String activityId) async {
    try {
      await _firestore
          .collection(_activitiesCollection)
          .doc(activityId)
          .delete();

      print('✅ ปฏิเสธและลบกิจกรรมสำเร็จ ID: $activityId');
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการปฏิเสธกิจกรรม: $e');
      rethrow;
    }
  }

  /// ดึงข้อมูลกิจกรรมเดียว
  Future<Activity?> getActivityById(String activityId) async {
    try {
      final doc = await _firestore
          .collection(_activitiesCollection)
          .doc(activityId)
          .get();

      if (doc.exists) {
        return Activity.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการดึงข้อมูลกิจกรรม: $e');
      return null;
    }
  }

  /// อัปเดตกิจกรรม
  Future<void> updateActivity(
      String activityId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection(_activitiesCollection)
          .doc(activityId)
          .update(updates);

      print('✅ อัปเดตกิจกรรมสำเร็จ ID: $activityId');
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการอัปเดตกิจกรรม: $e');
      rethrow;
    }
  }

  /// ลบกิจกรรม
  Future<void> deleteActivity(String activityId) async {
    try {
      await _firestore
          .collection(_activitiesCollection)
          .doc(activityId)
          .delete();

      print('✅ ลบกิจกรรมสำเร็จ ID: $activityId');
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการลบกิจกรรม: $e');
      rethrow;
    }
  }

  /// ค้นหากิจกรรม
  Future<List<Activity>> searchActivities({
    String? keyword,
    String? province,
    String? activityType,
    List<String>? tags,
  }) async {
    try {
      Query query = _firestore
          .collection(_activitiesCollection)
          .where('isApproved', isEqualTo: true)
          .where('activityDateTime', isGreaterThan: Timestamp.now());

      // กรองตามจังหวัด
      if (province != null && province.isNotEmpty) {
        query = query.where('province', isEqualTo: province);
      }

      // กรองตามประเภทกิจกรรม
      if (activityType != null && activityType.isNotEmpty) {
        query = query.where('activityType', isEqualTo: activityType);
      }

      final snapshot =
          await query.orderBy('activityDateTime', descending: false).get();

      List<Activity> activities =
          snapshot.docs.map((doc) => Activity.fromFirestore(doc)).toList();

      // กรองตามคำค้นหา (ทำใน client เพราะ Firestore ไม่รองรับ full-text search)
      if (keyword != null && keyword.isNotEmpty) {
        final lowerKeyword = keyword.toLowerCase();
        activities = activities.where((activity) {
          return activity.title.toLowerCase().contains(lowerKeyword) ||
              activity.description.toLowerCase().contains(lowerKeyword) ||
              activity.locationDetails.toLowerCase().contains(lowerKeyword) ||
              activity.organizerName.toLowerCase().contains(lowerKeyword);
        }).toList();
      }

      // กรองตามแท็ก
      if (tags != null && tags.isNotEmpty) {
        activities = activities.where((activity) {
          return tags.any((tag) => activity.tags.contains(tag));
        }).toList();
      }

      return activities;
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการค้นหากิจกรรม: $e');
      return [];
    }
  }

  /// นับจำนวนกิจกรรมตามสถานะ
  Future<Map<String, int>> getActivityStats() async {
    try {
      // นับกิจกรรมที่รออนุมัติ
      final pendingSnapshot = await _firestore
          .collection(_activitiesCollection)
          .where('isApproved', isEqualTo: false)
          .get();

      // นับกิจกรรมที่อนุมัติแล้ว
      final approvedSnapshot = await _firestore
          .collection(_activitiesCollection)
          .where('isApproved', isEqualTo: true)
          .get();

      // นับกิจกรรมที่กำลังจะมาถึง
      final upcomingSnapshot = await _firestore
          .collection(_activitiesCollection)
          .where('isApproved', isEqualTo: true)
          .where('activityDateTime', isGreaterThan: Timestamp.now())
          .get();

      return {
        'pending': pendingSnapshot.docs.length,
        'approved': approvedSnapshot.docs.length,
        'upcoming': upcomingSnapshot.docs.length,
      };
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการดึงสถิติกิจกรรม: $e');
      return {
        'pending': 0,
        'approved': 0,
        'upcoming': 0,
      };
    }
  }
}
