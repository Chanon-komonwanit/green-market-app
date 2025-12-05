// lib/widgets/qr_profile_share_widget.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';

/// QR Code Profile Sharing Widget
/// แชร์โปรไฟล์ผ่าน QR Code
class QRProfileShareWidget extends StatefulWidget {
  final String userId;
  final String displayName;
  final String? photoUrl;

  const QRProfileShareWidget({
    super.key,
    required this.userId,
    required this.displayName,
    this.photoUrl,
  });

  /// แสดง QR dialog
  static void show({
    required BuildContext context,
    required String userId,
    required String userName,
    String? userPhotoUrl,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: QRProfileShareWidget(
          userId: userId,
          displayName: userName,
          photoUrl: userPhotoUrl,
        ),
      ),
    );
  }

  @override
  State<QRProfileShareWidget> createState() => _QRProfileShareWidgetState();
}

class _QRProfileShareWidgetState extends State<QRProfileShareWidget> {
  final GlobalKey _qrKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    // สร้าง deep link สำหรับโปรไฟล์
    final profileUrl = 'https://greenmarket.app/profile/${widget.userId}';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'แชร์โปรไฟล์',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // QR Code Card
          RepaintBoundary(
            key: _qrKey,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Profile Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.green[100],
                        backgroundImage: widget.photoUrl != null
                            ? NetworkImage(widget.photoUrl!)
                            : null,
                        child: widget.photoUrl == null
                            ? Text(
                                widget.displayName[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.displayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Green Market Profile',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: QrImageView(
                      data: profileUrl,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                      embeddedImage: const AssetImage('assets/logo.jpg'),
                      embeddedImageStyle: const QrEmbeddedImageStyle(
                        size: Size(40, 40),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Instruction
                  const Text(
                    'สแกน QR Code เพื่อดูโปรไฟล์',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _shareQRCode(),
                  icon: const Icon(Icons.share),
                  label: const Text('แชร์ QR Code'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _shareLink(),
                  icon: const Icon(Icons.link),
                  label: const Text('คัดลอกลิงก์'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// แชร์ QR Code เป็นรูปภาพ
  Future<void> _shareQRCode() async {
    try {
      // Capture QR Code as image
      final boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final imageBytes = byteData!.buffer.asUint8List();

      // Save to temp and share
      await Share.shareXFiles(
        [
          XFile.fromData(imageBytes,
              mimeType: 'image/png', name: 'profile_qr.png')
        ],
        text:
            'สแกน QR Code เพื่อดูโปรไฟล์ ${widget.displayName} บน Green Market',
      );
    } catch (e) {
      debugPrint('Error sharing QR code: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาดในการแชร์')),
        );
      }
    }
  }

  /// แชร์ลิงก์โปรไฟล์
  Future<void> _shareLink() async {
    final profileUrl = 'https://greenmarket.app/profile/${widget.userId}';

    await Share.share(
      'ดูโปรไฟล์ ${widget.displayName} บน Green Market\n$profileUrl',
      subject: 'โปรไฟล์ ${widget.displayName}',
    );
  }
}

/// QR Scanner Widget (สำหรับสแกน QR Code)
class QRScannerWidget extends StatelessWidget {
  const QRScannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สแกน QR Code'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_scanner,
              size: 100,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            const Text(
              'QR Scanner',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'สแกน QR Code เพื่อดูโปรไฟล์ของเพื่อนคุณ',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement actual QR scanner
                // Can use mobile_scanner or qr_code_scanner package
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('QR Scanner จะพร้อมใช้งานเร็วๆ นี้'),
                  ),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('เปิดกล้องสแกน'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
