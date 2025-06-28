// lib/screens/admin/admin_order_management_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/order.dart' as app_order;
import 'dart:async';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/order_status_utils.dart'
    as order_status_utils;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:green_market/screens/admin/order_detail_screen.dart';

// CONVERTING AdminOrderManagementScreen to StatefulWidget
class AdminOrderManagementScreen extends StatefulWidget {
  const AdminOrderManagementScreen({super.key});

  @override
  State<AdminOrderManagementScreen> createState() =>
      _AdminOrderManagementScreenState();
}

class _AdminOrderManagementScreenState
    extends State<AdminOrderManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  String? _selectedStatusFilter;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim().toLowerCase();
        });
      }
    });
  }

  List<app_order.Order> _filterOrders(List<app_order.Order> allOrders) {
    return allOrders.where((order) {
      final String orderId = order.id.toLowerCase();
      final String buyerName = order.fullName.toLowerCase();
      final String status = order.status;

      final bool searchMatch = _searchQuery.isEmpty ||
          orderId.contains(_searchQuery) ||
          buyerName.contains(_searchQuery);

      final bool statusFilterMatch =
          _selectedStatusFilter == null || _selectedStatusFilter == status;

      return searchMatch && statusFilterMatch;
    }).toList();
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status) {
      case 'pending_payment':
        return Colors.orangeAccent;
      case 'processing':
        return Colors.blueAccent;
      case 'shipped':
        return theme.colorScheme.secondary;
      case 'delivered':
        return theme.colorScheme.primary;
      case 'cancelled':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  Widget _buildFilterChips(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          ...[
            'pending_payment',
            'processing',
            'shipped',
            'delivered',
            'cancelled'
          ].map((status) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(
                    order_status_utils.OrderStatusUtils.getDisplayString(
                        status)),
                selected: _selectedStatusFilter == status,
                onSelected: (selected) {
                  setState(() {
                    _selectedStatusFilter = selected ? status : null;
                  });
                },
                selectedColor: theme.colorScheme.primaryContainer,
                checkmarkColor: theme.colorScheme.onPrimaryContainer,
              ),
            ); // Corrected: Already correct
          }),
          if (_selectedStatusFilter != null)
            ActionChip(
              label: const Text('ล้างตัวกรอง'),
              onPressed: () {
                setState(() {
                  _selectedStatusFilter = null;
                });
              },
              backgroundColor: theme.colorScheme
                  .surfaceContainerHighest, // Corrected: Use surfaceContainerHighest // Corrected: Already correct // Corrected: Already correct // Corrected: Already correct // Corrected: Use surfaceContainerHighest
              labelStyle: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              avatar: Icon(Icons.clear,
                  size: 18, color: theme.colorScheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('จัดการคำสั่งซื้อ',
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.primary)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ค้นหาคำสั่งซื้อ (ID, ชื่อผู้ซื้อ)...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme
                    .surfaceContainerHighest, // Corrected: Use surfaceContainerHighest
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          _buildFilterChips(context), // Corrected: Already correct
          Expanded(
            child: StreamBuilder<List<app_order.Order>>(
              // Corrected: Cast to List<app_order.Order>
              stream:
                  firebaseService.getAllOrders().cast<List<app_order.Order>>(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('ไม่มีคำสั่งซื้อในระบบ'));
                }

                final orders =
                    _filterOrders(snapshot.data!); // Apply filters here

                if (orders.isEmpty) {
                  return const Center(
                      child: Text('ไม่พบคำสั่งซื้อที่ตรงกับตัวกรอง/การค้นหา'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 6.0, horizontal: 8.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(order.status, theme),
                          child: Icon(
                            Icons.receipt_long,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        title: Text('คำสั่งซื้อ #${order.id.substring(0, 8)}',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'ผู้ซื้อ: ${order.fullName} (${order.userId.substring(0, 8)}...)'),
                            Text(
                                'วันที่: ${DateFormat('dd MMM yyyy HH:mm').format(order.orderDate.toDate())}'),
                            Text(
                                'สถานะ: ${order_status_utils.OrderStatusUtils.getDisplayString(order.status)}',
                                style: TextStyle(
                                    color: _getStatusColor(order.status, theme),
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        trailing: Text(
                            '฿${order.totalAmount.toStringAsFixed(2)}',
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) =>
                                AdminOrderDetailScreen(order: order),
                          ));
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// You might want a dedicated AdminOrderDetailScreen for more detailed admin actions
class AdminOrderDetailScreen extends StatelessWidget {
  final app_order.Order order;
  const AdminOrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    // Use the improved OrderDetailScreen for consistency
    return OrderDetailScreen(order: order);
  }
}
