// lib/screens/seller/seller_order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/order.dart' as app_order;
import 'package:green_market/utils/constants.dart'; // For AppColors
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/order_status_utils.dart'
    as order_status_utils;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SellerOrderDetailScreen extends StatefulWidget {
  final app_order.Order order;

  const SellerOrderDetailScreen({super.key, required this.order});

  @override
  State<SellerOrderDetailScreen> createState() =>
      _SellerOrderDetailScreenState();
}

class _SellerOrderDetailScreenState extends State<SellerOrderDetailScreen> {
  late String _currentStatus;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status;
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() {
      _isUpdatingStatus = true;
    });
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    try {
      await firebaseService.updateOrderStatus(widget.order.id, newStatus);
      if (mounted) {
        setState(() {
          _currentStatus = newStatus;
          _isUpdatingStatus = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปเดตสถานะคำสั่งซื้อสำเร็จ')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปเดตสถานะ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final DateFormat dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'th_TH');

    return Scaffold(
      appBar: AppBar(
        title: Text('คำสั่งซื้อ #${widget.order.id.substring(0, 8)}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('คำสั่งซื้อ: #${widget.order.id.substring(0, 8)}',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                        'วันที่สั่ง: ${dateFormat.format(widget.order.orderDate.toDate().toLocal())}',
                        style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('สถานะ: ', style: theme.textTheme.bodyLarge),
                        Text(
                            order_status_utils.OrderStatusUtils
                                .getDisplayString(_currentStatus),
                            style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: order_status_utils.OrderStatusUtils
                                    .getStatusColor(_currentStatus))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                        'ยอดรวม: ฿${widget.order.totalAmount.toStringAsFixed(2)}',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(color: theme.colorScheme.secondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('ที่อยู่จัดส่ง:',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.primary)),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.order.fullName,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text(widget.order.phoneNumber,
                        style: theme.textTheme.bodyLarge),
                    Text(
                        '${widget.order.addressLine1}, ${widget.order.subDistrict}, ${widget.order.district}, ${widget.order.province} ${widget.order.zipCode}',
                        style: theme.textTheme.bodyLarge),
                    if (widget.order.note != null &&
                        widget.order.note!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text('หมายเหตุ: ${widget.order.note}',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontStyle: FontStyle.italic)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('รายการสินค้า:',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.primary)),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.order.items.length,
              itemBuilder: (context, index) {
                final item = widget.order.items[index];
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(vertical: 6.0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: item.imageUrl.isNotEmpty
                              ? Image.network(item.imageUrl,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, st) => const Icon(
                                      Icons.image,
                                      size: 70,
                                      color: Colors.grey))
                              : const Icon(Icons.image,
                                  size: 70, color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName,
                                  style: theme.textTheme.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                              Text('จำนวน: ${item.quantity}',
                                  style: theme.textTheme.bodyMedium),
                              Text(
                                  'ราคา: ฿${item.pricePerUnit.toStringAsFixed(2)}',
                                  style: theme.textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text('อัปเดตสถานะคำสั่งซื้อ:',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.primary)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _currentStatus,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'สถานะ',
              ),
              items: order_status_utils.OrderStatusUtils.sellerUpdatableStatuses
                  .map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(
                      order_status_utils.OrderStatusUtils.getDisplayString(
                          status)),
                );
              }).toList(),
              onChanged: _isUpdatingStatus
                  ? null
                  : (newValue) {
                      if (newValue != null) {
                        _updateStatus(newValue);
                      }
                    },
            ),
            if (_isUpdatingStatus)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
