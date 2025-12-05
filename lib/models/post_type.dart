// lib/models/post_type.dart

enum PostType {
  normal, // Regular post
  poll, // Poll (เหมือน Twitter/Facebook)
  marketplace, // Marketplace item
  activity, // Event/Activity
  announcement, // News/Announcement
}

extension PostTypeExtension on PostType {
  String get name {
    switch (this) {
      case PostType.normal:
        return 'โพสต์';
      case PostType.poll:
        return 'โพล';
      case PostType.marketplace:
        return 'ตลาดซื้อขาย';
      case PostType.activity:
        return 'กิจกรรม';
      case PostType.announcement:
        return 'ประกาศ';
    }
  }

  String get icon {
    switch (this) {
      case PostType.normal:
        return '✍️';
      case PostType.poll:
        return '📊';
      case PostType.marketplace:
        return '🛒';
      case PostType.activity:
        return '🎯';
      case PostType.announcement:
        return '📢';
    }
  }

  String get description {
    switch (this) {
      case PostType.normal:
        return 'แชร์ความคิด รูปภาพ วิดีโอ';
      case PostType.poll:
        return 'สำรวจความคิดเห็นจากเพื่อนๆ';
      case PostType.marketplace:
        return 'ซื้อขายสินค้ามือสอง';
      case PostType.activity:
        return 'สร้างกิจกรรม/อีเวนต์';
      case PostType.announcement:
        return 'ประกาศสำคัญจากแอดมิน';
    }
  }
}

class Reaction {
  static const String like = 'like';
  static const String love = 'love';
  static const String care = 'care';
  static const String wow = 'wow';
  static const String haha = 'haha';
  static const String sad = 'sad';
  static const String angry = 'angry';

  static String getEmoji(String reaction) {
    switch (reaction) {
      case like:
        return '👍';
      case love:
        return '❤️';
      case care:
        return '🤗';
      case wow:
        return '😮';
      case haha:
        return '😂';
      case sad:
        return '😢';
      case angry:
        return '😠';
      default:
        return '👍';
    }
  }
}
