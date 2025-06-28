// lib/models/sustainable_activity.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SustainableActivity {
  final String id;
  final String title;
  final String description;
  final String imageUrl; // This might be null in Firestore
  final String province;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final String organizerId;
  final String organizerName;
  final String contactInfo;
  final String submissionStatus; // 'pending', 'approved', 'rejected'
  final String? rejectionReason;
  final bool isActive;
  final Timestamp createdAt;
  final List<String> participants; // List of user IDs

  SustainableActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.province,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.organizerId,
    required this.organizerName,
    required this.contactInfo,
    this.submissionStatus = 'pending',
    this.rejectionReason,
    this.isActive = true,
    required this.createdAt,
    this.participants = const [],
  });

  factory SustainableActivity.fromMap(Map<String, dynamic> map) {
    return SustainableActivity(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? 'Unnamed Activity',
      description: map['description'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ??
          'https://via.placeholder.com/150', // Robustify
      province: map['province'] as String? ?? '',
      location: map['location'] as String? ?? '',
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      organizerId: map['organizerId'] as String? ?? '',
      organizerName: map['organizerName'] as String? ?? 'Unknown Organizer',
      contactInfo: map['contactInfo'] as String? ?? '',
      submissionStatus: map['submissionStatus'] as String? ?? 'pending',
      rejectionReason: map['rejectionReason'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?) ?? Timestamp.now(),
      participants: List<String>.from(map['participants'] as List? ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'province': province,
      'location': location,
      'startDate': startDate,
      'endDate': endDate,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'contactInfo': contactInfo,
      'submissionStatus': submissionStatus,
      'rejectionReason': rejectionReason,
      'isActive': isActive,
      'createdAt': createdAt,
      'participants': participants,
    };
  }

  SustainableActivity copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? province,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    String? organizerId,
    String? organizerName,
    String? contactInfo,
    String? submissionStatus,
    String? rejectionReason,
    bool? isActive,
    Timestamp? createdAt,
    List<String>? participants,
  }) {
    return SustainableActivity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      province: province ?? this.province,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      contactInfo: contactInfo ?? this.contactInfo,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      participants: participants ?? this.participants,
    );
  }
}
