// lib/services/firebase_data_seeder.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseDataSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Seed sample data for testing
  static Future<void> seedSampleData() async {
    try {
      await _seedGreenActivities();
      await _seedInvestments();
      await _seedCommunityUpdates();
      await _seedEcoChallenges();
      print('Sample data seeded successfully');
    } catch (e) {
      print('Error seeding data: $e');
    }
  }

  static Future<void> _seedGreenActivities() async {
    final activities = [
      {
        'title': 'ปลูกต้นไม้ในชุมชน',
        'description': 'ร่วมปลูกต้นไม้เพื่อสร้างพื้นที่สีเขียวในชุมชน',
        'category': 'gardening',
        'ecoCoinsReward': 100,
        'startDate':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 3))),
        'endDate':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 10))),
        'participantCount': 25,
        'maxParticipants': 50,
        'isActive': true,
        'tags': ['ปลูกต้นไม้', 'ชุมชน', 'สิ่งแวดล้อม'],
        'requirements': {
          'age': 'ทุกวัย',
          'equipment': 'ไม่จำเป็น',
          'location': 'สวนสาธารณะ',
        },
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'system',
      },
      {
        'title': 'รักษาความสะอาดชายหาด',
        'description': 'ร่วมกิจกรรมเก็บขยะชายหาดเพื่อรักษาระบบนิเวศทางทะเล',
        'category': 'waste',
        'ecoCoinsReward': 150,
        'startDate':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 5))),
        'endDate':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 5))),
        'participantCount': 12,
        'maxParticipants': 30,
        'isActive': true,
        'tags': ['ทำความสะอาด', 'ชายหาด', 'ทะเล'],
        'requirements': {
          'age': '12+',
          'equipment': 'ถุงมือ ถุงขยะ',
          'location': 'ชายหาดบางแสน',
        },
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'system',
      },
      {
        'title': 'ประหยัดพลังงานในออฟฟิศ',
        'description': 'แคมเปญการประหยัดพลังงานในสถานที่ทำงาน',
        'category': 'energy',
        'ecoCoinsReward': 80,
        'startDate':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
        'endDate':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        'participantCount': 45,
        'maxParticipants': 100,
        'isActive': true,
        'tags': ['ประหยัดพลังงาน', 'ออฟฟิศ', 'งาน'],
        'requirements': {
          'age': 'ทุกวัย',
          'equipment': 'ไม่จำเป็น',
          'location': 'ออนไลน์',
        },
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'system',
      },
    ];

    for (var activity in activities) {
      await _firestore.collection('green_activities').add(activity);
    }
  }

  static Future<void> _seedInvestments() async {
    final investments = [
      {
        'title': 'โซลาร์ฟาร์มขนาดเล็ก',
        'description': 'การลงทุนในโซลาร์ฟาร์มขนาดเล็กเพื่อการผลิตไฟฟ้าสะอาด',
        'category': 'renewable',
        'minInvestment': 5000.0,
        'targetAmount': 500000.0,
        'currentAmount': 250000.0,
        'expectedReturn': 8.5,
        'duration': 36,
        'riskLevel': 'medium',
        'isActive': true,
        'tags': ['พลังงานแสงอาทิตย์', 'ไฟฟ้า', 'ยั่งยืน'],
        'details': {
          'location': 'จังหวัดลพบุรี',
          'capacity': '500 kW',
          'roi': '8.5% ต่อปี',
          'timeline': '3 ปี',
        },
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'system',
      },
      {
        'title': 'โครงการจัดการขยะชุมชน',
        'description': 'การลงทุนในระบบจัดการขยะอัจฉริยะเพื่อชุมชน',
        'category': 'waste',
        'minInvestment': 2000.0,
        'targetAmount': 300000.0,
        'currentAmount': 180000.0,
        'expectedReturn': 7.2,
        'duration': 24,
        'riskLevel': 'low',
        'isActive': true,
        'tags': ['จัดการขยะ', 'ชุมชน', 'เทคโนโลยี'],
        'details': {
          'location': 'กรุงเทพมหานคร',
          'technology': 'AI Sorting',
          'impact': 'ลดขยะ 80%',
          'timeline': '2 ปี',
        },
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'system',
      },
      {
        'title': 'ป่าไผ่เพื่อคาร์บอนเครดิต',
        'description': 'การลงทุนในการปลูกป่าไผ่เพื่อสร้างคาร์บอนเครดิต',
        'category': 'carbon',
        'minInvestment': 10000.0,
        'targetAmount': 1000000.0,
        'currentAmount': 150000.0,
        'expectedReturn': 12.0,
        'duration': 60,
        'riskLevel': 'high',
        'isActive': true,
        'tags': ['ป่าไผ่', 'คาร์บอน', 'ระยะยาว'],
        'details': {
          'location': 'จังหวัดกาญจนบุรี',
          'area': '1,000 ไร่',
          'carbon': '50,000 ตัน CO2',
          'timeline': '5 ปี',
        },
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'system',
      },
    ];

    for (var investment in investments) {
      await _firestore.collection('green_investments').add(investment);
    }
  }

  static Future<void> _seedCommunityUpdates() async {
    final updates = [
      {
        'title': 'ยินดีด้วย! ชุมชนเก็บขยะได้ 1 ตัน',
        'description': 'สมาชิกชุมชนร่วมกันเก็บขยะได้ถึง 1 ตันในเดือนที่ผ่านมา',
        'type': 'activity',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'โครงการใหม่: การลงทุนพลังงานลม',
        'description': 'เปิดโอกาสการลงทุนในโครงการพลังงานลมใหม่',
        'type': 'investment',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'ความท้าทายใหม่: ปั่นจักรยาน 30 วัน',
        'description': 'ลองความท้าทายใหม่ในการปั่นจักรยานแทนการใช้รถยนต์',
        'type': 'challenge',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'การอัปเดตแพลตฟอร์ม',
        'description': 'เพิ่มฟีเจอร์ใหม่ในระบบติดตามคาร์บอนฟุตพรินต์',
        'type': 'general',
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (var update in updates) {
      await _firestore.collection('community_updates').add(update);
    }
  }

  static Future<void> _seedEcoChallenges() async {
    final challenges = [
      {
        'title': 'ไม่ใช้ถุงพลาสติก 7 วัน',
        'description': 'ท้าทายตัวเองให้ไม่ใช้ถุงพลาสติกเป็นเวลา 7 วัน',
        'category': 'waste',
        'difficulty': 'easy',
        'duration': 7,
        'target': 7,
        'reward': 100,
        'isActive': true,
        'requirements': {
          'equipment': 'ถุงผ้า',
          'commitment': '7 วัน',
        },
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'system',
      },
      {
        'title': 'ประหยัดน้ำ 30 วัน',
        'description': 'ลดการใช้น้ำอย่างน้อย 20% เป็นเวลา 30 วัน',
        'category': 'water',
        'difficulty': 'medium',
        'duration': 30,
        'target': 30,
        'reward': 200,
        'isActive': true,
        'requirements': {
          'equipment': 'เครื่องตรวจวัดน้ำ',
          'commitment': '30 วัน',
        },
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'system',
      },
      {
        'title': 'ปั่นจักรยานไปทำงาน',
        'description': 'ปั่นจักรยานไปทำงานอย่างน้อย 15 วันในเดือน',
        'category': 'transport',
        'difficulty': 'medium',
        'duration': 30,
        'target': 15,
        'reward': 250,
        'isActive': true,
        'requirements': {
          'equipment': 'จักรยาน',
          'commitment': '15 วันในเดือน',
        },
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'system',
      },
      {
        'title': 'ปลูกผักออร์แกนิค',
        'description': 'ปลูกผักออร์แกนิคเองที่บ้านเป็นเวลา 90 วัน',
        'category': 'gardening',
        'difficulty': 'hard',
        'duration': 90,
        'target': 90,
        'reward': 500,
        'isActive': true,
        'requirements': {
          'equipment': 'กระถาง เมล็ดพันธุ์',
          'commitment': '90 วัน',
        },
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'system',
      },
    ];

    for (var challenge in challenges) {
      await _firestore.collection('eco_challenges').add(challenge);
    }
  }

  // Method to clear all sample data
  static Future<void> clearSampleData() async {
    try {
      final collections = [
        'green_activities',
        'green_investments',
        'community_updates',
        'eco_challenges',
      ];

      for (String collection in collections) {
        final snapshot = await _firestore.collection(collection).get();
        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }
      }
      print('Sample data cleared successfully');
    } catch (e) {
      print('Error clearing data: $e');
    }
  }
}
