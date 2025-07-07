// lib/widgets/shipping_label_widget.dart
import 'package:flutter/material.dart';
import 'package:green_market/services/shipping/shipping_service_manager.dart';
import 'package:green_market/utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ShippingLabelWidget extends StatelessWidget {
  final ShippingLabel label;

  const ShippingLabelWidget({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GREEN MARKET',
                style: AppTextStyles.title.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTeal,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'ใบปะหน้าพัสดุ',
                    style: AppTextStyles.subtitle,
                  ),
                  Text(
                    label.carrier,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(thickness: 2),
          const SizedBox(height: 16),

          // Tracking Number Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryTeal),
            ),
            child: Column(
              children: [
                Text(
                  'หมายเลขติดตาม',
                  style: AppTextStyles.bodyBold,
                ),
                const SizedBox(height: 4),
                Text(
                  label.trackingNumber,
                  style: AppTextStyles.title.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                // Barcode
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black),
                  ),
                  child: Center(
                    child: Text(
                      '|||| | || ||| | || |||||| | ||',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 20,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Sender and Receiver Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sender
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ผู้ส่ง (FROM)',
                        style: AppTextStyles.bodyBold
                            .copyWith(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label.senderName,
                      style: AppTextStyles.bodyBold,
                    ),
                    Text(
                      label.senderAddress,
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'วิธีการส่ง: ${_getShippingMethodName(label.shippingMethod)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Receiver
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ผู้รับ (TO)',
                        style: AppTextStyles.bodyBold
                            .copyWith(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label.receiverName,
                      style: AppTextStyles.bodyBold,
                    ),
                    Text(
                      label.receiverAddress,
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'โทร: ${label.receiverPhone}',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Package Details
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'รายละเอียดพัสดุ',
                  style: AppTextStyles.bodyBold,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text('น้ำหนัก: ${label.weight}',
                          style: AppTextStyles.bodySmall),
                    ),
                    Expanded(
                      child: Text('มูลค่า: ฿${label.value.toStringAsFixed(2)}',
                          style: AppTextStyles.bodySmall),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('คำสั่งซื้อ: #${label.orderId.substring(0, 8)}',
                    style: AppTextStyles.bodySmall),
                if (label.specialInstructions != null &&
                    label.specialInstructions!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'หมายเหตุ: ${label.specialInstructions}',
                    style: AppTextStyles.bodySmall
                        .copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // QR Code and Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // QR Code
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: QrImageView(
                  data: label.trackingNumber,
                  version: QrVersions.auto,
                  size: 80.0,
                ),
              ),

              // Footer Info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'วันที่พิมพ์:',
                    style: AppTextStyles.bodySmall,
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(label.createdAt),
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Green Market System',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _printLabel(context),
                  icon: const Icon(Icons.print),
                  label: const Text('พิมพ์'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryTeal,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _shareLabel(context),
                  icon: const Icon(Icons.share),
                  label: const Text('แชร์'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getShippingMethodName(String methodId) {
    switch (methodId) {
      case 'standard_delivery':
        return 'ส่งปกติ';
      case 'express_delivery':
        return 'ส่งด่วน';
      case 'cod_delivery':
        return 'เก็บเงินปลายทาง';
      case 'free_shipping':
        return 'ส่งฟรี';
      default:
        return methodId;
    }
  }

  void _printLabel(BuildContext context) {
    // In a real implementation, this would trigger printing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('กำลังพิมพ์ใบปะหน้า ${label.trackingNumber}'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  void _shareLabel(BuildContext context) {
    // In a real implementation, this would share the label
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('แชร์ใบปะหน้า ${label.trackingNumber}'),
        backgroundColor: AppColors.primaryTeal,
      ),
    );
  }
}
