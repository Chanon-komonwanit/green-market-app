// lib/screens/seller/shipping_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:green_market/models/order.dart' as app_order;
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/utils/constants.dart';
import 'package:green_market/screens/admin/order_detail_screen.dart';
import 'package:intl/intl.dart';

class ShippingManagementScreen extends StatefulWidget {
  const ShippingManagementScreen({super.key});

  @override
  State<ShippingManagementScreen> createState() =>
      _ShippingManagementScreenState();
}

class _ShippingManagementScreenState extends State<ShippingManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการการจัดส่ง'),
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'รอจัดส่ง', icon: Icon(Icons.pending_actions)),
            Tab(text: 'กำลังส่ง', icon: Icon(Icons.local_shipping)),
            Tab(text: 'ส่งแล้ว', icon: Icon(Icons.check_circle)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PendingShipmentTab(),
          _InTransitTab(),
          _DeliveredTab(),
        ],
      ),
    );
  }
}

class _PendingShipmentTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final firebaseService = Provider.of<FirebaseService>(context);

    if (userProvider.currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<app_order.Order>>(
      stream: firebaseService.getOrdersBySellerId(userProvider.currentUser!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
          );
        }

        final orders = snapshot.data ?? [];
        final pendingOrders = orders
            .where((order) =>
                order.status == 'processing' ||
                order.status == 'pending_payment')
            .toList();

        if (pendingOrders.isEmpty) {
          return _EmptyState(
            icon: Icons.pending_actions,
            title: 'ไม่มีคำสั่งซื้อรอจัดส่ง',
            subtitle: 'คำสั่งซื้อใหม่จะปรากฏที่นี่',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingOrders.length,
          itemBuilder: (context, index) {
            final order = pendingOrders[index];
            return _OrderCard(
              order: order,
              showActions: true,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => OrderDetailScreen(order: order),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _InTransitTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final firebaseService = Provider.of<FirebaseService>(context);

    if (userProvider.currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<app_order.Order>>(
      stream: firebaseService.getOrdersBySellerId(userProvider.currentUser!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
          );
        }

        final orders = snapshot.data ?? [];
        final shippedOrders =
            orders.where((order) => order.status == 'shipped').toList();

        if (shippedOrders.isEmpty) {
          return _EmptyState(
            icon: Icons.local_shipping,
            title: 'ไม่มีพัสดุกำลังจัดส่ง',
            subtitle: 'พัสดุที่กำลังจัดส่งจะปรากฏที่นี่',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: shippedOrders.length,
          itemBuilder: (context, index) {
            final order = shippedOrders[index];
            return _OrderCard(
              order: order,
              showActions: false,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => OrderDetailScreen(order: order),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _DeliveredTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final firebaseService = Provider.of<FirebaseService>(context);

    if (userProvider.currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<app_order.Order>>(
      stream: firebaseService.getOrdersBySellerId(userProvider.currentUser!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
          );
        }

        final orders = snapshot.data ?? [];
        final deliveredOrders =
            orders.where((order) => order.status == 'delivered').toList();

        if (deliveredOrders.isEmpty) {
          return _EmptyState(
            icon: Icons.check_circle,
            title: 'ไม่มีคำสั่งซื้อที่ส่งแล้ว',
            subtitle: 'คำสั่งซื้อที่ส่งเสร็จแล้วจะปรากฏที่นี่',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: deliveredOrders.length,
          itemBuilder: (context, index) {
            final order = deliveredOrders[index];
            return _OrderCard(
              order: order,
              showActions: false,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => OrderDetailScreen(order: order),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final app_order.Order order;
  final bool showActions;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.showActions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'คำสั่งซื้อ #${order.id.substring(0, 8)}',
                          style: AppTextStyles.bodyBold.copyWith(
                            color: AppColors.primaryDarkGreen,
                          ),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy, HH:mm', 'th_TH')
                              .format(order.orderDate.toDate()),
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.darkGrey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 12),

              // Customer Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.offWhite,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: AppColors.primaryTeal, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.fullName,
                            style: AppTextStyles.bodyBold,
                          ),
                          Text(
                            'โทร: ${order.phoneNumber}',
                            style: AppTextStyles.body.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Order Items Summary
              Text(
                'รายการสินค้า (${order.items.length} รายการ)',
                style: AppTextStyles.bodyBold,
              ),
              const SizedBox(height: 8),
              ...order.items.take(2).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '• ${item.productName}',
                            style: AppTextStyles.body,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          'x${item.quantity}',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.darkGrey,
                          ),
                        ),
                      ],
                    ),
                  )),
              if (order.items.length > 2)
                Text(
                  'และอีก ${order.items.length - 2} รายการ...',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.darkGrey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              const SizedBox(height: 12),

              // Shipping Info
              if (order.shippingCarrier != null || order.shippingMethod != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.veryLightTeal.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_shipping,
                          color: AppColors.primaryTeal, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (order.shippingCarrier != null)
                              Text(
                                order.shippingCarrier!,
                                style: AppTextStyles.bodyBold,
                              ),
                            if (order.trackingNumber != null)
                              Text(
                                'Tracking: ${order.trackingNumber}',
                                style:
                                    AppTextStyles.body.copyWith(fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // Total and Actions
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'ยอดรวม: ฿${order.totalAmount.toStringAsFixed(2)}',
                      style: AppTextStyles.bodyBold.copyWith(
                        color: AppColors.primaryDarkGreen,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (showActions)
                    ElevatedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('จัดการ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
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
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case 'pending_payment':
        backgroundColor = AppColors.warningYellow;
        textColor = Colors.white;
        text = 'รอชำระเงิน';
        break;
      case 'processing':
        backgroundColor = AppColors.primaryTeal;
        textColor = Colors.white;
        text = 'กำลังเตรียม';
        break;
      case 'shipped':
        backgroundColor = AppColors.primaryDarkGreen;
        textColor = Colors.white;
        text = 'กำลังจัดส่ง';
        break;
      case 'delivered':
        backgroundColor = AppColors.successGreen;
        textColor = Colors.white;
        text = 'ส่งแล้ว';
        break;
      default:
        backgroundColor = AppColors.lightGrey;
        textColor = AppColors.darkGrey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: AppTextStyles.body.copyWith(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppColors.lightGrey,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTextStyles.subtitle.copyWith(
              color: AppColors.darkGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.body.copyWith(
              color: AppColors.lightGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
