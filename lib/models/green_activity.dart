// lib/models/green_activity.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class GreenActivity {
  final String id;
  final String title;
  final String description;
  final String category;
  final double ecoCoinsReward;
  final DateTime startDate;
  final DateTime endDate;
  final int participantCount;
  final int maxParticipants;
  final bool isActive;
  final String? imageUrl;
  final List<String> tags;
  final Map<String, dynamic> requirements;
  final DateTime createdAt;
  final String createdBy;

  GreenActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.ecoCoinsReward,
    required this.startDate,
    required this.endDate,
    required this.participantCount,
    required this.maxParticipants,
    required this.isActive,
    this.imageUrl,
    required this.tags,
    required this.requirements,
    required this.createdAt,
    required this.createdBy,
  });

  factory GreenActivity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GreenActivity(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'general',
      ecoCoinsReward: (data['ecoCoinsReward'] ?? 0).toDouble(),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      participantCount: data['participantCount'] ?? 0,
      maxParticipants: data['maxParticipants'] ?? 100,
      isActive: data['isActive'] ?? true,
      imageUrl: data['imageUrl'],
      tags: List<String>.from(data['tags'] ?? []),
      requirements: data['requirements'] ?? {},
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'ecoCoinsReward': ecoCoinsReward,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'participantCount': participantCount,
      'maxParticipants': maxParticipants,
      'isActive': isActive,
      'imageUrl': imageUrl,
      'tags': tags,
      'requirements': requirements,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  GreenActivity copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    double? ecoCoinsReward,
    DateTime? startDate,
    DateTime? endDate,
    int? participantCount,
    int? maxParticipants,
    bool? isActive,
    String? imageUrl,
    List<String>? tags,
    Map<String, dynamic>? requirements,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return GreenActivity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      ecoCoinsReward: ecoCoinsReward ?? this.ecoCoinsReward,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      participantCount: participantCount ?? this.participantCount,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      requirements: requirements ?? this.requirements,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

class ActivityCategory {
  static const String recycling = 'recycling';
  static const String energy = 'energy';
  static const String transport = 'transport';
  static const String waste = 'waste';
  static const String water = 'water';
  static const String education = 'education';
  static const String community = 'community';
  static const String gardening = 'gardening';
  static const String general = 'general';

  static List<String> get allCategories => [
        recycling,
        energy,
        transport,
        waste,
        water,
        education,
        community,
        gardening,
        general,
      ];

  static String getCategoryName(String category) {
    switch (category) {
      case recycling:
        return 'รีไซเคิล';
      case energy:
        return 'พลังงาน';
      case transport:
        return 'การขนส่ง';
      case waste:
        return 'จัดการขยะ';
      case water:
        return 'อนุรักษ์น้ำ';
      case education:
        return 'การศึกษา';
      case community:
        return 'ชุมชน';
      case gardening:
        return 'ทำสวน';
      case general:
        return 'ทั่วไป';
      default:
        return 'ทั่วไป';
    }
  }
}
