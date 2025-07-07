// lib/screens/seller/enhanced_shipping_management_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/order.dart' as app_order;
import 'package:green_market/services/shipping/shipping_service_manager.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:green_market/widgets/shipping_label_widget.dart';
import 'package:green_market/widgets/bulk_actions_widget.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EnhancedShippingManagementScreen extends StatefulWidget {
  const EnhancedShippingManagementScreen({super.key});

  @override
  State<EnhancedShippingManagementScreen> createState() =>
      _EnhancedShippingManagementScreenState();
}

class _EnhancedShippingManagementScreenState
    extends State<EnhancedShippingManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ShippingServiceManager _shippingManager = ShippingServiceManager();

  final List<app_order.Order> _selectedOrders = [];
  bool _isMultiSelectMode = false;
  bool _isLoading = false;
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initializeShippingManager();
    _loadStatistics();
  }

  Future<void> _initializeShippingManager() async {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    await _shippingManager.initialize(firebaseService);
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final stats = await _shippingManager.getShippingStatistics(
          sellerId: currentUser.uid,
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now(),
        );
        setState(() => _statistics = stats);
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการการจัดส่ง (ระบบใหม่)'),
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isMultiSelectMode ? Icons.close : Icons.checklist),
            onPressed: _toggleMultiSelectMode,
            tooltip: _isMultiSelectMode ? 'ยกเลิกการเลือก' : 'เลือกหลายรายการ',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
            tooltip: 'รีเฟรช',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'รอดำเนินการ', icon: Icon(Icons.hourglass_empty)),
            Tab(text: 'กำลังจัดส่ง', icon: Icon(Icons.local_shipping)),
            Tab(text: 'ส่งสำเร็จ', icon: Icon(Icons.check_circle)),
            Tab(text: 'ยกเลิก', icon: Icon(Icons.cancel)),
            Tab(text: 'สถิติ', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Bulk Actions Bar
          if (_isMultiSelectMode && _selectedOrders.isNotEmpty)
            BulkActionsWidget(
              selectedCount: _selectedOrders.length,
              onPrintLabels: _printSelectedLabels,
              onMarkAsShipped: _markSelectedAsShipped,
              onCancel: _cancelSelectedOrders,
            ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPendingOrdersTab(),
                _buildShippingOrdersTab(),
                _buildDeliveredOrdersTab(),
                _buildCancelledOrdersTab(),
                _buildStatisticsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildPendingOrdersTab() {
    return _buildOrdersList(['processing', 'awaiting_confirmation']);
  }

  Widget _buildShippingOrdersTab() {
    return _buildOrdersList(['shipped']);
  }

  Widget _buildDeliveredOrdersTab() {
    return _buildOrdersList(['delivered']);
  }

  Widget _buildCancelledOrdersTab() {
    return _buildOrdersList(['cancelled']);
  }

  Widget _buildOrdersList(List<String> statuses) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('กรุณาเข้าสู่ระบบ'));
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Provider.of<FirebaseService>(context, listen: false)
          .getOrdersBySellerAndStatus(currentUser.uid, statuses),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
        }

        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'ไม่มีคำสั่งซื้อ',
                  style:
                      AppTextStyles.subtitle.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadStatistics,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderMap = orders[index];
              final order = app_order.Order.fromMap(orderMap);
              return _buildEnhancedOrderCard(order);
            },
          ),
        );
      },
    );
  }

  Widget _buildEnhancedOrderCard(app_order.Order order) {
    final isSelected = _selectedOrders.contains(order);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _isMultiSelectMode
            ? _toggleOrderSelection(order)
            : _viewOrderDetails(order),
        onLongPress: () => _toggleOrderSelection(order),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: AppColors.primaryTeal, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header
              Row(
                children: [
                  if (_isMultiSelectMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (_) => _toggleOrderSelection(order),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'คำสั่งซื้อ #${order.id.substring(0, 8)}',
                          style: AppTextStyles.bodyBold,
                        ),
                        Text(
                          DateFormat('dd MMM yyyy, HH:mm', 'th_TH')
                              .format(order.orderDate.toDate()),
                          style: AppTextStyles.bodySmall
                              .copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(order.status),
                ],
              ),

              const SizedBox(height: 12),

              // Customer Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.person,
                            size: 16, color: AppColors.primaryTeal),
                        SizedBox(width: 8),
                        Text('ข้อมูลลูกค้า', style: AppTextStyles.bodyBold),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('ชื่อ: ${order.fullName}', style: AppTextStyles.body),
                    Text('เบอร์โทร: ${order.phoneNumber}',
                        style: AppTextStyles.body),
                    Text(
                      'ที่อยู่: ${order.addressLine1}, ${order.subDistrict}, ${order.district}, ${order.province} ${order.zipCode}',
                      style: AppTextStyles.bodySmall,
                    ),
                    if (order.note != null && order.note!.isNotEmpty)
                      Text('หมายเหตุ: ${order.note}',
                          style: AppTextStyles.bodySmall
                              .copyWith(fontStyle: FontStyle.italic)),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Order Items Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shopping_cart,
                            size: 16, color: AppColors.primaryTeal),
                        const SizedBox(width: 8),
                        Text('รายการสินค้า (${order.items.length} รายการ)',
                            style: AppTextStyles.bodyBold),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...order.items.take(2).map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '• ${item.productName} x${item.quantity}',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ),
                              Text(
                                '฿${(item.pricePerUnit * item.quantity).toStringAsFixed(2)}',
                                style: AppTextStyles.bodySmall
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        )),
                    if (order.items.length > 2)
                      Text(
                        'และอีก ${order.items.length - 2} รายการ',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.grey[600]),
                      ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ยอดรวม:', style: AppTextStyles.bodyBold),
                        Text(
                          '฿${order.totalAmount.toStringAsFixed(2)}',
                          style: AppTextStyles.bodyBold
                              .copyWith(color: AppColors.primaryGreen),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Shipping Info
              if (order.trackingNumber != null ||
                  order.shippingCarrier != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.primaryGreen.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_shipping,
                              size: 16, color: AppColors.primaryGreen),
                          const SizedBox(width: 8),
                          Text('ข้อมูลการจัดส่ง',
                              style: AppTextStyles.bodyBold
                                  .copyWith(color: AppColors.primaryGreen)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (order.shippingCarrier != null)
                        Text('บริษัทขนส่ง: ${order.shippingCarrier}',
                            style: AppTextStyles.bodySmall),
                      if (order.trackingNumber != null)
                        Text('หมายเลขติดตาม: ${order.trackingNumber}',
                            style: AppTextStyles.bodySmall),
                      if (order.shippedAt != null)
                        Text(
                          'วันที่จัดส่ง: ${DateFormat('dd MMM yyyy, HH:mm', 'th_TH').format(order.shippedAt!.toDate())}',
                          style: AppTextStyles.bodySmall,
                        ),
                      if (order.deliveredAt != null)
                        Text(
                          'วันที่ส่งถึง: ${DateFormat('dd MMM yyyy, HH:mm', 'th_TH').format(order.deliveredAt!.toDate())}',
                          style: AppTextStyles.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Action Buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _buildActionButtons(order),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'processing':
        color = AppColors.warningOrange;
        text = 'กำลังเตรียม';
        icon = Icons.inventory_2;
        break;
      case 'awaiting_confirmation':
        color = AppColors.primaryTeal;
        text = 'รอยืนยัน';
        icon = Icons.hourglass_top;
        break;
      case 'shipped':
        color = AppColors.primaryGreen;
        text = 'จัดส่งแล้ว';
        icon = Icons.local_shipping;
        break;
      case 'delivered':
        color = AppColors.primaryGreen;
        text = 'ส่งสำเร็จ';
        icon = Icons.check_circle;
        break;
      case 'cancelled':
        color = AppColors.errorRed;
        text = 'ยกเลิก';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        text = status;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(app_order.Order order) {
    final buttons = <Widget>[];

    switch (order.status) {
      case 'processing':
      case 'awaiting_confirmation':
        buttons.add(
          ElevatedButton.icon(
            onPressed: () => _createShipment(order),
            icon: const Icon(Icons.local_shipping, size: 16),
            label: const Text('สร้างใบจัดส่ง'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 36),
            ),
          ),
        );
        buttons.add(
          OutlinedButton.icon(
            onPressed: () => _printShippingLabel(order),
            icon: const Icon(Icons.print, size: 16),
            label: const Text('พิมพ์ใบปะหน้า'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryTeal,
              minimumSize: const Size(0, 36),
            ),
          ),
        );
        break;
      case 'shipped':
        buttons.add(
          ElevatedButton.icon(
            onPressed: () => _markAsDelivered(order),
            icon: const Icon(Icons.check_circle, size: 16),
            label: const Text('ส่งสำเร็จ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 36),
            ),
          ),
        );
        if (order.trackingNumber != null) {
          buttons.add(
            OutlinedButton.icon(
              onPressed: () => _showTrackingInfo(order),
              icon: const Icon(Icons.track_changes, size: 16),
              label: const Text('ติดตามสถานะ'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryTeal,
                minimumSize: const Size(0, 36),
              ),
            ),
          );
        }
        break;
    }

    // Edit shipping info button (always available for non-cancelled orders)
    if (order.status != 'cancelled') {
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => _editShippingInfo(order),
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('แก้ไขข้อมูล'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey[600],
            minimumSize: const Size(0, 36),
          ),
        ),
      );
    }

    return buttons;
  }

  Widget _buildStatisticsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('สถิติการจัดส่ง (30 วันที่ผ่านมา)', style: AppTextStyles.title),
          const SizedBox(height: 16),

          // Summary Cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildStatCard(
                  'คำสั่งซื้อทั้งหมด',
                  '${_statistics['totalOrders'] ?? 0}',
                  Icons.shopping_cart,
                  AppColors.primaryTeal),
              _buildStatCard(
                  'จัดส่งสำเร็จ',
                  '${_statistics['deliveredOrders'] ?? 0}',
                  Icons.check_circle,
                  AppColors.primaryGreen),
              _buildStatCard(
                  'กำลังจัดส่ง',
                  '${_statistics['shippedOrders'] ?? 0}',
                  Icons.local_shipping,
                  AppColors.warningOrange),
              _buildStatCard('ยกเลิก', '${_statistics['cancelledOrders'] ?? 0}',
                  Icons.cancel, AppColors.errorRed),
            ],
          ),

          const SizedBox(height: 24),

          // Performance Metrics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ประสิทธิภาพการจัดส่ง', style: AppTextStyles.subtitle),
                  const SizedBox(height: 16),
                  _buildPerformanceIndicator(
                    'อัตราการจัดส่งสำเร็จ',
                    (_statistics['deliveryRate'] ?? 0).toDouble(),
                    AppColors.primaryGreen,
                  ),
                  const SizedBox(height: 12),
                  _buildPerformanceIndicator(
                    'อัตราการยกเลิก',
                    (_statistics['cancellationRate'] ?? 0).toDouble(),
                    AppColors.errorRed,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Financial Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('สรุปค่าจัดส่ง', style: AppTextStyles.subtitle),
                  const SizedBox(height: 16),
                  _buildStatRow('ค่าจัดส่งรวม',
                      '฿${(_statistics['totalShippingFees'] ?? 0).toStringAsFixed(2)}'),
                  _buildStatRow('ค่าจัดส่งเฉลี่ย',
                      '฿${(_statistics['averageShippingFee'] ?? 0).toStringAsFixed(2)}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.title.copyWith(color: color, fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceIndicator(
      String label, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.body),
            Text('${percentage.toStringAsFixed(1)}%',
                style: AppTextStyles.bodyBold.copyWith(color: color)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body),
          Text(value, style: AppTextStyles.bodyBold),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (_tabController.index == 0) {
      // Pending orders tab
      return FloatingActionButton.extended(
        onPressed: _createBulkShipments,
        backgroundColor: AppColors.primaryTeal,
        icon: const Icon(Icons.local_shipping, color: Colors.white),
        label:
            const Text('จัดส่งทั้งหมด', style: TextStyle(color: Colors.white)),
      );
    }
    return null;
  }

  // Action Methods
  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedOrders.clear();
      }
    });
  }

  void _toggleOrderSelection(app_order.Order order) {
    if (!_isMultiSelectMode) {
      setState(() {
        _isMultiSelectMode = true;
        _selectedOrders.add(order);
      });
    } else {
      setState(() {
        if (_selectedOrders.contains(order)) {
          _selectedOrders.remove(order);
        } else {
          _selectedOrders.add(order);
        }
      });
    }
  }

  void _viewOrderDetails(app_order.Order order) {
    // Navigate to enhanced order details screen
    Navigator.pushNamed(context, '/enhanced-order-detail', arguments: order);
  }

  Future<void> _createShipment(app_order.Order order) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final result = await _shippingManager.createShipmentFromOrder(order);

      Navigator.pop(context); // Close loading dialog

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'สร้างใบจัดส่งสำเร็จ!\nหมายเลขติดตาม: ${result.trackingNumber}'),
            backgroundColor: AppColors.primaryGreen,
            duration: const Duration(seconds: 4),
          ),
        );
        _loadStatistics(); // Refresh statistics
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'เกิดข้อผิดพลาด'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  Future<void> _markAsDelivered(app_order.Order order) async {
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      await firebaseService.updateOrderStatus(order.id, 'delivered');

      // Update tracking status
      if (order.trackingNumber != null) {
        await _shippingManager.updateTrackingStatus(
          order.trackingNumber!,
          'delivered',
          'สินค้าถูกส่งมอบเรียบร้อยแล้ว',
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('อัพเดทสถานะเป็น "ส่งสำเร็จ" แล้ว'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
      _loadStatistics(); // Refresh statistics
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  Future<void> _printShippingLabel(app_order.Order order) async {
    try {
      final labels = await _shippingManager.generateShippingLabels([order]);
      if (labels.isNotEmpty) {
        // Show shipping label dialog
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: ShippingLabelWidget(label: labels.first),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการสร้างใบปะหน้า: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  void _showTrackingInfo(app_order.Order order) {
    if (order.trackingNumber != null) {
      Navigator.pushNamed(context, '/order-tracking', arguments: order);
    }
  }

  void _editShippingInfo(app_order.Order order) {
    // Show edit shipping info dialog
    _showEditShippingDialog(order);
  }

  void _showEditShippingDialog(app_order.Order order) {
    final trackingController =
        TextEditingController(text: order.trackingNumber ?? '');
    final carrierController =
        TextEditingController(text: order.shippingCarrier ?? 'Kerry Express');
    final methodController = TextEditingController(
        text: order.shippingMethod ?? 'standard_delivery');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('แก้ไขข้อมูลการจัดส่ง'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: carrierController.text,
                decoration: const InputDecoration(
                  labelText: 'บริษัทขนส่ง',
                  border: OutlineInputBorder(),
                ),
                items: [
                  'Kerry Express',
                  'J&T Express',
                  'Flash Express',
                  'ไปรษณีย์ไทย',
                  'Ninja Van',
                ]
                    .map((carrier) =>
                        DropdownMenuItem(value: carrier, child: Text(carrier)))
                    .toList(),
                onChanged: (value) => carrierController.text = value ?? '',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: trackingController,
                decoration: const InputDecoration(
                  labelText: 'หมายเลขติดตาม',
                  border: OutlineInputBorder(),
                  hintText: 'เช่น TH1234567890',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: methodController.text,
                decoration: const InputDecoration(
                  labelText: 'วิธีการส่ง',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                      value: 'standard_delivery',
                      child: Text('Standard Delivery')),
                  DropdownMenuItem(
                      value: 'express_delivery',
                      child: Text('Express Delivery')),
                  DropdownMenuItem(
                      value: 'cod_delivery', child: Text('Cash on Delivery')),
                  DropdownMenuItem(
                      value: 'free_shipping', child: Text('Free Shipping')),
                ].toList(),
                onChanged: (value) => methodController.text = value ?? '',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => _updateShippingInfo(
              order,
              carrierController.text,
              trackingController.text,
              methodController.text,
            ),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal),
            child: const Text('บันทึก', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateShippingInfo(
    app_order.Order order,
    String carrier,
    String trackingNumber,
    String method,
  ) async {
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);

      final updateData = <String, dynamic>{
        'shippingCarrier': carrier,
        'shippingMethod': method,
        'updatedAt': Timestamp.now(),
      };

      if (trackingNumber.isNotEmpty) {
        updateData['trackingNumber'] = trackingNumber;
        updateData['trackingUrl'] =
            _generateTrackingUrl(trackingNumber, carrier);
      }

      // Update status to shipped if not already
      if (order.status == 'processing' ||
          order.status == 'awaiting_confirmation') {
        updateData['status'] = 'shipped';
        updateData['shippedAt'] = Timestamp.now();
      }

      await firebaseService.updateOrderShippingInfo(order.id, updateData);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('อัพเดทข้อมูลการจัดส่งเรียบร้อย'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  String _generateTrackingUrl(String trackingNumber, String carrier) {
    switch (carrier.toLowerCase()) {
      case 'kerry express':
        return 'https://th.kerryexpress.com/track/?track=$trackingNumber';
      case 'j&t express':
        return 'https://www.jtexpress.co.th/index/query/gzquery.html?bills=$trackingNumber';
      case 'flash express':
        return 'https://www.flashexpress.co.th/tracking/?se=$trackingNumber';
      case 'ไปรษณีย์ไทย':
        return 'https://track.thailandpost.co.th/?trackNumber=$trackingNumber';
      default:
        return 'https://green-market.com/tracking/$trackingNumber';
    }
  }

  Future<void> _createBulkShipments() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Get pending orders
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final pendingOrders =
          await firebaseService.getOrdersNeedingLabels(currentUser.uid);

      if (pendingOrders.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่มีคำสั่งซื้อที่ต้องจัดส่ง')),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('กำลังสร้างใบจัดส่ง ${pendingOrders.length} รายการ...'),
            ],
          ),
        ),
      );

      final orderObjects = pendingOrders
          .map((orderMap) => app_order.Order.fromMap(orderMap))
          .toList();
      final results = await _shippingManager.createBulkShipments(orderObjects);

      Navigator.pop(context); // Close loading dialog

      final successCount = results.where((r) => r.success).length;
      final failureCount = results.length - successCount;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'สร้างใบจัดส่งสำเร็จ $successCount รายการ${failureCount > 0 ? ', ไม่สำเร็จ $failureCount รายการ' : ''}'),
          backgroundColor:
              successCount > 0 ? AppColors.primaryGreen : AppColors.errorRed,
          duration: const Duration(seconds: 4),
        ),
      );

      _loadStatistics(); // Refresh statistics
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  Future<void> _printSelectedLabels() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final labels =
          await _shippingManager.generateShippingLabels(_selectedOrders);

      Navigator.pop(context); // Close loading dialog

      // Show bulk printing dialog
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                AppBar(
                  title: Text('ใบปะหน้า (${labels.length} ใบ)'),
                  automaticallyImplyLeading: false,
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: labels.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 32),
                    itemBuilder: (context, index) =>
                        ShippingLabelWidget(label: labels[index]),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการสร้างใบปะหน้า: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  Future<void> _markSelectedAsShipped() async {
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final orderIds = _selectedOrders.map((order) => order.id).toList();

      await firebaseService.bulkUpdateOrderStatuses(orderIds, 'shipped');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'อัพเดทสถานะ ${_selectedOrders.length} รายการเป็น "จัดส่งแล้ว"'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );

      setState(() {
        _selectedOrders.clear();
        _isMultiSelectMode = false;
      });

      _loadStatistics(); // Refresh statistics
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  Future<void> _cancelSelectedOrders() async {
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final orderIds = _selectedOrders.map((order) => order.id).toList();

      await firebaseService.bulkUpdateOrderStatuses(orderIds, 'cancelled');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ยกเลิก ${_selectedOrders.length} รายการ'),
          backgroundColor: AppColors.warningOrange,
        ),
      );

      setState(() {
        _selectedOrders.clear();
        _isMultiSelectMode = false;
      });

      _loadStatistics(); // Refresh statistics
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
