// lib/models/reward_redemption.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class RewardRedemption {
  final String id;
  final String userId;
  final String rewardId;
  final String rewardTitle;
  final double coinsUsed;
  final String status; // 'pending', 'approved', 'delivered', 'cancelled'
  final DateTime redeemedAt;
  final DateTime? approvedAt;
  final DateTime? deliveredAt;
  final String? notes;
  final String? adminNotes;

  RewardRedemption({
    required this.id,
    required this.userId,
    required this.rewardId,
    required this.rewardTitle,
    required this.coinsUsed,
    required this.status,
    required this.redeemedAt,
    this.approvedAt,
    this.deliveredAt,
    this.notes,
    this.adminNotes,
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
      coinsUsed: (map['coinsUsed'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'pending',
      redeemedAt: (map['redeemedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (map['approvedAt'] as Timestamp?)?.toDate(),
      deliveredAt: (map['deliveredAt'] as Timestamp?)?.toDate(),
      notes: map['notes'] as String?,
      adminNotes: map['adminNotes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'rewardId': rewardId,
      'rewardTitle': rewardTitle,
      'coinsUsed': coinsUsed,
      'status': status,
      'redeemedAt': Timestamp.fromDate(redeemedAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'deliveredAt': deliveredAt != null
          ? Timestamp.fromDate(deliveredAt!)
          : null,
      'notes': notes,
      'adminNotes': adminNotes,
    };
  }

  RewardRedemption copyWith({
    String? id,
    String? userId,
    String? rewardId,
    String? rewardTitle,
    double? coinsUsed,
    String? status,
    DateTime? redeemedAt,
    DateTime? approvedAt,
    DateTime? deliveredAt,
    String? notes,
    String? adminNotes,
  }) {
    return RewardRedemption(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      rewardId: rewardId ?? this.rewardId,
      rewardTitle: rewardTitle ?? this.rewardTitle,
      coinsUsed: coinsUsed ?? this.coinsUsed,
      status: status ?? this.status,
      redeemedAt: redeemedAt ?? this.redeemedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      notes: notes ?? this.notes,
      adminNotes: adminNotes ?? this.adminNotes,
    );
  }
}
