// lib/utils/community_sample_data.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/community_post.dart';
import '../models/community_comment.dart';

class CommunitySampleData {
  static List<Map<String, dynamic>> getSamplePosts() {
    final now = DateTime.now();

    return [
      {
        'id': 'post1',
        'userId': 'user1',
        'userDisplayName': 'สวนผักออร์แกนิค',
        'userProfileImage':
            'https://via.placeholder.com/50/4CAF50/FFFFFF?text=SP',
        'content':
            'วันนี้เก็บเกี่ยวผักใหม่จากสวนออร์แกนิคของเรา 🥬🥕 สด ใส ปลอดสารพิษ ใครสนใจสั่งได้เลยครับ #ผักออร์แกนิค #ปลอดสารพิษ #รักษ์โลก',
        'imageUrls': [
          'https://images.unsplash.com/photo-1566385101042-1a0aa0c1268c?w=400',
          'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=400',
        ],
        'videoUrl': null,
        'likes': ['user2', 'user3'],
        'commentCount': 3,
        'shareCount': 1,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
        'updatedAt': null,
        'isActive': true,
        'tags': ['ผักออร์แกนิค', 'ปลอดสารพิษ', 'รักษ์โลก'],
      },
      {
        'id': 'post2',
        'userId': 'user2',
        'userDisplayName': 'Green Living',
        'userProfileImage':
            'https://via.placeholder.com/50/8BC34A/FFFFFF?text=GL',
        'content':
            'เคล็ดลับการลดขยะในครัวเรือน 🌱\n\n1. ใช้ถุงผ้าแทนถุงพลาสติก\n2. คัดแยกขยะก่อนทิ้ง\n3. ทำปุ๋ยหมักจากเศษผัก\n4. ใช้ผลิตภัณฑ์รีฟิลล์\n\nมาร่วมกันรักษ์โลกกันเถอะ! 💚',
        'imageUrls': [
          'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?w=400',
        ],
        'videoUrl': null,
        'likes': ['user1', 'user3', 'user4'],
        'commentCount': 5,
        'shareCount': 2,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 6))),
        'updatedAt': null,
        'isActive': true,
        'tags': ['ลดขยะ', 'รักษ์โลก', 'ZeroWaste'],
      },
      {
        'id': 'post3',
        'userId': 'user3',
        'userDisplayName': 'EcoWarrior',
        'userProfileImage':
            'https://via.placeholder.com/50/2E7D32/FFFFFF?text=EW',
        'content':
            'สถานการณ์โลกร้อนวันนี้น่าห่วงมาก 🌡️ แต่เราทุกคนสามารถช่วยได้ด้วยการ:\n\n- ลดการใช้พลังงาน\n- เดินทางด้วยขนส่งสาธารณะ\n- ปลูกต้นไม้\n- ใช้ผลิตภัณฑ์เป็นมิตรกับสิ่งแวดล้อม\n\n#SaveTheEarth #ClimateChange',
        'imageUrls': [],
        'videoUrl': null,
        'likes': ['user1', 'user2'],
        'commentCount': 8,
        'shareCount': 4,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'updatedAt': null,
        'isActive': true,
        'tags': ['SaveTheEarth', 'ClimateChange', 'โลกร้อน'],
      },
      {
        'id': 'post4',
        'userId': 'user4',
        'userDisplayName': 'บ้านสีเขียว',
        'userProfileImage':
            'https://via.placeholder.com/50/66BB6A/FFFFFF?text=บส',
        'content':
            'Review ผลิตภัณฑ์ทำความสะอาดธรรมชาติที่ทำเองได้ง่ายๆ ✨\n\n🍋 น้ำมะนาว + เบกกิ้งโซดา = สำหรับทำความสะอาดอ่างล้างจาน\n🍃 น้ำส้มสายชู + น้ำ = สำหรับเช็ดกระจก\n\nปลอดภัย ประหยัด และไม่ทำลายสิ่งแวดล้อม! 🌿',
        'imageUrls': [
          'https://images.unsplash.com/photo-1563453392212-326f5e854473?w=400',
          'https://images.unsplash.com/photo-1584464491033-06628f3a6b7b?w=400',
          'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400',
        ],
        'videoUrl': null,
        'likes': ['user1', 'user2', 'user3'],
        'commentCount': 6,
        'shareCount': 3,
        'createdAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 12)),
        ),
        'updatedAt': null,
        'isActive': true,
        'tags': ['DIY', 'ธรรมชาติ', 'ทำความสะอาด'],
      },
      {
        'id': 'post5',
        'userId': 'user5',
        'userDisplayName': 'รักโลกสีเขียว',
        'userProfileImage':
            'https://via.placeholder.com/50/4CAF50/FFFFFF?text=รส',
        'content':
            'วันนี้ไปงาน Green Market ที่ JJ Mall มีสินค้าเป็นมิตรกับสิ่งแวดล้อมเยอะมาก! 🛍️\n\nซื้อผลิตภัณฑ์หลายอย่าง:\n- แชมพูแท่งออร์แกนิค\n- ถ้วยกาแฟ reusable\n- ผ้าเช็ดหน้าจากไผ่\n\nแนะนำให้ไปเดินดูกันครับ มีของดีๆ เยอะ! 💚',
        'imageUrls': [
          'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=400',
        ],
        'videoUrl': null,
        'likes': ['user1', 'user3', 'user4'],
        'commentCount': 4,
        'shareCount': 1,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 8))),
        'updatedAt': null,
        'isActive': true,
        'tags': ['GreenMarket', 'ช้อปปิ้ง', 'สินค้าเขียว'],
      },
    ];
  }

  static List<Map<String, dynamic>> getSampleComments(String postId) {
    final now = DateTime.now();

    return [
      {
        'id': 'comment1_$postId',
        'postId': postId,
        'userId': 'user2',
        'userDisplayName': 'Green Living',
        'userProfileImage':
            'https://via.placeholder.com/30/8BC34A/FFFFFF?text=GL',
        'content': 'เก่งมากค่ะ! อยากได้สูตรการดูแลผักด้วย 🌱',
        'likes': ['user1', 'user3'],
        'parentCommentId': null,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 1))),
        'isActive': true,
      },
      {
        'id': 'comment2_$postId',
        'postId': postId,
        'userId': 'user3',
        'userDisplayName': 'EcoWarrior',
        'userProfileImage':
            'https://via.placeholder.com/30/2E7D32/FFFFFF?text=EW',
        'content': 'สนใจสั่งผักครับ ราคาเท่าไหร่?',
        'likes': ['user1'],
        'parentCommentId': null,
        'createdAt': Timestamp.fromDate(
          now.subtract(const Duration(minutes: 30)),
        ),
        'isActive': true,
      },
      {
        'id': 'comment3_$postId',
        'postId': postId,
        'userId': 'user1',
        'userDisplayName': 'สวนผักออร์แกนิค',
        'userProfileImage':
            'https://via.placeholder.com/30/4CAF50/FFFFFF?text=SP',
        'content':
            'ขอบคุณครับ! ส่วนราคาและรายละเอียดส่งข้อความมาคุยกันได้เลยครับ 😊',
        'likes': ['user2', 'user3'],
        'parentCommentId': 'comment2_$postId',
        'createdAt': Timestamp.fromDate(
          now.subtract(const Duration(minutes: 15)),
        ),
        'isActive': true,
      },
    ];
  }

  static List<Map<String, dynamic>> getSampleUsers() {
    return [
      {
        'id': 'user1',
        'displayName': 'สวนผักออร์แกนิค',
        'photoUrl': 'https://via.placeholder.com/100/4CAF50/FFFFFF?text=SP',
        'bio': 'ปลูกผักออร์แกนิคด้วยใจรัก เพื่อสุขภาพที่ดีของทุกคน 🌱',
        'ecoCoins': 150.5,
      },
      {
        'id': 'user2',
        'displayName': 'Green Living',
        'photoUrl': 'https://via.placeholder.com/100/8BC34A/FFFFFF?text=GL',
        'bio': 'แชร์ไอเดียการใช้ชีวิตแบบ Zero Waste และรักษ์สิ่งแวดล้อม 💚',
        'ecoCoins': 230.2,
      },
      {
        'id': 'user3',
        'displayName': 'EcoWarrior',
        'photoUrl': 'https://via.placeholder.com/100/2E7D32/FFFFFF?text=EW',
        'bio': 'นักสู้เพื่อสิ่งแวดล้อม มุ่งมั่นลดภาวะโลกร้อน 🌍',
        'ecoCoins': 89.7,
      },
      {
        'id': 'user4',
        'displayName': 'บ้านสีเขียว',
        'photoUrl': 'https://via.placeholder.com/100/66BB6A/FFFFFF?text=บส',
        'bio': 'DIY ผลิตภัณฑ์ธรรมชาติ สร้างบ้านเป็นมิตรกับสิ่งแวดล้อม 🏡',
        'ecoCoins': 45.3,
      },
      {
        'id': 'user5',
        'displayName': 'รักโลกสีเขียว',
        'photoUrl': 'https://via.placeholder.com/100/4CAF50/FFFFFF?text=รส',
        'bio': 'รีวิวสินค้าเป็นมิตรกับสิ่งแวดล้อม ชอปปิ้งอย่างมีสติ 🛍️',
        'ecoCoins': 78.1,
      },
    ];
  }
}
