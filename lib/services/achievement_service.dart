// lib/services/achievement_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Achievement & Badge System
/// ระบบตราสัญลักษณ์และความสำเร็จ
class AchievementService {
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();

  final _firestore = FirebaseFirestore.instance;

  /// ตรวจสอบและมอบ Achievement Badge
  Future<List<Achievement>> checkAndAwardAchievements(String userId) async {
    final awarded = <Achievement>[];

    try {
      // ดึงข้อมูลผู้ใช้
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return awarded;

      final userData = userDoc.data()!;
      final currentBadges = List<String>.from(userData['badges'] ?? []);

      // ดึงสถิติต่างๆ
      final ecoCoins = userData['ecoCoins'] ?? 0;
      final level = userData['level'] ?? 1;

      // นับจำนวนกิจกรรม
      final activitiesCount = await _countUserActivities(userId);

      // นับจำนวนโพสต์
      final postsCount = await _countUserPosts(userId);

      // ตรวจสอบแต่ละ Achievement
      for (final achievement in _allAchievements) {
        // ถ้ายังไม่ได้รับ
        if (!currentBadges.contains(achievement.id)) {
          bool earned = false;

          switch (achievement.type) {
            case AchievementType.ecoCoins:
              earned = ecoCoins >= achievement.requirement;
              break;
            case AchievementType.activities:
              earned = activitiesCount >= achievement.requirement;
              break;
            case AchievementType.posts:
              earned = postsCount >= achievement.requirement;
              break;
            case AchievementType.level:
              earned = level >= achievement.requirement;
              break;
            case AchievementType.special:
              // Special achievements (เช่น first purchase, verified email)
              earned = await _checkSpecialAchievement(userId, achievement.id);
              break;
          }

          if (earned) {
            await _awardBadge(userId, achievement);
            awarded.add(achievement);
          }
        }
      }

      return awarded;
    } catch (e) {
      debugPrint('Error checking achievements: $e');
      return awarded;
    }
  }

  /// มอบ Badge ให้ผู้ใช้
  Future<void> _awardBadge(String userId, Achievement achievement) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'badges': FieldValue.arrayUnion([achievement.id]),
        'lastBadgeEarned': achievement.id,
        'lastBadgeEarnedAt': FieldValue.serverTimestamp(),
      });

      // บันทึกประวัติ
      await _firestore.collection('achievement_history').add({
        'userId': userId,
        'achievementId': achievement.id,
        'earnedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Badge awarded: ${achievement.title} to user $userId');
    } catch (e) {
      debugPrint('Error awarding badge: $e');
    }
  }

  /// ดึง Badges ของผู้ใช้
  Future<List<Achievement>> getUserBadges(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return [];

      final badgeIds = List<String>.from(userDoc.data()?['badges'] ?? []);
      return _allAchievements.where((a) => badgeIds.contains(a.id)).toList();
    } catch (e) {
      debugPrint('Error getting user badges: $e');
      return [];
    }
  }

  /// นับกิจกรรมของผู้ใช้
  Future<int> _countUserActivities(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('activities')
          .where('organizerId', isEqualTo: userId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// นับโพสต์ของผู้ใช้
  Future<int> _countUserPosts(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('community_posts')
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// ตรวจสอบ Special Achievement
  Future<bool> _checkSpecialAchievement(
      String userId, String achievementId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;

      switch (achievementId) {
        case 'first_purchase':
          final orders = await _firestore
              .collection('orders')
              .where('buyerId', isEqualTo: userId)
              .limit(1)
              .get();
          return orders.docs.isNotEmpty;

        case 'email_verified':
          return userData['emailVerified'] == true;

        case 'profile_complete':
          return userData['displayName'] != null &&
              userData['photoUrl'] != null;

        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// รายการ Achievement ทั้งหมด
  static final List<Achievement> _allAchievements = [
    // Eco Coins Achievements
    Achievement(
      id: 'eco_beginner',
      title: 'Eco Beginner',
      description: 'รับ 100 Eco Coins แรก',
      icon: '🌱',
      type: AchievementType.ecoCoins,
      requirement: 100,
      tier: BadgeTier.bronze,
    ),
    Achievement(
      id: 'eco_contributor',
      title: 'Eco Contributor',
      description: 'สะสม 1,000 Eco Coins',
      icon: '🌿',
      type: AchievementType.ecoCoins,
      requirement: 1000,
      tier: BadgeTier.silver,
    ),
    Achievement(
      id: 'eco_warrior',
      title: 'Eco Warrior',
      description: 'สะสม 5,000 Eco Coins',
      icon: '🌳',
      type: AchievementType.ecoCoins,
      requirement: 5000,
      tier: BadgeTier.gold,
    ),
    Achievement(
      id: 'eco_legend',
      title: 'Eco Legend',
      description: 'สะสม 10,000 Eco Coins',
      icon: '🏆',
      type: AchievementType.ecoCoins,
      requirement: 10000,
      tier: BadgeTier.platinum,
    ),

    // Activity Achievements
    Achievement(
      id: 'activity_starter',
      title: 'Activity Starter',
      description: 'สร้างกิจกรรมแรก',
      icon: '🎯',
      type: AchievementType.activities,
      requirement: 1,
      tier: BadgeTier.bronze,
    ),
    Achievement(
      id: 'activity_organizer',
      title: 'Activity Organizer',
      description: 'จัดกิจกรรม 10 ครั้ง',
      icon: '📅',
      type: AchievementType.activities,
      requirement: 10,
      tier: BadgeTier.gold,
    ),

    // Community Achievements
    Achievement(
      id: 'first_post',
      title: 'First Post',
      description: 'โพสต์ครั้งแรกในชุมชน',
      icon: '✍️',
      type: AchievementType.posts,
      requirement: 1,
      tier: BadgeTier.bronze,
    ),
    Achievement(
      id: 'top_contributor',
      title: 'Top Contributor',
      description: 'โพสต์ 50 ครั้ง',
      icon: '⭐',
      type: AchievementType.posts,
      requirement: 50,
      tier: BadgeTier.gold,
    ),

    // Level Achievements
    Achievement(
      id: 'level_5',
      title: 'Rising Star',
      description: 'ถึงระดับ 5',
      icon: '🌟',
      type: AchievementType.level,
      requirement: 5,
      tier: BadgeTier.silver,
    ),
    Achievement(
      id: 'level_10',
      title: 'Veteran',
      description: 'ถึงระดับ 10',
      icon: '💎',
      type: AchievementType.level,
      requirement: 10,
      tier: BadgeTier.gold,
    ),

    // Special Achievements
    Achievement(
      id: 'first_purchase',
      title: 'First Purchase',
      description: 'ซื้อสินค้าครั้งแรก',
      icon: '🛒',
      type: AchievementType.special,
      requirement: 1,
      tier: BadgeTier.bronze,
    ),
    Achievement(
      id: 'email_verified',
      title: 'Verified Member',
      description: 'ยืนยันอีเมล',
      icon: '✅',
      type: AchievementType.special,
      requirement: 1,
      tier: BadgeTier.bronze,
    ),
    Achievement(
      id: 'profile_complete',
      title: 'Profile Complete',
      description: 'เติมข้อมูลโปรไฟล์ครบถ้วน',
      icon: '👤',
      type: AchievementType.special,
      requirement: 1,
      tier: BadgeTier.bronze,
    ),
  ];

  List<Achievement> get allAchievements => _allAchievements;
}

/// Achievement Model
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final AchievementType type;
  final int requirement;
  final BadgeTier tier;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    required this.requirement,
    required this.tier,
  });
}

enum AchievementType {
  ecoCoins,
  activities,
  posts,
  level,
  special,
}

enum BadgeTier {
  bronze,
  silver,
  gold,
  platinum,
}

extension BadgeTierExtension on BadgeTier {
  String get displayName {
    switch (this) {
      case BadgeTier.bronze:
        return 'Bronze';
      case BadgeTier.silver:
        return 'Silver';
      case BadgeTier.gold:
        return 'Gold';
      case BadgeTier.platinum:
        return 'Platinum';
    }
  }

  String get color {
    switch (this) {
      case BadgeTier.bronze:
        return '#CD7F32';
      case BadgeTier.silver:
        return '#C0C0C0';
      case BadgeTier.gold:
        return '#FFD700';
      case BadgeTier.platinum:
        return '#E5E4E2';
    }
  }
}
