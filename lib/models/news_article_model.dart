// lib/models/news_article_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class NewsArticle {
  final String id;
  final String title;
  final String summary;
  final String? imageUrl;
  final String? originalUrl;
  final String source;
  final DateTime publishedDate;
  final String content;

  const NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    this.imageUrl,
    this.originalUrl,
    required this.source,
    required this.publishedDate,
    required this.content,
  });

  factory NewsArticle.fromMap(Map<String, dynamic> map, String id) {
    return NewsArticle(
      id: id,
      title: map['title'] ?? '',
      summary: map['summary'] ?? '',
      imageUrl: map['imageUrl'],
      originalUrl: map['originalUrl'],
      source: map['source'] ?? '',
      publishedDate:
          (map['publishedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      content: map['content'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'summary': summary,
      'imageUrl': imageUrl,
      'originalUrl': originalUrl,
      'source': source,
      'publishedDate': Timestamp.fromDate(publishedDate),
      'content': content,
    };
  }
}
