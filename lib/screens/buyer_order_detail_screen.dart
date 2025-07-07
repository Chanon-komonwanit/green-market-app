// lib/screens/buyer_order_detail_screen.dart
// ignore_for_file: strict_top_level_inference

import 'package:flutter/material.dart';
// Import OrderItem
import 'package:green_market/models/order.dart' as app_order;
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:green_market/utils/order_utils.dart'; // Import order_utils
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:green_market/screens/write_review_screen.dart'; // Import the actual WriteReviewScreen
import 'package:green_market/screens/review_detail_screen.dart'; // Import ReviewDetailScreen
import 'package:green_market/screens/order_tracking_screen.dart'; // Import OrderTrackingScreen
import 'package:firebase_auth/firebase_auth.dart';

class BuyerOrderDetailScreen extends StatefulWidget {
  final app_order.Order order;

  const BuyerOrderDetailScreen({super.key, required this.order});

  @override
  State<BuyerOrderDetailScreen> createState() => _BuyerOrderDetailScreenState();
}

class _BuyerOrderDetailScreenState extends State<BuyerOrderDetailScreen> {
  Map<String, bool> _reviewStatus = {};
  bool _isLoadingReviewStatus = true;

  @override
  void initState() {
    super.initState();
    _checkReviewStatuses();
  }

  Future<void> _checkReviewStatuses() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) setState(() => _isLoadingReviewStatus = false);
      return;
    }
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    Map<String, bool> statuses = {};
    try {
      for (var item in widget.order.items) {
        final hasReviewed = await firebaseService.hasUserReviewedProductInOrder(
          currentUser.uid,
          widget.order.id,
          item.productId,
        );
        statuses[item.productId] = hasReviewed;
      }
      if (mounted) {
        setState(() {
          _reviewStatus = statuses;
          _isLoadingReviewStatus = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingReviewStatus = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการตรวจสอบสถานะรีวิว: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text('รายละเอียดคำสั่งซื้อ #${widget.order.id.substring(0, 8)}'),
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
                        style: AppTextStyles.subtitle),
                    const SizedBox(height: 4),
                    Text(
                        'วันที่สั่ง: ${dateFormat.format(widget.order.orderDate.toDate().toLocal())}',
                        style: AppTextStyles.body),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('สถานะ: ', style: AppTextStyles.body),
                        Text(getOrderStatusText(widget.order.status),
                            style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                        'ยอดรวม: ฿${widget.order.totalAmount.toStringAsFixed(2)}',
                        style: AppTextStyles.price),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('ที่อยู่จัดส่ง:',
                style: AppTextStyles.subtitle
                    .copyWith(color: AppColors.primaryGreen)),
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
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.bold)),
                    Text(widget.order.phoneNumber, style: AppTextStyles.body),
                    Text(
                        '${widget.order.addressLine1}, ${widget.order.subDistrict}, ${widget.order.district}, ${widget.order.province} ${widget.order.zipCode}',
                        style: AppTextStyles.body),
                    if (widget.order.note != null &&
                        widget.order.note!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text('หมายเหตุ: ${widget.order.note}',
                            style: AppTextStyles.body.copyWith(
                                fontStyle: FontStyle.italic, fontSize: 12)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Shipping Information Section
            if (widget.order.status == 'shipped' ||
                widget.order.status == 'delivered')
              _buildShippingInfoSection(),

            Text('รายการสินค้า:',
                style: AppTextStyles.subtitle
                    .copyWith(color: AppColors.primaryGreen)),
            const SizedBox(height: 8),
            _isLoadingReviewStatus
                ? const Center(
                    child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(
                            color: AppColors.primaryGreen)))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.order.items.length,
                    itemBuilder: (context, index) {
                      final item = widget.order.items[index];
                      final bool hasReviewed =
                          _reviewStatus[item.productId] ?? false;

                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(vertical: 6.0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(item.imageUrl,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, st) =>
                                            const Icon(Icons.image,
                                                size: 70,
                                                color: AppColors.lightGrey)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(item.productName,
                                            style: AppTextStyles.body.copyWith(
                                                fontWeight: FontWeight.w600)),
                                        Text('จำนวน: ${item.quantity}',
                                            style: AppTextStyles.body
                                                .copyWith(fontSize: 14)),
                                        Text(
                                            'ราคา: ฿${item.pricePerUnit.toStringAsFixed(2)}',
                                            style: AppTextStyles.body
                                                .copyWith(fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.order.status.toLowerCase() ==
                                  'delivered')
                                Padding(
                                  padding: const EdgeInsets.only(top: 10.0),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: hasReviewed
                                        ? TextButton.icon(
                                            icon: const Icon(
                                                Icons.rate_review_outlined,
                                                color: AppColors.darkGrey,
                                                size: 18),
                                            label: Text('ดูรีวิวของคุณ',
                                                style: AppTextStyles.body
                                                    .copyWith(
                                                        fontSize: 14,
                                                        color:
                                                            AppColors // Corrected: Already correct
                                                                .darkGrey)),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ReviewDetailScreen(
                                                    orderId: widget.order.id,
                                                    orderItem: item,
                                                  ),
                                                ),
                                              );
                                            },
                                          )
                                        : ElevatedButton(
                                            onPressed: () async {
                                              final result =
                                                  await Navigator.push<bool>(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      WriteReviewScreen(
                                                    orderId: widget.order.id,
                                                    orderItem: item,
                                                  ),
                                                ),
                                              );
                                              if (result == true && mounted) {
                                                _checkReviewStatuses(); // Refresh review statuses
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.accentGreen,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6)),
                                            child: Text('เขียนรีวิว',
                                                style: AppTextStyles.body
                                                    .copyWith(
                                                        fontSize: 14,
                                                        color:
                                                            AppColors.white)),
                                          ),
                                  ),
                                )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 20),
            Text('รายละเอียดการชำระเงิน:',
                style: AppTextStyles.subtitle
                    .copyWith(color: AppColors.primaryGreen)),
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
                    Text(
                        'วิธีชำระเงิน: ${widget.order.paymentMethod.replaceAll('_', ' ').toUpperCase()}',
                        style: AppTextStyles.body),
                    Text(
                        'ยอดรวมสินค้า: ฿${widget.order.subTotal.toStringAsFixed(2)}',
                        style: AppTextStyles.body),
                    Text(
                        'ค่าจัดส่ง: ฿${widget.order.shippingFee.toStringAsFixed(2)}',
                        style: AppTextStyles.body),
                    const Divider(height: 16),
                    Text(
                        'รวมทั้งสิ้น: ฿${widget.order.totalAmount.toStringAsFixed(2)}',
                        style: AppTextStyles.price.copyWith(fontSize: 18)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ข้อมูลการจัดส่ง:',
            style:
                AppTextStyles.subtitle.copyWith(color: AppColors.primaryGreen)),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.order.shippingCarrier != null)
                  Row(
                    children: [
                      Icon(Icons.local_shipping,
                          color: AppColors.primaryTeal, size: 20),
                      const SizedBox(width: 8),
                      Text('บริษัทขนส่ง: ${widget.order.shippingCarrier}',
                          style: AppTextStyles.body),
                    ],
                  ),
                if (widget.order.shippingMethod != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        Icon(Icons.speed,
                            color: AppColors.primaryTeal, size: 20),
                        const SizedBox(width: 8),
                        Text('วิธีการส่ง: ${widget.order.shippingMethod}',
                            style: AppTextStyles.body),
                      ],
                    ),
                  ),
                if (widget.order.trackingNumber != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        Icon(Icons.tag, color: AppColors.primaryTeal, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                              'หมายเลขติดตาม: ${widget.order.trackingNumber}',
                              style: AppTextStyles.body),
                        ),
                      ],
                    ),
                  ),
                if (widget.order.shippedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        Icon(Icons.schedule,
                            color: AppColors.primaryTeal, size: 20),
                        const SizedBox(width: 8),
                        Text(
                            'วันที่จัดส่ง: ${DateFormat('dd MMM yyyy, HH:mm', 'th_TH').format(widget.order.shippedAt!.toDate())}',
                            style: AppTextStyles.body),
                      ],
                    ),
                  ),
                if (widget.order.deliveredAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: AppColors.primaryGreen, size: 20),
                        const SizedBox(width: 8),
                        Text(
                            'วันที่ส่งถึง: ${DateFormat('dd MMM yyyy, HH:mm', 'th_TH').format(widget.order.deliveredAt!.toDate())}',
                            style: AppTextStyles.body),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                // Track Package Button
                if (widget.order.trackingNumber != null ||
                    widget.order.trackingUrl != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                OrderTrackingScreen(order: widget.order),
                          ),
                        );
                      },
                      icon: Icon(Icons.track_changes, color: Colors.white),
                      label: Text('ติดตามพัสดุ',
                          style:
                              AppTextStyles.body.copyWith(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
