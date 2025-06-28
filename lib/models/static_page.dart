// lib/models/static_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

class StaticPage {
  final String id;
  final String title;
  final String content; // Markdown content
  final Timestamp createdAt;
  final Timestamp updatedAt;

  StaticPage(
      {required this.id,
      required this.title,
      required this.content,
      required this.createdAt,
      required this.updatedAt});

  factory StaticPage.fromMap(Map<String, dynamic> map) {
    return StaticPage(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      createdAt: map['createdAt'] as Timestamp,
      updatedAt: map['updatedAt'] as Timestamp,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  StaticPage copyWith({
    String? id,
    String? title,
    String? content,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return StaticPage(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get lastUpdated => DateFormat('dd/MM/yyyy HH:mm')
      .format(updatedAt.toDate()); // Corrected: Already correct
}
