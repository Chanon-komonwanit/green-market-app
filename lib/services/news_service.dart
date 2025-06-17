import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/models/news_article.dart';

class NewsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath =
      'news_articles'; // ชื่อ collection ข่าวใน Firestore

  Future<List<NewsArticle>> getNewsArticles({int limit = 10}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionPath)
          .orderBy('publishedDate',
              descending: true) // เรียงตามวันที่ล่าสุดก่อน
          .limit(limit) // จำกัดจำนวนข่าวที่ดึงมา
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        Timestamp? publishedTimestamp = data['publishedDate'] as Timestamp?;

        return NewsArticle(
          id: doc.id,
          title: data['title'] ?? 'N/A',
          summary: data['summary'] ?? 'No summary available.',
          imageUrl: data['imageUrl'], // Can be null
          originalUrl: data['originalUrl'], // Can be null
          source: data['source'] ?? 'Unknown Source',
          publishedDate: publishedTimestamp?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      print('Error fetching news articles: $e');
      return [];
    }
  }
}
