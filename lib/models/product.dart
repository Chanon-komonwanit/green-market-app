// lib/models/product.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/utils/constants.dart';

class Product {
  final String id;
  final String sellerId;
  final String name;
  final String description;
  final double price;
  final List<String> imageUrls;
  final int ecoScore;
  final String materialDescription;
  final String ecoJustification;
  final String? verificationVideoUrl;
  final bool isApproved;
  final String? categoryId;
  final String? categoryName;
  final int? level;
  final Timestamp? createdAt;
  final Timestamp? approvedAt;

  Product({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrls,
    required this.ecoScore,
    required this.materialDescription,
    required this.ecoJustification,
    this.verificationVideoUrl,
    required this.isApproved,
    this.categoryId,
    this.categoryName,
    this.level,
    this.createdAt,
    this.approvedAt,
  });

  EcoLevel get ecoLevel => EcoLevelExtension.fromScore(ecoScore);

  factory Product.fromFirestore(DocumentSnapshot doc) {
    // It's safer to cast to Map<String, dynamic>? and then check for null
    // or handle it if you are sure data will always exist after checking doc.exists in service.
    // However, for robustness within the model, let's assume data might be unexpectedly null.
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      // This case should ideally be handled before calling fromFirestore,
      // e.g., by checking doc.exists in the FirebaseService.
      // Throwing an error here helps identify issues if malformed data reaches this point.
      throw StateError(
          'Failed to parse product from Firestore: data is null for doc ${doc.id}');
    }

    return Product(
      id: doc.id,
      sellerId: data['sellerId'] as String? ?? '',
      name: data['name'] as String? ?? 'Unnamed Product',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      imageUrls: List<String>.from(data['imageUrls'] as List<dynamic>? ?? []),
      ecoScore: data['ecoScore'] as int? ?? 0,
      materialDescription: data['materialDescription'] as String? ?? '',
      ecoJustification: data['ecoJustification'] as String? ?? '',
      verificationVideoUrl: data['verificationVideoUrl'] as String?,
      isApproved: data['isApproved'] as bool? ?? false,
      categoryId: data['categoryId'] as String?,
      categoryName: data['categoryName'] as String?,
      level: data['level'] as int?,
      createdAt:
          data['createdAt'] as Timestamp?, // Firestore Timestamps are nullable
      approvedAt:
          data['approvedAt'] as Timestamp?, // Firestore Timestamps are nullable
    );
  }

  String? get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : null;

  Map<String, dynamic> toFirestore() {
    return {
      'sellerId': sellerId,
      'name': name,
      'description': description,
      'price': price,
      'imageUrls': imageUrls,
      'ecoScore': ecoScore,
      'materialDescription': materialDescription,
      'ecoJustification': ecoJustification,
      'verificationVideoUrl': verificationVideoUrl,
      'isApproved': isApproved,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'level': level,
      'createdAt':
          createdAt ?? FieldValue.serverTimestamp(), // Use existing or set new
      // approvedAt is set by admin during approval or when product is directly approved
      if (isApproved && approvedAt == null)
        'approvedAt': FieldValue.serverTimestamp(),
      if (isApproved && approvedAt != null) 'approvedAt': approvedAt,
    };
  }

  Map<String, dynamic> toFirestoreForUpdate() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrls': imageUrls,
      'ecoScore': ecoScore,
      'materialDescription': materialDescription,
      'ecoJustification': ecoJustification,
      'verificationVideoUrl': verificationVideoUrl,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'level': level,
      'isApproved':
          isApproved, // Allow updating approval status, e.g., when seller edits an approved product
      'updatedAt': FieldValue.serverTimestamp(),
      // If re-approval sets approvedAt to null, then on approval it will be set again
      if (isApproved && approvedAt == null)
        'approvedAt': FieldValue.serverTimestamp(),
      if (!isApproved)
        'approvedAt': null, // Explicitly set to null if not approved
    };
  }
}
