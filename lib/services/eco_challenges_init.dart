// lib/services/eco_challenges_init.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service สำหรับสร้างข้อมูลตัวอย่างความท้าทาย Eco
class EcoChallengesInitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// สร้างข้อมูลความท้าทายเริ่มต้น
  Future<void> initializeSampleChallenges() async {
    final challenges = [
      {
        'title': '🌱 ปลูกต้นไม้ 5 ต้น',
        'description': 'ช่วยโลกโดยการปลูกต้นไม้อย่างน้อย 5 ต้นภายใน 7 วัน',
        'category': 'environment',
        'difficulty': 'easy',
        'duration': 7,
        'target': 5,
        'challengePoints': 100, // เปลี่ยนจาก reward เป็น challengePoints
        'unit': 'ต้น',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': '♻️ รีไซเคิลขยะ 10 ชิ้น',
        'description': 'แยกขยะรีไซเคิลและนำไปทิ้งให้ถูกต้อง',
        'category': 'recycle',
        'difficulty': 'easy',
        'duration': 7,
        'target': 10,
        'challengePoints': 80,
        'unit': 'ชิ้น',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': '🚴 ไปทำงานด้วยจักรยาน',
        'description': 'ใช้จักรยานแทนรถยนต์อย่างน้อย 5 วัน',
        'category': 'transport',
        'difficulty': 'medium',
        'duration': 14,
        'target': 5,
        'challengePoints': 150,
        'unit': 'วัน',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': '💡 ลดการใช้ไฟฟ้า',
        'description': 'ลดการใช้ไฟฟ้าในบ้าน ปิดไฟที่ไม่ใช้งาน',
        'category': 'energy',
        'difficulty': 'easy',
        'duration': 7,
        'target': 7,
        'challengePoints': 70,
        'unit': 'วัน',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': '🥗 กินอาหารมังสวิรัติ',
        'description': 'ลดการบริโภคเนื้อสัตว์ กินผักและผลไม้แทน',
        'category': 'food',
        'difficulty': 'medium',
        'duration': 7,
        'target': 5,
        'challengePoints': 120,
        'unit': 'มื้อ',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': '🚿 ประหยัดน้ำ',
        'description': 'ใช้น้ำให้น้อยลง อาบน้ำไม่เกิน 5 นาที',
        'category': 'water',
        'difficulty': 'easy',
        'duration': 7,
        'target': 7,
        'challengePoints': 80,
        'unit': 'วัน',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': '🛍️ ใช้ถุงผ้าแทนถุงพลาสติก',
        'description': 'พกถุงผ้าไปซื้อของทุกครั้ง ไม่ใช้ถุงพลาสติก',
        'category': 'waste',
        'difficulty': 'easy',
        'duration': 14,
        'target': 10,
        'challengePoints': 100,
        'unit': 'ครั้ง',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': '📱 ปิดอุปกรณ์อิเล็กทรอนิกส์',
        'description': 'ถอดปลั๊กอุปกรณ์ที่ไม่ใช้งานทุกวัน',
        'category': 'energy',
        'difficulty': 'easy',
        'duration': 7,
        'target': 7,
        'challengePoints': 90,
        'unit': 'วัน',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': '🌊 เก็บขยะริมชายหาด',
        'description': 'ร่วมกิจกรรมเก็บขยะชายหาดหรือริมน้ำ',
        'category': 'environment',
        'difficulty': 'medium',
        'duration': 7,
        'target': 2,
        'challengePoints': 200,
        'unit': 'ครั้ง',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': '🌿 สร้างสวนครัวเล็กๆ',
        'description': 'ปลูกผักสวนครัวเพื่อบริโภคเอง',
        'category': 'food',
        'difficulty': 'hard',
        'duration': 30,
        'target': 1,
        'challengePoints': 300,
        'unit': 'สวน',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    try {
      // เช็คว่ามีข้อมูลอยู่แล้วหรือไม่
      final existing =
          await _firestore.collection('eco_challenges').limit(1).get();

      if (existing.docs.isEmpty) {
        print('🌱 กำลังสร้างข้อมูลความท้าทาย Eco...');

        final batch = _firestore.batch();
        for (var challenge in challenges) {
          final docRef = _firestore.collection('eco_challenges').doc();
          batch.set(docRef, challenge);
        }

        await batch.commit();
        print('✅ สร้างข้อมูลความท้าทาย ${challenges.length} รายการสำเร็จ!');
      } else {
        print('ℹ️ มีข้อมูลความท้าทายอยู่แล้ว');
      }
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการสร้างข้อมูล: $e');
    }
  }

  /// สร้างข้อมูลตัวอย่างสำหรับ user challenges
  Future<void> createSampleUserChallenge(String userId) async {
    try {
      await _firestore.collection('user_challenges').add({
        'userId': userId,
        'challengeId': 'sample_challenge_1',
        'title': '🌱 ปลูกต้นไม้ 5 ต้น',
        'progress': 2,
        'target': 5,
        'status': 'in_progress',
        'startedAt': FieldValue.serverTimestamp(),
        'challengePoints': 100, // เปลี่ยนเป็น challengePoints
      });

      print('✅ สร้างความท้าทายตัวอย่างสำหรับผู้ใช้แล้ว');
    } catch (e) {
      print('❌ เกิดข้อผิดพลาด: $e');
    }
  }
}
