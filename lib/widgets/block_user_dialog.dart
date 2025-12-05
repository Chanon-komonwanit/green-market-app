// lib/widgets/block_user_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';
import '../theme/app_colors.dart';

class BlockUserDialog extends StatefulWidget {
  final String userId;
  final String userName;

  const BlockUserDialog({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<BlockUserDialog> createState() => _BlockUserDialogState();
}

class _BlockUserDialogState extends State<BlockUserDialog> {
  bool _isBlocking = false;

  Future<void> _blockUser() async {
    setState(() => _isBlocking = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserFirebase = authProvider.user;

      if (currentUserFirebase == null) {
        throw Exception('กรุณาเข้าสู่ระบบก่อนบล็อกผู้ใช้');
      }

      final firebaseService = FirebaseService();
      await firebaseService.blockUser(
        currentUserId: currentUserFirebase.uid,
        blockedUserId: widget.userId,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('บล็อก ${widget.userName} เรียบร้อยแล้ว'),
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
        setState(() => _isBlocking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Row(
        children: [
          Icon(Icons.block, color: Colors.red, size: 28),
          SizedBox(width: 12),
          Text('บล็อกผู้ใช้'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'คุณต้องการบล็อก ${widget.userName} ใช่หรือไม่?',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          Text(
            'เมื่อบล็อกแล้ว:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          _buildBulletPoint('คุณจะไม่เห็นโพสต์ของผู้ใช้นี้'),
          _buildBulletPoint('ผู้ใช้นี้จะไม่สามารถเห็นโพสต์ของคุณ'),
          _buildBulletPoint('ไม่สามารถส่งข้อความถึงกัน'),
          _buildBulletPoint('สามารถปลดบล็อกได้ทุกเมื่อในการตั้งค่า'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isBlocking ? null : () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: _isBlocking ? null : _blockUser,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isBlocking
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('บล็อก'),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
