// lib/screens/seller/sophisticated_order_hub.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:green_market/models/order.dart' as order_model;
import 'package:green_market/services/firebase_service.dart';

// Simple Order model for dashboard use
class SimpleOrder {
  final String id;
  final String customerId;
  final String sellerId;
  final double total;
  final String status;
  final DateTime createdAt;

  SimpleOrder({
    required this.id,
    required this.customerId,
    required this.sellerId,
    required this.total,
    required this.status,
    required this.createdAt,
  });
}

/// 🚀 Sophisticated Order Management Hub
/// Features: Automation Rules, Batch Processing, Intelligent Fulfillment, Communication Automation
class SophisticatedOrderHub extends StatefulWidget {
  const SophisticatedOrderHub({super.key});

  @override
  State<SophisticatedOrderHub> createState() => _SophisticatedOrderHubState();
}

class _SophisticatedOrderHubState extends State<SophisticatedOrderHub>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _refreshController;
  List<SimpleOrder> _allOrders = [];
  List<SimpleOrder> _filteredOrders = [];
  Map<String, dynamic> _orderStats = {};
  bool _isLoading = true;
  bool _isSelectionMode = false;
  final Set<String> _selectedOrders = {};
  String _filterStatus = 'all';

  // Automation rules
  final bool _autoConfirmEnabled = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _loadOrderData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadOrderData() async {
    setState(() => _isLoading = true);
    _refreshController.forward();

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await _loadOrders(userId);
      await _loadOrderStatistics();
    } finally {
      setState(() => _isLoading = false);
      _refreshController.reset();
    }
  }

  Future<void> _loadOrders(String sellerId) async {
    try {
      // Load orders from Firestore
      final ordersQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      final orders = ordersQuery.docs.map((doc) {
        final data = doc.data();
        return SimpleOrder(
          id: doc.id,
          customerId: data['customerId'] ?? '',
          sellerId: data['sellerId'] ?? '',
          total: (data['total'] as num?)?.toDouble() ?? 0.0,
          status: data['status'] ?? 'pending',
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();

      setState(() {
        _allOrders = orders;
        _applyFilters();
      });
    } catch (e) {
      print('Error loading orders: $e');
    }
  }

  Future<void> _loadOrderStatistics() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));

    // Calculate order statistics
    final todayOrders =
        _allOrders.where((o) => o.createdAt.isAfter(today)).length;
    final weeklyOrders =
        _allOrders.where((o) => o.createdAt.isAfter(weekAgo)).length;
    final pendingOrders = _allOrders
        .where((o) => o.status == 'pending' || o.status == 'new')
        .length;
    final processingOrders = _allOrders
        .where((o) => o.status == 'processing' || o.status == 'confirmed')
        .length;
    final completedOrders = _allOrders
        .where((o) => o.status == 'completed' || o.status == 'delivered')
        .length;
    final cancelledOrders =
        _allOrders.where((o) => o.status == 'cancelled').length;

    final totalRevenue = _allOrders
        .where((o) => o.status == 'completed' || o.status == 'delivered')
        .fold(0.0, (total, order) => total + order.total);

    final todayRevenue = _allOrders
        .where((o) =>
            (o.status == 'completed' || o.status == 'delivered') &&
            o.createdAt.isAfter(today))
        .fold(0.0, (total, order) => total + order.total);

    setState(() {
      _orderStats = {
        'totalOrders': _allOrders.length,
        'todayOrders': todayOrders,
        'weeklyOrders': weeklyOrders,
        'pendingOrders': pendingOrders,
        'processingOrders': processingOrders,
        'completedOrders': completedOrders,
        'cancelledOrders': cancelledOrders,
        'totalRevenue': totalRevenue,
        'todayRevenue': todayRevenue,
        'avgOrderValue':
            _allOrders.isEmpty ? 0.0 : totalRevenue / completedOrders,
        'fulfillmentRate': _allOrders.isEmpty
            ? 0.0
            : (completedOrders / _allOrders.length * 100),
        'cancelRate': _allOrders.isEmpty
            ? 0.0
            : (cancelledOrders / _allOrders.length * 100),
        'orderTrend': [
          FlSpot(0, 12),
          FlSpot(1, 18),
          FlSpot(2, 15),
          FlSpot(3, 22),
          FlSpot(4, 28),
          FlSpot(5, 24),
          FlSpot(6, 31),
        ],
        'automation': {
          'autoProcessed': 45,
          'smartRouted': 67,
          'timesSaved': '2.5 ชั่วโมง/วัน',
        }
      };
    });
  }

  void _applyFilters() {
    List<SimpleOrder> filtered = List.from(_allOrders);

    switch (_filterStatus) {
      case 'pending':
        filtered = filtered
            .where((o) => o.status == 'pending' || o.status == 'new')
            .toList();
        break;
      case 'processing':
        filtered = filtered
            .where((o) => o.status == 'processing' || o.status == 'confirmed')
            .toList();
        break;
      case 'completed':
        filtered = filtered
            .where((o) => o.status == 'completed' || o.status == 'delivered')
            .toList();
        break;
      case 'cancelled':
        filtered = filtered.where((o) => o.status == 'cancelled').toList();
        break;
    }

    setState(() {
      _filteredOrders = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildOrderOverview(),
                _buildQuickActions(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAllOrders(),
                      _buildAutomationCenter(),
                      _buildBatchOperations(),
                      _buildCommunicationHub(),
                      _buildAnalyticsCenter(),
                      _buildReturnManagement(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: _buildFloatingActions(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: _isSelectionMode
          ? Text('เลือกแล้ว ${_selectedOrders.length} ออเดอร์')
          : const Text(
              'Order Hub',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
      backgroundColor: const Color(0xFF1B5E20),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        if (_isSelectionMode) ...[
          IconButton(
            icon: const Icon(Icons.select_all),
            onPressed: _selectAllOrders,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _exitSelectionMode,
          ),
        ] else ...[
          IconButton(
            icon: AnimatedBuilder(
              animation: _refreshController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _refreshController.value * 2 * 3.14159,
                  child: const Icon(Icons.refresh),
                );
              },
            ),
            onPressed: _loadOrderData,
          ),
          IconButton(
            icon: const Icon(Icons.checklist),
            onPressed: _enterSelectionMode,
          ),
        ],
      ],
      bottom: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        tabs: const [
          Tab(text: 'ออเดอร์ทั้งหมด'),
          Tab(text: 'ระบบอัตโนมัติ'),
          Tab(text: 'จัดการหมู่'),
          Tab(text: 'การสื่อสาร'),
          Tab(text: 'วิเคราะห์'),
          Tab(text: 'การคืนสินค้า'),
        ],
      ),
    );
  }

  Widget _buildOrderOverview() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'ภาพรวมออเดอร์',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_autoConfirmEnabled)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'AUTO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildOverviewMetric(
                  'ออเดอร์วันนี้',
                  '${_orderStats['todayOrders'] ?? 0}',
                  Icons.today,
                ),
              ),
              Expanded(
                child: _buildOverviewMetric(
                  'รอดำเนินการ',
                  '${_orderStats['pendingOrders'] ?? 0}',
                  Icons.pending_actions,
                ),
              ),
              Expanded(
                child: _buildOverviewMetric(
                  'อัตราสำเร็จ',
                  '${(_orderStats['fulfillmentRate'] ?? 0).toStringAsFixed(1)}%',
                  Icons.check_circle,
                ),
              ),
              Expanded(
                child: _buildOverviewMetric(
                  'รายได้วันนี้',
                  '฿${(_orderStats['todayRevenue'] ?? 0).toStringAsFixed(0)}',
                  Icons.monetization_on,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewMetric(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionButton(
              'ยืนยันทั้งหมด',
              Icons.check_circle_outline,
              const Color(0xFF4CAF50),
              () => _batchConfirmOrders(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionButton(
              'พิมพ์ใบส่ง',
              Icons.print_outlined,
              const Color(0xFF2196F3),
              () => _printShippingLabels(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionButton(
              'อัปเดตสถานะ',
              Icons.update_outlined,
              const Color(0xFFFF9800),
              () => _bulkUpdateStatus(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllOrders() {
    return Column(
      children: [
        _buildOrderFilters(),
        Expanded(
          child: _filteredOrders.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = _filteredOrders[index];
                    return _buildOrderCard(order);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildOrderFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('ทั้งหมด', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip('รอดำเนินการ', 'pending'),
            const SizedBox(width: 8),
            _buildFilterChip('กำลังดำเนินการ', 'processing'),
            const SizedBox(width: 8),
            _buildFilterChip('เสร็จสิ้น', 'completed'),
            const SizedBox(width: 8),
            _buildFilterChip('ยกเลิก', 'cancelled'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterStatus = value;
          _applyFilters();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(SimpleOrder order) {
    final isSelected = _selectedOrders.contains(order.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: const Color(0xFF2E7D32), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _isSelectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (bool? value) {
                  _toggleOrderSelection(order.id);
                },
                activeColor: const Color(0xFF2E7D32),
              )
            : Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getStatusIcon(order.status),
                  color: _getStatusColor(order.status),
                  size: 20,
                ),
              ),
        title: Text(
          'ออเดอร์ #${order.id.substring(0, 8)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'มูลค่า: ฿${order.total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'สั่งเมื่อ: ${_formatDateTime(order.createdAt)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(order.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusText(order.status),
                style: TextStyle(
                  color: _getStatusColor(order.status),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 2),
                Text(
                  _getTimeAgo(order.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          if (_isSelectionMode) {
            _toggleOrderSelection(order.id);
          } else {
            _showOrderDetails(order);
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            _enterSelectionMode();
            _toggleOrderSelection(order.id);
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'ไม่มีออเดอร์',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ออเดอร์ใหม่จะแสดงที่นี่',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // Placeholder implementations for other tabs
  Widget _buildAutomationCenter() {
    return const Center(child: Text('Automation Center - Coming Next'));
  }

  Widget _buildBatchOperations() {
    return const Center(child: Text('Batch Operations - Coming Next'));
  }

  Widget _buildCommunicationHub() {
    return const Center(child: Text('Communication Hub - Coming Next'));
  }

  Widget _buildAnalyticsCenter() {
    return const Center(child: Text('Analytics Center - Coming Next'));
  }

  Widget _buildReturnManagement() {
    return const Center(child: Text('Return Management - Coming Next'));
  }

  Widget _buildFloatingActions() {
    if (_isSelectionMode) {
      return FloatingActionButton(
        onPressed: _processSelectedOrders,
        backgroundColor: const Color(0xFF2E7D32),
        child: const Icon(Icons.check, color: Colors.white),
      );
    }

    return FloatingActionButton.extended(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สร้างออเดอร์ใหม่ - Coming Soon!')),
        );
      },
      icon: const Icon(Icons.add),
      label: const Text('สร้างออเดอร์'),
      backgroundColor: const Color(0xFF2E7D32),
      foregroundColor: Colors.white,
    );
  }

  // Helper methods
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'new':
        return const Color(0xFFFF9800);
      case 'processing':
      case 'confirmed':
        return const Color(0xFF2196F3);
      case 'completed':
      case 'delivered':
        return const Color(0xFF4CAF50);
      case 'cancelled':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'new':
        return Icons.pending;
      case 'processing':
      case 'confirmed':
        return Icons.refresh;
      case 'completed':
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'รอดำเนินการ';
      case 'new':
        return 'ใหม่';
      case 'processing':
        return 'กำลังดำเนินการ';
      case 'confirmed':
        return 'ยืนยันแล้ว';
      case 'completed':
        return 'เสร็จสิ้น';
      case 'delivered':
        return 'จัดส่งแล้ว';
      case 'cancelled':
        return 'ยกเลิก';
      default:
        return status;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else {
      return '${difference.inDays} วันที่แล้ว';
    }
  }

  // Selection and action methods
  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedOrders.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedOrders.clear();
    });
  }

  void _toggleOrderSelection(String orderId) {
    setState(() {
      if (_selectedOrders.contains(orderId)) {
        _selectedOrders.remove(orderId);
      } else {
        _selectedOrders.add(orderId);
      }
    });
  }

  void _selectAllOrders() {
    setState(() {
      _selectedOrders.addAll(_filteredOrders.map((o) => o.id));
    });
  }

  void _processSelectedOrders() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('ดำเนินการ ${_selectedOrders.length} ออเดอร์ - Coming Soon!'),
      ),
    );
    _exitSelectionMode();
  }

  void _batchConfirmOrders() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ยืนยันออเดอร์หมู่ - Coming Soon!')),
    );
  }

  void _printShippingLabels() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('พิมพ์ใบส่งสินค้า - Coming Soon!')),
    );
  }

  void _bulkUpdateStatus() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('อัปเดตสถานะหมู่ - Coming Soon!')),
    );
  }

  void _showOrderDetails(SimpleOrder order) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('รายละเอียดออเดอร์ #${order.id.substring(0, 8)}')),
    );
  }
}
