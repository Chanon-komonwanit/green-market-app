// lib/widgets/share_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/community_post.dart';
import '../services/firebase_service.dart';
import '../providers/user_provider.dart';
import '../utils/constants.dart';
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
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isSharing)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: CircularProgressIndicator(),
              ),
            if (!_isSharing) ...[
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.ios_share_rounded,
                      color: AppColors.primaryTeal,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'แชร์โพสต์',
                      style: AppTextStyles.headline.copyWith(fontSize: 22),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close,
                        color: AppColors.graySecondary, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Divider(height: 1, color: AppColors.grayBorder),
              const SizedBox(height: 18),
              _buildShareOption(
                icon: Icons.forum_outlined,
                title: 'แชร์ในชุมชนสีเขียว',
                subtitle: 'แชร์โพสต์นี้ในฟีดของคุณ',
                onTap: _isSharing ? null : () => _shareInCommunity(),
              ),
              const SizedBox(height: 8),
              _buildShareOption(
                icon: Icons.link_rounded,
                title: 'คัดลอกลิงก์',
                subtitle: 'คัดลอกลิงก์เพื่อแชร์ภายนอก',
                onTap: _isSharing ? null : () => _copyLink(),
              ),
              const SizedBox(height: 8),
              _buildShareOption(
                icon: Icons.send_outlined,
                title: 'ส่งข้อความ',
                subtitle: 'ส่งให้เพื่อนใน Green Market',
                onTap: _isSharing ? null : () => _sendMessage(),
              ),
              const SizedBox(height: 8),
              _buildShareOption(
                icon: Icons.more_horiz_rounded,
                title: 'แชร์ภายนอก',
                subtitle: 'แชร์ไปยังแอปอื่น',
                onTap: _isSharing ? null : () => _shareExternal(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppTheme.smallPadding),
        decoration: BoxDecoration(
          color: AppColors.primaryTeal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        child: Icon(
          icon,
          color: AppColors.primaryTeal,
          size: 24,
        ),
      ),
      title: Text(title, style: AppTextStyles.bodyBold),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.caption,
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.graySecondary,
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
    );
  }

  Future<void> _shareInCommunity() async {
    final user = context.read<UserProvider>().currentUser;
    if (user == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('กรุณาเข้าสู่ระบบก่อน'),
            backgroundColor: AppColors.warningAmber),
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
        // No need to set loading state here as it's handled in the dialog
        // _isSharing = true;
      });

      try {
        await _firebaseService.shareCommunityPost(
          originalPostId: widget.post.id,
          userId: user.id,
          additionalContent: result.isNotEmpty ? result : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('แชร์โพสต์เรียบร้อยแล้ว'),
              backgroundColor: AppColors.successGreen,
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
      const SnackBar(
        content: Text('คัดลอกลิงก์เรียบร้อยแล้ว'),
        backgroundColor: AppColors.infoBlue,
      ),
    );
  }

  void _sendMessage() {
    setState(() {
      _isSharing = true;
    });
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isSharing = false;
      });
      Navigator.pop(context);
      Navigator.pushNamed(context, '/message', arguments: widget.post);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('นำทางไปหน้าข้อความเรียบร้อย'),
          backgroundColor: AppColors.infoBlue,
        ),
      );
    });
  }

  void _shareExternal() {
    // ใช้ share_plus package สำหรับการแชร์จริงไปยังแอปอื่นๆ
    final shareText = '''
🌱 แชร์จาก Green Market

${widget.post.content}

โดย: ${widget.post.userDisplayName}
วันที่: ${widget.post.createdAt.toDate().toString().split(' ')[0]}

🔗 ดูเพิ่มเติมที่: https://greenmarket.app/post/${widget.post.id}

#GreenMarket #สีเขียว #ความยั่งยืน
''';

    setState(() {
      _isSharing = true;
    });

    Share.share(
      shareText,
      subject: 'แชร์โพสต์จาก Green Market',
    ).then((_) {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('แชร์โพสต์เรียบร้อยแล้ว'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการแชร์: $error'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    });
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
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'แชร์พร้อมความคิดเห็น',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: AppTheme.padding),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'เขียนความคิดเห็นเกี่ยวกับโพสต์นี้...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  borderSide: const BorderSide(color: AppColors.grayBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  borderSide:
                      const BorderSide(color: AppColors.primaryTeal, width: 2),
                ),
                contentPadding: const EdgeInsets.all(AppTheme.padding),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
            const SizedBox(height: AppTheme.padding),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceGray,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                border: Border.all(color: AppColors.grayBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.post.userDisplayName,
                            style: AppTextStyles.captionBold),
                        const SizedBox(height: 2),
                        Text(
                          widget.post.content,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.graySecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.largePadding),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.padding - 4),
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
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.padding - 4),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadius),
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
