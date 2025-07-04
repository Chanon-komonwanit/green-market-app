// lib/widgets/share_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/community_post.dart';
import '../services/firebase_service.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';

class ShareDialog extends StatefulWidget {
  final CommunityPost post;

  const ShareDialog({
    super.key,
    required this.post,
  });

  @override
  State<ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<ShareDialog> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _commentController = TextEditingController();
  bool _isSharing = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.share,
                  color: Color(0xFF2E7D32),
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'แชร์โพสต์',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Share Options
            _buildShareOption(
              icon: Icons.repeat,
              title: 'แชร์ในชุมชนสีเขียว',
              subtitle: 'แชร์โพสต์นี้ในฟีดของคุณ',
              onTap: _shareInCommunity,
            ),

            const SizedBox(height: 12),

            _buildShareOption(
              icon: Icons.link,
              title: 'คัดลอกลิงก์',
              subtitle: 'คัดลอกลิงก์เพื่อแชร์ภายนอก',
              onTap: _copyLink,
            ),

            const SizedBox(height: 12),

            _buildShareOption(
              icon: Icons.message,
              title: 'ส่งข้อความ',
              subtitle: 'ส่งให้เพื่อนใน Green Market',
              onTap: _sendMessage,
            ),

            const SizedBox(height: 12),

            _buildShareOption(
              icon: Icons.more_horiz,
              title: 'แชร์ภายนอก',
              subtitle: 'แชร์ไปยังแอปอื่น',
              onTap: _shareExternal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF2E7D32),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareInCommunity() async {
    final user = context.read<UserProvider>().currentUser;
    if (user == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อน')),
      );
      return;
    }

    // Show share with comment dialog
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _ShareWithCommentDialog(post: widget.post),
    );

    if (result != null) {
      Navigator.pop(context);
      setState(() {
        _isSharing = true;
      });

      try {
        await _firebaseService.shareCommunityPost(
          originalPostId: widget.post.id,
          userId: user.id,
          additionalContent: result.isNotEmpty ? result : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('แชร์โพสต์เรียบร้อยแล้ว')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
          );
        }
      } finally {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  void _copyLink() {
    final postUrl = 'https://greenmarket.app/post/${widget.post.id}';
    Clipboard.setData(ClipboardData(text: postUrl));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('คัดลอกลิงก์เรียบร้อยแล้ว')),
    );
  }

  void _sendMessage() {
    Navigator.pop(context);
    // TODO: Navigate to message screen with post content
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ฟีเจอร์นี้จะพร้อมใช้งานเร็วๆ นี้')),
    );
  }

  void _shareExternal() {
    Navigator.pop(context);
    // TODO: Implement system share
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ฟีเจอร์นี้จะพร้อมใช้งานเร็วๆ นี้')),
    );
  }
}

class _ShareWithCommentDialog extends StatefulWidget {
  final CommunityPost post;

  const _ShareWithCommentDialog({required this.post});

  @override
  State<_ShareWithCommentDialog> createState() =>
      _ShareWithCommentDialogState();
}

class _ShareWithCommentDialogState extends State<_ShareWithCommentDialog> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            const Text(
              'แชร์พร้อมความคิดเห็น',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),

            const SizedBox(height: 20),

            // Comment input
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'เขียนความคิดเห็นเกี่ยวกับโพสต์นี้...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2E7D32)),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: 3,
              maxLength: 200,
            ),

            const SizedBox(height: 20),

            // Preview of original post
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.post.userDisplayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.post.content,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('ยกเลิก'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, _commentController.text);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('แชร์'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
