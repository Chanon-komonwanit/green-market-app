// lib/models/report.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportReason {
  spam('สแปม', 'spam'),
  harassment('การล่วงล้ำหรือรังแกผู้อื่น', 'harassment'),
  hateSpeech('คำพูดแสดงความเกลียดชัง', 'hate_speech'),
  violence('ความรุนแรง', 'violence'),
  nudity('ภาพลามก', 'nudity'),
  misinformation('ข้อมูลเท็จ', 'misinformation'),
  intellectual('ละเมิดลิขสิทธิ์', 'intellectual'),
  other('อื่นๆ', 'other');

  final String label;
  final String value;
  const ReportReason(this.label, this.value);

  static ReportReason fromString(String value) {
    return ReportReason.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReportReason.other,
    );
  }
}

enum ReportStatus {
  pending('รอตรวจสอบ', 'pending'),
  reviewing('กำลังตรวจสอบ', 'reviewing'),
  resolved('แก้ไขแล้ว', 'resolved'),
  dismissed('ยกเลิก', 'dismissed');

  final String label;
  final String value;
  const ReportStatus(this.label, this.value);

  static ReportStatus fromString(String value) {
    return ReportStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReportStatus.pending,
    );
  }
}

class Report {
  final String id;
  final String reporterId; // ผู้รายงาน
  final String reporterName;
  final String reportedUserId; // ผู้ถูกรายงาน (optional)
  final String? reportedUserName;
  final String? postId; // โพสต์ที่ถูกรายงาน (optional)
  final String? commentId; // คอมเมนต์ที่ถูกรายงาน (optional)
  final ReportReason reason;
  final String? additionalInfo; // รายละเอียดเพิ่มเติม
  final ReportStatus status;
  final Timestamp createdAt;
  final Timestamp? reviewedAt;
  final String? reviewedBy; // Admin ที่ตรวจสอบ
  final String? reviewNote; // หมายเหตุจาก Admin

  const Report({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.reportedUserId,
    this.reportedUserName,
    this.postId,
    this.commentId,
    required this.reason,
    this.additionalInfo,
    this.status = ReportStatus.pending,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewNote,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reportedUserId': reportedUserId,
      'reportedUserName': reportedUserName,
      'postId': postId,
      'commentId': commentId,
      'reason': reason.value,
      'additionalInfo': additionalInfo,
      'status': status.value,
      'createdAt': createdAt,
      'reviewedAt': reviewedAt,
      'reviewedBy': reviewedBy,
      'reviewNote': reviewNote,
    };
  }

  factory Report.fromMap(Map<String, dynamic> map, [String? docId]) {
    return Report(
      id: docId ?? map['id'] ?? '',
      reporterId: map['reporterId'] ?? '',
      reporterName: map['reporterName'] ?? '',
      reportedUserId: map['reportedUserId'] ?? '',
      reportedUserName: map['reportedUserName'],
      postId: map['postId'],
      commentId: map['commentId'],
      reason: ReportReason.fromString(map['reason'] ?? 'other'),
      additionalInfo: map['additionalInfo'],
      status: ReportStatus.fromString(map['status'] ?? 'pending'),
      createdAt: map['createdAt'] ?? Timestamp.now(),
      reviewedAt: map['reviewedAt'],
      reviewedBy: map['reviewedBy'],
      reviewNote: map['reviewNote'],
    );
  }

  Report copyWith({
    String? id,
    String? reporterId,
    String? reporterName,
    String? reportedUserId,
    String? reportedUserName,
    String? postId,
    String? commentId,
    ReportReason? reason,
    String? additionalInfo,
    ReportStatus? status,
    Timestamp? createdAt,
    Timestamp? reviewedAt,
    String? reviewedBy,
    String? reviewNote,
  }) {
    return Report(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      reportedUserName: reportedUserName ?? this.reportedUserName,
      postId: postId ?? this.postId,
      commentId: commentId ?? this.commentId,
      reason: reason ?? this.reason,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewNote: reviewNote ?? this.reviewNote,
    );
  }
}
