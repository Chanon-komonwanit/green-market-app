// lib/models/auto_reply.dart
// Auto Reply Model - ระบบตอบกลับอัตโนมัติสำหรับผู้ขาย

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Auto Reply Template - ข้อความตอบกลับอัตโนมัติ
class AutoReplyTemplate {
  final String id;
  final String sellerId;
  final String
      trigger; // คีย์เวิร์ดที่จะทริกเกอร์ (เช่น "ราคา", "ส่งไว", "สต็อก")
  final String response; // ข้อความตอบกลับ
  final bool isActive;
  final int priority; // ลำดับความสำคัญ (เลขน้อย = สำคัญกว่า)
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  AutoReplyTemplate({
    required this.id,
    required this.sellerId,
    required this.trigger,
    required this.response,
    this.isActive = true,
    this.priority = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory AutoReplyTemplate.fromMap(Map<String, dynamic> map) {
    return AutoReplyTemplate(
      id: map['id'] ?? '',
      sellerId: map['sellerId'] ?? '',
      trigger: map['trigger'] ?? '',
      response: map['response'] ?? '',
      isActive: map['isActive'] ?? true,
      priority: (map['priority'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] as Timestamp?,
      updatedAt: map['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sellerId': sellerId,
      'trigger': trigger,
      'response': response,
      'isActive': isActive,
      'priority': priority,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }

  AutoReplyTemplate copyWith({
    String? id,
    String? sellerId,
    String? trigger,
    String? response,
    bool? isActive,
    int? priority,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return AutoReplyTemplate(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      trigger: trigger ?? this.trigger,
      response: response ?? this.response,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Auto Reply Settings - การตั้งค่าระบบตอบกลับอัตโนมัติ
class AutoReplySettings {
  final String sellerId;
  final bool isEnabled; // เปิด/ปิดระบบ
  final String welcomeMessage; // ข้อความต้อนรับ
  final bool sendWelcomeMessage; // ส่งข้อความต้อนรับอัตโนมัติ
  final String outOfOfficeMessage; // ข้อความเมื่อนอกเวลาทำการ
  final bool enableOutOfOffice; // เปิดโหมดนอกเวลาทำการ
  final List<int> workingDays; // วันทำการ (0=จันทร์, 6=อาทิตย์)
  final String workingHoursStart; // เวลาเริ่มทำงาน (HH:mm)
  final String workingHoursEnd; // เวลาเลิกงาน (HH:mm)
  final int autoReplyDelaySeconds; // หน่วงเวลาก่อนตอบกลับ (วินาที)
  final Timestamp? updatedAt;

  AutoReplySettings({
    required this.sellerId,
    this.isEnabled = false,
    this.welcomeMessage = 'สวัสดีค่ะ! ยินดีให้บริการค่ะ 😊',
    this.sendWelcomeMessage = true,
    this.outOfOfficeMessage =
        'ขออภัยค่ะ ขณะนี้นอกเวลาทำการ เราจะตอบกลับโดยเร็วที่สุดค่ะ',
    this.enableOutOfOffice = false,
    this.workingDays = const [0, 1, 2, 3, 4], // จันทร์-ศุกร์
    this.workingHoursStart = '09:00',
    this.workingHoursEnd = '18:00',
    this.autoReplyDelaySeconds = 2,
    this.updatedAt,
  });

  factory AutoReplySettings.fromMap(Map<String, dynamic> map) {
    return AutoReplySettings(
      sellerId: map['sellerId'] ?? '',
      isEnabled: map['isEnabled'] ?? false,
      welcomeMessage:
          map['welcomeMessage'] ?? 'สวัสดีค่ะ! ยินดีให้บริการค่ะ 😊',
      sendWelcomeMessage: map['sendWelcomeMessage'] ?? true,
      outOfOfficeMessage: map['outOfOfficeMessage'] ??
          'ขออภัยค่ะ ขณะนี้นอกเวลาทำการ เราจะตอบกลับโดยเร็วที่สุดค่ะ',
      enableOutOfOffice: map['enableOutOfOffice'] ?? false,
      workingDays:
          (map['workingDays'] as List?)?.cast<int>() ?? [0, 1, 2, 3, 4],
      workingHoursStart: map['workingHoursStart'] ?? '09:00',
      workingHoursEnd: map['workingHoursEnd'] ?? '18:00',
      autoReplyDelaySeconds:
          (map['autoReplyDelaySeconds'] as num?)?.toInt() ?? 2,
      updatedAt: map['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'isEnabled': isEnabled,
      'welcomeMessage': welcomeMessage,
      'sendWelcomeMessage': sendWelcomeMessage,
      'outOfOfficeMessage': outOfOfficeMessage,
      'enableOutOfOffice': enableOutOfOffice,
      'workingDays': workingDays,
      'workingHoursStart': workingHoursStart,
      'workingHoursEnd': workingHoursEnd,
      'autoReplyDelaySeconds': autoReplyDelaySeconds,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }

  /// ตรวจสอบว่าอยู่ในเวลาทำการหรือไม่
  bool isWithinWorkingHours() {
    if (!enableOutOfOffice) return true;

    final now = DateTime.now();

    // ตรวจสอบวันทำการ
    if (!workingDays.contains(now.weekday - 1)) {
      return false;
    }

    // ตรวจสอบเวลา
    final startParts = workingHoursStart.split(':');
    final endParts = workingHoursEnd.split(':');

    final start = TimeOfDay(
      hour: int.parse(startParts[0]),
      minute: int.parse(startParts[1]),
    );
    final end = TimeOfDay(
      hour: int.parse(endParts[0]),
      minute: int.parse(endParts[1]),
    );

    final nowTime = TimeOfDay.fromDateTime(now);
    final nowMinutes = nowTime.hour * 60 + nowTime.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
  }

  /// ข้อความที่ควรใช้ (เวลาทำการ vs นอกเวลา)
  String? getAutoReplyMessage(bool isFirstMessage) {
    if (!isEnabled) return null;

    // ข้อความต้อนรับ (เฉพาะข้อความแรก)
    if (isFirstMessage && sendWelcomeMessage) {
      if (!isWithinWorkingHours() && enableOutOfOffice) {
        return '$welcomeMessage\n\n$outOfOfficeMessage';
      }
      return welcomeMessage;
    }

    // ข้อความนอกเวลาทำการ
    if (!isWithinWorkingHours() && enableOutOfOffice) {
      return outOfOfficeMessage;
    }

    return null;
  }

  AutoReplySettings copyWith({
    String? sellerId,
    bool? isEnabled,
    String? welcomeMessage,
    bool? sendWelcomeMessage,
    String? outOfOfficeMessage,
    bool? enableOutOfOffice,
    List<int>? workingDays,
    String? workingHoursStart,
    String? workingHoursEnd,
    int? autoReplyDelaySeconds,
    Timestamp? updatedAt,
  }) {
    return AutoReplySettings(
      sellerId: sellerId ?? this.sellerId,
      isEnabled: isEnabled ?? this.isEnabled,
      welcomeMessage: welcomeMessage ?? this.welcomeMessage,
      sendWelcomeMessage: sendWelcomeMessage ?? this.sendWelcomeMessage,
      outOfOfficeMessage: outOfOfficeMessage ?? this.outOfOfficeMessage,
      enableOutOfOffice: enableOutOfOffice ?? this.enableOutOfOffice,
      workingDays: workingDays ?? this.workingDays,
      workingHoursStart: workingHoursStart ?? this.workingHoursStart,
      workingHoursEnd: workingHoursEnd ?? this.workingHoursEnd,
      autoReplyDelaySeconds:
          autoReplyDelaySeconds ?? this.autoReplyDelaySeconds,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Quick Reply - ข้อความตอบกลับด่วน
class QuickReply {
  final String id;
  final String sellerId;
  final String label; // ชื่อแสดง (เช่น "ยินดี", "ส่งด่วน", "สต็อกหมด")
  final String message; // ข้อความที่จะส่ง
  final String? emoji; // Emoji (optional)
  final int usageCount; // จำนวนครั้งที่ใช้
  final Timestamp? createdAt;

  QuickReply({
    required this.id,
    required this.sellerId,
    required this.label,
    required this.message,
    this.emoji,
    this.usageCount = 0,
    this.createdAt,
  });

  factory QuickReply.fromMap(Map<String, dynamic> map) {
    return QuickReply(
      id: map['id'] ?? '',
      sellerId: map['sellerId'] ?? '',
      label: map['label'] ?? '',
      message: map['message'] ?? '',
      emoji: map['emoji'],
      usageCount: (map['usageCount'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sellerId': sellerId,
      'label': label,
      'message': message,
      if (emoji != null) 'emoji': emoji,
      'usageCount': usageCount,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  QuickReply copyWith({
    String? id,
    String? sellerId,
    String? label,
    String? message,
    String? emoji,
    int? usageCount,
    Timestamp? createdAt,
  }) {
    return QuickReply(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      label: label ?? this.label,
      message: message ?? this.message,
      emoji: emoji ?? this.emoji,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Default Quick Replies - ข้อความตอบกลับด่วนเริ่มต้น
class DefaultQuickReplies {
  static List<Map<String, String>> get templates => [
        {
          'label': 'ยินดีต้อนรับ',
          'emoji': '😊',
          'message': 'สวัสดีค่ะ! ยินดีให้บริการค่ะ มีอะไรให้ช่วยไหมคะ'
        },
        {
          'label': 'มีสินค้า',
          'emoji': '✅',
          'message': 'มีสินค้าพร้อมส่งเลยค่ะ สามารถสั่งได้เลยค่ะ'
        },
        {
          'label': 'หมดสต็อก',
          'emoji': '😔',
          'message': 'ขออภัยค่ะ สินค้าหมดชั่วคราว จะมีเข้าใหม่ภายใน 3-5 วันค่ะ'
        },
        {
          'label': 'ส่งไว',
          'emoji': '📦',
          'message': 'แพ็คของส่งวันนี้เลยค่ะ ได้รับภายใน 2-3 วันค่ะ'
        },
        {
          'label': 'ถามราคา',
          'emoji': '💰',
          'message':
              'ราคาตามที่แสดงในหน้าสินค้าเลยค่ะ สามารถกดสั่งซื้อได้เลยค่ะ'
        },
        {
          'label': 'ขอบคุณ',
          'emoji': '🙏',
          'message': 'ขอบคุณที่อุดหนุนค่ะ หวังว่าจะได้รับใช้อีกนะคะ 😊'
        },
        {
          'label': 'ติดต่อเพิ่ม',
          'emoji': '📞',
          'message': 'หากมีคำถามเพิ่มเติม สอบถามได้ตลอดเวลาเลยค่ะ'
        },
        {
          'label': 'ขอรูปเพิ่ม',
          'emoji': '📸',
          'message': 'รอสักครู่นะคะ จะส่งรูปเพิ่มเติมให้เลยค่ะ'
        },
      ];
}
