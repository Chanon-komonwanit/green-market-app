// lib/widgets/achievement_badge_widget.dart
import 'package:flutter/material.dart';
import '../services/achievement_service.dart';

/// Achievement Badge Display Widget
/// แสดง Badge ในรูปแบบสวยงาม
class AchievementBadgeWidget extends StatelessWidget {
  final Achievement achievement;
  final bool isEarned;
  final VoidCallback? onTap;

  const AchievementBadgeWidget({
    super.key,
    required this.achievement,
    this.isEarned = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isEarned ? _getTierColor() : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEarned ? _getTierBorderColor() : Colors.grey[400]!,
            width: 2,
          ),
          boxShadow: isEarned
              ? [
                  BoxShadow(
                    color: _getTierColor().withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  achievement.icon,
                  style: TextStyle(
                    fontSize: 32,
                    color: isEarned ? null : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isEarned ? Colors.white : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            // Tier
            Text(
              achievement.tier.displayName,
              style: TextStyle(
                fontSize: 10,
                color: isEarned ? Colors.white70 : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTierColor() {
    switch (achievement.tier) {
      case BadgeTier.bronze:
        return const Color(0xFFCD7F32);
      case BadgeTier.silver:
        return const Color(0xFFC0C0C0);
      case BadgeTier.gold:
        return const Color(0xFFFFD700);
      case BadgeTier.platinum:
        return const Color(0xFFE5E4E2);
    }
  }

  Color _getTierBorderColor() {
    switch (achievement.tier) {
      case BadgeTier.bronze:
        return const Color(0xFF8B4513);
      case BadgeTier.silver:
        return const Color(0xFF808080);
      case BadgeTier.gold:
        return const Color(0xFFB8860B);
      case BadgeTier.platinum:
        return const Color(0xFFBDBDBD);
    }
  }
}

/// Badge Grid View
/// แสดง Grid ของ Badges
class BadgeGridView extends StatelessWidget {
  final List<Achievement> allAchievements;
  final List<Achievement> earnedAchievements;

  const BadgeGridView({
    super.key,
    required this.allAchievements,
    required this.earnedAchievements,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: allAchievements.length,
      itemBuilder: (context, index) {
        final achievement = allAchievements[index];
        final isEarned = earnedAchievements.any((a) => a.id == achievement.id);

        return AchievementBadgeWidget(
          achievement: achievement,
          isEarned: isEarned,
          onTap: () => _showAchievementDetail(context, achievement, isEarned),
        );
      },
    );
  }

  void _showAchievementDetail(
    BuildContext context,
    Achievement achievement,
    bool isEarned,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: isEarned
                      ? _getTierColor(achievement.tier)
                      : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    achievement.icon,
                    style: const TextStyle(fontSize: 60),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                achievement.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Tier
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getTierColor(achievement.tier),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  achievement.tier.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Description
              Text(
                achievement.description,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Status
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isEarned ? Colors.green[50] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isEarned ? Colors.green : Colors.grey[400]!,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isEarned ? Icons.check_circle : Icons.lock,
                      color: isEarned ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEarned ? 'ปลดล็อกแล้ว' : 'ยังไม่ปลดล็อก',
                      style: TextStyle(
                        color: isEarned ? Colors.green : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Close button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ปิด'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTierColor(BadgeTier tier) {
    switch (tier) {
      case BadgeTier.bronze:
        return const Color(0xFFCD7F32);
      case BadgeTier.silver:
        return const Color(0xFFC0C0C0);
      case BadgeTier.gold:
        return const Color(0xFFFFD700);
      case BadgeTier.platinum:
        return const Color(0xFFE5E4E2);
    }
  }
}

/// Achievement Notification
/// แจ้งเตือนเมื่อได้รับ Badge ใหม่
class AchievementNotification extends StatelessWidget {
  final Achievement achievement;

  const AchievementNotification({
    super.key,
    required this.achievement,
  });

  static void show(BuildContext context, Achievement achievement) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AchievementNotification(achievement: achievement),
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getTierColor(),
            _getTierColor().withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getTierColor().withOpacity(0.5),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                achievement.icon,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🎉 ปลดล็อก Achievement!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  achievement.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTierColor() {
    switch (achievement.tier) {
      case BadgeTier.bronze:
        return const Color(0xFFCD7F32);
      case BadgeTier.silver:
        return const Color(0xFFC0C0C0);
      case BadgeTier.gold:
        return const Color(0xFFFFD700);
      case BadgeTier.platinum:
        return const Color(0xFFE5E4E2);
    }
  }
}
