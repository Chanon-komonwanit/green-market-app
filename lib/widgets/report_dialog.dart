// lib/widgets/report_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/report.dart';
import '../models/community_post.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';
import '../theme/app_colors.dart';

class ReportDialog extends StatefulWidget {
  final CommunityPost post;
  final String? commentId;

  const ReportDialog({
    super.key,
    required this.post,
    this.commentId,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  ReportReason? _selectedReason;
  final _additionalInfoController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _additionalInfoController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกเหตุผลในการรายงาน'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserFirebase = authProvider.user;

      if (currentUserFirebase == null) {
        throw Exception('กรุณาเข้าสู่ระบบก่อนรายงาน');
      }

      // Get user data from Firestore
      final firebaseService = FirebaseService();
      final currentUser =
          await firebaseService.getUserById(currentUserFirebase.uid);

      if (currentUser == null) {
        throw Exception('ไม่พบข้อมูลผู้ใช้');
      }

      await firebaseService.submitReport(
        reporterId: currentUser.id,
        reporterName: currentUser.displayName ?? 'ผู้ใช้',
        reportedUserId: widget.post.userId,
        reportedUserName: widget.post.userDisplayName,
        postId: widget.post.id,
        commentId: widget.commentId,
        reason: _selectedReason!,
        additionalInfo: _additionalInfoController.text.trim().isEmpty
            ? null
            : _additionalInfoController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('รายงานของคุณถูกส่งเรียบร้อยแล้ว'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.report_outlined,
                  color: Colors.red,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'รายงานเนื้อหาที่ไม่เหมาะสม',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'เลือกเหตุผลในการรายงาน:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            // Report reasons list
            ...ReportReason.values.map((reason) {
              return RadioListTile<ReportReason>(
                value: reason,
                groupValue: _selectedReason,
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        setState(() => _selectedReason = value);
                      },
                title: Text(reason.label),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                dense: true,
              );
            }),
            const SizedBox(height: 16),
            // Additional info
            TextField(
              controller: _additionalInfoController,
              maxLines: 3,
              maxLength: 500,
              enabled: !_isSubmitting,
              decoration: InputDecoration(
                labelText: 'รายละเอียดเพิ่มเติม (ไม่บังคับ)',
                hintText: 'อธิบายเพิ่มเติมเกี่ยวกับปัญหาที่พบ...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: const Text('ยกเลิก'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('ส่งรายงาน'),
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
