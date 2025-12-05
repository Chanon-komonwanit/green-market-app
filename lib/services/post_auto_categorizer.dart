// lib/services/post_auto_categorizer.dart
import '../models/post_type.dart';
import '../utils/hashtag_detector.dart';

/// ระบบคัดแยกหมวดหมู่โพสต์อัตโนมัติ (แบบ Facebook/Instagram AI)
class PostAutoCategorizer {
  /// คัดแยกหมวดหมู่จากเนื้อหาโพสต์
  static PostCategorizationResult categorize(String content,
      {List<String>? hashtags}) {
    final text = content.toLowerCase();
    final tags = hashtags ?? HashtagDetector.extractHashtags(content);

    // คำที่บ่งบอก marketplace
    final marketplaceKeywords = [
      'ขาย',
      'จอง',
      'สั่งซื้อ',
      'ราคา',
      'บาท',
      '฿',
      'ขายของ',
      'มีขาย',
      'ขายด่วน',
      'ลดราคา',
      'โปรโมชั่น',
      'สินค้า',
      'ซื้อ',
      'หาซื้อ',
      'อยากได้',
      'มีไหม',
      'ตลาด'
    ];

    // คำที่บ่งบอก activity
    final activityKeywords = [
      'กิจกรรม',
      'งาน',
      'ร่วม',
      'อาสา',
      'ชุมชน',
      'มาเจอกัน',
      'เชิญชวน',
      'ประชุม',
      'สัมมนา',
      'อบรม',
      'workshop',
      'มาร่วม',
      'ไปด้วยกัน',
      'event',
      'มาร่วมงาน'
    ];

    // คำที่บ่งบอก announcement
    final announcementKeywords = [
      'ประกาศ',
      'แจ้ง',
      'ข่าว',
      'แจ้งเตือน',
      'แจ้งความ',
      'สำคัญ',
      'เร่งด่วน',
      'ฉุกเฉิน',
      'อัพเดท',
      'update',
      'ประชาสัมพันธ์',
      'แจ้งให้ทราบ'
    ];

    // คำที่บ่งบอก poll/survey
    final pollKeywords = [
      'โหวต',
      'เลือก',
      'คิดเห็น',
      'สำรวจ',
      'อยากรู้',
      'poll',
      'vote',
      'ลงคะแนน',
      'อะไรดี',
      'แบบสำรวจ',
      'ว่าไง',
      'คิดยังไง',
      'อันไหนดี'
    ];

    // นับคะแนนแต่ละหมวด
    int marketplaceScore = _calculateScore(text, tags, marketplaceKeywords);
    int activityScore = _calculateScore(text, tags, activityKeywords);
    int announcementScore = _calculateScore(text, tags, announcementKeywords);
    int pollScore = _calculateScore(text, tags, pollKeywords);

    // หาคะแนนสูงสุด
    PostType suggestedType = PostType.normal;
    String? suggestedCategoryId;
    List<String> suggestedTags = [];
    double confidence = 0.0;

    // Marketplace
    if (marketplaceScore > 0) {
      suggestedType = PostType.marketplace;
      suggestedCategoryId = 'marketplace';
      suggestedTags = ['ขายของ', 'ตลาดนัด', 'ผักออร์แกนิค'];
      confidence = _normalizeScore(marketplaceScore);
    }

    // Activity
    if (activityScore > marketplaceScore) {
      suggestedType = PostType.activity;
      suggestedCategoryId = 'community_activity';
      suggestedTags = ['กิจกรรม', 'ชุมชน', 'อาสา'];
      confidence = _normalizeScore(activityScore);
    }

    // Announcement
    if (announcementScore > activityScore &&
        announcementScore > marketplaceScore) {
      suggestedType = PostType.announcement;
      suggestedCategoryId = 'announcement';
      suggestedTags = ['ประกาศ', 'ข่าวสาร'];
      confidence = _normalizeScore(announcementScore);
    }

    // Poll
    if (pollScore > announcementScore &&
        pollScore > activityScore &&
        pollScore > marketplaceScore) {
      suggestedType = PostType.poll;
      suggestedCategoryId = 'poll';
      suggestedTags = ['โพล', 'สำรวจความคิดเห็น'];
      confidence = _normalizeScore(pollScore);
    }

    // ถ้าไม่มีคำที่ชัดเจน ดูจาก context ทั่วไป
    if (confidence < 0.3) {
      final result = _categorizeByGeneralContext(text, tags);
      suggestedCategoryId = result.categoryId;
      suggestedTags = result.tags;
      confidence = 0.5; // Medium confidence
    }

    return PostCategorizationResult(
      suggestedType: suggestedType,
      suggestedCategoryId: suggestedCategoryId,
      suggestedTags: suggestedTags,
      confidence: confidence,
      detectedKeywords: _getDetectedKeywords(text, [
        ...marketplaceKeywords,
        ...activityKeywords,
        ...announcementKeywords,
        ...pollKeywords,
      ]),
    );
  }

  /// คำนวณคะแนนจากคำสำคัญและ hashtags
  static int _calculateScore(
      String text, List<String> hashtags, List<String> keywords) {
    int score = 0;

    // ตรวจสอบคำสำคัญในข้อความ
    for (String keyword in keywords) {
      if (text.contains(keyword.toLowerCase())) {
        score += 2; // น้ำหนักสูงกว่า
      }
    }

    // ตรวจสอบคำสำคัญใน hashtags
    for (String tag in hashtags) {
      final tagLower = tag.toLowerCase();
      for (String keyword in keywords) {
        if (tagLower.contains(keyword.toLowerCase())) {
          score += 1;
        }
      }
    }

    return score;
  }

  /// แปลงคะแนนเป็น confidence (0-1)
  static double _normalizeScore(int score) {
    if (score >= 5) return 0.9;
    if (score >= 3) return 0.7;
    if (score >= 1) return 0.5;
    return 0.3;
  }

  /// คัดแยกตาม context ทั่วไป
  static _CategorySuggestion _categorizeByGeneralContext(
      String text, List<String> hashtags) {
    // เกษตรอินทรีย์
    if (_containsAny(text, ['ปลูก', 'ผัก', 'ออร์แกนิค', 'อินทรีย์', 'สวน']) ||
        _containsAny(hashtags, ['ปลูกผัก', 'ออร์แกนิค', 'เกษตรอินทรีย์'])) {
      return _CategorySuggestion(
        categoryId: 'organic_farming',
        tags: ['ปลูกผัก', 'ออร์แกนิค', 'เกษตรอินทรีย์'],
      );
    }

    // สวนครัว
    if (_containsAny(text, ['สวนครัว', 'ปลูกกินเอง', 'บ้าน']) ||
        _containsAny(hashtags, ['สวนครัว', 'ผักสวนครัว'])) {
      return _CategorySuggestion(
        categoryId: 'home_garden',
        tags: ['สวนครัว', 'ผักสวนครัว', 'ปลูกผักกินเอง'],
      );
    }

    // ชีวิตยั่งยืน
    if (_containsAny(text,
            ['รักษ์โลก', 'ลดโลกร้อน', 'สิ่งแวดล้อม', 'รีไซเคิล', 'ลดขยะ']) ||
        _containsAny(hashtags, ['รักษ์โลก', 'ลดโลกร้อน', 'ชีวิตสีเขียว'])) {
      return _CategorySuggestion(
        categoryId: 'sustainable_living',
        tags: ['รักษ์โลก', 'ลดโลกร้อน', 'ชีวิตสีเขียว'],
      );
    }

    // แบ่งปันความรู้
    if (_containsAny(text, [
          'เทคนิค',
          'วิธีทำ',
          'วิธี',
          'สอน',
          'แชร์',
          'บอกวิธี',
          'คำแนะนำ'
        ]) ||
        _containsAny(hashtags, ['เทคนิค', 'วิธีทำ', 'สอนทำ'])) {
      return _CategorySuggestion(
        categoryId: 'knowledge_sharing',
        tags: ['เทคนิค', 'วิธีทำ', 'สอนทำ'],
      );
    }

    // Default: General post
    return _CategorySuggestion(
      categoryId: null,
      tags: [],
    );
  }

  /// ตรวจสอบว่ามีคำใดคำหนึ่งในรายการหรือไม่
  static bool _containsAny(dynamic source, List<String> keywords) {
    final text = source is String ? source.toLowerCase() : '';
    final list = source is List<String>
        ? source.map((s) => s.toLowerCase()).toList()
        : <String>[];

    for (String keyword in keywords) {
      final lowerKeyword = keyword.toLowerCase();
      if (text.contains(lowerKeyword) || list.contains(lowerKeyword)) {
        return true;
      }
    }
    return false;
  }

  /// ดึงคำสำคัญที่ตรวจพบ
  static List<String> _getDetectedKeywords(
      String text, List<String> allKeywords) {
    final detected = <String>[];
    for (String keyword in allKeywords) {
      if (text.contains(keyword.toLowerCase())) {
        detected.add(keyword);
      }
    }
    return detected;
  }
}

/// ผลลัพธ์การคัดแยกหมวดหมู่
class PostCategorizationResult {
  final PostType suggestedType;
  final String? suggestedCategoryId;
  final List<String> suggestedTags;
  final double confidence; // 0-1 (0 = ไม่แน่ใจ, 1 = แน่ใจมาก)
  final List<String> detectedKeywords;

  PostCategorizationResult({
    required this.suggestedType,
    this.suggestedCategoryId,
    required this.suggestedTags,
    required this.confidence,
    required this.detectedKeywords,
  });

  /// ความมั่นใจระดับสูง (>70%)
  bool get isHighConfidence => confidence >= 0.7;

  /// ความมั่นใจระดับกลาง (40-70%)
  bool get isMediumConfidence => confidence >= 0.4 && confidence < 0.7;

  /// ความมั่นใจระดับต่ำ (<40%)
  bool get isLowConfidence => confidence < 0.4;
}

class _CategorySuggestion {
  final String? categoryId;
  final List<String> tags;

  _CategorySuggestion({
    required this.categoryId,
    required this.tags,
  });
}
