// lib/screens/live/create_live_stream_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/live_stream_service.dart';
import '../../providers/user_provider.dart';
import '../../utils/constants.dart';
import '../../utils/hashtag_detector.dart';
import '../../widgets/hashtag_suggestions_widget.dart';
import '../../models/live_stream.dart';
import 'live_stream_host_screen.dart';

/// หน้าสร้าง Live Stream (เหมือน Facebook Live setup)
class CreateLiveStreamScreen extends StatefulWidget {
  const CreateLiveStreamScreen({super.key});

  @override
  State<CreateLiveStreamScreen> createState() => _CreateLiveStreamScreenState();
}

class _CreateLiveStreamScreenState extends State<CreateLiveStreamScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final LiveStreamService _liveService = LiveStreamService();

  bool _isLoading = false;
  bool _allowComments = true;
  bool _isPublic = true;
  int _retentionDays = 7;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live Preview Banner
                  _buildLivePreview(),
                  const SizedBox(height: 24),

                  // Title Input
                  _buildTitleInput(),
                  const SizedBox(height: 16),

                  // Description Input
                  _buildDescriptionInput(),
                  const SizedBox(height: 24),

                  // Hashtag Suggestions
                  HashtagSuggestionsWidget(
                    contentController: _titleController,
                    onHashtagTapped: (tag) {
                      setState(() {
                        _titleController.text =
                            '${_titleController.text} #$tag';
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Settings
                  _buildSettings(),
                  const SizedBox(height: 24),

                  // Retention Policy Info
                  _buildRetentionInfo(),
                  const SizedBox(height: 24),

                  // Start Live Button
                  _buildStartButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.grayBorder),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
          const SizedBox(width: 8),
          const Text(
            'เริ่มไลฟ์สด',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreview() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryTeal,
            AppColors.primaryTeal.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Pattern overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/logo.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Colors.white, size: 10),
                      SizedBox(width: 6),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'พร้อมไลฟ์แล้ว!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'คลิก "เริ่มไลฟ์" เพื่อเริ่มการถ่ายทอดสด',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.title, size: 20, color: AppColors.primaryTeal),
            SizedBox(width: 8),
            Text(
              'หัวข้อไลฟ์',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          maxLength: 100,
          decoration: InputDecoration(
            hintText: 'เช่น "ปลูกผักอินทรีย์สดๆ จากสวน 🌱"',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primaryTeal, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.description, size: 20, color: AppColors.primaryTeal),
            SizedBox(width: 8),
            Text(
              'รายละเอียด',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'บอกเล่าเพิ่มเติมเกี่ยวกับไลฟ์สดของคุณ...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primaryTeal, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'การตั้งค่า',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Allow Comments
          SwitchListTile(
            value: _allowComments,
            onChanged: (value) => setState(() => _allowComments = value),
            title: const Text('อนุญาตความคิดเห็น'),
            subtitle: const Text('ให้ผู้ชมแสดงความคิดเห็นได้'),
            activeColor: AppColors.primaryTeal,
            contentPadding: EdgeInsets.zero,
          ),

          const Divider(height: 1),

          // Public/Private
          SwitchListTile(
            value: _isPublic,
            onChanged: (value) => setState(() => _isPublic = value),
            title: const Text('สาธารณะ'),
            subtitle: Text(_isPublic ? 'ทุกคนดูได้' : 'เฉพาะคนที่คุณระบุ'),
            activeColor: AppColors.primaryTeal,
            contentPadding: EdgeInsets.zero,
          ),

          const Divider(height: 1),

          // Retention Days
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('เก็บบันทึกไว้'),
            subtitle: Text('$_retentionDays วัน หลังจบไลฟ์'),
            trailing: DropdownButton<int>(
              value: _retentionDays,
              items: [3, 7, 14, 30].map((days) {
                return DropdownMenuItem(
                  value: days,
                  child: Text('$days วัน'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _retentionDays = value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetentionInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.infoBlue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.infoBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'นโยบายการจัดเก็บ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ไลฟ์จะถูกบันทึกเป็น SD (480p) และลบอัตโนมัติหลังจาก $_retentionDays วัน\nคุณสามารถ Archive เพื่อเก็บถาวรได้',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _startLiveStream,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 4,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'เริ่มไลฟ์',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _startLiveStream() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาใส่หัวข้อไลฟ์'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userProvider = context.read<UserProvider>();
      final currentUser = userProvider.currentUser;

      if (currentUser == null) {
        throw Exception('กรุณาเข้าสู่ระบบก่อน');
      }

      // Extract hashtags
      final title = _titleController.text.trim();
      final tags = HashtagDetector.extractHashtags(title);

      // Create live stream
      final streamId = await _liveService.createLiveStream(
        streamerId: currentUser.id,
        streamerName: currentUser.displayName ?? 'ผู้ใช้',
        streamerPhoto: currentUser.photoUrl,
        title: title,
        description: _descriptionController.text.trim(),
        tags: tags,
        allowComments: _allowComments,
        isPublic: _isPublic,
        retentionDays: _retentionDays,
      );

      // Start live stream
      await _liveService.startLiveStream(streamId);

      if (mounted) {
        // Get updated live stream data
        final liveDoc = await FirebaseFirestore.instance
            .collection('live_streams')
            .doc(streamId)
            .get();
        final liveStream = LiveStream.fromFirestore(liveDoc);

        // Close create dialog
        Navigator.pop(context);

        // Navigate to host screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LiveStreamHostScreen(
              streamId: streamId,
              liveStream: liveStream,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
