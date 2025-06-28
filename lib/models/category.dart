// lib/models/category.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // For IconData

class Category {
  final String id;
  final String name;
  final String imageUrl;
  final String? parentId; // For subcategories
  final IconData? iconData; // Optional icon for UI
  final Timestamp createdAt;

  Category({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.parentId,
    this.iconData,
    required this.createdAt,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unnamed Category',
      imageUrl: map['imageUrl'] as String? ??
          'https://via.placeholder.com/50', // Provide default
      parentId: map['parentId'] as String?,
      iconData: map['iconCodePoint'] != null
          ? IconData(map['iconCodePoint'] as int, fontFamily: 'MaterialIcons')
          : null,
      createdAt: (map['createdAt'] as Timestamp?) ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'parentId': parentId,
      'iconCodePoint': iconData?.codePoint, // Store codePoint for IconData
      'createdAt': createdAt,
    };
  }

  Category copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? parentId,
    IconData? iconData,
    Timestamp? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      parentId: parentId ?? this.parentId,
      iconData: iconData ?? this.iconData,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
