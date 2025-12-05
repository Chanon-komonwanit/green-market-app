// lib/widgets/hashtag_suggestions_widget.dart
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/hashtag_detector.dart';

class HashtagSuggestionsWidget extends StatelessWidget {
  final TextEditingController contentController;
  final Function(String) onHashtagTapped;

  const HashtagSuggestionsWidget({
    super.key,
    required this.contentController,
    required this.onHashtagTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'แท็กยอดนิยม',
                style: AppTextStyles.bodyBold.copyWith(
                  color: AppColors.grayPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'แตะเพื่อเพิ่ม',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.graySecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: HashtagDetector.getSuggestedHashtags().map((tag) {
              final isUsed = contentController.text.contains('#$tag');
              return _buildHashtagChip(
                tag: tag,
                isUsed: isUsed,
                onTap: () => onHashtagTapped(tag),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHashtagChip({
    required String tag,
    required bool isUsed,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isUsed
          ? AppColors.primaryTeal.withOpacity(0.2)
          : AppColors.surfaceGray,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isUsed ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '#$tag',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isUsed ? AppColors.primaryTeal : AppColors.grayPrimary,
                  fontWeight: isUsed ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (isUsed) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.check_circle,
                  size: 14,
                  color: AppColors.primaryTeal,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
