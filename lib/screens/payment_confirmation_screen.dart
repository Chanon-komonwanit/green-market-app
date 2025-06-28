// lib/screens/payment_confirmation_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:green_market/models/order.dart' as app_order;
import 'package:green_market/screens/image_viewer_screen.dart';
import 'package:green_market/screens/order_confirmation_screen.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/app_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class PaymentConfirmationScreen extends StatefulWidget {
  final app_order.Order order;
  final String? qrCodeUrl;

  const PaymentConfirmationScreen({
    super.key,
    required this.order,
    this.qrCodeUrl,
  });

  @override
  State<PaymentConfirmationScreen> createState() =>
      _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  XFile? _pickedSlipFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickSlipImage() async {
    final XFile? selectedImage = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (selectedImage != null) {
      setState(() {
        _pickedSlipFile = selectedImage;
      });
    }
  }

  Future<void> _uploadSlipAndConfirm() async {
    if (_pickedSlipFile == null) {
      showAppSnackBar(context, 'กรุณาแนบสลิปการชำระเงิน', isError: true);
      return;
    }

    setState(() => _isUploading = true);
    final firebaseService = Provider.of<FirebaseService>(
      context,
      listen: false,
    );

    try {
      const uuid = Uuid();
      final extension = _pickedSlipFile!.name.split('.').last;
      final fileName = 'slip_${widget.order.id}_${uuid.v4()}.$extension';
      // const storagePath = 'payment_slips';

      String? slipUrl;
      if (kIsWeb) {
        final bytes = await _pickedSlipFile!.readAsBytes();
        slipUrl = await firebaseService.uploadWebImage(bytes, fileName);
      } else {
        slipUrl = await firebaseService.uploadImageFile(
            File(_pickedSlipFile!.path), fileName);
      }

      await firebaseService.updateOrderStatusWithSlip(
        widget.order.id,
        'processing',
        slipUrl,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(
              order: widget.order.copyWith(status: 'processing'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          'เกิดข้อผิดพลาด: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('ยืนยันการชำระเงิน')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'คำสั่งซื้อ #${widget.order.id.substring(0, 8)}',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'ยอดชำระ: ฿${widget.order.totalAmount.toStringAsFixed(2)}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            if (widget.qrCodeUrl != null && widget.qrCodeUrl!.isNotEmpty) ...[
              Text(
                'สแกน QR Code เพื่อชำระเงิน',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () {
                  // Ensure qrCodeUrl is not null before passing to Image.network
                  if (widget.qrCodeUrl != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ImageViewerScreen(
                          imageUrl:
                              widget.qrCodeUrl!, // Corrected: Add null check
                          heroTag: 'qr_code_${widget.order.id}',
                        ),
                      ),
                    );
                  }
                },
                child: Image.network(
                  widget.qrCodeUrl!,
                  height: 200,
                  width: 200,
                  errorBuilder: (context, error, stackTrace) =>
                      const Text('ไม่สามารถโหลด QR Code ได้'),
                ),
              ),
              const SizedBox(height: 24),
            ],
            const Divider(),
            const SizedBox(height: 24),
            Text('อัปโหลดสลิปการชำระเงิน', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            if (_pickedSlipFile != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: kIsWeb
                    ? Image.network(
                        _pickedSlipFile!.path,
                        height: 200,
                        fit: BoxFit.contain,
                      )
                    : Image.file(
                        File(_pickedSlipFile!.path),
                        height: 200,
                        fit: BoxFit.contain,
                      ),
              ),
            OutlinedButton.icon(
              onPressed: _pickSlipImage,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(
                _pickedSlipFile == null
                    ? 'เลือกรูปภาพสลิป'
                    : 'เปลี่ยนรูปภาพสลิป',
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadSlipAndConfirm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isUploading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Text('ยืนยันการชำระเงิน'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
