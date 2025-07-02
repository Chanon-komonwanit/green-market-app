// lib/screens/seller/seller_notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/app_notification.dart';
import '../../services/notification_service.dart';

class SellerNotificationsScreen extends StatefulWidget {
  const SellerNotificationsScreen({super.key});

  @override
  State<SellerNotificationsScreen> createState() =>
      _SellerNotificationsScreenState();
}

class _SellerNotificationsScreenState extends State<SellerNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NotificationService _notificationService = NotificationService();
  String? _userId;

  // Seller-specific notification types
  final Map<NotificationType, String> _sellerNotificationTypes = {
    NotificationType.newOrder: 'คำสั่งซื้อใหม่',
    NotificationType.orderPaid: 'ชำระเงินแล้ว',
    NotificationType.productSold: 'สินค้าขายได้',
    NotificationType.newReview: 'รีวิวใหม่',
    NotificationType.lowStock: 'สินค้าใกล้หมด',
    NotificationType.salesMilestone: 'ยอดขายเป้าหมาย',
    NotificationType.accountVerified: 'ร้านค้าได้รับการยืนยัน',
  };

  final Map<NotificationType, IconData> _typeIcons = {
    NotificationType.newOrder: Icons.shopping_cart,
    NotificationType.orderPaid: Icons.payment,
    NotificationType.productSold: Icons.sell,
    NotificationType.newReview: Icons.rate_review,
    NotificationType.lowStock: Icons.inventory_2,
    NotificationType.salesMilestone: Icons.trending_up,
    NotificationType.accountVerified: Icons.verified,
  };

  final Map<NotificationType, Color> _typeColors = {
    NotificationType.newOrder: const Color(0xFF2196F3),
    NotificationType.orderPaid: const Color(0xFF4CAF50),
    NotificationType.productSold: const Color(0xFFFF9800),
    NotificationType.newReview: const Color(0xFF9C27B0),
    NotificationType.lowStock: const Color(0xFFF44336),
    NotificationType.salesMilestone: const Color(0xFFFF5722),
    NotificationType.accountVerified: const Color(0xFF00BCD4),
  };

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _tabController =
        TabController(length: 4, vsync: this); // All, Orders, Reviews, Shop
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(
        body: Center(
          child: Text('กรุณาเข้าสู่ระบบก่อน'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'แจ้งเตือนร้านค้า',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          // Unread count indicator
          StreamBuilder<int>(
            stream: _notificationService.getUnreadCountByCategoryStream(
              _userId!,
              NotificationCategory.seller,
            ),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.mark_chat_read, color: Colors.white),
                    tooltip: 'ทำเครื่องหมายอ่านแล้วทั้งหมด',
                    onPressed: unreadCount > 0 ? () => _markAllAsRead() : null,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'ทั้งหมด'),
            Tab(text: 'คำสั่งซื้อ'),
            Tab(text: 'รีวิว'),
            Tab(text: 'ร้านค้า'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllSellerNotifications(),
          _buildOrderNotifications(),
          _buildReviewNotifications(),
          _buildShopNotifications(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _sendTestNotification(),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alert),
        label: const Text('ทดสอบแจ้งเตือน'),
      ),
    );
  }

  Widget _buildAllSellerNotifications() {
    return StreamBuilder<List<AppNotification>>(
      stream: _notificationService.getUserNotificationsByCategoryStream(
        _userId!,
        NotificationCategory.seller,
      ),
      builder: (context, snapshot) => _buildNotificationList(snapshot),
    );
  }

  Widget _buildOrderNotifications() {
    return StreamBuilder<List<AppNotification>>(
      stream: _notificationService.getUserNotificationsByCategoryStream(
        _userId!,
        NotificationCategory.seller,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final orderNotifications = snapshot.data!
              .where((notification) =>
                  notification.type == NotificationType.newOrder ||
                  notification.type == NotificationType.orderPaid ||
                  notification.type == NotificationType.productSold)
              .toList();

          return _buildNotificationList(
            AsyncSnapshot.withData(
                snapshot.connectionState, orderNotifications),
          );
        }
        return _buildNotificationList(snapshot);
      },
    );
  }

  Widget _buildReviewNotifications() {
    return StreamBuilder<List<AppNotification>>(
      stream: _notificationService.getUserNotificationsByCategoryStream(
        _userId!,
        NotificationCategory.seller,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final reviewNotifications = snapshot.data!
              .where((notification) =>
                  notification.type == NotificationType.newReview)
              .toList();

          return _buildNotificationList(
            AsyncSnapshot.withData(
                snapshot.connectionState, reviewNotifications),
          );
        }
        return _buildNotificationList(snapshot);
      },
    );
  }

  Widget _buildShopNotifications() {
    return StreamBuilder<List<AppNotification>>(
      stream: _notificationService.getUserNotificationsByCategoryStream(
        _userId!,
        NotificationCategory.seller,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final shopNotifications = snapshot.data!
              .where((notification) =>
                  notification.type == NotificationType.lowStock ||
                  notification.type == NotificationType.salesMilestone ||
                  notification.type == NotificationType.accountVerified)
              .toList();

          return _buildNotificationList(
            AsyncSnapshot.withData(snapshot.connectionState, shopNotifications),
          );
        }
        return _buildNotificationList(snapshot);
      },
    );
  }

  Widget _buildNotificationList(AsyncSnapshot<List<AppNotification>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
          ],
        ),
      );
    }

    final notifications = snapshot.data ?? [];

    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return _buildSellerNotificationCard(notifications[index]);
        },
      ),
    );
  }

  Widget _buildSellerNotificationCard(AppNotification notification) {
    final typeColor = _typeColors[notification.type] ?? const Color(0xFF4CAF50);
    final typeIcon = _typeIcons[notification.type] ?? Icons.store;
    final typeName = _sellerNotificationTypes[notification.type] ?? 'ร้านค้า';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: notification.isRead ? 1 : 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _handleNotificationTap(notification),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: !notification.isRead
                ? LinearGradient(
                    colors: [
                      typeColor.withOpacity(0.05),
                      Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            border: !notification.isRead
                ? Border.all(color: typeColor.withOpacity(0.3), width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Priority indicator and icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      typeIcon,
                      color: typeColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title and type
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
                                  fontWeight: notification.isRead
                                      ? FontWeight.w600
                                      : FontWeight.bold,
                                  fontSize: 18,
                                  color: notification.isRead
                                      ? Colors.grey[700]
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            if (notification.priority ==
                                NotificationPriority.urgent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.priority_high,
                                        size: 14, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      'ด่วน',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                typeName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: typeColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              notification.formattedDate,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Read status
                  if (!notification.isRead)
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: typeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Body
              Text(
                notification.body,
                style: TextStyle(
                  fontSize: 15,
                  color:
                      notification.isRead ? Colors.grey[600] : Colors.grey[800],
                  height: 1.5,
                ),
              ),

              // Additional data display
              if (notification.data != null) ...[
                const SizedBox(height: 12),
                _buildNotificationData(notification.data!, typeColor),
              ],

              // Image if available
              if (notification.imageUrl != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    notification.imageUrl!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 140,
                        color: Colors.grey[200],
                        child:
                            const Icon(Icons.broken_image, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ],

              // Actions
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Quick action buttons based on notification type
                  Row(
                    children: _buildQuickActions(notification, typeColor),
                  ),
                  // Common actions
                  Row(
                    children: [
                      if (!notification.isRead)
                        TextButton.icon(
                          onPressed: () => _markAsRead(notification),
                          icon: const Icon(Icons.mark_chat_read, size: 16),
                          label: const Text('อ่านแล้ว'),
                          style: TextButton.styleFrom(
                            foregroundColor: typeColor,
                          ),
                        ),
                      TextButton.icon(
                        onPressed: () => _archiveNotification(notification),
                        icon: const Icon(Icons.archive_outlined, size: 16),
                        label: const Text('เก็บถาวร'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationData(Map<String, dynamic> data, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.key}: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 13,
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.value.toString(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildQuickActions(AppNotification notification, Color color) {
    final actions = <Widget>[];

    switch (notification.type) {
      case NotificationType.newOrder:
        actions.addAll([
          ElevatedButton.icon(
            onPressed: () => _viewOrder(notification),
            icon: const Icon(Icons.visibility, size: 16),
            label: const Text('ดูคำสั่งซื้อ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => _processOrder(notification),
            icon: const Icon(Icons.local_shipping, size: 16),
            label: const Text('จัดส่ง'),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ]);
        break;
      case NotificationType.newReview:
        actions.add(
          ElevatedButton.icon(
            onPressed: () => _viewReview(notification),
            icon: const Icon(Icons.rate_review, size: 16),
            label: const Text('ดูรีวิว'),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        );
        break;
      case NotificationType.lowStock:
        actions.add(
          ElevatedButton.icon(
            onPressed: () => _manageInventory(notification),
            icon: const Icon(Icons.inventory, size: 16),
            label: const Text('จัดการสต็อก'),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        );
        break;
      default:
        break;
    }

    return actions;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'ไม่มีการแจ้งเตือนร้านค้า',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'เมื่อมีคำสั่งซื้อใหม่หรือกิจกรรมร้านค้า\nจะแจ้งเตือนที่นี่',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(AppNotification notification) async {
    if (!notification.isRead) {
      await _markAsRead(notification);
    }

    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.newOrder:
        _viewOrder(notification);
        break;
      case NotificationType.newReview:
        _viewReview(notification);
        break;
      case NotificationType.lowStock:
        _manageInventory(notification);
        break;
      default:
        _showNotificationDetails(notification);
        break;
    }
  }

  void _viewOrder(AppNotification notification) {
    // Navigate to order detail screen
    print('View order: ${notification.relatedId}');
    // Navigator.push(context, MaterialPageRoute(builder: (context) => OrderDetailScreen(...)));
  }

  void _processOrder(AppNotification notification) {
    // Navigate to order processing screen
    print('Process order: ${notification.relatedId}');
  }

  void _viewReview(AppNotification notification) {
    // Navigate to review detail screen
    print('View review: ${notification.relatedId}');
  }

  void _manageInventory(AppNotification notification) {
    // Navigate to inventory management screen
    print('Manage inventory: ${notification.relatedId}');
  }

  void _showNotificationDetails(AppNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _typeIcons[notification.type] ?? Icons.store,
              color: _typeColors[notification.type],
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(notification.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 16),
            Text(
              'วันที่: ${notification.detailedFormattedDate}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'ประเภท: ${_sellerNotificationTypes[notification.type] ?? 'ไม่ทราบ'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (notification.data != null) ...[
              const SizedBox(height: 12),
              const Text(
                'ข้อมูลเพิ่มเติม:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...notification.data!.entries.map(
                (entry) => Text('${entry.key}: ${entry.value}'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsRead(AppNotification notification) async {
    await _notificationService.markAsRead(notification.id);
  }

  Future<void> _markAllAsRead() async {
    await _notificationService.markAllAsRead(_userId!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ทำเครื่องหมายอ่านแล้วทั้งหมดแล้ว'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _archiveNotification(AppNotification notification) async {
    await _notificationService.archiveNotification(notification.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เก็บถาวรการแจ้งเตือนแล้ว'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _sendTestNotification() async {
    final testNotifications = [
      {
        'title': 'คำสั่งซื้อใหม่ #12345',
        'body':
            'คุณมีคำสั่งซื้อใหม่จากลูกค้า สินค้า: เสื้อยืดผ้าฝ้ายออร์แกนิค จำนวน 2 ชิ้น',
        'type': NotificationType.newOrder,
        'data': {
          'orderId': '12345',
          'customerName': 'สมชาย ใจดี',
          'amount': '890 บาท',
          'products': '2 รายการ'
        },
      },
      {
        'title': 'รีวิวใหม่ 5 ดาว!',
        'body':
            'ลูกค้าให้รีวิว 5 ดาวสำหรับสินค้า "กระเป๋าผ้าจากขวดพลาสติกรีไซเคิล"',
        'type': NotificationType.newReview,
        'data': {
          'rating': '5 ดาว',
          'productName': 'กระเป๋าผ้าจากขวดพลาสติกรีไซเคิล',
          'reviewText': 'สินค้าดีมาก คุณภาพเยี่ยม'
        },
      },
      {
        'title': 'แจ้งเตือนสต็อกต่ำ',
        'body': 'สินค้า "แก้วน้ำไผ่ธรรมชาติ" เหลือเพียง 3 ชิ้น ควรเติมสต็อก',
        'type': NotificationType.lowStock,
        'data': {
          'productName': 'แก้วน้ำไผ่ธรรมชาติ',
          'currentStock': '3 ชิ้น',
          'recommendedStock': '20 ชิ้น'
        },
      },
    ];

    final random = testNotifications[
        DateTime.now().millisecond % testNotifications.length];

    await _notificationService.sendSellerNotification(
      userId: _userId!,
      title: random['title'] as String,
      body: random['body'] as String,
      type: random['type'] as NotificationType,
      data: random['data'] as Map<String, dynamic>?,
      priority: NotificationPriority.high,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ส่งการแจ้งเตือนทดสอบแล้ว'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
