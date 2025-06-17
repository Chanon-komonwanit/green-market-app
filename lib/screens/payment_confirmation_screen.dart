// lib/screens/payment_confirmation_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/order.dart'
    as app_order; // ใช้ Order model ของเรา
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:green_market/screens/main_screen.dart'; // For navigating back to home

class PaymentConfirmationScreen extends StatefulWidget {
  final app_order.Order order; // รับข้อมูลคำสั่งสั่งซื้อ
  const PaymentConfirmationScreen({super.key, required this.order});

  @override
  State<PaymentConfirmationScreen> createState() =>
      _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  File? _paymentSlip; // สำหรับเก็บรูปภาพสลิปที่เลือก
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickSlipImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _paymentSlip = File(pickedFile.path);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เลือกสลิปสำเร็จ: ${pickedFile.name}')),
      );
    }
  }

  Future<void> _submitPaymentConfirmation() async {
    if (_paymentSlip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('กรุณาเลือกรูปภาพสลิปเพื่อยืนยันการชำระเงิน')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);

      String? slipUrl;
      if (_paymentSlip != null) {
        // Generate a unique file name for the slip
        // Upload the slip image to Firebase Storage
        // Assuming firebaseService.uploadImageFile can handle File type directly
        // or you might need a method like uploadImageBytes if you read the file as bytes.
        // For simplicity, let's assume uploadImageFile takes a File path.
        slipUrl = await firebaseService.uploadImageFile(
            'payment_slips/order_${widget.order.id}', // Path in storage
            _paymentSlip!.path,
            fileName:
                'slip_${DateTime.now().millisecondsSinceEpoch}.png' // Optional: specific file name
            );
      }

      // อัปเดตสถานะคำสั่งซื้อใน Firestore เป็น 'awaiting_confirmation' หรือ 'payment_received'
      // และเพิ่ม Field สำหรับ URL สลิป
      await firebaseService.updateOrderStatusWithSlip(
        widget.order.id,
        'awaiting_confirmation', // สถานะใหม่
        slipUrl, // URL สลิป (Mock หรือจริง)
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('แจ้งการชำระเงินสำเร็จ! คำสั่งซื้อจะได้รับการตรวจสอบ'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        // กลับไปหน้าหลัก
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('เกิดข้อผิดพลาดในการแจ้งการชำระเงิน: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('แจ้งการชำระเงิน #${widget.order.id.substring(0, 8)}'),
        // backgroundColor and iconTheme will use the app's theme
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ยอดที่ต้องชำระ:',
                      style: AppTextStyles.subtitle
                          .copyWith(color: AppColors.primaryDarkGreen)),
                  const SizedBox(height: 8),
                  Text('฿${widget.order.totalAmount.toStringAsFixed(2)}',
                      style: AppTextStyles.headline.copyWith(
                          color: AppColors.primaryGreen, fontSize: 32)),
                  const SizedBox(height: 20),
                  Text(
                      'วิธีการชำระเงิน: ${widget.order.paymentMethod == 'qr_code' ? 'QR Code' : 'เก็บเงินปลายทาง'}',
                      style: AppTextStyles.body),
                  if (widget.order.paymentMethod == 'qr_code')
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // แสดง QR Code เดิมอีกครั้งเพื่อให้ผู้ใช้สแกนได้ (ถ้ามี URL QR Code จริง)
                          // For now, using a placeholder as the actual QR might have been generated on previous screen
                          Image.network(
                            widget.order.qrCodeImageUrl ??
                                'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=Amount:${widget.order.totalAmount.toStringAsFixed(2)}THB_Order:${widget.order.id.substring(0, 6)}', // Use actual QR if stored in order, else generate a mock one
                            width: 200, height: 200, fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                    width: 200,
                                    height: 200,
                                    color: AppColors.lightGrey,
                                    child: Icon(Icons.qr_code,
                                        size: 80, color: AppColors.darkGrey)),
                          ),
                          const SizedBox(height: 8),
                          Text('สแกน QR Code นี้เพื่อชำระเงิน',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.modernGrey)),
                          Text(
                              'จำนวน: ฿${widget.order.totalAmount.toStringAsFixed(2)}',
                              style: AppTextStyles.subtitle
                                  .copyWith(color: AppColors.primaryGreen)),
                          const SizedBox(height: 16),
                          Text(
                              // This text might be more relevant on the CheckoutSummaryScreen
                              'โปรดชำระเงินภายใน 30 นาที มิฉะนั้นคำสั่งซื้อจะถูกยกเลิก',
                              style: AppTextStyles.body.copyWith(
                                  fontSize: 12, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _pickSlipImage,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('อัปโหลดสลิป'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightTeal,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                  if (_paymentSlip != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'สลิปที่เลือก: ${_paymentSlip!.path.split('/').last}',
                              style: AppTextStyles.bodySmall),
                          const SizedBox(height: 8),
                          // Image.file(_paymentSlip!, height: 150, fit: BoxFit.contain), // Optional: Show preview
                        ],
                      ),
                    ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading || _paymentSlip == null
                          ? null
                          : _submitPaymentConfirmation,
                      // style will use theme's ElevatedButton style
                      child: const Text('ยืนยันการชำระเงิน'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
