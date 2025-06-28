// lib/screens/admin/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/order.dart' as app_order;
import 'package:green_market/utils/constants.dart';
import 'package:green_market/utils/order_utils.dart'; // Import order_utils
import 'package:green_market/screens/image_viewer_screen.dart'; // Import image viewer
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // For launching URLs

class OrderDetailScreen extends StatelessWidget {
  final app_order.Order order;

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
                    .format(order.orderDate.toDate())),
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
                                  heroTag: 'slip_${order.id}',
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
            _buildSectionTitle('ที่อยู่ในการจัดส่ง'),
            Text(order.fullName, style: AppTextStyles.body),
            Text(order.addressLine1, style: AppTextStyles.body),
            Text(
                '${order.subDistrict}, ${order.district}, ${order.province}, ${order.zipCode}',
                style: AppTextStyles.body),
            Text('โทร: ${order.phoneNumber}', style: AppTextStyles.body),
            if (order.trackingNumber != null &&
                order.trackingNumber!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('ข้อมูลการจัดส่ง'),
                    _buildInfoRow('หมายเลขติดตาม:', order.trackingNumber!),
                    if (order.trackingUrl != null &&
                        order.trackingUrl!.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () =>
                            _launchURL(context, order.trackingUrl!),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('ติดตามพัสดุ'),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            _buildSectionTitle('รายการสินค้า'),
            ...order.items.map((item) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    leading: item.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              item.imageUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image_not_supported),
                            ),
                          )
                        : const Icon(Icons.image_not_supported),
                    title:
                        Text(item.productName, style: AppTextStyles.bodyBold),
                    subtitle: Text(
                        'จำนวน: ${item.quantity} x ฿${item.pricePerUnit.toStringAsFixed(2)}',
                        style: AppTextStyles.body),
                    trailing: Text(
                        '฿${(item.quantity * item.pricePerUnit).toStringAsFixed(2)}',
                        style: AppTextStyles.bodyBold),
                  ),
                )),
            const SizedBox(height: 16),
            Card(
              color: AppColors.veryLightTeal,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ยอดรวมทั้งสิ้น', style: AppTextStyles.bodyBold),
                    Text('฿${order.totalAmount.toStringAsFixed(2)}',
                        style: AppTextStyles.title.copyWith(
                          color: AppColors.primaryDarkGreen,
                          fontWeight: FontWeight.bold,
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: AppTextStyles.subtitle.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.primaryDarkGreen,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: highlight
                  ? AppTextStyles.bodyBold.copyWith(
                      color: AppColors.primaryDarkGreen,
                    )
                  : AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}
