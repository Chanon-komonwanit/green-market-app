// lib/models/news_article_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class NewsArticle {
  final Timestamp? createdAt;

  NewsArticle copyWith({
    String? id,
    String? title,
    String? summary,
    String? imageUrl,
    String? originalUrl,
    String? source,
    DateTime? publishedDate,
    String? content,
    Timestamp? createdAt,
  }) {
    return NewsArticle(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      imageUrl: imageUrl ?? this.imageUrl,
      originalUrl: originalUrl ?? this.originalUrl,
      source: source ?? this.source,
      publishedDate: publishedDate ?? this.publishedDate,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

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
    this.createdAt,
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
      createdAt: map['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'imageUrl': imageUrl,
      'originalUrl': originalUrl,
      'source': source,
      'publishedDate': Timestamp.fromDate(publishedDate),
      'content': content,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }
}
