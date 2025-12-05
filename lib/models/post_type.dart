// lib/models/post_type.dart

enum PostType {
  normal, // Regular post
  product, // Product listing
  activity, // Event/Activity
  announcement, // News/Announcement from admin
  poll, // Poll
  marketplace, // Marketplace item
  live, // Live stream
}

extension PostTypeExtension on PostType {
  String get name {
    switch (this) {
      case PostType.normal:
        return 'โพสต์ทั่วไป';
      case PostType.product:
        return 'ขายสินค้า';
      case PostType.activity:
        return 'กิจกรรม';
      case PostType.announcement:
        return 'ประกาศ';
      case PostType.poll:
        return 'โพล';
      case PostType.marketplace:
        return 'ตลาดซื้อขาย';
      case PostType.live:
        return 'ไลฟ์สด';
    }
  }

  String get icon {
    switch (this) {
      case PostType.normal:
        return '✍️';
      case PostType.product:
        return '🛒';
      case PostType.activity:
        return '🌱';
      case PostType.announcement:
        return '📢';
      case PostType.poll:
        return '📊';
      case PostType.marketplace:
        return '🏪';
      case PostType.live:
        return '🔴';
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
