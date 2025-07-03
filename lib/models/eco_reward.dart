// lib/models/eco_reward.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class EcoReward {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final double requiredCoins;
  final int quantity; // จำนวนรางวัลที่มีให้แลก
  final int redeemedCount; // จำนวนที่แลกไปแล้ว
  final bool isActive;
  final DateTime createdAt;
  final DateTime? expiryDate;
  final String rewardType; // 'physical', 'digital', 'discount', 'service'
  final Map<String, dynamic>? metadata; // ข้อมูลเพิ่มเติมตามประเภทรางวัล

  EcoReward({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.requiredCoins,
    required this.quantity,
    this.redeemedCount = 0,
    this.isActive = true,
    required this.createdAt,
    this.expiryDate,
    this.rewardType = 'physical',
    this.metadata,
  });

  bool get isAvailable =>
      isActive &&
      redeemedCount < quantity &&
      (expiryDate == null || DateTime.now().isBefore(expiryDate!));

  int get remainingQuantity => quantity - redeemedCount;

  factory EcoReward.fromMap(Map<String, dynamic> map, String documentId) {
    return EcoReward(
      id: documentId,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      requiredCoins: (map['requiredCoins'] as num?)?.toDouble() ?? 0.0,
      quantity: map['quantity'] as int? ?? 0,
      redeemedCount: map['redeemedCount'] as int? ?? 0,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiryDate: (map['expiryDate'] as Timestamp?)?.toDate(),
      rewardType: map['rewardType'] as String? ?? 'physical',
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'requiredCoins': requiredCoins,
      'quantity': quantity,
      'redeemedCount': redeemedCount,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'rewardType': rewardType,
      'metadata': metadata,
    };
  }

  EcoReward copyWith({
    String? title,
    String? description,
    String? imageUrl,
    double? requiredCoins,
    int? quantity,
    int? redeemedCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? expiryDate,
    String? rewardType,
    Map<String, dynamic>? metadata,
  }) {
    return EcoReward(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      requiredCoins: requiredCoins ?? this.requiredCoins,
      quantity: quantity ?? this.quantity,
      redeemedCount: redeemedCount ?? this.redeemedCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      expiryDate: expiryDate ?? this.expiryDate,
      rewardType: rewardType ?? this.rewardType,
      metadata: metadata ?? this.metadata,
    );
  }
}

// Model สำหรับประวัติการแลกรางวัล
class RewardRedemption {
  final String id;
  final String userId;
  final String rewardId;
  final String rewardTitle;
  final int coinsUsed;
  final DateTime redeemedAt;
  final String status; // 'pending', 'approved', 'delivered', 'cancelled'
  final String? deliveryAddress;
  final String? notes;

  RewardRedemption({
    required this.id,
    required this.userId,
    required this.rewardId,
    required this.rewardTitle,
    required this.coinsUsed,
    required this.redeemedAt,
    this.status = 'pending',
    this.deliveryAddress,
    this.notes,
  });

  factory RewardRedemption.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return RewardRedemption(
      id: documentId,
      userId: map['userId'] as String? ?? '',
      rewardId: map['rewardId'] as String? ?? '',
      rewardTitle: map['rewardTitle'] as String? ?? '',
      coinsUsed: map['coinsUsed'] as int? ?? 0,
      redeemedAt: (map['redeemedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] as String? ?? 'pending',
      deliveryAddress: map['deliveryAddress'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'rewardId': rewardId,
      'rewardTitle': rewardTitle,
      'coinsUsed': coinsUsed,
      'redeemedAt': Timestamp.fromDate(redeemedAt),
      'status': status,
      'deliveryAddress': deliveryAddress,
      'notes': notes,
    };
  }
}
