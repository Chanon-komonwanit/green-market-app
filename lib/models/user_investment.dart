// lib/models/user_investment.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserInvestment {
  final String id;
  final String userId;
  final String projectId;
  final String projectTitle; // Added projectTitle for display
  final double amount;
  final Timestamp investedAt;

  UserInvestment({
    required this.id,
    required this.userId,
    required this.projectId,
    required this.projectTitle,
    required this.amount,
    required this.investedAt,
  });

  factory UserInvestment.fromMap(Map<String, dynamic> map) {
    return UserInvestment(
      id: map['id'] as String,
      userId: map['userId'] as String,
      projectId: map['projectId'] as String,
      amount: (map['amount'] as num).toDouble(),
      investedAt: map['investedAt'] as Timestamp,
      projectTitle: map['projectTitle'] as String? ?? 'Unknown Project',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'projectId': projectId,
      'projectTitle': projectTitle,
      'amount': amount,
      'investedAt': investedAt,
    };
  }

  UserInvestment copyWith({
    String? id,
    String? userId,
    String? projectId,
    String? projectTitle,
    double? amount,
    Timestamp? investedAt,
  }) {
    return UserInvestment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      projectId: projectId ?? this.projectId,
      projectTitle: projectTitle ?? this.projectTitle,
      amount: amount ?? this.amount,
      investedAt: investedAt ?? this.investedAt,
    );
  }
}
