// lib/screens/order_tracking_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/order.dart' as app_order;
import 'package:green_market/utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderTrackingScreen extends StatelessWidget {
  final app_order.Order order;

  const OrderTrackingScreen({super.key, required this.order});

  Future<void> _launchTrackingUrl() async {
    if (order.trackingUrl != null && order.trackingUrl!.isNotEmpty) {
      final Uri url = Uri.parse(order.trackingUrl!);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch ${order.trackingUrl}';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ติดตามพัสดุ #${order.id.substring(0, 8)}'),
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary Card
            _buildOrderSummaryCard(),
            const SizedBox(height: 20),

            // Shipping Info Card
            _buildShippingInfoCard(),
            const SizedBox(height: 20),

            // Tracking Timeline
            _buildTrackingTimeline(),
            const SizedBox(height: 20),

            // Delivery Address
            _buildDeliveryAddressCard(),

            // Action Buttons
            if (order.trackingUrl != null && order.trackingUrl!.isNotEmpty)
              const SizedBox(height: 20),
            if (order.trackingUrl != null && order.trackingUrl!.isNotEmpty)
              _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_bag, color: AppColors.primaryTeal),
                const SizedBox(width: 8),
                Text(
                  'รายละเอียดคำสั่งซื้อ',
                  style: AppTextStyles.bodyBold.copyWith(
                    color: AppColors.primaryDarkGreen,
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('หมายเลขคำสั่งซื้อ:', style: AppTextStyles.body),
                Text('#${order.id.substring(0, 8)}',
                    style: AppTextStyles.bodyBold),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('วันที่สั่งซื้อ:', style: AppTextStyles.body),
                Text(
                  DateFormat('dd MMM yyyy', 'th_TH')
                      .format(order.orderDate.toDate()),
                  style: AppTextStyles.bodyBold,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('สถานะ:', style: AppTextStyles.body),
                _StatusChip(status: order.status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ยอดรวม:', style: AppTextStyles.body),
                Text(
                  '฿${order.totalAmount.toStringAsFixed(2)}',
                  style: AppTextStyles.bodyBold.copyWith(
                    color: AppColors.primaryDarkGreen,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingInfoCard() {
    if (order.shippingCarrier == null && order.trackingNumber == null) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.pending, size: 48, color: AppColors.warningYellow),
              const SizedBox(height: 8),
              Text(
                'รอข้อมูลการจัดส่ง',
                style: AppTextStyles.bodyBold,
              ),
              Text(
                'ผู้ขายยังไม่ได้ส่งสินค้า',
                style: AppTextStyles.body.copyWith(color: AppColors.darkGrey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping, color: AppColors.primaryTeal),
                const SizedBox(width: 8),
                Text(
                  'ข้อมูลการจัดส่ง',
                  style: AppTextStyles.bodyBold.copyWith(
                    color: AppColors.primaryDarkGreen,
                  ),
                ),
              ],
            ),
            const Divider(),
            if (order.shippingCarrier != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('บริษัทขนส่ง:', style: AppTextStyles.body),
                  Text(order.shippingCarrier!, style: AppTextStyles.bodyBold),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (order.trackingNumber != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('หมายเลขติดตาม:', style: AppTextStyles.body),
                  SelectableText(
                    order.trackingNumber!,
                    style: AppTextStyles.bodyBold.copyWith(
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (order.shippedAt != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('วันที่จัดส่ง:', style: AppTextStyles.body),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm', 'th_TH')
                        .format(order.shippedAt!.toDate()),
                    style: AppTextStyles.bodyBold,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingTimeline() {
    final List<Map<String, dynamic>> timeline = _getTrackingTimeline();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: AppColors.primaryTeal),
                const SizedBox(width: 8),
                Text(
                  'ขั้นตอนการจัดส่ง',
                  style: AppTextStyles.bodyBold.copyWith(
                    color: AppColors.primaryDarkGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...timeline.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isLast = index == timeline.length - 1;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline indicator
                  Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: step['completed']
                              ? AppColors.primaryTeal
                              : AppColors.lightGrey,
                        ),
                        child: Icon(
                          step['completed'] ? Icons.check : Icons.circle,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 40,
                          color: step['completed']
                              ? AppColors.primaryTeal
                              : AppColors.lightGrey,
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Timeline content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step['title'],
                            style: AppTextStyles.bodyBold.copyWith(
                              color: step['completed']
                                  ? AppColors.primaryDarkGreen
                                  : AppColors.darkGrey,
                            ),
                          ),
                          if (step['subtitle'] != null)
                            Text(
                              step['subtitle'],
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.darkGrey,
                                fontSize: 12,
                              ),
                            ),
                          if (step['timestamp'] != null)
                            Text(
                              step['timestamp'],
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.darkGrey,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryAddressCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: AppColors.primaryTeal),
                const SizedBox(width: 8),
                Text(
                  'ที่อยู่จัดส่ง',
                  style: AppTextStyles.bodyBold.copyWith(
                    color: AppColors.primaryDarkGreen,
                  ),
                ),
              ],
            ),
            const Divider(),
            Text(order.fullName, style: AppTextStyles.bodyBold),
            const SizedBox(height: 4),
            Text('โทร: ${order.phoneNumber}', style: AppTextStyles.body),
            const SizedBox(height: 8),
            Text(
              '${order.addressLine1}, ${order.subDistrict}, ${order.district}, ${order.province} ${order.zipCode}',
              style: AppTextStyles.body,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _launchTrackingUrl,
            icon: const Icon(Icons.open_in_new),
            label: const Text('ติดตามบนเว็บไซต์ขนส่ง'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Implement problem reporting
              // TODO: [ภาษาไทย] เพิ่มฟีเจอร์ให้ผู้ใช้รายงานปัญหาเกี่ยวกับการติดตามคำสั่งซื้อ
            },
            icon: const Icon(Icons.report_problem),
            label: const Text('แจ้งปัญหาการจัดส่ง'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.errorRed,
              side: BorderSide(color: AppColors.errorRed),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getTrackingTimeline() {
    final timeline = <Map<String, dynamic>>[];

    // Order placed
    timeline.add({
      'title': 'สั่งซื้อเรียบร้อย',
      'subtitle': 'คำสั่งซื้อได้รับการยืนยันแล้ว',
      'timestamp': DateFormat('dd MMM yyyy, HH:mm', 'th_TH')
          .format(order.orderDate.toDate()),
      'completed': true,
    });

    // Payment confirmed (if paid)
    if (order.status != 'pending_payment') {
      timeline.add({
        'title': 'ชำระเงินแล้ว',
        'subtitle': 'ผู้ขายได้รับการชำระเงินแล้ว',
        'timestamp': null,
        'completed': true,
      });
    }

    // Preparing to ship
    timeline.add({
      'title': 'กำลังเตรียมสินค้า',
      'subtitle': 'ผู้ขายกำลังเตรียมสินค้าสำหรับจัดส่ง',
      'timestamp': null,
      'completed': order.status == 'processing' ||
          order.status == 'shipped' ||
          order.status == 'delivered',
    });

    // Shipped
    timeline.add({
      'title': 'จัดส่งแล้ว',
      'subtitle': order.shippingCarrier != null
          ? 'ส่งโดย ${order.shippingCarrier}'
          : 'สินค้าถูกส่งออกแล้ว',
      'timestamp': order.shippedAt != null
          ? DateFormat('dd MMM yyyy, HH:mm', 'th_TH')
              .format(order.shippedAt!.toDate())
          : null,
      'completed': order.status == 'shipped' || order.status == 'delivered',
    });

    // Out for delivery
    timeline.add({
      'title': 'กำลังนำส่ง',
      'subtitle': 'สินค้าอยู่ระหว่างการนำส่งถึงผู้รับ',
      'timestamp': null,
      'completed': false, // This would be updated from real tracking API
    });

    // Delivered
    timeline.add({
      'title': 'ส่งถึงแล้ว',
      'subtitle': 'สินค้าถูกส่งถึงผู้รับเรียบร้อย',
      'timestamp': order.deliveredAt != null
          ? DateFormat('dd MMM yyyy, HH:mm', 'th_TH')
              .format(order.deliveredAt!.toDate())
          : null,
      'completed': order.status == 'delivered',
    });

    return timeline;
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
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
