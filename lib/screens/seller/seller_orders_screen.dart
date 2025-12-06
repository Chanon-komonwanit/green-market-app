// lib/screens/seller/seller_orders_screen.dart
// 📦 Unified Order Management - Shopee/TikTok Shop Standard
// Merged features from seller_orders + sophisticated_order_hub

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:green_market/models/order.dart' as app_order;
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/screens/seller/seller_order_detail_screen.dart';

class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;

  List<app_order.Order> _allOrders = [];
  List<app_order.Order> _filteredOrders = [];
  Map<String, int> _statusCounts = {};
  bool _isLoading = true;
  bool _isSelectionMode = false;
  final Set<String> _selectedOrders = {};
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) {
      setState(() {
        _isSelectionMode = false;
        _selectedOrders.clear();
      });
      _filterOrders();
    }
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _allOrders = [];
          _filteredOrders = [];
          _isLoading = false;
        });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('sellerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final orders = snapshot.docs
          .map((doc) {
            try {
              return app_order.Order.fromFirestore(doc);
            } catch (e) {
              print('Error parsing order: $e');
              return null;
            }
          })
          .whereType<app_order.Order>()
          .toList();

      // Calculate status counts
      _statusCounts = {
        'all': orders.length,
        'pending': orders.where((o) => o.status == 'pending').length,
        'confirmed': orders
            .where((o) => o.status == 'confirmed' || o.status == 'processing')
            .length,
        'shipping': orders.where((o) => o.status == 'shipping').length,
        'completed': orders
            .where((o) => o.status == 'completed' || o.status == 'delivered')
            .length,
        'cancelled': orders.where((o) => o.status == 'cancelled').length,
      };

      setState(() {
        _allOrders = orders;
        _isLoading = false;
      });

      _filterOrders();
    } catch (e) {
      print('Error loading orders: $e');
      setState(() {
        _allOrders = [];
        _filteredOrders = [];
        _isLoading = false;
      });
    }
  }

  void _filterOrders() {
    List<app_order.Order> filtered = List.from(_allOrders);

    // Filter by tab
    switch (_tabController.index) {
      case 0: // ทั้งหมด
        break;
      case 1: // รอดำเนินการ
        filtered = filtered.where((o) => o.status == 'pending').toList();
        break;
      case 2: // ยืนยันแล้ว
        filtered = filtered
            .where((o) => o.status == 'confirmed' || o.status == 'processing')
            .toList();
        break;
      case 3: // กำลังจัดส่ง
        filtered = filtered.where((o) => o.status == 'shipping').toList();
        break;
      case 4: // เสร็จสิ้น
        filtered = filtered
            .where((o) => o.status == 'completed' || o.status == 'delivered')
            .toList();
        break;
      case 5: // ยกเลิก
        filtered = filtered.where((o) => o.status == 'cancelled').toList();
        break;
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((o) {
        return o.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            o.fullName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
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
      body: _isLoading ? _buildLoadingState() : _buildOrdersContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (_isSelectionMode) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              _isSelectionMode = false;
              _selectedOrders.clear();
            });
          },
        ),
        title: Text(
          'เลือกแล้ว ${_selectedOrders.length} รายการ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          // Bulk Actions
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleBulkAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'confirm',
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 20),
                    SizedBox(width: 12),
                    Text('ยืนยันคำสั่งซื้อ'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'cancel',
                child: Row(
                  children: [
                    Icon(Icons.cancel_outlined, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('ยกเลิก', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }

    return AppBar(
      title: const Text(
        'คำสั่งซื้อ',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: const Color(0xFF2E7D32),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        // Search
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _showSearchDialog,
        ),
        // Refresh
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadOrders,
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            _buildTabWithBadge('ทั้งหมด', _statusCounts['all'] ?? 0),
            _buildTabWithBadge('รอดำเนินการ', _statusCounts['pending'] ?? 0),
            _buildTabWithBadge('ยืนยันแล้ว', _statusCounts['confirmed'] ?? 0),
            _buildTabWithBadge('กำลังจัดส่ง', _statusCounts['shipping'] ?? 0),
            _buildTabWithBadge('เสร็จสิ้น', _statusCounts['completed'] ?? 0),
            _buildTabWithBadge('ยกเลิก', _statusCounts['cancelled'] ?? 0),
          ],
        ),
      ),
    );
  }

  Widget _buildTabWithBadge(String label, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
          ),
          SizedBox(height: 16),
          Text(
            'กำลังโหลดคำสั่งซื้อ...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersContent() {
    if (_filteredOrders.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: const Color(0xFF2E7D32),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _filteredOrders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = _filteredOrders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    String message = 'ยังไม่มีคำสั่งซื้อ';
    IconData icon = Icons.receipt_long_outlined;

    switch (_tabController.index) {
      case 1:
        message = 'ไม่มีคำสั่งซื้อรอดำเนินการ';
        break;
      case 2:
        message = 'ไม่มีคำสั่งซื้อที่ยืนยันแล้ว';
        break;
      case 3:
        message = 'ไม่มีคำสั่งซื้อกำลังจัดส่ง';
        break;
      case 4:
        message = 'ไม่มีคำสั่งซื้อที่เสร็จสิ้น';
        break;
      case 5:
        message = 'ไม่มีคำสั่งซื้อที่ยกเลิก';
        break;
    }

    if (_searchQuery.isNotEmpty) {
      message = 'ไม่พบคำสั่งซื้อที่ค้นหา';
      icon = Icons.search_off;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(app_order.Order order) {
    final isSelected = _selectedOrders.contains(order.id);
    final statusInfo = _getOrderStatusInfo(order.status);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: () {
          if (_isSelectionMode) {
            _toggleOrderSelection(order.id);
          } else {
            _viewOrderDetail(order);
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            setState(() {
              _isSelectionMode = true;
              _selectedOrders.add(order.id);
            });
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: const Color(0xFF2E7D32), width: 2)
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Order ID and Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (_isSelectionMode)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? const Color(0xFF2E7D32)
                                      : Colors.grey,
                                  size: 20,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                'คำสั่งซื้อ #${order.id.substring(0, 8).toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateTime(order.orderDate.toDate()),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusInfo['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusInfo['icon'],
                          size: 14,
                          color: statusInfo['color'],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusInfo['text'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusInfo['color'],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Customer Info
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.fullName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        if (order.items.isNotEmpty)
                          Text(
                            '${order.items.length} รายการ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Total Amount
                  Text(
                    '฿${NumberFormat('#,##0.00').format(order.total)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),

              // Action Buttons (if not in selection mode and order is actionable)
              if (!_isSelectionMode && _canTakeAction(order.status)) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (order.status == 'pending')
                      Expanded(
                        child: _buildActionButton(
                          label: 'ยืนยันคำสั่งซื้อ',
                          icon: Icons.check_circle_outline,
                          color: const Color(0xFF4CAF50),
                          onTap: () => _confirmOrder(order),
                        ),
                      ),
                    if (order.status == 'confirmed' ||
                        order.status == 'processing') ...[
                      Expanded(
                        child: _buildActionButton(
                          label: 'จัดส่งสินค้า',
                          icon: Icons.local_shipping_outlined,
                          color: const Color(0xFF2196F3),
                          onTap: () => _shipOrder(order),
                        ),
                      ),
                    ],
                    if ((order.status == 'pending' ||
                            order.status == 'confirmed') &&
                        _canTakeAction(order.status)) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          label: 'ยกเลิก',
                          icon: Icons.cancel_outlined,
                          color: Colors.red,
                          onTap: () => _cancelOrder(order),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  bool _canTakeAction(String status) {
    return status == 'pending' ||
        status == 'confirmed' ||
        status == 'processing';
  }

  void _toggleOrderSelection(String orderId) {
    setState(() {
      if (_selectedOrders.contains(orderId)) {
        _selectedOrders.remove(orderId);
        if (_selectedOrders.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedOrders.add(orderId);
      }
    });
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ค้นหาคำสั่งซื้อ'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'รหัสคำสั่งซื้อหรือชื่อลูกค้า',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
            _filterOrders();
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
              _filterOrders();
              Navigator.pop(context);
            },
            child: const Text('ล้าง'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  void _handleBulkAction(String action) async {
    if (_selectedOrders.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(action == 'confirm' ? 'ยืนยันคำสั่งซื้อ' : 'ยกเลิกคำสั่งซื้อ'),
        content: Text(
          'คุณต้องการ${action == 'confirm' ? 'ยืนยัน' : 'ยกเลิก'}คำสั่งซื้อ ${_selectedOrders.length} รายการใช่หรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  action == 'confirm' ? const Color(0xFF4CAF50) : Colors.red,
            ),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      final newStatus = action == 'confirm' ? 'confirmed' : 'cancelled';

      for (final orderId in _selectedOrders) {
        final docRef =
            FirebaseFirestore.instance.collection('orders').doc(orderId);
        batch.update(docRef, {'status': newStatus});
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${action == 'confirm' ? 'ยืนยัน' : 'ยกเลิก'}คำสั่งซื้อสำเร็จ ${_selectedOrders.length} รายการ',
            ),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }

      setState(() {
        _isSelectionMode = false;
        _selectedOrders.clear();
      });

      _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmOrder(app_order.Order order) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(order.id)
          .update({'status': 'confirmed'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ยืนยันคำสั่งซื้อสำเร็จ'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }

      _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shipOrder(app_order.Order order) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(order.id)
          .update({'status': 'shipping'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เริ่มจัดส่งสินค้าแล้ว'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }

      _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelOrder(app_order.Order order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยกเลิกคำสั่งซื้อ'),
        content: const Text('คุณต้องการยกเลิกคำสั่งซื้อนี้ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ไม่'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ยกเลิก'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(order.id)
          .update({'status': 'cancelled'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ยกเลิกคำสั่งซื้อสำเร็จ'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }

      _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewOrderDetail(app_order.Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SellerOrderDetailScreen(order: order),
      ),
    ).then((_) => _loadOrders());
  }

  Map<String, dynamic> _getOrderStatusInfo(String status) {
    switch (status) {
      case 'pending':
        return {
          'text': 'รอดำเนินการ',
          'icon': Icons.pending_actions,
          'color': const Color(0xFFFF9800),
        };
      case 'confirmed':
      case 'processing':
        return {
          'text': 'ยืนยันแล้ว',
          'icon': Icons.check_circle,
          'color': const Color(0xFF2196F3),
        };
      case 'shipping':
        return {
          'text': 'กำลังจัดส่ง',
          'icon': Icons.local_shipping,
          'color': const Color(0xFF9C27B0),
        };
      case 'completed':
      case 'delivered':
        return {
          'text': 'เสร็จสิ้น',
          'icon': Icons.check_circle,
          'color': const Color(0xFF4CAF50),
        };
      case 'cancelled':
        return {
          'text': 'ยกเลิก',
          'icon': Icons.cancel,
          'color': const Color(0xFFF44336),
        };
      default:
        return {
          'text': 'ไม่ทราบสถานะ',
          'icon': Icons.help_outline,
          'color': Colors.grey,
        };
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'เมื่อสักครู่';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} วันที่แล้ว';
    } else {
      return DateFormat('d MMM yyyy', 'th').format(dateTime);
    }
  }
}
