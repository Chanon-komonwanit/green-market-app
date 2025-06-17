// lib/screens/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/order.dart';
import 'package:green_market/models/order_item.dart'; // Direct import for OrderItem
import 'package:green_market/utils/constants.dart';
import 'package:green_market/utils/order_utils.dart'; // Import order_utils
import 'package:green_market/screens/image_viewer_screen.dart'; // Import image viewer
import 'package:green_market/screens/write_review_screen.dart'; // Import review screen
import 'package:green_market/services/firebase_service.dart'; // For checking reviews
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // For FirebaseService
import 'package:url_launcher/url_launcher.dart'; // For launching URLs
import 'package:firebase_auth/firebase_auth.dart'; // For current user

class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  Future<void> _launchURL(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถเปิดลิงก์: $urlString')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายละเอียดคำสั่งซื้อ #${order.id.substring(0, 8)}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('ข้อมูลคำสั่งซื้อ'),
            _buildInfoRow('หมายเลขคำสั่งซื้อ:', order.id),
            _buildInfoRow(
                'วันที่สั่งซื้อ:',
                DateFormat('dd MMMM yyyy, HH:mm', 'th_TH')
                    .format(order.orderDate.toDate())), // Use utility function
            _buildInfoRow('สถานะ:', getOrderStatusText(order.status),
                highlight: true),
            _buildInfoRow('ยอดรวม:', '฿${order.totalAmount.toStringAsFixed(2)}',
                highlight: true),
            _buildInfoRow(
                'วิธีการชำระเงิน:',
                order.paymentMethod == 'qr_code'
                    ? 'QR Code'
                    : 'เก็บเงินปลายทาง'),
            if (order.paymentSlipUrl != null &&
                order.paymentSlipUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('สลิปการชำระเงิน:', style: AppTextStyles.bodyBold),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => ImageViewerScreen(
                                  imageUrl: order.paymentSlipUrl!,
                                  heroTag:
                                      'slip_${order.id}', // Optional: for Hero animation
                                )));
                      },
                      child: Image.network(
                        order.paymentSlipUrl!,
                        height: 150,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Text('ไม่สามารถโหลดรูปสลิปได้'),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),
            _buildSectionTitle(
                'ที่อยู่ในการจัดส่ง'), // Use direct fields from order
            Text(order.fullName, style: AppTextStyles.body),
            Text(order.addressLine1, style: AppTextStyles.body),
            // Assuming addressLine2 is not part of the Order model directly,
            // but part of the shippingAddress map during creation.
            // If order.addressLine2 exists, use it. Otherwise, this part might need adjustment
            // based on how addressLine2 is stored in the Order model.
            // For now, assuming Order model has direct fields like addressLine1, subDistrict etc.
            Text(
                '${order.subDistrict}, ${order.district}, ${order.province}, ${order.zipCode}',
                style: AppTextStyles.body),
            Text('โทร: ${order.phoneNumber}', style: AppTextStyles.body),
            // Section for Tracking Information
            if (order.trackingNumber != null &&
                order.trackingNumber!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSectionTitle('ข้อมูลการติดตามพัสดุ'),
              _buildInfoRow(
                'หมายเลขพัสดุ:',
                order.trackingNumber!,
                isLink:
                    order.trackingUrl != null && order.trackingUrl!.isNotEmpty,
                url: order.trackingUrl,
                contextForUrlLaunch: context,
              ),
              // You can add more tracking details if available
            ],

            const SizedBox(height: 20),
            _buildSectionTitle('รายการสินค้า (${order.items.length})'),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.items.length,
              itemBuilder: (ctx, index) {
                final OrderItem item = order.items[index]; // Explicit type
                final firebaseService =
                    Provider.of<FirebaseService>(context, listen: false);
                final currentUser = FirebaseAuth.instance.currentUser;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6.0),
                  child: ListTile(
                    leading: item.imageUrl.isNotEmpty
                        ? Image.network(item.imageUrl,
                            width: 50, height: 50, fit: BoxFit.cover)
                        : Container(
                            width: 50,
                            height: 50,
                            color: AppColors.lightGrey,
                            child: const Icon(Icons.image_not_supported)),
                    title:
                        Text(item.productName, style: AppTextStyles.bodyBold),
                    subtitle: Text(
                        'จำนวน: ${item.quantity} x ฿${item.pricePerUnit.toStringAsFixed(2)}'),
                    trailing: Text(
                      '฿${(item.quantity * item.pricePerUnit).toStringAsFixed(2)}',
                      style: AppTextStyles.bodyBold,
                    ),
                    // Add "Write Review" button conditionally
                    onTap: (order.status == 'delivered' && currentUser != null)
                        ? () async {
                            bool hasReviewed = await firebaseService
                                .hasUserReviewedProductInOrder(
                              currentUser.uid,
                              order.id,
                              item.productId,
                            );
                            if (context.mounted) {
                              if (!hasReviewed) {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => WriteReviewScreen(
                                    orderId: order.id, // Pass the Order object
                                    orderItem:
                                        item, // Pass the OrderItem directly
                                  ), // Pass the OrderItem directly
                                ));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('คุณได้รีวิวสินค้านี้แล้ว')),
                                );
                              }
                            }
                          }
                        : null, // Disable onTap if not deliverable or no user
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: AppTextStyles.title
            .copyWith(fontSize: 18, color: AppColors.primaryDarkGreen),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool highlight = false,
      bool isLink = false,
      String? url,
      BuildContext? contextForUrlLaunch}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label ',
              style:
                  AppTextStyles.body.copyWith(color: AppColors.modernDarkGrey)),
          Expanded(
            child: isLink && url != null && contextForUrlLaunch != null
                ? InkWell(
                    onTap: () => _launchURL(contextForUrlLaunch, url),
                    child: Text(
                      value,
                      style: AppTextStyles.link.copyWith(
                          color: AppColors.primaryTeal,
                          fontSize: AppTextStyles.body.fontSize),
                    ),
                  )
                : Text(
                    value,
                    style: highlight
                        ? AppTextStyles.bodyBold
                            .copyWith(color: AppColors.primaryGreen)
                        : AppTextStyles.body
                            .copyWith(color: AppColors.modernDarkGrey),
                  ),
          ),
        ],
      ),
    );
  }
}
