// lib/screens/customer_shipping_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/order.dart' as app_order;
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/screens/order_tracking_screen.dart';
import 'package:green_market/utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class CustomerShippingDashboardScreen extends StatefulWidget {
  const CustomerShippingDashboardScreen({super.key});

  @override
  State<CustomerShippingDashboardScreen> createState() =>
      _CustomerShippingDashboardScreenState();
}

class _CustomerShippingDashboardScreenState
    extends State<CustomerShippingDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<app_order.Order> _allOrders = [];
  List<app_order.Order> _filteredOrders = [];
  String _selectedStatus = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final firebaseService =
            Provider.of<FirebaseService>(context, listen: false);
        final orders = await firebaseService.getOrdersByUserId(user.uid).first;
        setState(() {
          _allOrders = orders;
          _filterOrders();
        });
      }
    } catch (e) {
      print('Error loading orders: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterOrders() {
    setState(() {
      _filteredOrders = _allOrders.where((order) {
        // Filter by status
        bool statusMatch =
            _selectedStatus == 'all' || order.status == _selectedStatus;

        // Filter by search query
        bool searchMatch = _searchQuery.isEmpty ||
            order.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (order.trackingNumber
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false);

        return statusMatch && searchMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('การจัดส่งของฉัน'),
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'ทั้งหมด (${_getOrderCountByStatus('all')})'),
            Tab(text: 'รอจัดส่ง (${_getOrderCountByStatus('processing')})'),
            Tab(text: 'จัดส่งแล้ว (${_getOrderCountByStatus('shipped')})'),
            Tab(text: 'ได้รับแล้ว (${_getOrderCountByStatus('delivered')})'),
            Tab(text: 'ยกเลิก (${_getOrderCountByStatus('cancelled')})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.veryLightTeal,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: (value) {
                    _searchQuery = value;
                    _filterOrders();
                  },
                  decoration: InputDecoration(
                    hintText: 'ค้นหาด้วยหมายเลขคำสั่งซื้อหรือหมายเลขติดตาม',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Quick Status Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusFilter('all', 'ทั้งหมด'),
                      _buildStatusFilter('processing', 'รอจัดส่ง'),
                      _buildStatusFilter('shipped', 'จัดส่งแล้ว'),
                      _buildStatusFilter('delivered', 'ได้รับแล้ว'),
                      _buildStatusFilter('cancelled', 'ยกเลิก'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Orders List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList('all'),
                _buildOrdersList('processing'),
                _buildOrdersList('shipped'),
                _buildOrdersList('delivered'),
                _buildOrdersList('cancelled'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter(String status, String label) {
    final isSelected = _selectedStatus == status;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedStatus = selected ? status : 'all';
            _filterOrders();
          });
        },
        backgroundColor: Colors.white,
        selectedColor: AppColors.primaryTeal,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.darkModernGrey,
        ),
      ),
    );
  }

  Widget _buildOrdersList(String status) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final orders = _filteredOrders
        .where((order) => status == 'all' || order.status == status)
        .toList();

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 64,
              color: AppColors.lightModernGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'ไม่มีคำสั่งซื้อในสถานะนี้',
              style: AppTextStyles.subtitle.copyWith(
                color: AppColors.lightModernGrey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(app_order.Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderTrackingScreen(order: order),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'คำสั่งซื้อ #${order.id.substring(0, 8)}',
                    style: AppTextStyles.bodyBold,
                  ),
                  _buildStatusBadge(order.status),
                ],
              ),
              const SizedBox(height: 8),

              // Order Date
              Text(
                'วันที่สั่งซื้อ: ${DateFormat('dd MMM yyyy', 'th_TH').format(order.orderDate.toDate())}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.darkModernGrey,
                ),
              ),
              const SizedBox(height: 8),

              // Items Preview
              Text(
                '${order.items.length} รายการ • ฿${order.totalAmount.toStringAsFixed(2)}',
                style: AppTextStyles.body,
              ),

              // Shipping Information
              if (order.trackingNumber != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.veryLightTeal,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_shipping,
                            size: 16,
                            color: AppColors.primaryTeal,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ข้อมูลการจัดส่ง',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primaryTeal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'หมายเลขติดตาม: ${order.trackingNumber}',
                        style: AppTextStyles.bodySmall,
                      ),
                      if (order.shippingCarrier != null)
                        Text(
                          'ขนส่ง: ${order.shippingCarrier}',
                          style: AppTextStyles.bodySmall,
                        ),
                      if (order.shippedAt != null)
                        Text(
                          'วันที่จัดส่ง: ${DateFormat('dd MMM yyyy', 'th_TH').format(order.shippedAt!.toDate())}',
                          style: AppTextStyles.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],

              // Action Buttons
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                OrderTrackingScreen(order: order),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('ดูรายละเอียด'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryTeal,
                        side: BorderSide(color: AppColors.primaryTeal),
                      ),
                    ),
                  ),
                  if (order.trackingNumber != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OrderTrackingScreen(order: order),
                            ),
                          );
                        },
                        icon: const Icon(Icons.track_changes),
                        label: const Text('ติดตามพัสดุ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'processing':
        color = AppColors.warningOrange;
        label = 'รอจัดส่ง';
        break;
      case 'shipped':
        color = AppColors.primaryTeal;
        label = 'จัดส่งแล้ว';
        break;
      case 'delivered':
        color = AppColors.primaryGreen;
        label = 'ได้รับแล้ว';
        break;
      case 'cancelled':
        color = AppColors.alertRed;
        label = 'ยกเลิก';
        break;
      default:
        color = AppColors.lightModernGrey;
        label = 'ไม่ทราบสถานะ';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  int _getOrderCountByStatus(String status) {
    if (status == 'all') return _allOrders.length;
    return _allOrders.where((order) => order.status == status).length;
  }
}
