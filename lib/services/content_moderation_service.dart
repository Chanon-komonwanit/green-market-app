// lib/services/content_moderation_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Content Moderation Service
/// กรองเนื้อหาไม่เหมาะสม, spam detection, และคำหยาบ
class ContentModerationService {
  static final ContentModerationService _instance =
      ContentModerationService._internal();
  factory ContentModerationService() => _instance;
  ContentModerationService._internal();

  // คำหยาบและคำต้องห้าม (ภาษาไทยและอังกฤษ)
  final List<String> _badWords = [
    // ภาษาไทย
    'ควย',
    'หี',
    'เหี้ย',
    'สัส',
    'ไอ้สัตว์',
    'ไอ้เวร',
    'ชาติชั่ว',
    'เชี่ย',
    // อังกฤษ
    'fuck',
    'shit',
    'bitch',
    'asshole',
    'damn',
    'crap',
  ];

  // คำที่บ่งบอกถึง spam
  final List<String> _spamKeywords = [
    'กดติดตาม',
    'คลิกลิงก์',
    'รับเงินฟรี',
    'หาเงินออนไลน์',
    'สมัครตอนนี้',
    'โอนเงินมาที่',
    'เลขบัญชี',
    'click here',
    'free money',
    'buy now',
    'limited offer',
    'act now',
  ];

  // URL patterns ที่น่าสงสัย
  final List<RegExp> _suspiciousUrlPatterns = [
    RegExp(r'bit\.ly', caseSensitive: false),
    RegExp(r'tinyurl\.com', caseSensitive: false),
    RegExp(r'goo\.gl', caseSensitive: false),
    RegExp(r'ow\.ly', caseSensitive: false),
  ];

  /// ตรวจสอบเนื้อหาทั้งหมด
  Future<ModerationResult> moderateContent(String content) async {
    final issues = <String>[];
    var severity = ModerationSeverity.none;

    // 1. ตรวจสอบคำหยาบ
    final hasProfanity = _checkProfanity(content);
    if (hasProfanity) {
      issues.add('พบคำหยาบคาย');
      severity = ModerationSeverity.high;
    }

    // 2. ตรวจสอบ spam
    final isSpam = _checkSpam(content);
    if (isSpam) {
      issues.add('เนื้อหาต้องสงสัยว่าเป็น spam');
      severity = severity == ModerationSeverity.high
          ? severity
          : ModerationSeverity.medium;
    }

    // 3. ตรวจสอบ URL ต้องสงสัย
    final hasSuspiciousUrl = _checkSuspiciousUrls(content);
    if (hasSuspiciousUrl) {
      issues.add('พบลิงก์ที่ต้องสงสัย');
      severity = severity == ModerationSeverity.none
          ? ModerationSeverity.low
          : severity;
    }

    // 4. ตรวจสอบการใช้ตัวพิมพ์ใหญ่มากเกินไป
    final hasExcessiveCaps = _checkExcessiveCaps(content);
    if (hasExcessiveCaps) {
      issues.add('ใช้ตัวพิมพ์ใหญ่มากเกินไป');
      severity = severity == ModerationSeverity.none
          ? ModerationSeverity.low
          : severity;
    }

    // 5. ตรวจสอบข้อความซ้ำซาก
    final isRepetitive = _checkRepetitiveText(content);
    if (isRepetitive) {
      issues.add('ข้อความซ้ำซากผิดปกติ');
      severity = severity == ModerationSeverity.none
          ? ModerationSeverity.low
          : severity;
    }

    return ModerationResult(
      isClean: issues.isEmpty,
      severity: severity,
      issues: issues,
      cleanedContent: _cleanContent(content),
    );
  }

  /// ตรวจสอบคำหยาบ
  bool _checkProfanity(String content) {
    final lowerContent = content.toLowerCase();
    return _badWords.any((word) => lowerContent.contains(word.toLowerCase()));
  }

  /// ตรวจสอบ spam
  bool _checkSpam(String content) {
    final lowerContent = content.toLowerCase();
    int spamScore = 0;

    // นับจำนวนคำที่บ่งบอกถึง spam
    for (final keyword in _spamKeywords) {
      if (lowerContent.contains(keyword.toLowerCase())) {
        spamScore++;
      }
    }

    // ถ้ามีคำ spam มากกว่า 2 คำ ถือว่าเป็น spam
    return spamScore >= 2;
  }

  /// ตรวจสอบ URL ต้องสงสัย
  bool _checkSuspiciousUrls(String content) {
    return _suspiciousUrlPatterns.any((pattern) => pattern.hasMatch(content));
  }

  /// ตรวจสอบการใช้ตัวพิมพ์ใหญ่มากเกินไป
  bool _checkExcessiveCaps(String content) {
    if (content.length < 10) return false;

    final capsCount = content
        .split('')
        .where((c) => c == c.toUpperCase() && c != c.toLowerCase())
        .length;
    final ratio = capsCount / content.length;

    // ถ้ามีตัวพิมพ์ใหญ่มากกว่า 70% ของข้อความ
    return ratio > 0.7;
  }

  /// ตรวจสอบข้อความซ้ำซาก
  bool _checkRepetitiveText(String content) {
    if (content.length < 20) return false;

    final words = content.split(' ');
    if (words.length < 3) return false;

    // นับจำนวนคำที่ซ้ำกัน
    final wordCounts = <String, int>{};
    for (final word in words) {
      if (word.length > 2) {
        wordCounts[word.toLowerCase()] =
            (wordCounts[word.toLowerCase()] ?? 0) + 1;
      }
    }

    // ถ้ามีคำใดซ้ำมากกว่า 5 ครั้ง ถือว่าซ้ำซาก
    return wordCounts.values.any((count) => count > 5);
  }

  /// ทำความสะอาดเนื้อหา (แทนที่คำหยาบด้วย ***)
  String _cleanContent(String content) {
    var cleaned = content;

    for (final badWord in _badWords) {
      final replacement = '*' * badWord.length;
      cleaned = cleaned.replaceAll(
        RegExp(badWord, caseSensitive: false),
        replacement,
      );
    }

    return cleaned;
  }

  /// ตรวจสอบประวัติการโพสต์ของผู้ใช้ (spam detection)
  Future<bool> checkUserSpamHistory(String userId) async {
    try {
      final now = DateTime.now();
      final oneHourAgo =
          Timestamp.fromDate(now.subtract(const Duration(hours: 1)));

      // นับจำนวนโพสต์ในชั่วโมงที่แล้ว
      final recentPosts = await FirebaseFirestore.instance
          .collection('community_posts')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThan: oneHourAgo)
          .get();

      // ถ้าโพสต์มากกว่า 10 โพสต์ต่อชั่วโมง ถือว่าเป็น spam
      if (recentPosts.docs.length > 10) {
        debugPrint('User $userId is posting too frequently');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking spam history: $e');
      return false;
    }
  }

  /// บันทึกการรายงาน
  Future<void> reportContent({
    required String contentId,
    required String contentType, // post, comment, message
    required String reportedBy,
    required String reason,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('content_reports').add({
        'contentId': contentId,
        'contentType': contentType,
        'reportedBy': reportedBy,
        'reason': reason,
        'status': 'pending', // pending, reviewed, action_taken
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Content reported successfully');
    } catch (e) {
      debugPrint('Error reporting content: $e');
      rethrow;
    }
  }

  /// ดึงรายงานที่รอตรวจสอบ (สำหรับ Admin)
  Stream<List<Map<String, dynamic>>> getPendingReports() {
    return FirebaseFirestore.instance
        .collection('content_reports')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  /// อัปเดตสถานะการรายงาน
  Future<void> updateReportStatus(String reportId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('content_reports')
          .doc(reportId)
          .update({
        'status': status,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating report status: $e');
      rethrow;
    }
  }

  /// ระงับผู้ใช้ชั่วคราว
  Future<void> suspendUser(String userId, int durationDays) async {
    try {
      final suspendUntil = DateTime.now().add(Duration(days: durationDays));

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isSuspended': true,
        'suspendedUntil': Timestamp.fromDate(suspendUntil),
        'suspendedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('User $userId suspended until $suspendUntil');
    } catch (e) {
      debugPrint('Error suspending user: $e');
      rethrow;
    }
  }

  /// ตรวจสอบว่าผู้ใช้ถูกระงับหรือไม่
  Future<bool> isUserSuspended(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return false;

      final data = userDoc.data();
      final isSuspended = data?['isSuspended'] ?? false;

      if (!isSuspended) return false;

      final suspendedUntil = data?['suspendedUntil'] as Timestamp?;
      if (suspendedUntil == null) return false;

      // ตรวจสอบว่าพ้นระยะเวลาระงับแล้วหรือยัง
      if (DateTime.now().isAfter(suspendedUntil.toDate())) {
        // ยกเลิกการระงับอัตโนมัติ
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'isSuspended': false,
          'suspendedUntil': FieldValue.delete(),
        });
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error checking suspension status: $e');
      return false;
    }
  }
}

/// ผลการตรวจสอบเนื้อหา
class ModerationResult {
  final bool isClean;
  final ModerationSeverity severity;
  final List<String> issues;
  final String cleanedContent;

  ModerationResult({
    required this.isClean,
    required this.severity,
    required this.issues,
    required this.cleanedContent,
  });
}

/// ระดับความรุนแรงของปัญหา
enum ModerationSeverity {
  none,
  low,
  medium,
  high,
}
