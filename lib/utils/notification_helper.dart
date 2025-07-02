// lib/utils/notification_helper.dart

import '../models/app_notification.dart';
import '../services/notification_service.dart';

class NotificationHelper {
  static final NotificationService _notificationService = NotificationService();

  // ============ BUYER NOTIFICATIONS ============

  /// แจ้งเตือนเมื่อคำสั่งซื้อได้รับการยืนยัน
  static Future<void> orderConfirmed({
    required String userId,
    required String orderId,
    required String orderTotal,
    required List<String> productNames,
  }) async {
    await _notificationService.sendBuyerNotification(
      userId: userId,
      title: 'คำสั่งซื้อได้รับการยืนยันแล้ว',
      body:
          'คำสั่งซื้อ #$orderId มูลค่า $orderTotal บาท ได้รับการยืนยันแล้ว ร้านค้าจะดำเนินการจัดส่งโดยเร็ว',
      type: NotificationType.orderConfirmed,
      relatedId: orderId,
      data: {
        'orderId': orderId,
        'orderTotal': orderTotal,
        'productCount': productNames.length.toString(),
        'products': productNames.join(', '),
      },
      actionUrl: '/order/$orderId',
      priority: NotificationPriority.high,
    );
  }

  /// แจ้งเตือนเมื่อสินค้าถูกจัดส่งแล้ว
  static Future<void> orderShipped({
    required String userId,
    required String orderId,
    required String trackingNumber,
    required String courierName,
    required String estimatedDelivery,
  }) async {
    await _notificationService.sendBuyerNotification(
      userId: userId,
      title: 'สินค้าถูกจัดส่งแล้ว',
      body:
          'คำสั่งซื้อ #$orderId ถูกจัดส่งแล้วผ่าน $courierName หมายเลขติดตาม: $trackingNumber',
      type: NotificationType.orderShipped,
      relatedId: orderId,
      data: {
        'orderId': orderId,
        'trackingNumber': trackingNumber,
        'courier': courierName,
        'estimatedDelivery': estimatedDelivery,
      },
      actionUrl: '/tracking/$trackingNumber',
      priority: NotificationPriority.high,
    );
  }

  /// แจ้งเตือนเมื่อสินค้าถูกส่งมอบแล้ว
  static Future<void> orderDelivered({
    required String userId,
    required String orderId,
    required String deliveryDate,
  }) async {
    await _notificationService.sendBuyerNotification(
      userId: userId,
      title: 'สินค้าถูกส่งมอบแล้ว',
      body:
          'คำสั่งซื้อ #$orderId ถูกส่งมอบเรียบร้อยแล้ว กรุณาตรวจสอบสินค้าและให้คะแนนรีวิว',
      type: NotificationType.orderDelivered,
      relatedId: orderId,
      data: {
        'orderId': orderId,
        'deliveryDate': deliveryDate,
      },
      actionUrl: '/order/$orderId/review',
      priority: NotificationPriority.normal,
    );
  }

  /// แจ้งเตือนเมื่อการชำระเงินสำเร็จ
  static Future<void> paymentSuccess({
    required String userId,
    required String orderId,
    required String amount,
    required String paymentMethod,
  }) async {
    await _notificationService.sendBuyerNotification(
      userId: userId,
      title: 'ชำระเงินสำเร็จ',
      body:
          'การชำระเงินสำหรับคำสั่งซื้อ #$orderId จำนวน $amount บาท สำเร็จแล้ว',
      type: NotificationType.paymentSuccess,
      relatedId: orderId,
      data: {
        'orderId': orderId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'timestamp': DateTime.now().toIso8601String(),
      },
      actionUrl: '/order/$orderId',
      priority: NotificationPriority.high,
    );
  }

  /// แจ้งเตือนเมื่อสินค้าในรายการโปรดลดราคา
  static Future<void> wishlistDiscount({
    required String userId,
    required String productId,
    required String productName,
    required String originalPrice,
    required String discountPrice,
    required String discountPercent,
  }) async {
    await _notificationService.sendBuyerNotification(
      userId: userId,
      title: 'สินค้าในรายการโปรดลดราคา!',
      body:
          '$productName ลดราคาแล้ว $discountPercent จาก $originalPrice เหลือ $discountPrice',
      type: NotificationType.wishlistDiscount,
      relatedId: productId,
      data: {
        'productId': productId,
        'productName': productName,
        'originalPrice': originalPrice,
        'discountPrice': discountPrice,
        'discountPercent': discountPercent,
      },
      actionUrl: '/product/$productId',
      priority: NotificationPriority.normal,
    );
  }

  // ============ SELLER NOTIFICATIONS ============

  /// แจ้งเตือนเมื่อมีคำสั่งซื้อใหม่
  static Future<void> newOrder({
    required String sellerId,
    required String orderId,
    required String customerName,
    required String orderTotal,
    required List<Map<String, dynamic>> products,
  }) async {
    final productList =
        products.map((p) => '${p['name']} x${p['quantity']}').join(', ');

    await _notificationService.sendSellerNotification(
      userId: sellerId,
      title: 'คำสั่งซื้อใหม่ #$orderId',
      body:
          'คุณมีคำสั่งซื้อใหม่จาก $customerName มูลค่า $orderTotal บาท ($productList)',
      type: NotificationType.newOrder,
      relatedId: orderId,
      data: {
        'orderId': orderId,
        'customerName': customerName,
        'orderTotal': orderTotal,
        'productCount': products.length.toString(),
        'products': productList,
      },
      actionUrl: '/seller/order/$orderId',
      priority: NotificationPriority.urgent,
    );
  }

  /// แจ้งเตือนเมื่อได้รับรีวิวใหม่
  static Future<void> newReview({
    required String sellerId,
    required String productId,
    required String productName,
    required String customerName,
    required int rating,
    required String reviewText,
    String? reviewImageUrl,
  }) async {
    final stars = '⭐' * rating;

    await _notificationService.sendSellerNotification(
      userId: sellerId,
      title: 'รีวิวใหม่ $rating ดาว!',
      body:
          '$customerName ให้รีวิว $stars สำหรับ "$productName"\n"$reviewText"',
      type: NotificationType.newReview,
      relatedId: productId,
      data: {
        'productId': productId,
        'productName': productName,
        'customerName': customerName,
        'rating': rating.toString(),
        'reviewText': reviewText,
      },
      imageUrl: reviewImageUrl,
      actionUrl: '/seller/review/$productId',
      priority: NotificationPriority.normal,
    );
  }

  /// แจ้งเตือนเมื่อสต็อกสินค้าต่ำ
  static Future<void> lowStock({
    required String sellerId,
    required String productId,
    required String productName,
    required int currentStock,
    required int minimumStock,
  }) async {
    await _notificationService.sendSellerNotification(
      userId: sellerId,
      title: 'แจ้งเตือนสต็อกต่ำ',
      body:
          '"$productName" เหลือเพียง $currentStock ชิ้น (ต่ำกว่าขั้นต่ำ $minimumStock ชิ้น) ควรเติมสต็อก',
      type: NotificationType.lowStock,
      relatedId: productId,
      data: {
        'productId': productId,
        'productName': productName,
        'currentStock': currentStock.toString(),
        'minimumStock': minimumStock.toString(),
      },
      actionUrl: '/seller/product/$productId/inventory',
      priority: NotificationPriority.high,
    );
  }

  /// แจ้งเตือนเมื่อถึงเป้าหมายยอดขาย
  static Future<void> salesMilestone({
    required String sellerId,
    required String milestone,
    required String currentSales,
    required String period,
  }) async {
    await _notificationService.sendSellerNotification(
      userId: sellerId,
      title: 'ยินดีด้วย! ถึงเป้าหมายยอดขาย',
      body:
          'คุณทำยอดขายได้ $currentSales บาท ถึงเป้าหมาย $milestone ใน$period แล้ว',
      type: NotificationType.salesMilestone,
      data: {
        'milestone': milestone,
        'currentSales': currentSales,
        'period': period,
        'achievement': 'completed',
      },
      actionUrl: '/seller/analytics',
      priority: NotificationPriority.normal,
    );
  }

  // ============ INVESTMENT NOTIFICATIONS ============

  /// แจ้งเตือนโอกาสลงทุนใหม่
  static Future<void> investmentOpportunity({
    required String userId,
    required String opportunityId,
    required String title,
    required String description,
    required String expectedReturn,
    required String riskLevel,
    required String minimumInvestment,
  }) async {
    await _notificationService.sendInvestmentNotification(
      userId: userId,
      title: 'โอกาสลงทุนใหม่: $title',
      body:
          '$description\nผลตอบแทนคาดหวัง: $expectedReturn\nระดับความเสี่ยง: $riskLevel',
      type: NotificationType.investmentOpportunity,
      relatedId: opportunityId,
      data: {
        'opportunityId': opportunityId,
        'expectedReturn': expectedReturn,
        'riskLevel': riskLevel,
        'minimumInvestment': minimumInvestment,
      },
      actionUrl: '/investment/$opportunityId',
      priority: NotificationPriority.normal,
    );
  }

  /// แจ้งเตือนผลตอบแทนการลงทุน
  static Future<void> investmentReturn({
    required String userId,
    required String investmentId,
    required String amount,
    required String returnAmount,
    required String returnPercentage,
  }) async {
    await _notificationService.sendInvestmentNotification(
      userId: userId,
      title: 'คุณได้รับผลตอบแทนการลงทุน',
      body:
          'การลงทุน #$investmentId ได้รับผลตอบแทน $returnAmount บาท ($returnPercentage)',
      type: NotificationType.investmentReturn,
      relatedId: investmentId,
      data: {
        'investmentId': investmentId,
        'originalAmount': amount,
        'returnAmount': returnAmount,
        'returnPercentage': returnPercentage,
      },
      actionUrl: '/investment/$investmentId',
      priority: NotificationPriority.high,
    );
  }

  /// แจ้งเตือนอัปเดตพอร์ตโฟลิโอ
  static Future<void> portfolioUpdate({
    required String userId,
    required String totalValue,
    required String dailyChange,
    required String dailyChangePercent,
    required bool isGain,
  }) async {
    final changeIndicator = isGain ? '📈' : '📉';
    final changeText = isGain ? 'เพิ่มขึ้น' : 'ลดลง';

    await _notificationService.sendInvestmentNotification(
      userId: userId,
      title: '$changeIndicator อัปเดตพอร์ตโฟลิโอ',
      body:
          'มูลค่าพอร์ตโฟลิโอปัจจุบัน $totalValue บาท ($changeText $dailyChange บาท, $dailyChangePercent%)',
      type: NotificationType.portfolioUpdate,
      data: {
        'totalValue': totalValue,
        'dailyChange': dailyChange,
        'dailyChangePercent': dailyChangePercent,
        'isGain': isGain.toString(),
      },
      actionUrl: '/investment/portfolio',
      priority: NotificationPriority.normal,
    );
  }

  // ============ ACTIVITY NOTIFICATIONS ============

  /// แจ้งเตือนกิจกรรมใหม่
  static Future<void> newActivity({
    required String userId,
    required String activityId,
    required String activityName,
    required String description,
    required String date,
    required String location,
  }) async {
    await _notificationService.sendActivityNotification(
      userId: userId,
      title: 'กิจกรรมใหม่: $activityName',
      body: '$description\n📅 $date\n📍 $location',
      type: NotificationType.newActivity,
      relatedId: activityId,
      data: {
        'activityId': activityId,
        'activityName': activityName,
        'date': date,
        'location': location,
      },
      actionUrl: '/activity/$activityId',
      priority: NotificationPriority.normal,
    );
  }

  /// แจ้งเตือนกิจกรรมจะเริ่มแล้ว
  static Future<void> activityStarting({
    required String userId,
    required String activityId,
    required String activityName,
    required String timeToStart,
    required String location,
  }) async {
    await _notificationService.sendActivityNotification(
      userId: userId,
      title: 'กิจกรรมจะเริ่มแล้ว!',
      body: '"$activityName" จะเริ่มใน $timeToStart ที่ $location',
      type: NotificationType.activityStarting,
      relatedId: activityId,
      data: {
        'activityId': activityId,
        'activityName': activityName,
        'timeToStart': timeToStart,
        'location': location,
      },
      actionUrl: '/activity/$activityId',
      priority: NotificationPriority.high,
    );
  }

  /// แจ้งเตือนโพสต์ชุมชนใหม่
  static Future<void> communityPost({
    required String userId,
    required String postId,
    required String authorName,
    required String postTitle,
    required String postPreview,
  }) async {
    await _notificationService.sendActivityNotification(
      userId: userId,
      title: 'โพสต์ใหม่จาก $authorName',
      body: '$postTitle\n$postPreview',
      type: NotificationType.communityPost,
      relatedId: postId,
      data: {
        'postId': postId,
        'authorName': authorName,
        'postTitle': postTitle,
      },
      actionUrl: '/community/post/$postId',
      priority: NotificationPriority.low,
    );
  }

  // ============ SYSTEM NOTIFICATIONS ============

  /// แจ้งเตือนอัปเดตแอป
  static Future<void> appUpdate({
    required String userId,
    required String version,
    required String features,
    required bool isRequired,
  }) async {
    await _notificationService.sendSystemNotification(
      userId: userId,
      title: isRequired ? 'จำเป็นต้องอัปเดต' : 'มีเวอร์ชันใหม่',
      body: 'Green Market เวอร์ชัน $version พร้อมให้ดาวน์โหลด\n$features',
      type: NotificationType.appUpdate,
      data: {
        'version': version,
        'features': features,
        'isRequired': isRequired.toString(),
      },
      actionUrl: '/update',
      priority: isRequired
          ? NotificationPriority.urgent
          : NotificationPriority.normal,
    );
  }

  /// แจ้งเตือนข้อเสนอพิเศษ
  static Future<void> promo({
    required String userId,
    required String promoId,
    required String title,
    required String description,
    required String discount,
    required String validUntil,
  }) async {
    await _notificationService.sendSystemNotification(
      userId: userId,
      title: '🎉 $title',
      body: '$description\nลดทันที $discount\nใช้ได้ถึง $validUntil',
      type: NotificationType.promo,
      relatedId: promoId,
      data: {
        'promoId': promoId,
        'discount': discount,
        'validUntil': validUntil,
      },
      actionUrl: '/promo/$promoId',
      priority: NotificationPriority.normal,
    );
  }

  /// แจ้งเตือนต้อนรับสมาชิกใหม่
  static Future<void> welcomeMessage({
    required String userId,
    required String userName,
  }) async {
    await _notificationService.sendSystemNotification(
      userId: userId,
      title: 'ยินดีต้อนรับสู่ Green Market!',
      body:
          'สวัสดี $userName! ขอบคุณที่เข้าร่วมชุมชน Green Market เริ่มต้นการช้อปปิ้งเพื่อสิ่งแวดล้อมได้เลย',
      type: NotificationType.welcomeMessage,
      data: {
        'userName': userName,
        'joinDate': DateTime.now().toIso8601String(),
      },
      actionUrl: '/welcome',
      priority: NotificationPriority.normal,
    );
  }

  // ============ BATCH NOTIFICATIONS ============

  /// ส่งการแจ้งเตือนหลายคนพร้อมกัน
  static Future<void> sendBulkNotification({
    required List<String> userIds,
    required String title,
    required String body,
    required NotificationType type,
    String? relatedId,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    final futures = userIds.map((userId) async {
      switch (type.category) {
        case NotificationCategory.buyer:
          return _notificationService.sendBuyerNotification(
            userId: userId,
            title: title,
            body: body,
            type: type,
            relatedId: relatedId,
            data: data,
            imageUrl: imageUrl,
            actionUrl: actionUrl,
            priority: priority,
          );
        case NotificationCategory.seller:
          return _notificationService.sendSellerNotification(
            userId: userId,
            title: title,
            body: body,
            type: type,
            relatedId: relatedId,
            data: data,
            imageUrl: imageUrl,
            actionUrl: actionUrl,
            priority: priority,
          );
        case NotificationCategory.investment:
          return _notificationService.sendInvestmentNotification(
            userId: userId,
            title: title,
            body: body,
            type: type,
            relatedId: relatedId,
            data: data,
            imageUrl: imageUrl,
            actionUrl: actionUrl,
            priority: priority,
          );
        case NotificationCategory.activity:
          return _notificationService.sendActivityNotification(
            userId: userId,
            title: title,
            body: body,
            type: type,
            relatedId: relatedId,
            data: data,
            imageUrl: imageUrl,
            actionUrl: actionUrl,
            priority: priority,
          );
        case NotificationCategory.system:
          return _notificationService.sendSystemNotification(
            userId: userId,
            title: title,
            body: body,
            type: type,
            relatedId: relatedId,
            data: data,
            imageUrl: imageUrl,
            actionUrl: actionUrl,
            priority: priority,
          );
      }
    });

    await Future.wait(futures);
  }
}
