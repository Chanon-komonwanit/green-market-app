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

  // คำหยาบและคำต้องห้าม (ภาษาไทยและอังกฤษ) - ครบถ้วนมาตรฐาน
  final List<String> _badWords = [
    // ภาษาไทย - คำหยาบคาย
    'ควย', 'หี', 'เหี้ย', 'สัส', 'ไอ้สัตว์', 'ไอ้เวร', 'ชาติชั่ว', 'เชี่ย',
    'กาก', 'ห่า', 'เหี้ย', 'สันดาน', 'เวร', 'พ่อมึง', 'แม่มึง', 'ตาย',
    'ไอ้ห่า', 'แม่ง', 'ควาย', 'สัตว์', 'เลว', 'ขี้', 'เปรต', 'ตีน',

    // ภาษาไทย - Hate Speech
    'ฆ่า', 'ตาย', 'ทำร้าย', 'รังเกียจ', 'เกลียด', 'สาปแช่ง',
    'ชิงชัง', 'เหยียด', 'เหยียดผิว', 'เหยียดเชื้อชาติ',

    // อังกฤษ - Profanity
    'fuck', 'shit', 'bitch', 'asshole', 'damn', 'crap',
    'bastard', 'dick', 'pussy', 'cock', 'fag', 'whore',
    'slut', 'retard', 'idiot', 'stupid',

    // อังกฤษ - Hate Speech
    'kill', 'hate', 'racist', 'nazi', 'terrorism',
  ];

  // คำที่บ่งบอกถึง spam - ครบถ้วนมาตรฐาน
  final List<String> _spamKeywords = [
    // ภาษาไทย - Marketing Spam
    'กดติดตาม', 'คลิกลิงก์', 'รับเงินฟรี', 'หาเงินออนไลน์',
    'สมัครตอนนี้', 'โอนเงินมาที่', 'เลขบัญชี', 'ฟรีตอนนี้',
    'ของแถม', 'ลดราคา 90%', 'รับทันที', 'ด่วน', 'เท่านั้น',
    'ช่องทาง', 'ดูข้อมูล', 'ติดต่อ ID', 'Line @', 'Add Line',

    // ภาษาไทย - False Claims
    'รวยใน 7 วัน', 'ไม่ต้องลงทุน', 'รายได้แน่นอน', 'ทำเงิน',
    'เงินเข้าทุกวัน', 'เป็นหมื่น', 'เป็นแสน', 'เป็นล้าน',

    // ภาษาไทย - Personal Info Requests
    'ส่งเบอร์', 'ส่ง OTP', 'ใส่รหัส', 'ยืนยันตัวตน',

    // อังกฤษ - Marketing Spam
    'click here', 'free money', 'buy now', 'limited offer',
    'act now', 'hurry up', 'only today', 'last chance',
    'make money', 'earn money', 'get rich', 'passive income',

    // อังกฤษ - Phishing
    'verify account', 'confirm identity', 'send password',
    'bank account', 'credit card', 'social security',
  ];

  // URL patterns ที่น่าสงสัย
  final List<RegExp> _suspiciousUrlPatterns = [
    RegExp(r'bit\.ly', caseSensitive: false),
    RegExp(r'tinyurl\.com', caseSensitive: false),
    RegExp(r'goo\.gl', caseSensitive: false),
    RegExp(r'ow\.ly', caseSensitive: false),
  ];

  /// ตรวจสอบเนื้อหาทั้งหมด (ข้อความ + รูปภาพ + วิดีโอ)
  Future<ModerationResult> moderateContent(
    String content, {
    List<String>? imageUrls,
    String? videoUrl,
  }) async {
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

    // 6. ตรวจสอบรูปภาพ (ถ้ามี)
    if (imageUrls != null && imageUrls.isNotEmpty) {
      final imageResult = await _moderateImages(imageUrls);
      if (!imageResult.isClean) {
        issues.addAll(imageResult.issues);
        if (imageResult.severity.index > severity.index) {
          severity = imageResult.severity;
        }
      }
    }

    // 7. ตรวจสอบวิดีโอ (ถ้ามี)
    if (videoUrl != null && videoUrl.isNotEmpty) {
      final videoResult = await _moderateVideo(videoUrl);
      if (!videoResult.isClean) {
        issues.addAll(videoResult.issues);
        if (videoResult.severity.index > severity.index) {
          severity = videoResult.severity;
        }
      }
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
    return wordCounts.values.any((wordCount) => wordCount > 5);
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

  /// ตรวจสอบรูปภาพ (Image Moderation)
  /// ใช้ heuristics และ metadata analysis
  Future<ModerationResult> _moderateImages(List<String> imageUrls) async {
    final issues = <String>[];
    var severity = ModerationSeverity.none;

    try {
      // ตรวจสอบ metadata และ file extensions
      for (final url in imageUrls) {
        // ตรวจสอบนามสกุลไฟล์ต้องสงสัย
        if (url.toLowerCase().endsWith('.exe') ||
            url.toLowerCase().endsWith('.bat') ||
            url.toLowerCase().endsWith('.sh')) {
          issues.add('ไฟล์ต้องสงสัย (ไม่ใช่รูปภาพ)');
          severity = ModerationSeverity.high;
        }

        // ตรวจสอบ URL ต้องสงสัย
        if (_suspiciousUrlPatterns.any((pattern) => pattern.hasMatch(url))) {
          issues.add('URL รูปภาพต้องสงสัย');
          severity = severity == ModerationSeverity.none
              ? ModerationSeverity.medium
              : severity;
        }
      }

      // TODO: เชื่อม Google Cloud Vision API, AWS Rekognition หรือ Azure Computer Vision
      // สำหรับตรวจจับเนื้อหาไม่เหมาะสม (NSFW, violence, etc.)
      // ตัวอย่าง:
      // - Adult content detection
      // - Violence detection
      // - Text extraction (OCR) for profanity check

      debugPrint('Image moderation completed for ${imageUrls.length} images');
    } catch (e) {
      debugPrint('Error moderating images: $e');
    }

    return ModerationResult(
      isClean: issues.isEmpty,
      severity: severity,
      issues: issues,
      cleanedContent: '',
    );
  }

  /// ตรวจสอบวิดีโอ (Video Moderation)
  Future<ModerationResult> _moderateVideo(String videoUrl) async {
    final issues = <String>[];
    var severity = ModerationSeverity.none;

    try {
      // ตรวจสอบนามสกุลไฟล์
      if (!videoUrl.toLowerCase().endsWith('.mp4') &&
          !videoUrl.toLowerCase().endsWith('.mov') &&
          !videoUrl.toLowerCase().endsWith('.avi') &&
          !videoUrl.toLowerCase().endsWith('.webm')) {
        issues.add('ไฟล์วิดีโอต้องสงสัย');
        severity = ModerationSeverity.medium;
      }

      // ตรวจสอบ URL
      if (_suspiciousUrlPatterns.any((pattern) => pattern.hasMatch(videoUrl))) {
        issues.add('URL วิดีโอต้องสงสัย');
        severity = ModerationSeverity.medium;
      }

      // TODO: เชื่อม Video Intelligence API
      // - Frame-by-frame analysis
      // - Audio transcription and profanity check
      // - Violence/NSFW detection

      debugPrint('Video moderation completed for: $videoUrl');
    } catch (e) {
      debugPrint('Error moderating video: $e');
    }

    return ModerationResult(
      isClean: issues.isEmpty,
      severity: severity,
      issues: issues,
      cleanedContent: '',
    );
  }

  /// คำนวณเปร์เซ็นต์หักคะแนนตามความรุนแรง
  double getPenaltyPercentage(ModerationSeverity severity, int violationCount) {
    // Base penalty ตามระดับความรุนแรง
    double basePenalty = 0.0;
    switch (severity) {
      case ModerationSeverity.none:
        basePenalty = 0.0;
        break;
      case ModerationSeverity.low:
        basePenalty = 5.0; // หัก 5%
        break;
      case ModerationSeverity.medium:
        basePenalty = 15.0; // หัก 15%
        break;
      case ModerationSeverity.high:
        basePenalty = 30.0; // หัก 30%
        break;
    }

    // เพิ่ม penalty ตามจำนวนครั้งที่ละเมิด (สะสม)
    double multiplier = 1.0 + (violationCount * 0.5); // +50% ต่อครั้ง
    double totalPenalty = basePenalty * multiplier;

    // จำกัดไม่ให้เกิน 80% (เหลือคะแนนอย่างน้อย 20%)
    return totalPenalty.clamp(0.0, 80.0);
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

  /// บันทึกการละเมิดและหักคะแนน
  Future<void> recordViolationAndApplyPenalty({
    required String userId,
    required String contentId,
    required String contentType,
    required ModerationSeverity severity,
    required List<String> issues,
  }) async {
    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);
      final userDoc = await userRef.get();

      if (!userDoc.exists) return;

      final data = userDoc.data()!;
      final currentViolationCount = data['violationCount'] as int? ?? 0;
      final violationHistory = (data['violationHistory'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];

      // คำนวณ penalty
      final penaltyPercentage =
          getPenaltyPercentage(severity, currentViolationCount);

      // สร้างประวัติการละเมิด
      final violation = {
        'contentId': contentId,
        'contentType': contentType,
        'severity': severity.toString(),
        'issues': issues,
        'penaltyPercentage': penaltyPercentage,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // อัปเดตข้อมูล
      await userRef.update({
        'violationCount': currentViolationCount + 1,
        'violationHistory': [...violationHistory, violation],
        'lastViolationDate': FieldValue.serverTimestamp(),
        'penaltyPercentage': penaltyPercentage,
      });

      debugPrint(
          'Violation recorded for user $userId: ${severity.toString()} - Penalty: $penaltyPercentage%');

      // ส่งการแจ้งเตือนไปยังผู้ใช้ 🔔
      await _sendViolationNotificationToUser(
        userId: userId,
        severity: severity,
        issues: issues,
        penaltyPercentage: penaltyPercentage,
      );

      // อัปเดตคะแนนอิทธิพล (เรียกผ่าน EcoInfluenceService)
      // จะทำใน EcoInfluenceService.calculateTotalInfluenceScore() โดยหักตาม penaltyPercentage
    } catch (e) {
      debugPrint('Error recording violation: $e');
      rethrow;
    }
  }

  /// ลบ penalty (สำหรับ Admin ยกเลิกการลงโทษ)
  Future<void> removePenalty(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'penaltyPercentage': 0.0,
        'lastViolationDate': FieldValue.delete(),
      });
      debugPrint('Penalty removed for user $userId');
    } catch (e) {
      debugPrint('Error removing penalty: $e');
      rethrow;
    }
  }

  /// ดึงประวัติการละเมิด
  Future<List<Map<String, dynamic>>> getViolationHistory(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return [];

      final data = userDoc.data();
      return (data?['violationHistory'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];
    } catch (e) {
      debugPrint('Error getting violation history: $e');
      return [];
    }
  }

  /// ส่งการแจ้งเตือนไปยังผู้ใช้เมื่อตรวจพบการละเมิด
  Future<void> _sendViolationNotificationToUser({
    required String userId,
    required ModerationSeverity severity,
    required List<String> issues,
    required double penaltyPercentage,
  }) async {
    try {
      String severityText;
      String icon;

      switch (severity) {
        case ModerationSeverity.high:
          severityText = 'รุนแรง';
          icon = '🚨';
          break;
        case ModerationSeverity.medium:
          severityText = 'ปานกลาง';
          icon = '⚠️';
          break;
        case ModerationSeverity.low:
          severityText = 'เล็กน้อย';
          icon = '⚡';
          break;
        default:
          severityText = '';
          icon = 'ℹ️';
      }

      // สร้าง notification
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'type': 'content_violation',
        'title': '$icon ตรวจพบการละเมิดกฎชุมชน (ระดับ$severityText)',
        'body':
            'เนื้อหาของคุณถูกตรวจพบว่ามีปัญหา: ${issues.join(", ")}\n\nคะแนนอิทธิพลของคุณถูกหัก ${penaltyPercentage.toStringAsFixed(1)}%',
        'severity': severity.toString(),
        'penaltyPercentage': penaltyPercentage,
        'issues': issues,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Violation notification sent to user $userId');
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  /// ส่งรายงานไปยัง Admin เมื่อตรวจพบเนื้อหาไม่เหมาะสม (อัตโนมัติ)
  Future<void> sendAutoReportToAdmin({
    required String contentId,
    required String contentType,
    required String userId,
    required ModerationSeverity severity,
    required List<String> issues,
    String? contentPreview,
    List<String>? imageUrls,
    String? videoUrl,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('content_reports').add({
        'contentId': contentId,
        'contentType': contentType,
        'reportedUserId': userId,
        'reportedBy': 'system', // รายงานโดยระบบอัตโนมัติ
        'reason': issues.join(', '),
        'severity': severity.toString(),
        'issues': issues,
        'contentPreview': contentPreview,
        'imageUrls': imageUrls,
        'videoUrl': videoUrl,
        'status': 'pending', // pending, reviewed, action_taken
        'autoDetected': true, // แยกจากรายงานโดยผู้ใช้
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Auto-report sent to admin for content: $contentId');
    } catch (e) {
      debugPrint('Error sending auto-report to admin: $e');
    }
  }

  /// ลบเนื้อหา (สำหรับ Admin)
  Future<void> deleteContent({
    required String contentId,
    required String contentType,
    String? reason,
  }) async {
    try {
      String collectionName;

      switch (contentType) {
        case 'community_post':
        case 'post':
          collectionName = 'community_posts';
          break;
        case 'comment':
          collectionName = 'comments';
          break;
        case 'product_review':
          collectionName = 'reviews';
          break;
        case 'message':
          collectionName = 'messages';
          break;
        default:
          collectionName = 'community_posts';
      }

      // ลบเนื้อหา
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(contentId)
          .delete();

      // บันทึกประวัติการลบ
      await FirebaseFirestore.instance.collection('admin_actions').add({
        'action': 'delete_content',
        'contentId': contentId,
        'contentType': contentType,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('Content deleted by admin: $contentId');
    } catch (e) {
      debugPrint('Error deleting content: $e');
      rethrow;
    }
  }

  /// ซ่อนเนื้อหา (soft delete - สำหรับ Admin)
  Future<void> hideContent({
    required String contentId,
    required String contentType,
    String? reason,
  }) async {
    try {
      String collectionName;

      switch (contentType) {
        case 'community_post':
        case 'post':
          collectionName = 'community_posts';
          break;
        case 'comment':
          collectionName = 'comments';
          break;
        default:
          collectionName = 'community_posts';
      }

      // ซ่อนเนื้อหา (soft delete)
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(contentId)
          .update({
        'isHidden': true,
        'hiddenReason': reason,
        'hiddenAt': FieldValue.serverTimestamp(),
        'hiddenBy': 'admin',
      });

      debugPrint('Content hidden by admin: $contentId');
    } catch (e) {
      debugPrint('Error hiding content: $e');
      rethrow;
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
