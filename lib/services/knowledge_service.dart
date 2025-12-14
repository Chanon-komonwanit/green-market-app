// lib/services/knowledge_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:green_market/models/knowledge_article.dart';

class KnowledgeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _collectionPath = 'knowledge_articles';

  /// Get published articles by category
  Stream<List<KnowledgeArticle>> getArticlesByCategory({
    KnowledgeCategory? category,
    int limit = 10,
  }) {
    Query query = _firestore
        .collection(_collectionPath)
        .where('isPublished', isEqualTo: true);

    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) =>
                  KnowledgeArticle.fromMap(doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  /// Get featured articles
  Stream<List<KnowledgeArticle>> getFeaturedArticles({int limit = 5}) {
    return _firestore
        .collection(_collectionPath)
        .where('isPublished', isEqualTo: true)
        .where('isFeatured', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => KnowledgeArticle.fromMap(doc.data()))
              .toList(),
        );
  }

  /// Get article by ID and increment view count
  Future<KnowledgeArticle?> getArticleById(String articleId) async {
    try {
      final doc =
          await _firestore.collection(_collectionPath).doc(articleId).get();

      if (!doc.exists) {
        return null;
      }

      // Increment view count
      await _firestore.collection(_collectionPath).doc(articleId).update({
        'viewCount': FieldValue.increment(1),
      });

      return KnowledgeArticle.fromMap(doc.data()!);
    } catch (e) {
      print('[ERROR] เกิดข้อผิดพลาดในการดึงบทความ: $e');
      return null;
    }
  }

  /// Search articles
  Future<List<KnowledgeArticle>> searchArticles(String keyword) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionPath)
          .where('isPublished', isEqualTo: true)
          .get();

      final lowerKeyword = keyword.toLowerCase();

      return snapshot.docs
          .map((doc) => KnowledgeArticle.fromMap(doc.data()))
          .where((article) {
        return article.title.toLowerCase().contains(lowerKeyword) ||
            article.summary.toLowerCase().contains(lowerKeyword) ||
            article.tags.any((tag) => tag.toLowerCase().contains(lowerKeyword));
      }).toList();
    } catch (e) {
      print('[ERROR] เกิดข้อผิดพลาดในการค้นหา: $e');
      return [];
    }
  }

  /// Like article
  Future<bool> likeArticle(String articleId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('กรุณาเข้าสู่ระบบ');
      }

      // Check if already liked
      final likeDoc = await _firestore
          .collection('article_likes')
          .doc('${user.uid}_$articleId')
          .get();

      if (likeDoc.exists) {
        // Unlike
        await _firestore
            .collection('article_likes')
            .doc('${user.uid}_$articleId')
            .delete();

        await _firestore.collection(_collectionPath).doc(articleId).update({
          'likeCount': FieldValue.increment(-1),
        });
      } else {
        // Like
        await _firestore
            .collection('article_likes')
            .doc('${user.uid}_$articleId')
            .set({
          'userId': user.uid,
          'articleId': articleId,
          'likedAt': FieldValue.serverTimestamp(),
        });

        await _firestore.collection(_collectionPath).doc(articleId).update({
          'likeCount': FieldValue.increment(1),
        });
      }

      return true;
    } catch (e) {
      print('[ERROR] เกิดข้อผิดพลาดในการกดไลค์: $e');
      return false;
    }
  }

  /// Check if user liked article
  Future<bool> hasUserLikedArticle(String articleId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final likeDoc = await _firestore
          .collection('article_likes')
          .doc('${user.uid}_$articleId')
          .get();

      return likeDoc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get popular articles (most viewed)
  Stream<List<KnowledgeArticle>> getPopularArticles({int limit = 5}) {
    return _firestore
        .collection(_collectionPath)
        .where('isPublished', isEqualTo: true)
        .orderBy('viewCount', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => KnowledgeArticle.fromMap(doc.data()))
              .toList(),
        );
  }

  /// Get latest articles
  Stream<List<KnowledgeArticle>> getLatestArticles({int limit = 10}) {
    return _firestore
        .collection(_collectionPath)
        .where('isPublished', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => KnowledgeArticle.fromMap(doc.data()))
              .toList(),
        );
  }

  /// Admin: Create article
  Future<String> createArticle({
    required String title,
    required String content,
    required String summary,
    required KnowledgeCategory category,
    required DifficultyLevel level,
    required String thumbnailUrl,
    required List<String> tags,
    required int estimatedReadMinutes,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('กรุณาเข้าสู่ระบบ');
      }

      final article = KnowledgeArticle(
        id: '',
        title: title,
        content: content,
        summary: summary,
        category: category,
        level: level,
        thumbnailUrl: thumbnailUrl,
        authorId: user.uid,
        authorName: user.displayName ?? 'Unknown',
        tags: tags,
        createdAt: Timestamp.now(),
        estimatedReadMinutes: estimatedReadMinutes,
        isPublished: false,
      );

      final docRef =
          await _firestore.collection(_collectionPath).add(article.toMap());

      print('[SUCCESS] สร้างบทความสำเร็จ ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('[ERROR] เกิดข้อผิดพลาดในการสร้างบทความ: $e');
      rethrow;
    }
  }

  /// Admin: Publish article
  Future<bool> publishArticle(String articleId) async {
    try {
      await _firestore.collection(_collectionPath).doc(articleId).update({
        'isPublished': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('[SUCCESS] เผยแพร่บทความสำเร็จ');
      return true;
    } catch (e) {
      print('[ERROR] เกิดข้อผิดพลาดในการเผยแพร่: $e');
      return false;
    }
  }

  /// Admin: Set featured article
  Future<bool> setFeaturedArticle(String articleId, bool isFeatured) async {
    try {
      await _firestore.collection(_collectionPath).doc(articleId).update({
        'isFeatured': isFeatured,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('[SUCCESS] อัปเดตสถานะ featured สำเร็จ');
      return true;
    } catch (e) {
      print('[ERROR] เกิดข้อผิดพลาดในการอัปเดต: $e');
      return false;
    }
  }
}
