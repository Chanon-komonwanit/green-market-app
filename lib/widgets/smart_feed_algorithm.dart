// lib/widgets/smart_feed_algorithm.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/models/community_post.dart';

/// Smart Feed Algorithm - แบบ Instagram/Facebook/TikTok
/// จัดเรียงโพสต์ตาม: Engagement, Relevance, Freshness, Eco Score, User Interests
class SmartFeedAlgorithm {
  // Algorithm weights - ปรับได้ตามต้องการ
  static const double _engagementWeight = 0.30; // 30%
  static const double _freshnessWeight = 0.25; // 25%
  static const double _relevanceWeight = 0.20; // 20%
  static const double _ecoScoreWeight = 0.15; // 15%
  static const double _userAffinityWeight = 0.10; // 10%

  /// คำนวณ Feed Score สำหรับแต่ละโพสต์
  static double calculateFeedScore({
    required Map<String, dynamic> postData,
    required String currentUserId,
    List<String> userInterests = const [],
    List<String> followingUserIds = const [],
  }) {
    // 1. Engagement Score (Likes + Comments*2 + Shares*3)
    final engagementScore = _calculateEngagementScore(postData);

    // 2. Freshness Score (ใหม่กว่า = คะแนนสูงกว่า)
    final freshnessScore = _calculateFreshnessScore(postData);

    // 3. Relevance Score (ตาม tags/interests ของ user)
    final relevanceScore = _calculateRelevanceScore(postData, userInterests);

    // 4. Eco Score (โพสต์ที่มี eco-friendly content)
    final ecoScore = _calculateEcoScore(postData);

    // 5. User Affinity (คนที่ follow หรือเคย interact)
    final affinityScore = _calculateUserAffinityScore(
      postData,
      currentUserId,
      followingUserIds,
    );

    // รวมคะแนนตาม weights
    final totalScore = (engagementScore * _engagementWeight) +
        (freshnessScore * _freshnessWeight) +
        (relevanceScore * _relevanceWeight) +
        (ecoScore * _ecoScoreWeight) +
        (affinityScore * _userAffinityWeight);

    return totalScore;
  }

  /// คำนวณ Engagement Score (0-100)
  static double _calculateEngagementScore(Map<String, dynamic> postData) {
    final likes = (postData['likes'] as List?)?.length ?? 0;
    final comments = postData['commentCount'] ?? 0;
    final shares = postData['shareCount'] ?? 0;
    final views = postData['viewCount'] ?? 0;

    // ถ้ามี views ให้คำนวณ engagement rate
    if (views > 0) {
      final engagementRate = (likes + comments * 2 + shares * 3) / views;
      return (engagementRate * 100).clamp(0, 100).toDouble();
    }

    // ไม่มี views ให้คำนวณจาก absolute numbers
    final totalEngagement = likes + (comments * 2) + (shares * 3);

    // Normalize to 0-100 scale (assuming 100+ engagement = 100 score)
    return (totalEngagement / 100 * 100).clamp(0, 100).toDouble();
  }

  /// คำนวณ Freshness Score (0-100) - ยิ่งใหม่ยิ่งดี
  static double _calculateFreshnessScore(Map<String, dynamic> postData) {
    final createdAt = postData['createdAt'] as Timestamp?;
    if (createdAt == null) return 50.0; // Default middle score

    final now = DateTime.now();
    final postTime = createdAt.toDate();
    final ageInHours = now.difference(postTime).inHours;

    // Decay curve - แบบ Instagram
    if (ageInHours <= 1) return 100.0; // ภายใน 1 ชม. = คะแนนเต็ม
    if (ageInHours <= 6) return 90.0; // 1-6 ชม.
    if (ageInHours <= 24) return 70.0; // 6-24 ชม.
    if (ageInHours <= 48) return 50.0; // 1-2 วัน
    if (ageInHours <= 72) return 30.0; // 2-3 วัน
    if (ageInHours <= 168) return 15.0; // 3-7 วัน
    return 5.0; // มากกว่า 7 วัน
  }

  /// คำนวณ Relevance Score (0-100) - ตาม interests ของ user
  static double _calculateRelevanceScore(
    Map<String, dynamic> postData,
    List<String> userInterests,
  ) {
    if (userInterests.isEmpty) return 50.0; // No interests = middle score

    final postTags = List<String>.from(postData['tags'] ?? []);
    if (postTags.isEmpty) return 40.0;

    // นับว่า tags ของโพสต์ตรงกับ interests ของ user กี่ตัว
    int matchCount = 0;
    for (final tag in postTags) {
      if (userInterests.contains(tag.toLowerCase())) {
        matchCount++;
      }
    }

    // คำนวณเปอร์เซ็นต์ความตรง
    final matchPercentage = (matchCount / userInterests.length) * 100;
    return matchPercentage.clamp(0, 100).toDouble();
  }

  /// คำนวณ Eco Score (0-100) - โพสต์ที่เกี่ยวกับสิ่งแวดล้อม
  static double _calculateEcoScore(Map<String, dynamic> postData) {
    // Keywords ที่เกี่ยวกับสิ่งแวดล้อม
    const ecoKeywords = [
      'eco',
      'green',
      'organic',
      'sustainable',
      'recycle',
      'environment',
      'ออร์แกนิค',
      'รักษ์โลก',
      'สิ่งแวดล้อม',
      'รีไซเคิล',
      'ลดโลกร้อน',
      'ปลอดสารพิษ',
    ];

    final content = (postData['content'] ?? '').toString().toLowerCase();
    final tags = List<String>.from(postData['tags'] ?? [])
        .map((tag) => tag.toLowerCase())
        .toList();

    int ecoMatchCount = 0;

    // Check content
    for (final keyword in ecoKeywords) {
      if (content.contains(keyword)) {
        ecoMatchCount++;
      }
    }

    // Check tags
    for (final tag in tags) {
      if (ecoKeywords.any((keyword) => tag.contains(keyword))) {
        ecoMatchCount += 2; // Tags count more
      }
    }

    // Check if it's linked to eco product/activity
    if (postData['productId'] != null || postData['activityId'] != null) {
      ecoMatchCount += 3;
    }

    // Normalize to 0-100
    return (ecoMatchCount * 10).clamp(0, 100).toDouble();
  }

  /// คำนวณ User Affinity Score (0-100) - ความสัมพันธ์กับ user
  static double _calculateUserAffinityScore(
    Map<String, dynamic> postData,
    String currentUserId,
    List<String> followingUserIds,
  ) {
    final postUserId = postData['userId'] ?? '';

    // ถ้าเป็นโพสต์ของตัวเอง = 0 (ไม่แสดงใน feed)
    if (postUserId == currentUserId) return 0.0;

    // ถ้าเป็นคนที่ follow = 100
    if (followingUserIds.contains(postUserId)) return 100.0;

    // ถ้าเคยกด like/comment โพสต์ของคนนี้
    final likes = List<String>.from(postData['likes'] ?? []);
    if (likes.contains(currentUserId)) return 80.0;

    // Default = 50
    return 50.0;
  }

  /// เรียงลำดับโพสต์ตาม Feed Algorithm
  static List<Map<String, dynamic>> sortPostsByFeedScore({
    required List<Map<String, dynamic>> posts,
    required String currentUserId,
    List<String> userInterests = const [],
    List<String> followingUserIds = const [],
  }) {
    // คำนวณคะแนนสำหรับแต่ละโพสต์
    final postsWithScores = posts.map((post) {
      final score = calculateFeedScore(
        postData: post,
        currentUserId: currentUserId,
        userInterests: userInterests,
        followingUserIds: followingUserIds,
      );

      return {
        ...post,
        '_feedScore': score,
      };
    }).toList();

    // เรียงตามคะแนนจากมากไปน้อย
    postsWithScores.sort((a, b) {
      final scoreA = a['_feedScore'] as double;
      final scoreB = b['_feedScore'] as double;
      return scoreB.compareTo(scoreA);
    });

    return postsWithScores;
  }

  /// Filter โพสต์ที่ไม่เหมาะสม
  static List<Map<String, dynamic>> filterInappropriatePosts({
    required List<Map<String, dynamic>> posts,
    required String currentUserId,
    List<String> blockedUserIds = const [],
    List<String> mutedKeywords = const [],
  }) {
    return posts.where((post) {
      final postUserId = post['userId'] ?? '';
      final content = (post['content'] ?? '').toString().toLowerCase();

      // Filter blocked users
      if (blockedUserIds.contains(postUserId)) return false;

      // Filter muted keywords
      for (final keyword in mutedKeywords) {
        if (content.contains(keyword.toLowerCase())) return false;
      }

      // Filter own posts (optional)
      // if (postUserId == currentUserId) return false;

      return true;
    }).toList();
  }

  /// ผสม Viral Posts เข้ากับ Following Feed (แบบ Instagram)
  static List<Map<String, dynamic>> mixViralAndFollowing({
    required List<Map<String, dynamic>> allPosts,
    required String currentUserId,
    required List<String> followingUserIds,
    double viralRatio = 0.3, // 30% viral, 70% following
  }) {
    // แบ่งโพสต์ออกเป็น 2 กลุ่ม
    final followingPosts = allPosts.where((post) {
      return followingUserIds.contains(post['userId']);
    }).toList();

    final viralPosts = allPosts.where((post) {
      return !followingUserIds.contains(post['userId']);
    }).toList();

    // เรียงตาม engagement
    followingPosts.sort((a, b) {
      final scoreA = _calculateEngagementScore(a);
      final scoreB = _calculateEngagementScore(b);
      return scoreB.compareTo(scoreA);
    });

    viralPosts.sort((a, b) {
      final scoreA = _calculateEngagementScore(a);
      final scoreB = _calculateEngagementScore(b);
      return scoreB.compareTo(scoreA);
    });

    // ผสมตามสัดส่วน
    final mixedPosts = <Map<String, dynamic>>[];
    int followingIndex = 0;
    int viralIndex = 0;

    while (followingIndex < followingPosts.length ||
        viralIndex < viralPosts.length) {
      // เพิ่ม following posts
      final followingCount = (10 * (1 - viralRatio)).round();
      for (int i = 0; i < followingCount; i++) {
        if (followingIndex < followingPosts.length) {
          mixedPosts.add(followingPosts[followingIndex++]);
        }
      }

      // เพิ่ม viral posts
      final viralCount = (10 * viralRatio).round();
      for (int i = 0; i < viralCount; i++) {
        if (viralIndex < viralPosts.length) {
          mixedPosts.add(viralPosts[viralIndex++]);
        }
      }
    }

    return mixedPosts;
  }

  /// Diversify Feed - หลีกเลี่ยงการแสดงโพสต์จากคนเดิมซ้ำๆ
  static List<Map<String, dynamic>> diversifyFeed(
    List<Map<String, dynamic>> posts, {
    int maxPostsPerUser = 3,
  }) {
    final Map<String, int> userPostCount = {};
    final diversifiedPosts = <Map<String, dynamic>>[];

    for (final post in posts) {
      final userId = post['userId'] ?? '';
      final count = userPostCount[userId] ?? 0;

      if (count < maxPostsPerUser) {
        diversifiedPosts.add(post);
        userPostCount[userId] = count + 1;
      }
    }

    return diversifiedPosts;
  }

  /// Boost Recent Interactions - โพสต์จากคนที่เพิ่ง interact ไว้
  static List<Map<String, dynamic>> boostRecentInteractions({
    required List<Map<String, dynamic>> posts,
    required List<String> recentlyInteractedUserIds,
  }) {
    final boostedPosts = posts.map((post) {
      final postUserId = post['userId'] ?? '';

      if (recentlyInteractedUserIds.contains(postUserId)) {
        // Boost score by 20%
        final currentScore = post['_feedScore'] as double? ?? 50.0;
        return {
          ...post,
          '_feedScore': currentScore * 1.2,
        };
      }

      return post;
    }).toList();

    boostedPosts.sort((a, b) {
      final scoreA = a['_feedScore'] as double? ?? 0;
      final scoreB = b['_feedScore'] as double? ?? 0;
      return scoreB.compareTo(scoreA);
    });

    return boostedPosts;
  }
}
