// lib/services/eco_influence_service.dart
// บริการจัดการคะแนนอิทธิพลชุมชนสีเขียว (Eco Influence Score)
// แยกจาก Eco Coins ในตลาด - เฉพาะสำหรับชุมชนสีเขียว

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ระดับอิทธิพล (Tier System) - เชื่อมกับ ECO Level
enum EcoInfluenceTier {
  sprout, // 0-49: 🌱 ต้นกล้า
  seedling, // 50-149: 🌿 ต้นอ่อน
  blooming, // 150-299: 🌸 กำลังเบ่งบาน
  guardian, // 300-499: 🌳 ผู้พิทักษ์
  champion, // 500-749: 🏆 แชมป์สิ่งแวดล้อม
  ecoHero, // 750+: 💎 Eco Hero
}

/// ค่าน้ำหนักคะแนนตามมาตรฐานสากล
class EcoInfluenceWeights {
  static const double followers = 0.20; // 20% - ผู้ติดตาม
  static const double ecoPurchases = 0.15; // 15% - ซื้อสินค้า ECO
  static const double challenges =
      0.45; // 45% - เข้าร่วมกิจกรรม (น้ำหนักสูงสุด)
  static const double socialEngagement = 0.20; // 20% - การมีส่วนร่วมในชุมชน
}

/// คะแนนต่อกิจกรรม
/// คะแนนต่อกิจกรรม - ปรับให้สมดุลกับ 0-100 คะแนน
class EcoInfluencePoints {
  // Challenges - น้ำหนักสูงสุด (45%)
  static const double challengeEasy = 2.0; // ง่าย
  static const double challengeMedium = 4.0; // ปานกลาง
  static const double challengeHard = 8.0; // ยาก

  // Social Engagement (20%)
  static const double postCreated = 1.0; // สร้างโพสต์
  static const double postLiked = 0.1; // ได้รับ Like
  static const double commentReceived = 0.3; // ได้รับ Comment
  static const double postShared = 0.5; // ได้รับ Share

  // Followers (20%)
  static const double perFollower = 0.05; // แต่ละคน
  static const double followerMilestone50 = 2.0; // โบนัส 50 คน
  static const double followerMilestone100 = 3.0; // โบนัส 100 คน
  static const double followerMilestone500 = 5.0; // โบนัส 500 คน

  // ECO Purchases (15%)
  static const double per1000BahtEco = 1.0; // ทุก 1,000 บาท
}

class EcoInfluenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// คำนวณคะแนนอิทธิพลทั้งหมด (รวมหักตาม penalty)
  Future<double> calculateTotalInfluenceScore(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return 0.0;

      final data = userDoc.data()!;

      // ดึงข้อมูลพื้นฐาน
      final followersCount = data['followersCount'] as int? ?? 0;
      final challengesCompleted = data['challengesCompleted'] as int? ?? 0;
      final communityEngagement = data['communityEngagement'] as int? ?? 0;
      final ecoProductsPurchased =
          (data['ecoProductsPurchased'] as num?)?.toDouble() ?? 0.0;

      // ดึงข้อมูล penalty
      final penaltyPercentage =
          (data['penaltyPercentage'] as num?)?.toDouble() ?? 0.0;

      // คำนวณคะแนนแต่ละส่วน
      final followersScore = _calculateFollowersScore(followersCount);
      final challengesScore = _calculateChallengesScore(challengesCompleted);
      final engagementScore = _calculateEngagementScore(communityEngagement);
      final purchasesScore = _calculatePurchasesScore(ecoProductsPurchased);

      // รวมคะแนนตามน้ำหนัก
      double totalScore = (followersScore * EcoInfluenceWeights.followers) +
          (purchasesScore * EcoInfluenceWeights.ecoPurchases) +
          (challengesScore * EcoInfluenceWeights.challenges) +
          (engagementScore * EcoInfluenceWeights.socialEngagement);

      // หักคะแนนตาม penalty (ถ้ามี)
      if (penaltyPercentage > 0) {
        final penaltyAmount = totalScore * (penaltyPercentage / 100);
        totalScore = totalScore - penaltyAmount;
        debugPrint(
            'Applied penalty: $penaltyPercentage% (-${penaltyAmount.toStringAsFixed(2)}) for user $userId');
      }

      // จำกัดไม่ให้ติดลบ
      totalScore = totalScore.clamp(0.0, 100.0);

      return totalScore;
    } catch (e) {
      debugPrint('Error calculating influence score: $e');
      return 0.0;
    }
  }

  /// คำนวณคะแนนจากผู้ติดตาม
  double _calculateFollowersScore(int followersCount) {
    double score = followersCount * EcoInfluencePoints.perFollower;

    // Milestone bonuses
    if (followersCount >= 500) {
      score += EcoInfluencePoints.followerMilestone500;
    } else if (followersCount >= 100) {
      score += EcoInfluencePoints.followerMilestone100;
    } else if (followersCount >= 50) {
      score += EcoInfluencePoints.followerMilestone50;
    }

    return score;
  }

  /// คำนวณคะแนนจากการทำ Challenges (น้ำหนักสูงสุด 45%)
  double _calculateChallengesScore(int challengesCompleted) {
    // Base score: เฉลี่ย 4 คะแนนต่อ Challenge (ปานกลาง)
    double score = challengesCompleted * EcoInfluencePoints.challengeMedium;

    // โบนัสคะแนนแบบ additive สำหรับการเข้าร่วมสม่ำเสมอ (สมดุลกว่า multiplicative)
    if (challengesCompleted >= 50) {
      score += 25.0; // Milestone bonus - Eco Champion
    } else if (challengesCompleted >= 30) {
      score += 15.0; // Milestone bonus - Expert
    } else if (challengesCompleted >= 20) {
      score += 10.0; // Milestone bonus - Active
    } else if (challengesCompleted >= 10) {
      score += 5.0; // Milestone bonus - Beginner
    }

    return score;
  }

  /// คำนวณคะแนนจากการมีส่วนร่วมในชุมชน
  double _calculateEngagementScore(int totalEngagement) {
    // Base: แต่ละ engagement = 0.15 คะแนน (ลดลงเล็กน้อยเพื่อสมดุล)
    double score = totalEngagement * 0.15;

    // โบนัสสำหรับ engagement สูง (คนที่ได้รับความนิยม)
    if (totalEngagement >= 1000) {
      score *= 1.4; // 40% bonus - Viral
    } else if (totalEngagement >= 500) {
      score *= 1.3; // 30% bonus - ยอดนิยมมาก
    } else if (totalEngagement >= 200) {
      score *= 1.2; // 20% bonus - ยอดนิยม
    } else if (totalEngagement >= 50) {
      score *= 1.1; // 10% bonus - เริ่มได้รับความสนใจ
    }

    return score;
  }

  /// คำนวณคะแนนจากการซื้อสินค้า ECO
  double _calculatePurchasesScore(double totalPurchased) {
    return (totalPurchased / 1000) * EcoInfluencePoints.per1000BahtEco;
  }

  /// อัปเดตคะแนนอิทธิพล
  Future<void> updateInfluenceScore(String userId) async {
    try {
      final score = await calculateTotalInfluenceScore(userId);

      await _firestore.collection('users').doc(userId).update({
        'ecoInfluenceScore': score,
        'lastInfluenceUpdate': FieldValue.serverTimestamp(),
      });

      debugPrint('Updated influence score for $userId: $score');
    } catch (e) {
      debugPrint('Error updating influence score: $e');
    }
  }

  /// เพิ่มคะแนนเมื่อทำ Challenge สำเร็จ
  Future<void> awardChallengePoints(String userId, String difficulty) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'challengesCompleted': FieldValue.increment(1),
      });

      await updateInfluenceScore(userId);
    } catch (e) {
      debugPrint('Error awarding challenge points: $e');
    }
  }

  /// เพิ่มคะแนนเมื่อสร้างโพสต์
  Future<void> awardPostPoints(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'communityPostsCount': FieldValue.increment(1),
      });

      await updateInfluenceScore(userId);
    } catch (e) {
      debugPrint('Error awarding post points: $e');
    }
  }

  /// เพิ่มคะแนนเมื่อได้รับ engagement
  Future<void> awardEngagementPoints(String userId, String type) async {
    try {
      int points = 1;

      switch (type.toLowerCase()) {
        case 'like':
          points = 1;
          break;
        case 'comment':
          points = 3;
          break;
        case 'share':
          points = 5;
          break;
      }

      await _firestore.collection('users').doc(userId).update({
        'communityEngagement': FieldValue.increment(points),
      });

      await updateInfluenceScore(userId);
    } catch (e) {
      debugPrint('Error awarding engagement points: $e');
    }
  }

  /// เพิ่มคะแนนเมื่อซื้อสินค้า ECO
  Future<void> awardEcoPurchasePoints(String userId, double amount) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'ecoProductsPurchased': FieldValue.increment(amount),
      });

      await updateInfluenceScore(userId);
    } catch (e) {
      debugPrint('Error awarding purchase points: $e');
    }
  }

  /// เพิ่ม/ลดผู้ติดตาม
  Future<void> updateFollowerCount(String userId, int change) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'followersCount': FieldValue.increment(change),
      });

      await updateInfluenceScore(userId);
    } catch (e) {
      debugPrint('Error updating follower count: $e');
    }
  }

  /// ดึงระดับอิทธิพล (Tier) - ระบบ 0-100
  EcoInfluenceTier getTier(double score) {
    if (score >= 95) return EcoInfluenceTier.ecoHero; // 95-100 (S)
    if (score >= 80) return EcoInfluenceTier.champion; // 80-94 (A)
    if (score >= 60) return EcoInfluenceTier.guardian; // 60-79 (B)
    if (score >= 40) return EcoInfluenceTier.blooming; // 40-59 (C)
    if (score >= 20) return EcoInfluenceTier.seedling; // 20-39 (D)
    return EcoInfluenceTier.sprout; // 0-19 (F)
  }

  /// ดึงชื่อ Tier เป็นภาษาไทย
  String getTierName(EcoInfluenceTier tier) {
    switch (tier) {
      case EcoInfluenceTier.sprout:
        return 'ต้นกล้า';
      case EcoInfluenceTier.seedling:
        return 'ต้นอ่อน';
      case EcoInfluenceTier.blooming:
        return 'กำลังเบ่งบาน';
      case EcoInfluenceTier.guardian:
        return 'ผู้พิทักษ์';
      case EcoInfluenceTier.champion:
        return 'แชมป์สิ่งแวดล้อม';
      case EcoInfluenceTier.ecoHero:
        return 'Eco Hero';
    }
  }

  /// ดึงสี Tier - สอดคล้องกับ ECO Level
  int getTierColor(EcoInfluenceTier tier) {
    switch (tier) {
      case EcoInfluenceTier.sprout:
        return 0xFF9CA3AF; // Gray - เริ่มต้น
      case EcoInfluenceTier.seedling:
        return 0xFF10B981; // Green - เข้ากับสีเขียว
      case EcoInfluenceTier.blooming:
        return 0xFF3B82F6; // Blue - กำลังเติบโต
      case EcoInfluenceTier.guardian:
        return 0xFF8B5CF6; // Purple - พิทักษ์
      case EcoInfluenceTier.champion:
        return 0xFFEAB308; // Gold - แชมป์
      case EcoInfluenceTier.ecoHero:
        return 0xFFEC4899; // Pink Diamond - Eco Hero
    }
  }

  /// ดึงไอคอน Tier - สอดคล้องกับ ECO Level
  String getTierIcon(EcoInfluenceTier tier) {
    switch (tier) {
      case EcoInfluenceTier.sprout:
        return '🌱'; // ต้นกล้า
      case EcoInfluenceTier.seedling:
        return '🌿'; // ต้นอ่อน
      case EcoInfluenceTier.blooming:
        return '🌸'; // ดอกไม้
      case EcoInfluenceTier.guardian:
        return '🌳'; // ต้นไม้ใหญ่
      case EcoInfluenceTier.champion:
        return '🏆'; // ถ้วยแชมป์
      case EcoInfluenceTier.ecoHero:
        return '💎'; // Eco Hero
    }
  }

  /// ดึงสิทธิพิเศษและรางวัลตาม Tier
  List<String> getTierBenefits(EcoInfluenceTier tier) {
    switch (tier) {
      case EcoInfluenceTier.sprout:
        return [
          'เข้าร่วมชุมชนสีเขียว',
          'โพสต์และแชร์เนื้อหา',
        ];
      case EcoInfluenceTier.seedling:
        return [
          'Badge 🌿 ต้นอ่อน',
          'โพสต์ Reach +15%',
          'รางวัล: คูปองส่วนลด 5%',
        ];
      case EcoInfluenceTier.blooming:
        return [
          'Badge 🌸 กำลังเบ่งบาน',
          'โพสต์ Reach +30%',
          'สร้างกิจกรรมเอง',
          'รางวัล: คูปองลด 10%, Free Shipping 1ครั้ง/เดือน',
        ];
      case EcoInfluenceTier.guardian:
        return [
          'Badge 🌳 ผู้พิทักษ์',
          'โพสต์ Reach +50%',
          'ปักหมุดโพสต์ได้ 1 โพสต์',
          'สร้างกิจกรรมพิเศษ',
          'รางวัล: คูปองลด 15%, Free Shipping ทุกครั้ง',
        ];
      case EcoInfluenceTier.champion:
        return [
          'Badge 🏆 แชมป์สิ่งแวดล้อม',
          'โพสต์ Reach +75%',
          'ปักหมุดโพสต์ได้ 3 โพสต์',
          'แนะนำในหน้าแรก',
          'รางวัล: คูปองลด 20%, คะแนน Eco Coins x1.5',
        ];
      case EcoInfluenceTier.ecoHero:
        return [
          'Badge 💎 Eco Hero',
          'โพสต์ Reach +100% (ดันแนะนำ)',
          'ปักหมุดโพสต์ได้ 5 โพสต์',
          'แนะนำพิเศษในหน้าแรก',
          'สิทธิ์จัดงาน Official',
          'รางวัล: คูปองลด 25%, คะแนน Eco Coins x2',
        ];
    }
  }

  /// ดึงคะแนนถัดไปที่ต้องทำ
  Map<String, dynamic> getNextTierInfo(double currentScore) {
    final currentTier = getTier(currentScore);
    EcoInfluenceTier? nextTier;
    double nextTierScore = 0;

    switch (currentTier) {
      case EcoInfluenceTier.sprout:
        nextTier = EcoInfluenceTier.seedling;
        nextTierScore = 20;
        break;
      case EcoInfluenceTier.seedling:
        nextTier = EcoInfluenceTier.blooming;
        nextTierScore = 40;
        break;
      case EcoInfluenceTier.blooming:
        nextTier = EcoInfluenceTier.guardian;
        nextTierScore = 60;
        break;
      case EcoInfluenceTier.guardian:
        nextTier = EcoInfluenceTier.champion;
        nextTierScore = 80;
        break;
      case EcoInfluenceTier.champion:
        nextTier = EcoInfluenceTier.ecoHero;
        nextTierScore = 95;
        break;
      case EcoInfluenceTier.ecoHero:
        break; // Max tier
    }

    if (nextTier == null) {
      return {
        'hasNext': false,
        'message': 'คุณอยู่ในระดับสูงสุดแล้ว!',
      };
    }

    final remaining = nextTierScore - currentScore;
    final progress = currentScore / nextTierScore;

    return {
      'hasNext': true,
      'nextTier': nextTier,
      'nextTierName': getTierName(nextTier),
      'nextTierScore': nextTierScore,
      'remaining': remaining,
      'progress': progress,
    };
  }

  /// ดึงอันดับของผู้ใช้ในชุมชน
  Future<int> getUserRank(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('ecoInfluenceScore', descending: true)
          .get();

      int rank = 1;
      for (var doc in snapshot.docs) {
        if (doc.id == userId) {
          return rank;
        }
        rank++;
      }
      return rank;
    } catch (e) {
      debugPrint('Error getting user rank: $e');
      return 0;
    }
  }

  /// ดึงประวัติการถูกหักคะแนน
  Future<List<Map<String, dynamic>>> getPenaltyHistory(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return [];

      final data = userDoc.data()!;
      return (data['violationHistory'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];
    } catch (e) {
      debugPrint('Error getting penalty history: $e');
      return [];
    }
  }

  /// ลบ penalty (สำหรับ Admin)
  Future<void> removePenalty(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'penaltyPercentage': 0.0,
      });

      // อัปเดตคะแนนใหม่
      await updateInfluenceScore(userId);

      debugPrint('Penalty removed and score updated for user $userId');
    } catch (e) {
      debugPrint('Error removing penalty: $e');
      rethrow;
    }
  }

  /// ดึง Top Influencers
  Stream<QuerySnapshot> getTopInfluencers({int limit = 10}) {
    return _firestore
        .collection('users')
        .orderBy('ecoInfluenceScore', descending: true)
        .limit(limit)
        .snapshots();
  }
}
