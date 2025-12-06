// lib/models/ai_settings.dart
// 🎛️ AI System Settings Model
// สำหรับควบคุมการเปิด/ปิด AI และตั้งค่าต่างๆ

import 'package:cloud_firestore/cloud_firestore.dart';

class AISettings {
  final bool aiEnabled; // เปิด/ปิด AI
  final int dailyLimit; // จำนวนครั้งที่ใช้ได้ต่อวัน
  final int currentUsage; // จำนวนครั้งที่ใช้ไปแล้ววันนี้
  final DateTime lastResetDate; // วันที่ reset ครั้งล่าสุด
  final bool autoApproveHighConfidence; // อนุมัติอัตโนมัติถ้า AI มั่นใจสูง
  final int minConfidenceScore; // คะแนนความมั่นใจขั้นต่ำ (0-100)
  final String apiKey; // Gemini API Key
  final DateTime? updatedAt;
  final String? updatedBy; // Admin ที่แก้ไขล่าสุด

  AISettings({
    required this.aiEnabled,
    this.dailyLimit = 1500, // Default: 1,500 ตาม Gemini free tier
    this.currentUsage = 0,
    DateTime? lastResetDate,
    this.autoApproveHighConfidence = false,
    this.minConfidenceScore = 80,
    this.apiKey = '',
    this.updatedAt,
    this.updatedBy,
  }) : lastResetDate = lastResetDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'aiEnabled': aiEnabled,
      'dailyLimit': dailyLimit,
      'currentUsage': currentUsage,
      'lastResetDate': Timestamp.fromDate(lastResetDate),
      'autoApproveHighConfidence': autoApproveHighConfidence,
      'minConfidenceScore': minConfidenceScore,
      'apiKey': apiKey,
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    };
  }

  factory AISettings.fromMap(Map<String, dynamic> map) {
    return AISettings(
      aiEnabled: map['aiEnabled'] ?? false,
      dailyLimit: map['dailyLimit'] ?? 1500,
      currentUsage: map['currentUsage'] ?? 0,
      lastResetDate:
          (map['lastResetDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      autoApproveHighConfidence: map['autoApproveHighConfidence'] ?? false,
      minConfidenceScore: map['minConfidenceScore'] ?? 80,
      apiKey: map['apiKey'] ?? '',
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: map['updatedBy'],
    );
  }

  /// สร้างค่าเริ่มต้น
  factory AISettings.defaultSettings() {
    return AISettings(
      aiEnabled: true, // เปิดใช้งาน AI โดยค่าเริ่มต้น
      dailyLimit: 1500,
      currentUsage: 0,
      autoApproveHighConfidence: false,
      minConfidenceScore: 80,
    );
  }

  /// ตรวจสอบว่าสามารถใช้ AI ได้หรือไม่
  bool canUseAI() {
    // ตรวจสอบว่าเปิดใช้งานและยังไม่เกิน limit
    if (!aiEnabled) return false;
    if (currentUsage >= dailyLimit) return false;

    // ตรวจสอบว่าต้อง reset หรือไม่ (เปลี่ยนวันแล้ว)
    final now = DateTime.now();
    final resetDate =
        DateTime(lastResetDate.year, lastResetDate.month, lastResetDate.day);
    final today = DateTime(now.year, now.month, now.day);

    // ถ้าเปลี่ยนวันแล้ว ควร reset (จะ reset ใน service)
    if (today.isAfter(resetDate)) return true;

    return true;
  }

  /// คำนวณ usage percentage
  double get usagePercentage {
    if (dailyLimit == 0) return 0;
    return (currentUsage / dailyLimit * 100).clamp(0, 100);
  }

  /// คำนวณจำนวนที่เหลือ
  int get remainingUsage {
    return (dailyLimit - currentUsage).clamp(0, dailyLimit);
  }

  /// สร้าง copy พร้อมแก้ไขค่า
  AISettings copyWith({
    bool? aiEnabled,
    int? dailyLimit,
    int? currentUsage,
    DateTime? lastResetDate,
    bool? autoApproveHighConfidence,
    int? minConfidenceScore,
    String? apiKey,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return AISettings(
      aiEnabled: aiEnabled ?? this.aiEnabled,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      currentUsage: currentUsage ?? this.currentUsage,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      autoApproveHighConfidence:
          autoApproveHighConfidence ?? this.autoApproveHighConfidence,
      minConfidenceScore: minConfidenceScore ?? this.minConfidenceScore,
      apiKey: apiKey ?? this.apiKey,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
