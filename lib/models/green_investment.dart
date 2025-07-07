// lib/models/green_investment.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GreenInvestment {
  final String id;
  final String title;
  final String description;
  final String category;
  final double minInvestment;
  final double targetAmount;
  final double currentAmount;
  final double expectedReturn;
  final int duration; // in months
  final String riskLevel;
  final bool isActive;
  final String? imageUrl;
  final List<String> tags;
  final Map<String, dynamic> details;
  final DateTime createdAt;
  final String createdBy;
  final DateTime? closingDate;

  GreenInvestment({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.minInvestment,
    required this.targetAmount,
    required this.currentAmount,
    required this.expectedReturn,
    required this.duration,
    required this.riskLevel,
    required this.isActive,
    this.imageUrl,
    required this.tags,
    required this.details,
    required this.createdAt,
    required this.createdBy,
    this.closingDate,
  });

  factory GreenInvestment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GreenInvestment(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'renewable',
      minInvestment: (data['minInvestment'] ?? 0).toDouble(),
      targetAmount: (data['targetAmount'] ?? 0).toDouble(),
      currentAmount: (data['currentAmount'] ?? 0).toDouble(),
      expectedReturn: (data['expectedReturn'] ?? 0).toDouble(),
      duration: data['duration'] ?? 12,
      riskLevel: data['riskLevel'] ?? 'medium',
      isActive: data['isActive'] ?? true,
      imageUrl: data['imageUrl'],
      tags: List<String>.from(data['tags'] ?? []),
      details: data['details'] ?? {},
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      closingDate: (data['closingDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'minInvestment': minInvestment,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'expectedReturn': expectedReturn,
      'duration': duration,
      'riskLevel': riskLevel,
      'isActive': isActive,
      'imageUrl': imageUrl,
      'tags': tags,
      'details': details,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'closingDate':
          closingDate != null ? Timestamp.fromDate(closingDate!) : null,
    };
  }

  double get progressPercentage =>
      targetAmount > 0 ? (currentAmount / targetAmount) * 100 : 0;

  bool get isFullyFunded => currentAmount >= targetAmount;

  String get progressText =>
      '${currentAmount.toStringAsFixed(0)}/${targetAmount.toStringAsFixed(0)} บาท';

  GreenInvestment copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    double? minInvestment,
    double? targetAmount,
    double? currentAmount,
    double? expectedReturn,
    int? duration,
    String? riskLevel,
    bool? isActive,
    String? imageUrl,
    List<String>? tags,
    Map<String, dynamic>? details,
    DateTime? createdAt,
    String? createdBy,
    DateTime? closingDate,
  }) {
    return GreenInvestment(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      minInvestment: minInvestment ?? this.minInvestment,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      expectedReturn: expectedReturn ?? this.expectedReturn,
      duration: duration ?? this.duration,
      riskLevel: riskLevel ?? this.riskLevel,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      details: details ?? this.details,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      closingDate: closingDate ?? this.closingDate,
    );
  }
}

class InvestmentCategory {
  static const String renewable = 'renewable';
  static const String waste = 'waste';
  static const String water = 'water';
  static const String transport = 'transport';
  static const String agriculture = 'agriculture';
  static const String technology = 'technology';
  static const String forestry = 'forestry';
  static const String carbon = 'carbon';

  static List<String> get allCategories => [
        renewable,
        waste,
        water,
        transport,
        agriculture,
        technology,
        forestry,
        carbon,
      ];

  static String getCategoryName(String category) {
    switch (category) {
      case renewable:
        return 'พลังงานทดแทน';
      case waste:
        return 'จัดการขยะ';
      case water:
        return 'น้ำสะอาด';
      case transport:
        return 'การขนส่งสีเขียว';
      case agriculture:
        return 'เกษตรยั่งยืน';
      case technology:
        return 'เทคโนโลยีสีเขียว';
      case forestry:
        return 'ป่าไผ่';
      case carbon:
        return 'คาร์บอนเครดิต';
      default:
        return 'ทั่วไป';
    }
  }
}

class RiskLevel {
  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';

  static String getRiskLevelName(String riskLevel) {
    switch (riskLevel) {
      case low:
        return 'ต่ำ';
      case medium:
        return 'ปานกลาง';
      case high:
        return 'สูง';
      default:
        return 'ปานกลาง';
    }
  }

  static Color getRiskLevelColor(String riskLevel) {
    switch (riskLevel) {
      case low:
        return const Color(0xFF10B981);
      case medium:
        return const Color(0xFFF59E0B);
      case high:
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }
}
