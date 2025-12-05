// lib/widgets/message_read_receipt.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Message Read Receipt Widget
/// แสดงสถานะการอ่านข้อความ (✓ = ส่งแล้ว, ✓✓ = อ่านแล้ว)
class MessageReadReceipt extends StatelessWidget {
  final String messageId;
  final String senderId;
  final Timestamp? sentAt;
  final bool isRead;
  final Timestamp? readAt;
  final bool isSending;
  final bool hasFailed;

  const MessageReadReceipt({
    super.key,
    required this.messageId,
    required this.senderId,
    this.sentAt,
    this.isRead = false,
    this.readAt,
    this.isSending = false,
    this.hasFailed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // เวลา
        if (sentAt != null && !isSending)
          Text(
            DateFormat('HH:mm').format(sentAt!.toDate()),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        const SizedBox(width: 4),
        // สถานะ
        _buildStatusIcon(),
      ],
    );
  }

  Widget _buildStatusIcon() {
    if (hasFailed) {
      return Icon(
        Icons.error_outline,
        size: 16,
        color: Colors.red[400],
      );
    }

    if (isSending) {
      return SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
        ),
      );
    }

    if (isRead) {
      // อ่านแล้ว - Double check (✓✓) สีน้ำเงิน
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.done_all,
            size: 16,
            color: Colors.blue[600],
          ),
          if (readAt != null)
            Tooltip(
              message:
                  'อ่านเมื่อ ${DateFormat('d MMM, HH:mm').format(readAt!.toDate())}',
              child: const SizedBox.shrink(),
            ),
        ],
      );
    }

    // ส่งแล้วแต่ยังไม่อ่าน - Single check (✓) สีเทา
    return Icon(
      Icons.done,
      size: 16,
      color: Colors.grey[500],
    );
  }
}

/// Online Status Indicator
/// แสดงสถานะออนไลน์ของผู้ใช้ (จุดสีเขียว)
class OnlineStatusIndicator extends StatelessWidget {
  final String userId;
  final double size;

  const OnlineStatusIndicator({
    super.key,
    required this.userId,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final isOnline = data?['isOnline'] ?? false;
        final lastSeen = data?['lastSeen'] as Timestamp?;

        if (!isOnline) {
          return const SizedBox.shrink();
        }

        return Stack(
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            if (lastSeen != null)
              Tooltip(
                message: 'ออนไลน์ล่าสุด ${_formatLastSeen(lastSeen)}',
                child: const SizedBox.shrink(),
              ),
          ],
        );
      },
    );
  }

  String _formatLastSeen(Timestamp lastSeen) {
    final now = DateTime.now();
    final lastSeenDate = lastSeen.toDate();
    final difference = now.difference(lastSeenDate);

    if (difference.inMinutes < 1) {
      return 'เมื่อสักครู่';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else {
      return DateFormat('d MMM').format(lastSeenDate);
    }
  }
}

/// Typing Indicator
/// แสดงสถานะกำลังพิมพ์
class TypingIndicator extends StatefulWidget {
  final String chatId;
  final String currentUserId;

  const TypingIndicator({
    super.key,
    required this.chatId,
    required this.currentUserId,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final typingUsers = data?['typingUsers'] as Map<String, dynamic>?;

        if (typingUsers == null || typingUsers.isEmpty) {
          return const SizedBox.shrink();
        }

        // ตรวจสอบว่ามีคนอื่นกำลังพิมพ์อยู่หรือไม่ (ไม่ใช่ตัวเอง)
        final isOtherTyping =
            typingUsers.keys.any((userId) => userId != widget.currentUserId);

        if (!isOtherTyping) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDot(0),
                    const SizedBox(width: 4),
                    _buildDot(1),
                    const SizedBox(width: 4),
                    _buildDot(2),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final delay = index * 0.2;
        final value = _controller.value - delay;
        final normalizedValue = value < 0 ? 0 : (value > 1 ? 1 : value);
        final scale = 1.0 + (0.5 * (1 - (normalizedValue - 0.5).abs() * 2));

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

/// Helper functions สำหรับจัดการ read receipts

/// อัปเดตสถานะการอ่านข้อความ
Future<void> markMessageAsRead(String chatId, String messageId) async {
  try {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    debugPrint('Error marking message as read: $e');
  }
}

/// อัปเดตสถานะออนไลน์ของผู้ใช้
Future<void> updateUserOnlineStatus(String userId, bool isOnline) async {
  try {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    debugPrint('Error updating online status: $e');
  }
}

/// อัปเดตสถานะกำลังพิมพ์
Future<void> updateTypingStatus({
  required String chatId,
  required String userId,
  required bool isTyping,
}) async {
  try {
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

    if (isTyping) {
      await chatRef.update({
        'typingUsers.$userId': FieldValue.serverTimestamp(),
      });
    } else {
      await chatRef.update({
        'typingUsers.$userId': FieldValue.delete(),
      });
    }
  } catch (e) {
    debugPrint('Error updating typing status: $e');
  }
}
