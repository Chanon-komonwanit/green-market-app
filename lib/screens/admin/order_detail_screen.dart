// lib/screens/admin/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/order.dart' as app_order;
import 'package:green_market/utils/constants.dart'; // Assuming AppTextStyles and AppColors are here

class OrderDetailScreen extends StatelessWidget {
  final app_order.Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายละเอียดคำสั่งซื้อ', style: AppTextStyles.title),
        backgroundColor: AppColors.lightGrey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text('คำสั่งซื้อ #${order.id.substring(0, 8)}',
                style: AppTextStyles.subtitle), // Show partial ID for brevity
            const SizedBox(height: 8),
            _buildDetailRow('ID เต็ม:', order.id),
            _buildDetailRow(
                'ผู้ซื้อ:',
                order
                    .fullName), // Assuming fullName is part of shipping address
            _buildDetailRow('ที่อยู่:',
                '${order.addressLine1}, ${order.subDistrict}, ${order.district}, ${order.province} ${order.zipCode}'), // Construct full address here or use order.fullAddress if implemented
            _buildDetailRow('เบอร์โทรศัพท์:', order.phoneNumber),
            _buildDetailRow('วันที่:',
                order.orderDate.toDate().toLocal().toString().split('.')[0]),
            _buildDetailRow(
                'สถานะ:', order.status.replaceAll('_', ' ').toUpperCase()),
            const SizedBox(height: 16),
            Text('รายการสินค้า:',
                style: AppTextStyles.subtitle.copyWith(fontSize: 16)),
            ...order.items.map((item) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    leading: item.imageUrl.isNotEmpty
                        ? Image.network(item.imageUrl,
                            width: 50, height: 50, fit: BoxFit.cover)
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
            _buildDetailRow('รวม:', '฿${order.totalAmount.toStringAsFixed(2)}',
                isBold: true),
            // เพิ่มรายละเอียดอื่น ๆ ตามต้องการ เช่น ช่องทางการชำระเงิน, tracking number
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label ',
              style: AppTextStyles.bodyBold.copyWith(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Expanded(
              child: Text(value,
                  style: AppTextStyles.body.copyWith(
                      fontWeight:
                          isBold ? FontWeight.bold : FontWeight.normal))),
        ],
      ),
    );
  }
}
