// lib/widgets/empty_state.dart
import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Empty State widget แบบ modern apps
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color:
                          (iconColor ?? AppColors.primaryTeal).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 60,
                      color: iconColor ?? AppColors.primaryTeal,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTextStyles.headline.copyWith(fontSize: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.body.copyWith(
                color: AppColors.graySecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_circle_outline),
                label: Text(actionText!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor ?? AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty Post State
class EmptyPostState extends StatelessWidget {
  final VoidCallback? onCreatePost;

  const EmptyPostState({super.key, this.onCreatePost});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.article_outlined,
      title: 'ยังไม่มีโพสต์',
      message: 'เริ่มแบ่งปันเรื่องราวสีเขียวของคุณกับชุมชน',
      actionText: 'สร้างโพสต์แรก',
      onAction: onCreatePost,
      iconColor: AppColors.primaryTeal,
    );
  }
}

/// Empty Activity State
class EmptyActivityState extends StatelessWidget {
  final VoidCallback? onExplore;

  const EmptyActivityState({super.key, this.onExplore});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.eco,
      title: 'ยังไม่มีกิจกรรม',
      message: 'ค้นหากิจกรรมสีเขียวที่น่าสนใจและเข้าร่วมเลย',
      actionText: 'สำรวจกิจกรรม',
      onAction: onExplore,
      iconColor: AppColors.accentGreen,
    );
  }
}

/// Empty Product State
class EmptyProductState extends StatelessWidget {
  final VoidCallback? onBrowse;

  const EmptyProductState({super.key, this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.shopping_bag_outlined,
      title: 'ยังไม่มีสินค้า',
      message: 'เริ่มช้อปสินค้าเพื่อสิ่งแวดล้อมที่เป็นมิตรกับโลก',
      actionText: 'เลือกซื้อสินค้า',
      onAction: onBrowse,
      iconColor: AppColors.primaryTeal,
    );
  }
}
