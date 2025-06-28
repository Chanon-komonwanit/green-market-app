// lib/models/investment_project.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/utils/constants.dart';

/// Enum for the submission status of a project.
enum ProjectSubmissionStatus { pending, approved, rejected }

/// Enum for the risk level of an investment.
/// This is likely defined in constants.dart, but shown here for clarity.
// enum RiskLevel { low, medium, high }

class InvestmentProject {
  final String id;
  final String title;
  final String description;
  final double goalAmount;
  final double currentAmount;
  final String projectOwnerId;
  final String imageUrl;
  final String projectOwnerName; // Added for display
  final double expectedReturnRate;
  final RiskLevel riskLevel; // Changed from String to Enum
  final String? rejectionReason; // Added
  final DateTime startDate;
  final DateTime endDate;
  final ProjectSubmissionStatus submissionStatus; // Changed from String to Enum
  final bool isActive; // For approved projects, can be toggled by admin
  final Timestamp? createdAt; // Made nullable for initial creation

  InvestmentProject({
    required this.id,
    required this.title,
    required this.description,
    required this.goalAmount,
    required this.currentAmount,
    required this.projectOwnerId,
    required this.imageUrl,
    required this.projectOwnerName,
    required this.expectedReturnRate,
    required this.riskLevel,
    this.rejectionReason,
    required this.startDate,
    required this.endDate,
    this.submissionStatus = ProjectSubmissionStatus.pending,
    this.isActive = false,
    this.createdAt,
  });

  factory InvestmentProject.fromMap(Map<String, dynamic> map) {
    return InvestmentProject(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      goalAmount: (map['goalAmount'] as num).toDouble(),
      currentAmount: (map['currentAmount'] as num).toDouble(),
      projectOwnerId: map['projectOwnerId'] as String,
      imageUrl: map['imageUrl'] as String,
      projectOwnerName: map['projectOwnerName'] as String? ?? 'Unknown',
      expectedReturnRate:
          (map['expectedReturnRate'] as num?)?.toDouble() ?? 0.0,
      riskLevel: RiskLevel.values.firstWhere(
        (e) => e.name == (map['riskLevel'] as String?),
        orElse: () => RiskLevel.low,
      ),
      rejectionReason: map['rejectionReason'] as String?,
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      submissionStatus: ProjectSubmissionStatus.values.firstWhere(
        (e) => e.name == (map['submissionStatus'] as String?),
        orElse: () => ProjectSubmissionStatus.pending,
      ),
      isActive: map['isActive'] as bool? ?? false,
      createdAt: map['createdAt'] as Timestamp?,
    );
  }

  /// Calculates the funding progress as a value between 0.0 and 1.0.
  double get fundingProgress =>
      (goalAmount > 0) ? (currentAmount / goalAmount).clamp(0.0, 1.0) : 0.0;

  /// Formats the expected return rate into a user-friendly percentage string.
  String get formattedExpectedReturn =>
      '${(expectedReturnRate * 100).toStringAsFixed(1)}%';

  /// Calculates the number of days remaining until the project's end date.
  /// Returns 0 if the project has already ended.
  int get daysRemaining {
    final now = DateTime.now();
    if (endDate.isBefore(now)) return 0;
    return endDate.difference(now).inDays;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'goalAmount': goalAmount,
      'currentAmount': currentAmount,
      'projectOwnerId': projectOwnerId,
      'imageUrl': imageUrl,
      'projectOwnerName': projectOwnerName,
      'expectedReturnRate': expectedReturnRate,
      'riskLevel': riskLevel.name, // Store enum as string
      'rejectionReason': rejectionReason,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'submissionStatus': submissionStatus.name, // Store enum as string
      'isActive': isActive,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  InvestmentProject copyWith(
      {String? id,
      String? title,
      String? description,
      double? goalAmount,
      double? currentAmount,
      String? projectOwnerId,
      String? imageUrl,
      String? projectOwnerName,
      double? expectedReturnRate,
      RiskLevel? riskLevel,
      String? rejectionReason,
      DateTime? startDate,
      DateTime? endDate,
      ProjectSubmissionStatus? submissionStatus,
      bool? isActive,
      Timestamp? createdAt}) {
    return InvestmentProject(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      goalAmount: goalAmount ?? this.goalAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      projectOwnerId: projectOwnerId ?? this.projectOwnerId,
      imageUrl: imageUrl ?? this.imageUrl,
      projectOwnerName: projectOwnerName ?? this.projectOwnerName,
      expectedReturnRate: expectedReturnRate ?? this.expectedReturnRate,
      riskLevel: riskLevel ?? this.riskLevel,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
