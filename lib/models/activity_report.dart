// lib/models/activity_report.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityReport {
  final String id;
  final String activityId;
  final String activityTitle; // For display convenience
  final String reporterId;
  final String reporterName; // For display convenience
  final String reason;
  final String status; // e.g., 'pending', 'reviewed', 'action_taken'
  final String? adminNotes;
  final Timestamp createdAt;

  ActivityReport({
    required this.id,
    required this.activityId,
    required this.activityTitle,
    required this.reporterId,
    required this.reporterName,
    required this.reason,
    this.status = 'pending',
    this.adminNotes,
    required this.createdAt,
  });

  factory ActivityReport.fromMap(Map<String, dynamic> map) {
    return ActivityReport(
      id: map['id'] as String,
      activityId: map['activityId'] as String,
      activityTitle: map['activityTitle'] as String,
      reporterId: map['reporterId'] as String,
      reporterName: map['reporterName'] as String,
      reason: map['reason'] as String,
      status: map['status'] as String? ?? 'pending',
      adminNotes: map['adminNotes'] as String?,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'activityId': activityId,
      'activityTitle': activityTitle,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reason': reason,
      'status': status,
      'adminNotes': adminNotes,
      'createdAt': createdAt,
    };
  }

  ActivityReport copyWith({
    String? id,
    String? activityId,
    String? activityTitle,
    String? reporterId,
    String? reporterName,
    String? reason,
    String? status,
    String? adminNotes,
    Timestamp? createdAt,
  }) {
    return ActivityReport(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      activityTitle: activityTitle ?? this.activityTitle,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
