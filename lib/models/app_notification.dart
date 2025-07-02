// lib/models/app_notification.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Notification Categories
enum NotificationCategory {
  buyer('buyer'),
  seller('seller'),
  investment('investment'),
  activity('activity'),
  system('system');

  const NotificationCategory(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case NotificationCategory.buyer:
        return 'ผู้ซื้อ';
      case NotificationCategory.seller:
        return 'ร้านค้า';
      case NotificationCategory.investment:
        return 'การลงทุน';
      case NotificationCategory.activity:
        return 'กิจกรรม';
      case NotificationCategory.system:
        return 'ระบบ';
    }
  }

  static NotificationCategory fromString(String value) {
    return NotificationCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationCategory.system,
    );
  }
}

// Notification Types
enum NotificationType {
  // Buyer Notifications
  orderConfirmed('order_confirmed'),
  orderShipped('order_shipped'),
  orderDelivered('order_delivered'),
  orderCancelled('order_cancelled'),
  paymentSuccess('payment_success'),
  paymentFailed('payment_failed'),
  reviewReceived('review_received'),
  productAvailable('product_available'),
  wishlistDiscount('wishlist_discount'),

  // Seller Notifications
  newOrder('new_order'),
  orderPaid('order_paid'),
  productSold('product_sold'),
  newReview('new_review'),
  lowStock('low_stock'),
  salesMilestone('sales_milestone'),
  accountVerified('account_verified'),

  // Investment Notifications
  investmentOpportunity('investment_opportunity'),
  investmentReturn('investment_return'),
  investmentMatured('investment_matured'),
  portfolioUpdate('portfolio_update'),
  marketAlert('market_alert'),
  investmentApproved('investment_approved'),
  investmentRejected('investment_rejected'),

  // Activity Notifications
  newActivity('new_activity'),
  activityReminder('activity_reminder'),
  activityCancelled('activity_cancelled'),
  activityStarting('activity_starting'),
  communityPost('community_post'),
  activityApproved('activity_approved'),
  activityRejected('activity_rejected'),
  activityUpdate('activity_update'),

  // System Notifications
  appUpdate('app_update'),
  maintenance('maintenance'),
  securityAlert('security_alert'),
  welcomeMessage('welcome_message'),
  promo('promo');

  const NotificationType(this.value);
  final String value;

  String get displayName {
    switch (this) {
      // Buyer Notifications
      case NotificationType.orderConfirmed:
        return 'คำสั่งซื้อได้รับการยืนยัน';
      case NotificationType.orderShipped:
        return 'สินค้าถูกจัดส่งแล้ว';
      case NotificationType.orderDelivered:
        return 'สินค้าถูกส่งมอบแล้ว';
      case NotificationType.orderCancelled:
        return 'คำสั่งซื้อถูกยกเลิก';
      case NotificationType.paymentSuccess:
        return 'ชำระเงินสำเร็จ';
      case NotificationType.paymentFailed:
        return 'ชำระเงินไม่สำเร็จ';
      case NotificationType.reviewReceived:
        return 'ได้รับรีวิว';
      case NotificationType.productAvailable:
        return 'สินค้ามีสต็อกแล้ว';
      case NotificationType.wishlistDiscount:
        return 'สินค้าในรายการโปรดลดราคา';

      // Seller Notifications
      case NotificationType.newOrder:
        return 'คำสั่งซื้อใหม่';
      case NotificationType.orderPaid:
        return 'ลูกค้าชำระเงินแล้ว';
      case NotificationType.productSold:
        return 'สินค้าขายออกแล้ว';
      case NotificationType.newReview:
        return 'รีวิวใหม่';
      case NotificationType.lowStock:
        return 'สต็อกต่ำ';
      case NotificationType.salesMilestone:
        return 'เป้าหมายยอดขาย';
      case NotificationType.accountVerified:
        return 'บัญชีได้รับการยืนยัน';

      // Investment Notifications
      case NotificationType.investmentOpportunity:
        return 'โอกาสลงทุนใหม่';
      case NotificationType.investmentReturn:
        return 'ผลตอบแทนการลงทุน';
      case NotificationType.investmentMatured:
        return 'การลงทุนครบกำหนด';
      case NotificationType.portfolioUpdate:
        return 'อัปเดตพอร์ตโฟลิโอ';
      case NotificationType.marketAlert:
        return 'เตือนตลาด';
      case NotificationType.investmentApproved:
        return 'การลงทุนได้รับอนุมัติ';
      case NotificationType.investmentRejected:
        return 'การลงทุนถูกปฏิเสธ';

      // Activity Notifications
      case NotificationType.newActivity:
        return 'กิจกรรมใหม่';
      case NotificationType.activityReminder:
        return 'เตือนกิจกรรม';
      case NotificationType.activityCancelled:
        return 'กิจกรรมถูกยกเลิก';
      case NotificationType.activityStarting:
        return 'กิจกรรมจะเริ่มแล้ว';
      case NotificationType.communityPost:
        return 'โพสต์ชุมชน';
      case NotificationType.activityApproved:
        return 'กิจกรรมได้รับอนุมัติ';
      case NotificationType.activityRejected:
        return 'กิจกรรมถูกปฏิเสธ';
      case NotificationType.activityUpdate:
        return 'อัปเดตกิจกรรม';

      // System Notifications
      case NotificationType.appUpdate:
        return 'อัปเดตแอป';
      case NotificationType.maintenance:
        return 'ปรับปรุงระบบ';
      case NotificationType.securityAlert:
        return 'เตือนความปลอดภัย';
      case NotificationType.welcomeMessage:
        return 'ข้อความต้อนรับ';
      case NotificationType.promo:
        return 'ข้อเสนอพิเศษ';
    }
  }

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationType.welcomeMessage,
    );
  }

  NotificationCategory get category {
    switch (this) {
      case NotificationType.orderConfirmed:
      case NotificationType.orderShipped:
      case NotificationType.orderDelivered:
      case NotificationType.orderCancelled:
      case NotificationType.paymentSuccess:
      case NotificationType.paymentFailed:
      case NotificationType.reviewReceived:
      case NotificationType.productAvailable:
      case NotificationType.wishlistDiscount:
        return NotificationCategory.buyer;

      case NotificationType.newOrder:
      case NotificationType.orderPaid:
      case NotificationType.productSold:
      case NotificationType.newReview:
      case NotificationType.lowStock:
      case NotificationType.salesMilestone:
      case NotificationType.accountVerified:
        return NotificationCategory.seller;

      case NotificationType.investmentOpportunity:
      case NotificationType.investmentReturn:
      case NotificationType.investmentMatured:
      case NotificationType.portfolioUpdate:
      case NotificationType.marketAlert:
      case NotificationType.investmentApproved:
      case NotificationType.investmentRejected:
        return NotificationCategory.investment;

      case NotificationType.newActivity:
      case NotificationType.activityReminder:
      case NotificationType.activityCancelled:
      case NotificationType.activityStarting:
      case NotificationType.communityPost:
      case NotificationType.activityApproved:
      case NotificationType.activityRejected:
      case NotificationType.activityUpdate:
        return NotificationCategory.activity;

      default:
        return NotificationCategory.system;
    }
  }
}

// Priority levels
enum NotificationPriority {
  low('low'),
  normal('normal'),
  high('high'),
  urgent('urgent');

  const NotificationPriority(this.value);
  final String value;

  static NotificationPriority fromString(String value) {
    return NotificationPriority.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationPriority.normal,
    );
  }
}

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationCategory category;
  final NotificationPriority priority;
  final String? relatedId;
  final Map<String, dynamic>? data; // Additional data
  final String? imageUrl;
  final String? actionUrl; // Deep link or navigation target
  final bool isRead;
  final bool isArchived;
  final Timestamp createdAt;
  final Timestamp? expiresAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    NotificationCategory? category,
    this.priority = NotificationPriority.normal,
    this.relatedId,
    this.data,
    this.imageUrl,
    this.actionUrl,
    this.isRead = false,
    this.isArchived = false,
    required this.createdAt,
    this.expiresAt,
  }) : category = category ?? type.category;

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      type: NotificationType.fromString(map['type'] as String),
      category: NotificationCategory.fromString(
          map['category'] as String? ?? 'system'),
      priority: NotificationPriority.fromString(
          map['priority'] as String? ?? 'normal'),
      relatedId: map['relatedId'] as String?,
      data: map['data'] as Map<String, dynamic>?,
      imageUrl: map['imageUrl'] as String?,
      actionUrl: map['actionUrl'] as String?,
      isRead: map['isRead'] as bool? ?? false,
      isArchived: map['isArchived'] as bool? ?? false,
      createdAt: map['createdAt'] as Timestamp,
      expiresAt: map['expiresAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.value,
      'category': category.value,
      'priority': priority.value,
      'relatedId': relatedId,
      'data': data,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'isRead': isRead,
      'isArchived': isArchived,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    NotificationCategory? category,
    NotificationPriority? priority,
    String? relatedId,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
    bool? isRead,
    bool? isArchived,
    Timestamp? createdAt,
    Timestamp? expiresAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      relatedId: relatedId ?? this.relatedId,
      data: data ?? this.data,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      isRead: isRead ?? this.isRead,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  String get formattedDate {
    final now = DateTime.now();
    final date = createdAt.toDate();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'เมื่อสักครู่';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} วันที่แล้ว';
    } else {
      return DateFormat('dd MMM yyyy').format(date);
    }
  }

  String get detailedFormattedDate {
    return DateFormat('dd MMM yyyy เวลา HH:mm น.').format(createdAt.toDate());
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!.toDate());
  }

  bool get isRecent {
    final difference = DateTime.now().difference(createdAt.toDate());
    return difference.inHours < 24;
  }
}
