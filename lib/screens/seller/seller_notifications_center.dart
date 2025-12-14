import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// ศูนย์การแจ้งเตือนผู้ขาย - Notification Center (Shopee/TikTok Style)
/// รองรับ: คำสั่งซื้อใหม่, สินค้าใกล้หมด, รีวิวใหม่, โปรโมชั่นหมดอายุ, ข้อความลูกค้า
class SellerNotificationCenter extends StatefulWidget {
  const SellerNotificationCenter({super.key});

  @override
  State<SellerNotificationCenter> createState() =>
      _SellerNotificationCenterState();
}

class _SellerNotificationCenterState extends State<SellerNotificationCenter>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _sellerId;

  List<NotificationItem> _allNotifications = [];
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _sellerId = FirebaseAuth.instance.currentUser?.uid;
    if (_sellerId != null) {
      _loadNotifications();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      List<NotificationItem> notifications = [];

      // 1. คำสั่งซื้อใหม่
      final newOrders = await _firestore
          .collection('orders')
          .where('sellerId', isEqualTo: _sellerId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      for (var doc in newOrders.docs) {
        final data = doc.data();
        notifications.add(NotificationItem(
          id: doc.id,
          type: NotificationType.newOrder,
          title: 'คำสั่งซื้อใหม่ #${doc.id.substring(0, 8)}',
          message:
              'มีคำสั่งซื้อใหม่รอดำเนินการ มูลค่า ฿${(data['totalAmount'] ?? 0).toStringAsFixed(0)}',
          timestamp: (data['createdAt'] as Timestamp).toDate(),
          isRead: false,
          actionData: {'orderId': doc.id},
        ));
      }

      // 2. สินค้าใกล้หมด
      final lowStockProducts = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: _sellerId)
          .where('isActive', isEqualTo: true)
          .get();

      for (var doc in lowStockProducts.docs) {
        final data = doc.data();
        final stock = (data['stock'] as num?)?.toInt() ?? 0;
        if (stock <= 5 && stock > 0) {
          notifications.add(NotificationItem(
            id: 'stock_${doc.id}',
            type: NotificationType.lowStock,
            title: '⚠️ สินค้าใกล้หมด',
            message: '${data['name']} เหลือเพียง $stock ชิ้น',
            timestamp: DateTime.now(),
            isRead: false,
            actionData: {'productId': doc.id},
          ));
        }
      }

      // 3. รีวิวใหม่
      final recentReviews = await _firestore
          .collection('reviews')
          .where('sellerId', isEqualTo: _sellerId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      for (var doc in recentReviews.docs) {
        final data = doc.data();
        final hasReply = data['sellerReply'] != null;
        if (!hasReply) {
          notifications.add(NotificationItem(
            id: doc.id,
            type: NotificationType.newReview,
            title: 'รีวิวใหม่ ⭐ ${data['rating']}/5',
            message: data['comment'] ?? 'ลูกค้าให้รีวิว',
            timestamp: (data['createdAt'] as Timestamp).toDate(),
            isRead: false,
            actionData: {'reviewId': doc.id, 'productId': data['productId']},
          ));
        }
      }

      // 4. โปรโมชั่นใกล้หมดอายุ
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      final expiringPromotions = await _firestore
          .collection('advanced_promotions')
          .where('sellerId', isEqualTo: _sellerId)
          .where('isActive', isEqualTo: true)
          .get();

      for (var doc in expiringPromotions.docs) {
        final data = doc.data();
        final endDate = (data['endDate'] as Timestamp).toDate();
        if (endDate.isBefore(tomorrow) && endDate.isAfter(now)) {
          notifications.add(NotificationItem(
            id: 'promo_${doc.id}',
            type: NotificationType.promotionExpiring,
            title: '⏰ โปรโมชั่นใกล้หมดอายุ',
            message:
                '${data['name']} จะหมดอายุในอีก ${endDate.difference(now).inHours} ชั่วโมง',
            timestamp: now,
            isRead: false,
            actionData: {'promotionId': doc.id},
          ));
        }
      }

      // 5. ข้อความจากลูกค้า (Real chat notifications)
      final chatSnapshot = await _firestore
          .collection('chat_rooms')
          .where('participants', arrayContains: _sellerId)
          .orderBy('lastMessageTime', descending: true)
          .limit(20)
          .get();

      for (var doc in chatSnapshot.docs) {
        final data = doc.data();
        final unreadMap = data['unreadCount'] as Map<String, dynamic>?;
        final unreadCount = unreadMap?[_sellerId] as int? ?? 0;

        if (unreadCount > 0) {
          final participants = data['participants'] as List;
          final otherUserId = participants.firstWhere(
            (p) => p != _sellerId,
            orElse: () => '',
          );
          final participantNames =
              data['participantNames'] as Map<String, dynamic>?;
          final otherUserName = participantNames?[otherUserId] ?? 'ลูกค้า';

          notifications.add(NotificationItem(
            id: doc.id,
            type: NotificationType.newMessage,
            title: '💬 ข้อความใหม่จาก $otherUserName',
            message: data['lastMessage'] ?? 'มีข้อความใหม่',
            timestamp: (data['lastMessageTime'] as Timestamp?)?.toDate() ??
                DateTime.now(),
            isRead: false,
            actionData: {
              'roomId': doc.id,
              'otherUserId': otherUserId,
              'otherUserName': otherUserName,
            },
          ));
        }
      }

      // เรียงตามเวลาล่าสุด
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        _allNotifications = notifications;
        _unreadCount = notifications.where((n) => !n.isRead).length;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  List<NotificationItem> _getFilteredNotifications(NotificationType? type) {
    if (type == null) return _allNotifications;
    return _allNotifications.where((n) => n.type == type).toList();
  }

  Future<void> _markAsRead(NotificationItem notification) async {
    setState(() {
      notification.isRead = true;
      _unreadCount = _allNotifications.where((n) => !n.isRead).length;
    });

    // Persist read status to Firestore
    try {
      await _firestore
          .collection('seller_notifications')
          .doc(notification.id)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      for (var notification in _allNotifications) {
        notification.isRead = true;
      }
      _unreadCount = 0;
    });

    // Persist all read statuses to Firestore
    try {
      final batch = _firestore.batch();
      for (var notification in _allNotifications) {
        final docRef =
            _firestore.collection('seller_notifications').doc(notification.id);
        batch.update(docRef, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('การแจ้งเตือน'),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'อ่านทั้งหมด',
                style: TextStyle(color: Colors.white),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            _buildTab('ทั้งหมด', null),
            _buildTab('คำสั่งซื้อ', NotificationType.newOrder),
            _buildTab('สินค้า', NotificationType.lowStock),
            _buildTab('รีวิว', NotificationType.newReview),
            _buildTab('โปรโมชั่น', NotificationType.promotionExpiring),
            _buildTab('ข้อความ', NotificationType.newMessage),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationList(null),
                _buildNotificationList(NotificationType.newOrder),
                _buildNotificationList(NotificationType.lowStock),
                _buildNotificationList(NotificationType.newReview),
                _buildNotificationList(NotificationType.promotionExpiring),
                _buildNotificationList(NotificationType.newMessage),
              ],
            ),
    );
  }

  Widget _buildTab(String label, NotificationType? type) {
    final count = type == null
        ? _allNotifications.length
        : _allNotifications.where((n) => n.type == type).length;
    final unread = type == null
        ? _unreadCount
        : _allNotifications.where((n) => n.type == type && !n.isRead).length;

    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: unread > 0 ? Colors.red : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: unread > 0 ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationList(NotificationType? type) {
    final notifications = _getFilteredNotifications(type);

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none,
                size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'ไม่มีการแจ้งเตือน',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildNotificationCard(notifications[index]);
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    final typeInfo = _getTypeInfo(notification.type);
    final timeAgo = _getTimeAgo(notification.timestamp);

    return Card(
      elevation: notification.isRead ? 0 : 2,
      color: notification.isRead ? Colors.grey.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: notification.isRead
              ? Colors.grey.shade200
              : typeInfo['color'].withOpacity(0.3),
          width: notification.isRead ? 1 : 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          _markAsRead(notification);
          _handleNotificationTap(notification);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: typeInfo['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  typeInfo['icon'],
                  color: typeInfo['color'],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getTypeInfo(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
        return {
          'icon': Icons.shopping_cart,
          'color': const Color(0xFF4CAF50),
          'label': 'คำสั่งซื้อ'
        };
      case NotificationType.lowStock:
        return {
          'icon': Icons.warning_amber_rounded,
          'color': const Color(0xFFFF9800),
          'label': 'สต็อกต่ำ'
        };
      case NotificationType.newReview:
        return {
          'icon': Icons.star,
          'color': const Color(0xFFFFB300),
          'label': 'รีวิว'
        };
      case NotificationType.promotionExpiring:
        return {
          'icon': Icons.campaign,
          'color': const Color(0xFFE91E63),
          'label': 'โปรโมชั่น'
        };
      case NotificationType.newMessage:
        return {
          'icon': Icons.chat_bubble,
          'color': const Color(0xFF2196F3),
          'label': 'ข้อความ'
        };
      case NotificationType.paymentReceived:
        return {
          'icon': Icons.payment,
          'color': const Color(0xFF00BCD4),
          'label': 'การชำระเงิน'
        };
    }
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'เมื่อสักครู่';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} วันที่แล้ว';
    } else {
      return DateFormat('d MMM yyyy', 'th').format(timestamp);
    }
  }

  void _handleNotificationTap(NotificationItem notification) {
    switch (notification.type) {
      case NotificationType.newOrder:
        // Navigate to order detail
        Navigator.pushNamed(
          context,
          '/seller/order-detail',
          arguments: notification.actionData['orderId'],
        );
        break;

      case NotificationType.lowStock:
        // Navigate to product edit
        Navigator.pushNamed(
          context,
          '/seller/edit-product',
          arguments: notification.actionData['productId'],
        );
        break;

      case NotificationType.newReview:
        // Navigate to review management
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กำลังพัฒนาหน้าจัดการรีวิว')),
        );
        break;

      case NotificationType.promotionExpiring:
        // Navigate to promotions
        Navigator.pushNamed(context, '/seller/advanced-promotions');
        break;

      case NotificationType.newMessage:
        // Navigate to chat
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กำลังพัฒนาระบบแชท')),
        );
        break;

      default:
        break;
    }
  }
}

// ==================== MODELS ====================
enum NotificationType {
  newOrder,
  lowStock,
  newReview,
  promotionExpiring,
  newMessage,
  paymentReceived,
}

class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;
  final Map<String, dynamic> actionData;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.actionData = const {},
  });
}
