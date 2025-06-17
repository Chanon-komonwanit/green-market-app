class NewsArticle {
  final String id;
  final String title;
  final String summary;
  final String? imageUrl; // Optional image URL
  final String? originalUrl; // URL to the full article
  final String source;
  final DateTime publishedDate;

  NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    this.imageUrl,
    this.originalUrl,
    required this.source,
    required this.publishedDate,
  });
}
