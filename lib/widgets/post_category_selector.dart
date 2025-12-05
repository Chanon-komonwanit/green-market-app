// lib/widgets/post_category_selector.dart
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/hashtag_detector.dart';

class PostCategorySelector extends StatelessWidget {
  final PostCategory? selectedCategory;
  final Function(PostCategory?) onCategorySelected;

  const PostCategorySelector({
    super.key,
    this.selectedCategory,
    required this.onCategorySelected,
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
              Icon(Icons.category_outlined,
                  color: AppColors.primaryTeal, size: 20),
              const SizedBox(width: 8),
              Text(
                'หมวดหมู่',
                style: AppTextStyles.bodyBold
                    .copyWith(color: AppColors.grayPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // "ไม่เลือก" chip
              _buildCategoryChip(
                context: context,
                category: null,
                label: 'ไม่เลือก',
                icon: '✨',
                isSelected: selectedCategory == null,
              ),
              // Category chips
              ...HashtagDetector.getStandardCategories().map(
                (category) => _buildCategoryChip(
                  context: context,
                  category: category,
                  label: category.name,
                  icon: category.icon,
                  isSelected: selectedCategory?.id == category.id,
                ),
              ),
            ],
          ),
          if (selectedCategory != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    selectedCategory!.icon,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedCategory!.name,
                          style: AppTextStyles.bodyBold.copyWith(
                            color: AppColors.primaryTeal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'แท็กที่แนะนำ: ${selectedCategory!.tags.map((t) => '#$t').join(' ')}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.graySecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required BuildContext context,
    required PostCategory? category,
    required String label,
    required String icon,
    required bool isSelected,
  }) {
    return Material(
      color: isSelected ? AppColors.primaryTeal : AppColors.surfaceGray,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => onCategorySelected(category),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isSelected ? AppColors.white : AppColors.grayPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
