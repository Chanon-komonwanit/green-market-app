// lib/screens/notifications_center_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import '../services/firebase_service.dart';

class NotificationsCenterScreen extends StatefulWidget {
  const NotificationsCenterScreen({super.key});

  @override
  State<NotificationsCenterScreen> createState() =>
      _NotificationsCenterScreenState();
}

class _NotificationsCenterScreenState extends State<NotificationsCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NotificationService _notificationService = NotificationService();
  String? _userId;

  final Map<NotificationCategory, String> _categoryNames = {
    NotificationCategory.buyer: 'การซื้อสินค้า',
    NotificationCategory.seller: 'ร้านค้าของฉัน',
    NotificationCategory.investment: 'การลงทุน',
    NotificationCategory.activity: 'กิจกรรม',
    NotificationCategory.system: 'ระบบ',
  };

  final Map<NotificationCategory, IconData> _categoryIcons = {
    NotificationCategory.buyer: Icons.shopping_cart,
    NotificationCategory.seller: Icons.store,
    NotificationCategory.investment: Icons.trending_up,
    NotificationCategory.activity: Icons.event,
    NotificationCategory.system: Icons.settings,
  };

  final Map<NotificationCategory, Color> _categoryColors = {
    NotificationCategory.buyer: const Color(0xFF2196F3),
    NotificationCategory.seller: const Color(0xFF4CAF50),
    NotificationCategory.investment: const Color(0xFFFF9800),
    NotificationCategory.activity: const Color(0xFF9C27B0),
    NotificationCategory.system: const Color(0xFF607D8B),
  };

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _tabController =
        TabController(length: 6, vsync: this); // 5 categories + All
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
          'การแจ้งเตือน',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          // Mark all as read button
          StreamBuilder<int>(
            stream: _notificationService.getUnreadCountStream(_userId!),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              if (unreadCount == 0) return const SizedBox.shrink();

              return IconButton(
                icon: const Icon(Icons.mark_chat_read, color: Colors.white),
                tooltip: 'ทำเครื่องหมายอ่านแล้วทั้งหมด',
                onPressed: () async {
                  await _notificationService.markAllAsRead(_userId!);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ทำเครื่องหมายอ่านแล้วทั้งหมดแล้ว'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              );
            },
          ),
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'ตั้งค่าการแจ้งเตือน',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            _buildTab('ทั้งหมด', Icons.notifications, null),
            ..._categoryNames.entries.map(
              (entry) => _buildTabWithBadge(
                _categoryNames[entry.key]!,
                _categoryIcons[entry.key]!,
                entry.key,
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // All notifications
          _buildAllNotificationsTab(),
          // Category-specific tabs
          ...NotificationCategory.values.map(
            (category) => _buildCategoryNotificationsTab(category),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
      String label, IconData icon, NotificationCategory? category) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTabWithBadge(
      String label, IconData icon, NotificationCategory category) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Icon(icon, size: 20),
              StreamBuilder<int>(
                stream: _notificationService.getUnreadCountByCategoryStream(
                    _userId!, category),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  if (count == 0) return const SizedBox.shrink();

                  return Positioned(
                    right: -2,
                    top: -2,
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
                        count > 99 ? '99+' : count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildAllNotificationsTab() {
    return StreamBuilder<List<AppNotification>>(
      stream: _notificationService.getUserNotificationsStream(_userId!),
      builder: (context, snapshot) {
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
              return _buildNotificationCard(notifications[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryNotificationsTab(NotificationCategory category) {
    return StreamBuilder<List<AppNotification>>(
      stream: _notificationService.getUserNotificationsByCategoryStream(
          _userId!, category),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
          );
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return _buildEmptyStateForCategory(category);
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              return _buildNotificationCard(notifications[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    final categoryColor = _categoryColors[notification.category] ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: notification.isRead ? 1 : 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _handleNotificationTap(notification),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: !notification.isRead
                ? Border.all(color: categoryColor.withOpacity(0.3), width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Category icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _categoryIcons[notification.category],
                      color: categoryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title and category
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.bold,
                            fontSize: 16,
                            color: notification.isRead
                                ? Colors.grey[700]
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _categoryNames[notification.category]!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: categoryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (notification.priority ==
                                NotificationPriority.urgent) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.priority_high,
                                        size: 12, color: Colors.red),
                                    SizedBox(width: 2),
                                    Text(
                                      'ด่วน',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Time and read status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        notification.formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: categoryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Body
              Text(
                notification.body,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      notification.isRead ? Colors.grey[600] : Colors.grey[800],
                  height: 1.4,
                ),
              ),

              // Image if available
              if (notification.imageUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    notification.imageUrl!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        color: Colors.grey[200],
                        child:
                            const Icon(Icons.broken_image, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ],

              // Actions
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!notification.isRead)
                    TextButton.icon(
                      onPressed: () => _markAsRead(notification),
                      icon: const Icon(Icons.mark_chat_read, size: 16),
                      label: const Text('ทำเครื่องหมายอ่านแล้ว'),
                      style: TextButton.styleFrom(
                        foregroundColor: categoryColor,
                      ),
                    ),
                  const SizedBox(width: 8),
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
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'ไม่มีการแจ้งเตือน',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'เมื่อมีการแจ้งเตือนใหม่ จะแสดงที่นี่',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateForCategory(NotificationCategory category) {
    final categoryColor = _categoryColors[category] ?? Colors.grey;
    final categoryName = _categoryNames[category] ?? 'ไม่ทราบ';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _categoryIcons[category],
            size: 80,
            color: categoryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'ไม่มีการแจ้งเตือนใน$categoryName',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'เมื่อมีการแจ้งเตือนใหม่เกี่ยวกับ$categoryName จะแสดงที่นี่',
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
    // Mark as read if not already read
    if (!notification.isRead) {
      await _markAsRead(notification);
    }

    // Handle navigation based on notification type and actionUrl
    if (notification.actionUrl != null) {
      // Navigate to specific screen based on actionUrl
      _navigateToScreen(notification.actionUrl!, notification);
    } else {
      // Show notification details
      _showNotificationDetails(notification);
    }
  }

  void _navigateToScreen(String actionUrl, AppNotification notification) {
    // Implement navigation logic based on actionUrl
    print('Navigate to: $actionUrl');
    // Example navigation logic:
    // if (actionUrl.contains('/order/')) {
    //   Navigator.push(context, MaterialPageRoute(builder: (context) => OrderDetailScreen(...)));
    // }
  }

  void _showNotificationDetails(AppNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
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
              'ประเภท: ${_categoryNames[notification.category]}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
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
}

// Notification Settings Screen
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final Map<NotificationCategory, bool> _categorySettings = {
    NotificationCategory.buyer: true,
    NotificationCategory.seller: true,
    NotificationCategory.investment: true,
    NotificationCategory.activity: true,
    NotificationCategory.system: true,
  };

  final Map<NotificationCategory, String> _categoryNames = {
    NotificationCategory.buyer: 'การซื้อสินค้า',
    NotificationCategory.seller: 'ร้านค้าของฉัน',
    NotificationCategory.investment: 'การลงทุน',
    NotificationCategory.activity: 'กิจกรรม',
    NotificationCategory.system: 'ระบบ',
  };

  final Map<NotificationCategory, String> _categoryDescriptions = {
    NotificationCategory.buyer: 'คำสั่งซื้อ การชำระเงิน การจัดส่ง',
    NotificationCategory.seller: 'คำสั่งซื้อใหม่ รีวิว ยอดขาย',
    NotificationCategory.investment: 'โอกาสลงทุน ผลตอบแทน พอร์ตโฟลิโอ',
    NotificationCategory.activity: 'กิจกรรมใหม่ การแจ้งเตือน ชุมชน',
    NotificationCategory.system: 'อัปเดตระบบ ประกาศ ความปลอดภัย',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ตั้งค่าการแจ้งเตือน',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'เลือกประเภทการแจ้งเตือนที่ต้องการรับ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          ..._categorySettings.entries.map((entry) {
            final category = entry.key;
            final isEnabled = entry.value;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: SwitchListTile(
                title: Text(
                  _categoryNames[category]!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(_categoryDescriptions[category]!),
                value: isEnabled,
                onChanged: (value) {
                  setState(() {
                    _categorySettings[category] = value;
                  });
                },
                activeColor: const Color(0xFF4CAF50),
              ),
            );
          }),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'บันทึกการตั้งค่า',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Save notification settings to Firebase
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'notificationSettings': {
            'orderNotifications': true,
            'promotionNotifications': true,
            'investmentNotifications': true,
            'systemNotifications': true,
            'pushNotifications': true,
            'emailNotifications': false,
            'activityNotifications': true,
            'updatedAt': FieldValue.serverTimestamp(),
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกการตั้งค่าแล้ว'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการบันทึกการตั้งค่า: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    Navigator.pop(context);
  }
}
