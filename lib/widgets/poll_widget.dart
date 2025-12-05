// lib/widgets/poll_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/poll_option.dart';
import '../providers/user_provider.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';

class PollWidget extends StatefulWidget {
  final String postId;
  final PollData pollData;
  final VoidCallback? onVote;

  const PollWidget({
    super.key,
    required this.postId,
    required this.pollData,
    this.onVote,
  });

  @override
  State<PollWidget> createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
  String? _selectedOptionId;
  bool _isVoting = false;

  @override
  void initState() {
    super.initState();
    final currentUserId = context.read<UserProvider>().currentUser?.id;
    if (currentUserId != null && widget.pollData.hasUserVoted(currentUserId)) {
      _selectedOptionId = widget.pollData.getUserVote(currentUserId)?.id;
    }
  }

  Future<void> _vote(String optionId) async {
    final currentUserId = context.read<UserProvider>().currentUser?.id;
    if (currentUserId == null || _isVoting) return;

    // Check if poll ended
    if (widget.pollData.isEnded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('การโหวตสิ้นสุดแล้ว')),
      );
      return;
    }

    // Check if already voted
    if (widget.pollData.hasUserVoted(currentUserId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('คุณโหวตแล้ว')),
      );
      return;
    }

    setState(() {
      _isVoting = true;
      _selectedOptionId = optionId;
    });

    try {
      // Update vote in Firestore
      await FirebaseFirestore.instance
          .collection('community_posts')
          .doc(widget.postId)
          .update({
        'pollData.options.$optionId.votes': FieldValue.increment(1),
        'pollData.options.$optionId.votedBy':
            FieldValue.arrayUnion([currentUserId]),
        'pollData.totalVotes': FieldValue.increment(1),
      });

      widget.onVote?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('โหวตสำเร็จ! 🎉')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
      setState(() {
        _selectedOptionId = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isVoting = false;
        });
      }
    }
  }

  String _formatTimeRemaining() {
    final now = DateTime.now();
    final difference = widget.pollData.endTime.difference(now);

    if (difference.isNegative) {
      return 'สิ้นสุดแล้ว';
    }

    if (difference.inDays > 0) {
      return 'เหลือ ${difference.inDays} วัน';
    } else if (difference.inHours > 0) {
      return 'เหลือ ${difference.inHours} ชั่วโมง';
    } else if (difference.inMinutes > 0) {
      return 'เหลือ ${difference.inMinutes} นาที';
    } else {
      return 'เหลือไม่ถึง 1 นาที';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<UserProvider>().currentUser?.id;
    final hasVoted =
        currentUserId != null && widget.pollData.hasUserVoted(currentUserId);
    final isEnded = widget.pollData.isEnded;
    final showResults = hasVoted || isEnded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryTeal.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poll Header
          Row(
            children: [
              Icon(
                Icons.poll,
                color: AppColors.primaryTeal,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'โพล (Poll)',
                style: AppTextStyles.bodyBold.copyWith(
                  color: AppColors.primaryTeal,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isEnded
                      ? AppColors.graySecondary.withOpacity(0.2)
                      : AppColors.primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatTimeRemaining(),
                  style: AppTextStyles.caption.copyWith(
                    color: isEnded
                        ? AppColors.graySecondary
                        : AppColors.primaryTeal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Poll Options
          ...widget.pollData.options.map((option) {
            final percentage = option.getPercentage(widget.pollData.totalVotes);
            final isSelected = _selectedOptionId == option.id;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: showResults || _isVoting ? null : () => _vote(option.id),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryTeal
                          : AppColors.grayBorder,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Progress Bar (show after voting)
                      if (showResults)
                        Positioned.fill(
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: percentage / 100,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryTeal.withOpacity(0.2)
                                    : AppColors.grayBorder.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                          ),
                        ),

                      // Option Content
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            // Radio/Check Icon
                            if (!showResults)
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: isSelected
                                    ? AppColors.primaryTeal
                                    : AppColors.graySecondary,
                                size: 20,
                              )
                            else
                              Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: isSelected
                                    ? AppColors.primaryTeal
                                    : AppColors.graySecondary,
                                size: 20,
                              ),

                            const SizedBox(width: 12),

                            // Option Text
                            Expanded(
                              child: Text(
                                option.text,
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),

                            // Percentage (show after voting)
                            if (showResults)
                              Text(
                                '${percentage.toStringAsFixed(0)}%',
                                style: AppTextStyles.bodyBold.copyWith(
                                  color: isSelected
                                      ? AppColors.primaryTeal
                                      : AppColors.grayPrimary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Total Votes
          Row(
            children: [
              Icon(
                Icons.how_to_vote,
                size: 16,
                color: AppColors.graySecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.pollData.totalVotes} คน',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.graySecondary,
                ),
              ),
              if (hasVoted) ...[
                const SizedBox(width: 8),
                const Text('•'),
                const SizedBox(width: 8),
                Text(
                  'คุณโหวตแล้ว',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryTeal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
