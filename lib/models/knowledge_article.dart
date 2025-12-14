// lib/models/knowledge_article.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for article category
enum KnowledgeCategory {
  activities, // กิจกรรม
  investment, // การลงทุน
  carbonCredit, // คาร์บอนเครดิต
  sustainability, // ความยั่งยืน
  general, // ทั่วไป
}

/// Enum for article difficulty level
enum DifficultyLevel {
  beginner, // เริ่มต้น
  intermediate, // ปานกลาง
  advanced, // ขั้นสูง
}

/// Model for Knowledge Base Article
class KnowledgeArticle {
  final String id;
  final String title;
  final String content;
  final String summary; // สรุปสั้นๆ
  final KnowledgeCategory category;
  final DifficultyLevel level;
  final String thumbnailUrl;
  final String authorId;
  final String authorName;
  final List<String> tags;
  final int viewCount;
  final int likeCount;
  final bool isFeatured;
  final bool isPublished;
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final int estimatedReadMinutes; // เวลาอ่านโดยประมาณ (นาที)

  KnowledgeArticle({
    required this.id,
    required this.title,
    required this.content,
    required this.summary,
    required this.category,
    required this.level,
    required this.thumbnailUrl,
    required this.authorId,
    required this.authorName,
    this.tags = const [],
    this.viewCount = 0,
    this.likeCount = 0,
    this.isFeatured = false,
    this.isPublished = false,
    required this.createdAt,
    this.updatedAt,
    this.estimatedReadMinutes = 5,
  });

  /// Format category for display
  String get categoryText {
    switch (category) {
      case KnowledgeCategory.activities:
        return 'กิจกรรม';
      case KnowledgeCategory.investment:
        return 'การลงทุน';
      case KnowledgeCategory.carbonCredit:
        return 'คาร์บอนเครดิต';
      case KnowledgeCategory.sustainability:
        return 'ความยั่งยืน';
      case KnowledgeCategory.general:
        return 'ทั่วไป';
    }
  }

  /// Format difficulty level for display
  String get levelText {
    switch (level) {
      case DifficultyLevel.beginner:
        return 'เริ่มต้น';
      case DifficultyLevel.intermediate:
        return 'ปานกลาง';
      case DifficultyLevel.advanced:
        return 'ขั้นสูง';
    }
  }

  /// Get level color
  String get levelEmoji {
    switch (level) {
      case DifficultyLevel.beginner:
        return '🌱';
      case DifficultyLevel.intermediate:
        return '🌿';
      case DifficultyLevel.advanced:
        return '🌳';
    }
  }

  factory KnowledgeArticle.fromMap(Map<String, dynamic> map) {
    return KnowledgeArticle(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? 'Untitled',
      content: map['content'] as String? ?? '',
      summary: map['summary'] as String? ?? '',
      category: KnowledgeCategory.values.firstWhere(
        (e) => e.name == (map['category'] as String?),
        orElse: () => KnowledgeCategory.general,
      ),
      level: DifficultyLevel.values.firstWhere(
        (e) => e.name == (map['level'] as String?),
        orElse: () => DifficultyLevel.beginner,
      ),
      thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
      authorId: map['authorId'] as String? ?? '',
      authorName: map['authorName'] as String? ?? 'Unknown',
      tags: List<String>.from(map['tags'] as List? ?? []),
      viewCount: map['viewCount'] as int? ?? 0,
      likeCount: map['likeCount'] as int? ?? 0,
      isFeatured: map['isFeatured'] as bool? ?? false,
      isPublished: map['isPublished'] as bool? ?? false,
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: map['updatedAt'] as Timestamp?,
      estimatedReadMinutes: map['estimatedReadMinutes'] as int? ?? 5,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'summary': summary,
      'category': category.name,
      'level': level.name,
      'thumbnailUrl': thumbnailUrl,
      'authorId': authorId,
      'authorName': authorName,
      'tags': tags,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'isFeatured': isFeatured,
      'isPublished': isPublished,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'estimatedReadMinutes': estimatedReadMinutes,
    };
  }

  KnowledgeArticle copyWith({
    String? id,
    String? title,
    String? content,
    String? summary,
    KnowledgeCategory? category,
    DifficultyLevel? level,
    String? thumbnailUrl,
    String? authorId,
    String? authorName,
    List<String>? tags,
    int? viewCount,
    int? likeCount,
    bool? isFeatured,
    bool? isPublished,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    int? estimatedReadMinutes,
  }) {
    return KnowledgeArticle(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      category: category ?? this.category,
      level: level ?? this.level,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      tags: tags ?? this.tags,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      isFeatured: isFeatured ?? this.isFeatured,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      estimatedReadMinutes: estimatedReadMinutes ?? this.estimatedReadMinutes,
    );
  }
}
