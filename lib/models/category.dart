import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // For IconData

/// Enhanced Category model with comprehensive features for e-commerce
/// Supports hierarchical categories, icons, caching, and validation
class Category {
  final String id;
  final String name;
  final String imageUrl;
  final String? parentId; // For subcategories
  final IconData? iconData; // Optional icon for UI
  final Timestamp createdAt;
  final bool isActive; // For enabling/disabling categories
  final int sortOrder; // For custom sorting
  final String? description; // Category description
  final Map<String, dynamic> metadata; // Flexible additional data

  Category({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.parentId,
    this.iconData,
    required this.createdAt,
    this.isActive = true,
    this.sortOrder = 0,
    this.description,
    this.metadata = const {},
  });

  /// Validates category data
  bool get isValid {
    return id.isNotEmpty &&
        name.isNotEmpty &&
        name.length >= 2 &&
        name.length <= 100 &&
        imageUrl.isNotEmpty;
  }

  /// Checks if this is a root category (no parent)
  bool get isRootCategory => parentId == null || parentId!.isEmpty;

  /// Gets display name with validation
  String get displayName =>
      name.trim().isEmpty ? 'Unnamed Category' : name.trim();

  // Factory for Firestore DocumentSnapshot with error handling
  factory Category.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Category document data is null');
      }
      return Category.fromMap({
        ...data,
        'id': doc.id,
      });
    } catch (e) {
      // Return default category if parsing fails
      return Category(
        id: doc.id,
        name: 'Error Loading Category',
        imageUrl: 'https://via.placeholder.com/50',
        createdAt: Timestamp.now(),
        isActive: false,
      );
    }
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: (map['id'] as String?)?.trim() ?? '',
      name: (map['name'] as String?)?.trim() ?? 'Unnamed Category',
      imageUrl: (map['imageUrl'] as String?)?.trim() ??
          'https://via.placeholder.com/50',
      parentId: (map['parentId'] as String?)?.trim(),
      iconData: _getIconDataFromCodePoint(map['iconCodePoint']),
      createdAt: (map['createdAt'] as Timestamp?) ?? Timestamp.now(),
      isActive: map['isActive'] as bool? ?? true,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      description: (map['description'] as String?)?.trim(),
      metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name.trim(),
      'imageUrl': imageUrl.trim(),
      'parentId': parentId?.trim(),
      'iconCodePoint': iconData?.codePoint,
      'createdAt': createdAt,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'description': description?.trim(),
      'metadata': metadata,
    };
  }

  /// Convert to Firestore document (excludes id)
  Map<String, dynamic> toFirestore() {
    final map = toMap();
    map.remove('id'); // Firestore handles document ID separately
    return map;
  }

  Category copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? parentId,
    IconData? iconData,
    Timestamp? createdAt,
    bool? isActive,
    int? sortOrder,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      parentId: parentId ?? this.parentId,
      iconData: iconData ?? this.iconData,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          parentId == other.parentId;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ parentId.hashCode;

  @override
  String toString() {
    return 'Category{id: $id, name: $name, parentId: $parentId, isActive: $isActive}';
  }

  /// Enhanced IconData mapping with more comprehensive icon support
  static IconData? _getIconDataFromCodePoint(dynamic codePoint) {
    if (codePoint == null) return null;
    if (codePoint is int) {
      // Extended icon mapping for better UX
      switch (codePoint) {
        case 0xe047:
          return Icons.category;
        case 0xe55b:
          return Icons.shopping_bag;
        case 0xe59d:
          return Icons.restaurant;
        case 0xe30a:
          return Icons.local_grocery_store;
        case 0xe1ac:
          return Icons.eco;
        case 0xe0ba:
          return Icons.computer;
        case 0xe1a3:
          return Icons.smartphone;
        case 0xe439:
          return Icons.sports_soccer;
        case 0xe3f7:
          return Icons.school;
        case 0xe51d:
          return Icons.home;
        case 0xe3fb:
          return Icons.local_hospital;
        case 0xe4c4:
          return Icons.directions_car;
        case 0xe559:
          return Icons.book;
        case 0xe30b:
          return Icons.child_care;
        case 0xe6a1:
          return Icons.pets;
        default:
          return Icons.category; // fallback
      }
    }
    return Icons.category; // fallback
  }

  /// Static method to get icon by category type
  static IconData getIconByType(String categoryType) {
    switch (categoryType.toLowerCase()) {
      case 'electronics':
        return Icons.computer;
      case 'clothing':
        return Icons.shopping_bag;
      case 'food':
        return Icons.restaurant;
      case 'grocery':
        return Icons.local_grocery_store;
      case 'eco':
        return Icons.eco;
      case 'sports':
        return Icons.sports_soccer;
      case 'education':
        return Icons.school;
      case 'home':
        return Icons.home;
      case 'health':
        return Icons.local_hospital;
      case 'automotive':
        return Icons.directions_car;
      case 'books':
        return Icons.book;
      case 'baby':
        return Icons.child_care;
      case 'pets':
        return Icons.pets;
      default:
        return Icons.category;
    }
  }

  /// Validation method for category creation
  static String? validateCategoryData({
    required String name,
    required String imageUrl,
    String? parentId,
  }) {
    if (name.trim().isEmpty) {
      return 'Category name cannot be empty';
    }
    if (name.trim().length < 2) {
      return 'Category name must be at least 2 characters';
    }
    if (name.trim().length > 100) {
      return 'Category name cannot exceed 100 characters';
    }
    if (imageUrl.trim().isEmpty) {
      return 'Category image URL cannot be empty';
    }
    final uri = Uri.tryParse(imageUrl);
    if (uri == null || !uri.hasAbsolutePath) {
      return 'Invalid image URL format';
    }
    return null; // Valid
  }
}
