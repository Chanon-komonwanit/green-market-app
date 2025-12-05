// lib/utils/hashtag_detector.dart

class HashtagDetector {
  /// ดึง hashtags (#) จากข้อความ
  static List<String> extractHashtags(String text) {
    final RegExp hashtagRegex = RegExp(r'#([ก-๙a-zA-Z0-9_]+)', unicode: true);
    final matches = hashtagRegex.allMatches(text);

    return matches
        .map((match) => match.group(1)!)
        .where((tag) => tag.isNotEmpty)
        .toSet() // Remove duplicates
        .toList();
  }

  /// ดึง mentions (@) จากข้อความ
  static List<String> extractMentions(String text) {
    final RegExp mentionRegex = RegExp(r'@([ก-๙a-zA-Z0-9_]+)', unicode: true);
    final matches = mentionRegex.allMatches(text);

    return matches
        .map((match) => match.group(1)!)
        .where((mention) => mention.isNotEmpty)
        .toSet() // Remove duplicates
        .toList();
  }

  /// แนะนำ hashtags ยอดนิยม
  static List<String> getSuggestedHashtags() {
    return [
      'ปลูกผัก',
      'สวนครัว',
      'ออร์แกนิค',
      'เกษตรอินทรีย์',
      'ลดโลกร้อน',
      'รักษ์โลก',
      'กินดีอยู่ดี',
      'ผักสวนครัว',
      'ผักปลอดสาร',
      'ชีวิตสีเขียว',
      'รักษ์สิ่งแวดล้อม',
      'เกษตรยั่งยืน',
      'ศูนย์คาร์บอน',
      'รีไซเคิล',
      'ลดขยะ',
    ];
  }

  /// หมวดหมู่มาตรฐาน (เหมือน Facebook Groups)
  static List<PostCategory> getStandardCategories() {
    return [
      PostCategory(
        id: 'organic_farming',
        name: 'เกษตรอินทรีย์',
        icon: '🌾',
        tags: ['ปลูกผัก', 'ออร์แกนิค', 'เกษตรอินทรีย์'],
      ),
      PostCategory(
        id: 'home_garden',
        name: 'สวนครัว',
        icon: '🏡',
        tags: ['สวนครัว', 'ผักสวนครัว', 'ปลูกผักกินเอง'],
      ),
      PostCategory(
        id: 'sustainable_living',
        name: 'ชีวิตยั่งยืน',
        icon: '♻️',
        tags: ['รักษ์โลก', 'ลดโลกร้อน', 'ชีวิตสีเขียว'],
      ),
      PostCategory(
        id: 'marketplace',
        name: 'ตลาดซื้อขาย',
        icon: '🛒',
        tags: ['ขายของ', 'ตลาดนัด', 'ผักออร์แกนิค'],
      ),
      PostCategory(
        id: 'knowledge_sharing',
        name: 'แบ่งปันความรู้',
        icon: '📚',
        tags: ['เทคนิค', 'วิธีทำ', 'สอนทำ'],
      ),
      PostCategory(
        id: 'community_activity',
        name: 'กิจกรรมชุมชน',
        icon: '🤝',
        tags: ['กิจกรรม', 'ชุมชน', 'อาสา'],
      ),
    ];
  }
}

class PostCategory {
  final String id;
  final String name;
  final String icon;
  final List<String> tags;

  PostCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.tags,
  });
}
