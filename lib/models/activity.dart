// lib/models/activity.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  final String id;
  final String organizerId;
  final String organizerName;
  final String title;
  final String description;
  final String imageUrl;
  final String province;
  final String locationDetails;
  final DateTime activityDateTime;
  final String contactInfo;
  final bool isApproved;
  final DateTime createdAt;
  final List<String> tags; // เพิ่มแท็กสำหรับหมวดหมู่กิจกรรม
  final String activityType; // ประเภทกิจกรรม (สิ่งแวดล้อม, สังคม, การศึกษา ฯลฯ)

  Activity({
    required this.id,
    required this.organizerId,
    required this.organizerName,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.province,
    required this.locationDetails,
    required this.activityDateTime,
    required this.contactInfo,
    required this.isApproved,
    required this.createdAt,
    this.tags = const [],
    this.activityType = 'สิ่งแวดล้อม',
  });

  // สร้าง Activity จาก Firestore Document
  factory Activity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Activity(
      id: doc.id,
      organizerId: data['organizerId'] ?? '',
      organizerName: data['organizerName'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      province: data['province'] ?? '',
      locationDetails: data['locationDetails'] ?? '',
      activityDateTime: (data['activityDateTime'] as Timestamp).toDate(),
      contactInfo: data['contactInfo'] ?? '',
      isApproved: data['isApproved'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      tags: List<String>.from(data['tags'] ?? []),
      activityType: data['activityType'] ?? 'สิ่งแวดล้อม',
    );
  }

  // แปลง Activity เป็น Map สำหรับบันทึกใน Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'organizerId': organizerId,
      'organizerName': organizerName,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'province': province,
      'locationDetails': locationDetails,
      'activityDateTime': Timestamp.fromDate(activityDateTime),
      'contactInfo': contactInfo,
      'isApproved': isApproved,
      'createdAt': Timestamp.fromDate(createdAt),
      'tags': tags,
      'activityType': activityType,
    };
  }

  // สำเนา Activity พร้อมอัปเดตฟิลด์บางอย่าง
  Activity copyWith({
    String? id,
    String? organizerId,
    String? organizerName,
    String? title,
    String? description,
    String? imageUrl,
    String? province,
    String? locationDetails,
    DateTime? activityDateTime,
    String? contactInfo,
    bool? isApproved,
    DateTime? createdAt,
    List<String>? tags,
    String? activityType,
  }) {
    return Activity(
      id: id ?? this.id,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      province: province ?? this.province,
      locationDetails: locationDetails ?? this.locationDetails,
      activityDateTime: activityDateTime ?? this.activityDateTime,
      contactInfo: contactInfo ?? this.contactInfo,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
      activityType: activityType ?? this.activityType,
    );
  }

  // ตรวจสอบว่ากิจกรรมนี้ยังไม่หมดเวลาหรือไม่
  bool get isActive => activityDateTime.isAfter(DateTime.now());

  // ตรวจสอบว่ากิจกรรมนี้เริ่มใน 24 ชั่วโมงข้างหน้าหรือไม่
  bool get isStartingSoon {
    final now = DateTime.now();
    final timeDiff = activityDateTime.difference(now);
    return timeDiff.inHours <= 24 && timeDiff.inHours >= 0;
  }

  // แปลงวันที่เป็นรูปแบบที่อ่านง่าย
  String get formattedDate {
    final months = [
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม'
    ];

    return '${activityDateTime.day} ${months[activityDateTime.month - 1]} ${activityDateTime.year + 543}';
  }

  // แปลงเวลาเป็นรูปแบบที่อ่านง่าย
  String get formattedTime {
    return '${activityDateTime.hour.toString().padLeft(2, '0')}:${activityDateTime.minute.toString().padLeft(2, '0')} น.';
  }

  @override
  String toString() {
    return 'Activity(id: $id, title: $title, province: $province, isApproved: $isApproved, activityDateTime: $activityDateTime)';
  }
}

// รายชื่อจังหวัดทั้งหมดในประเทศไทย
class ThaiProvinces {
  static const List<String> all = [
    'กรุงเทพมหานคร',
    'กระบี่',
    'กาญจนบุรี',
    'กาฬสินธุ์',
    'กำแพงเพชร',
    'ขอนแก่น',
    'จันทบุรี',
    'ฉะเชิงเทรา',
    'ชลบุรี',
    'ชัยนาท',
    'ชัยภูมิ',
    'ชุมพร',
    'เชียงราย',
    'เชียงใหม่',
    'ตรัง',
    'ตราด',
    'ตาก',
    'นครนายก',
    'นครปฐม',
    'นครพนม',
    'นครราชสีมา',
    'นครศรีธรรมราช',
    'นครสวรรค์',
    'นนทบุรี',
    'นราธิวาส',
    'น่าน',
    'บึงกาฬ',
    'บุรีรัมย์',
    'ปทุมธานี',
    'ประจวบคีรีขันธ์',
    'ปราจีนบุรี',
    'ปัตตานี',
    'พระนครศรีอยุธยา',
    'พังงา',
    'พัทลุง',
    'พิจิตร',
    'พิษณุโลก',
    'เพชรบุรี',
    'เพชรบูรณ์',
    'แพร่',
    'ภูเก็ต',
    'มหาสารคาม',
    'มุกดาหาร',
    'แม่ฮ่องสอน',
    'ยโสธร',
    'ยะลา',
    'ร้อยเอ็ด',
    'ระนอง',
    'ระยอง',
    'ราชบุรี',
    'ลพบุรี',
    'ลำปาง',
    'ลำพูน',
    'เลย',
    'ศรีสะเกษ',
    'สกลนคร',
    'สงขลา',
    'สตูล',
    'สมุทรปราการ',
    'สมุทรสงคราม',
    'สมุทรสาคร',
    'สระแก้ว',
    'สระบุรี',
    'สิงห์บุรี',
    'สุโขทัย',
    'สุพรรณบุรี',
    'สุราษฎร์ธานี',
    'สุรินทร์',
    'หนองคาย',
    'หนองบัวลำภู',
    'อ่างทอง',
    'อำนาจเจริญ',
    'อุดรธานี',
    'อุตรดิตถ์',
    'อุทัยธานี',
    'อุบลราชธานี',
  ];

  // จัดกลุ่มจังหวัดตามภูมิภาค
  static const Map<String, List<String>> byRegion = {
    'ภาคเหนือ': [
      'เชียงใหม่',
      'เชียงราย',
      'แม่ฮ่องสอน',
      'น่าน',
      'แพร่',
      'ลำปาง',
      'ลำพูน',
      'อุตรดิตถ์',
      'สุโขทัย',
      'ตาก',
      'พิษณุโลก',
      'พิจิตร',
      'เพชรบูรณ์',
      'กำแพงเพชร',
      'นครสวรรค์',
      'อุทัยธานี',
      'ชัยนาท',
    ],
    'ภาคกลาง': [
      'กรุงเทพมหานคร',
      'นนทบุรี',
      'ปทุมธานี',
      'พระนครศรีอยุธยา',
      'อ่างทอง',
      'ลพบุรี',
      'สิงห์บุรี',
      'ชัยนาท',
      'สระบุรี',
      'นครนายก',
      'ปราจีนบุรี',
      'ฉะเชิงเทรา',
      'สมุทรปราการ',
      'สมุทรสาคร',
      'สมุทรสงคราม',
      'นครปฐม',
      'กาญจนบุรี',
      'ราชบุรี',
      'เพชรบุรี',
      'ประจวบคีรีขันธ์',
    ],
    'ภาคตะวันออก': [
      'ชลบุรี',
      'ระยอง',
      'จันทบุรี',
      'ตราด',
      'สระแก้ว',
    ],
    'ภาคตะวันออกเหนือ': [
      'นครราชสีมา',
      'บุรีรัมย์',
      'สุรินทร์',
      'ศรีสะเกษ',
      'อุบลราชธานี',
      'ยโสธร',
      'ชัยภูมิ',
      'อำนาจเจริญ',
      'หนองบัวลำภู',
      'ขอนแก่น',
      'อุดรธานี',
      'เลย',
      'หนองคาย',
      'บึงกาฬ',
      'สกลนคร',
      'นครพนม',
      'มุกดาหาร',
      'ร้อยเอ็ด',
      'กาฬสินธุ์',
      'มหาสารคาม',
    ],
    'ภาคใต้': [
      'นครศรีธรรมราช',
      'กระบี่',
      'พังงา',
      'ภูเก็ต',
      'สุราษฎร์ธานี',
      'ระนอง',
      'ชุมพร',
      'สงขลา',
      'สตูล',
      'ตรัง',
      'พัทลุง',
      'ปัตตานี',
      'ยะลา',
      'นราธิวาส',
    ],
  };
}

// ประเภทกิจกรรม
class ActivityTypes {
  static const List<String> all = [
    'สิ่งแวดล้อม',
    'ปลูกป่า',
    'ทำความสะอาด',
    'รีไซเคิล',
    'อนุรักษ์น้ำ',
    'ลดโลกร้อน',
    'เกษตรอินทรีย์',
    'การศึกษา',
    'ช่วยเหลือสังคม',
    'บริจาค',
    'อื่นๆ',
  ];

  static Map<String, String> get icons => {
        'สิ่งแวดล้อม': '🌱',
        'ปลูกป่า': '🌳',
        'ทำความสะอาด': '🧹',
        'รีไซเคิล': '♻️',
        'อนุรักษ์น้ำ': '💧',
        'ลดโลกร้อน': '🌍',
        'เกษตรอินทรีย์': '🌾',
        'การศึกษา': '📚',
        'ช่วยเหลือสังคม': '🤝',
        'บริจาค': '❤️',
        'อื่นๆ': '📝',
      };
}
