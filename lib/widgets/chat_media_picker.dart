// lib/widgets/chat_media_picker.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../services/image_compression_service.dart';

/// ประเภทของสื่อ
enum MediaType {
  image,
  video,
}

/// Chat Media Picker Widget
/// รองรับการเลือกรูปภาพและวิดีโอพร้อมแสดง preview ก่อนส่ง
class ChatMediaPicker extends StatefulWidget {
  final Function(File file, MediaType type) onMediaSelected;

  const ChatMediaPicker({
    super.key,
    required this.onMediaSelected,
  });

  /// แสดง bottom sheet สำหรับเลือกสื่อ
  static Future<void> show({
    required BuildContext context,
    required Function(MediaType mediaType, String filePath) onMediaSelected,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChatMediaPicker(
        onMediaSelected: (file, type) {
          onMediaSelected(type, file.path);
        },
      ),
    );
  }

  @override
  State<ChatMediaPicker> createState() => _ChatMediaPickerState();
}

class _ChatMediaPickerState extends State<ChatMediaPicker> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedFile;
  MediaType? _mediaType;
  VideoPlayerController? _videoController;
  bool _isCompressing = false;

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  /// เลือกรูปภาพจากแกลเลอรี่
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        setState(() {
          _isCompressing = true;
        });

        // บีบอัดรูปภาพ
        final compressed = await ImageCompressionService()
            .compressImageForChat(File(image.path));

        setState(() {
          _selectedFile = compressed;
          _mediaType = MediaType.image;
          _isCompressing = false;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาดในการเลือกรูปภาพ')),
        );
      }
      setState(() {
        _isCompressing = false;
      });
    }
  }

  /// เลือกรูปภาพจากกล้อง
  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (photo != null) {
        setState(() {
          _isCompressing = true;
        });

        // บีบอัดรูปภาพ
        final compressed = await ImageCompressionService()
            .compressImageForChat(File(photo.path));

        setState(() {
          _selectedFile = compressed;
          _mediaType = MediaType.image;
          _isCompressing = false;
        });
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาดในการถ่ายรูป')),
        );
      }
      setState(() {
        _isCompressing = false;
      });
    }
  }

  /// เลือกวิดีโอจากแกลเลอรี่
  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );

      if (video != null) {
        final file = File(video.path);

        // ตรวจสอบขนาดไฟล์ (จำกัดไว้ที่ 50MB)
        final fileSize = await file.length();
        if (fileSize > 50 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ไฟล์วิดีโอใหญ่เกินไป (สูงสุด 50MB)'),
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedFile = file;
          _mediaType = MediaType.video;
        });

        // เตรียม video player
        _initVideoController(file);
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาดในการเลือกวิดีโอ')),
        );
      }
    }
  }

  /// เตรียม VideoPlayerController
  void _initVideoController(File videoFile) {
    _videoController?.dispose();
    _videoController = VideoPlayerController.file(videoFile)
      ..initialize().then((_) {
        setState(() {});
        _videoController?.play();
        _videoController?.setLooping(true);
      });
  }

  /// ส่งไฟล์
  void _sendMedia() {
    if (_selectedFile != null && _mediaType != null) {
      widget.onMediaSelected(_selectedFile!, _mediaType!);
      Navigator.of(context).pop();
    }
  }

  /// ยกเลิกและเลือกใหม่
  void _reset() {
    setState(() {
      _selectedFile = null;
      _mediaType = null;
      _videoController?.dispose();
      _videoController = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child:
          _selectedFile == null ? _buildMediaOptions() : _buildMediaPreview(),
    );
  }

  /// แสดงตัวเลือกสื่อ
  Widget _buildMediaOptions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Text(
          'เลือกสื่อที่ต้องการส่ง',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildOptionButton(
              icon: Icons.photo_library,
              label: 'แกลเลอรี่',
              color: Colors.blue,
              onTap: _pickImage,
            ),
            _buildOptionButton(
              icon: Icons.camera_alt,
              label: 'ถ่ายรูป',
              color: Colors.green,
              onTap: _takePhoto,
            ),
            _buildOptionButton(
              icon: Icons.videocam,
              label: 'วิดีโอ',
              color: Colors.purple,
              onTap: _pickVideo,
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_isCompressing)
          const Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text('กำลังบีบอัดรูปภาพ...'),
            ],
          ),
      ],
    );
  }

  /// ปุ่มตัวเลือก
  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// แสดง preview ของสื่อที่เลือก
  Widget _buildMediaPreview() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Text(
          'ตรวจสอบก่อนส่ง',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // Preview
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _mediaType == MediaType.image
                ? Image.file(
                    _selectedFile!,
                    fit: BoxFit.contain,
                  )
                : _videoController != null &&
                        _videoController!.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      )
                    : const Center(
                        child: CircularProgressIndicator(),
                      ),
          ),
        ),
        const SizedBox(height: 16),
        // ปุ่มควบคุม
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh),
                label: const Text('เลือกใหม่'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _sendMedia,
                icon: const Icon(Icons.send),
                label: const Text('ส่ง'),
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
    );
  }
}
