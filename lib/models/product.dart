// lib/models/product.dart
// Enhanced Product model with comprehensive validation and production readiness
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:green_market/utils/constants.dart';

// Enums for better type safety
enum ProductStatus {
  pendingApproval,
  approved,
  rejected,
  outOfStock,
  discontinued
}

enum ProductCondition { new_, likeNew, good, fair, poor }

enum ProductCategory {
  clothing,
  electronics,
  home,
  beauty,
  food,
  books,
  sports,
  toys,
  other
}

// Validation errors for products
enum ProductValidationError {
  emptyName,
  invalidName,
  emptyDescription,
  invalidDescription,
  invalidPrice,
  invalidStock,
  invalidWeight,
  invalidDimensions,
  invalidImageUrls,
  invalidEcoScore,
  emptyMaterialDescription,
  emptyEcoJustification,
  invalidCategory,
}

/// Enhanced Product model with comprehensive validation and type safety
/// Ready for production with proper error handling and business logic
@immutable
class Product {
  final String id;
  final String sellerId;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String categoryId;
  final String? categoryName;
  final List<String> imageUrls;
  final String? promotionalImageUrl;
  final int ecoScore;
  final String materialDescription;
  final String ecoJustification;
  final String? verificationVideoUrl;
  final String status; // e.g., 'pending_approval', 'approved', 'rejected'
  final String? rejectionReason;
  final Timestamp? createdAt;
  final Timestamp? approvedAt;
  final Timestamp? updatedAt;

  // Enhanced properties
  final int stockQuantity;
  final double? weight;
  final String? dimensions;
  final List<String>? keywords;
  final String? condition;
  final bool allowReturns;
  final bool isActive;
  final bool isFeatured;
  final double averageRating;
  final int reviewCount;
  final String approvalStatus;

  // Enhanced metadata for production
  final DateTime? lastStockUpdate;
  final int version; // For optimistic locking
  final Map<String, dynamic>? metadata; // For extensibility
  final bool isDiscounted;
  final double? originalPrice;
  final DateTime? discountEndDate;
  final String? sku; // Stock Keeping Unit
  final List<String>? tags; // For better searchability
  final String? brandName;
  final String? manufacturerCountry;

  // Additional properties for UI features
  final double rating; // Average product rating (0.0 - 5.0)
  final int soldCount; // Total units sold
  final String category; // Category name for display

  // AI Analysis properties
  final int? aiEcoScore; // AI-predicted Eco Score (0-100)
  final String? aiReasoning; // AI's explanation for the score
  final List<String>? aiSuggestions; // AI's improvement suggestions
  final Map<String, double>? aiScoreBreakdown; // Category-wise breakdown
  final String? aiEcoLevel; // champion/excellent/good/standard
  final String? aiConfidence; // high/medium/low
  final bool aiAnalyzed; // Whether AI has analyzed this product
  final Timestamp? aiAnalyzedAt; // When AI analysis was done
  final bool? adminVerified; // Whether admin verified the AI result
  final String? adminFeedback; // Admin's feedback on AI accuracy
  final int? adminApprovedScore; // Final score approved by admin

  // Validation state cache
  late final List<ProductValidationError> _validationErrors;

  Product({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
    this.categoryName,
    required this.imageUrls,
    this.promotionalImageUrl,
    required this.ecoScore,
    required this.materialDescription,
    required this.ecoJustification,
    this.verificationVideoUrl,
    this.status = 'pending_approval',
    this.rejectionReason,
    this.createdAt,
    this.approvedAt,
    this.updatedAt,
    this.stockQuantity = 0,
    this.weight,
    this.dimensions,
    this.keywords,
    this.condition,
    this.allowReturns = false,
    this.isActive = true,
    this.isFeatured = false,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.approvalStatus = 'pending_approval',
    this.lastStockUpdate,
    this.version = 1,
    this.metadata,
    this.isDiscounted = false,
    this.originalPrice,
    this.discountEndDate,
    this.sku,
    this.tags,
    this.brandName,
    this.manufacturerCountry,
    this.rating = 0.0,
    this.soldCount = 0,
    String? category,
    // AI Analysis parameters
    this.aiEcoScore,
    this.aiReasoning,
    this.aiSuggestions,
    this.aiScoreBreakdown,
    this.aiEcoLevel,
    this.aiConfidence,
    this.aiAnalyzed = false,
    this.aiAnalyzedAt,
    this.adminVerified,
    this.adminFeedback,
    this.adminApprovedScore,
  }) : category = category ?? categoryName ?? 'อื่นๆ' {
    // Initialize validation errors using existing validation logic
    _validationErrors = _computeValidationErrors();
  }

  /// Private method to compute validation errors
  List<ProductValidationError> _computeValidationErrors() {
    final errors = <ProductValidationError>[];

    if (name.trim().isEmpty) {
      errors.add(ProductValidationError.emptyName);
    }
    if (name.trim().length < 3) {
      errors.add(ProductValidationError.invalidName);
    }

    if (description.trim().isEmpty) {
      errors.add(ProductValidationError.emptyDescription);
    }
    if (description.trim().length < 10) {
      errors.add(ProductValidationError.invalidDescription);
    }

    if (price <= 0) {
      errors.add(ProductValidationError.invalidPrice);
    }
    if (stock < 0) {
      errors.add(ProductValidationError.invalidStock);
    }

    if (categoryId.trim().isEmpty) {
      errors.add(ProductValidationError.invalidCategory);
    }

    if (ecoScore < 1 || ecoScore > 100) {
      errors.add(ProductValidationError.invalidEcoScore);
    }

    if (materialDescription.trim().isEmpty) {
      errors.add(ProductValidationError.emptyMaterialDescription);
    }
    if (ecoJustification.trim().isEmpty) {
      errors.add(ProductValidationError.emptyEcoJustification);
    }

    if (imageUrls.isEmpty) {
      errors.add(ProductValidationError.invalidImageUrls);
    }

    if (weight != null && weight! < 0) {
      errors.add(ProductValidationError.invalidWeight);
    }

    return errors;
  }

  // Enhanced getters with business logic
  ProductStatus get productStatus {
    switch (status.toLowerCase()) {
      case 'pending_approval':
        return ProductStatus.pendingApproval;
      case 'approved':
        return ProductStatus.approved;
      case 'rejected':
        return ProductStatus.rejected;
      case 'out_of_stock':
        return ProductStatus.outOfStock;
      case 'discontinued':
        return ProductStatus.discontinued;
      default:
        return ProductStatus.pendingApproval;
    }
  }

  ProductCondition get productCondition {
    switch (condition?.toLowerCase()) {
      case 'new':
        return ProductCondition.new_;
      case 'like_new':
        return ProductCondition.likeNew;
      case 'good':
        return ProductCondition.good;
      case 'fair':
        return ProductCondition.fair;
      case 'poor':
        return ProductCondition.poor;
      default:
        return ProductCondition.new_;
    }
  }

  // Validation getters
  bool get isValid => _validationErrors.isEmpty;
  List<ProductValidationError> get validationErrors =>
      List.unmodifiable(_validationErrors);
  bool get hasValidationErrors => _validationErrors.isNotEmpty;

  // Business logic getters
  bool get isAvailable =>
      isActive && stock > 0 && productStatus == ProductStatus.approved;
  bool get isOutOfStock => stock <= 0;
  bool get isPendingApproval => productStatus == ProductStatus.pendingApproval;
  bool get isApproved => productStatus == ProductStatus.approved;
  bool get isRejected => productStatus == ProductStatus.rejected;
  bool get hasDiscount =>
      isDiscounted && originalPrice != null && originalPrice! > price;
  double get discountPercentage =>
      hasDiscount ? ((originalPrice! - price) / originalPrice! * 100) : 0.0;
  bool get isDiscountActive =>
      hasDiscount &&
      (discountEndDate == null || DateTime.now().isBefore(discountEndDate!));

  // Enhanced image handling
  String? get primaryImageUrl {
    if (promotionalImageUrl != null && promotionalImageUrl!.isNotEmpty) {
      return promotionalImageUrl;
    }
    if (imageUrls.isNotEmpty) {
      return imageUrls.first;
    }
    return null;
  }

  // Backward compatibility getter for imageUrl
  String? get imageUrl => primaryImageUrl;

  List<String> get allImageUrls {
    final allImages = <String>[];
    if (promotionalImageUrl != null && promotionalImageUrl!.isNotEmpty) {
      allImages.add(promotionalImageUrl!);
    }
    allImages.addAll(imageUrls);
    return allImages.toSet().toList(); // Remove duplicates
  }

  // Flash sale support
  DateTime? get flashSaleEndTime => discountEndDate;
  bool get isFlashSale => isDiscountActive && discountEndDate != null;

  // Rating and review getters
  bool get hasReviews => reviewCount > 0;
  String get ratingDisplay =>
      hasReviews ? averageRating.toStringAsFixed(1) : 'ไม่มีรีวิว';
  bool get isHighlyRated => averageRating >= 4.0 && reviewCount >= 5;

  factory Product.fromMap(Map<String, dynamic> map) {
    // Handle both 'isApproved' and 'status' fields from Firestore
    final bool isApproved = map['isApproved'] as bool? ?? false;
    final String statusFromMap = map['status'] as String? ??
        (isApproved ? 'approved' : 'pending_approval');

    return Product(
      id: map['id'] as String? ??
          '', // Note: ID should be passed from document ID
      sellerId: map['sellerId'] as String? ?? '',
      name: map['name'] as String? ?? 'Unnamed Product',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      categoryId: map['categoryId'] as String? ?? '',
      categoryName: map['categoryName'] as String?,
      imageUrls: List<String>.from(map['imageUrls'] as List? ?? []),
      promotionalImageUrl: map['promotionalImageUrl'] as String?,
      ecoScore: (map['ecoScore'] as num?)?.toInt() ?? 0,
      materialDescription: map['materialDescription'] as String? ?? '',
      ecoJustification: map['ecoJustification'] as String? ?? '',
      verificationVideoUrl: map['verificationVideoUrl'] as String?,
      status: statusFromMap,
      rejectionReason: map['rejectionReason'] as String?,
      createdAt: map['createdAt'] as Timestamp?,
      approvedAt: map['approvedAt'] as Timestamp?,
      updatedAt: map['updatedAt'] as Timestamp?,

      // Additional properties
      stockQuantity: (map['stockQuantity'] as num?)?.toInt() ??
          (map['stock'] as num?)?.toInt() ??
          0,
      weight: (map['weight'] as num?)?.toDouble(),
      dimensions: map['dimensions'] as String?,
      keywords:
          map['keywords'] != null ? List<String>.from(map['keywords']) : null,
      condition: map['condition'] as String?,
      allowReturns: map['allowReturns'] as bool? ?? false,
      isActive: map['isActive'] as bool? ?? true,
      isFeatured: map['isFeatured'] as bool? ?? false,
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      approvalStatus: map['approvalStatus'] as String? ??
          map['status'] as String? ??
          'pending_approval',
      rating: (map['rating'] as num?)?.toDouble() ??
          (map['averageRating'] as num?)?.toDouble() ??
          0.0,
      soldCount: (map['soldCount'] as num?)?.toInt() ?? 0,
      category: map['category'] as String? ?? map['categoryName'] as String?,
      // AI Analysis fields
      aiEcoScore: (map['aiEcoScore'] as num?)?.toInt(),
      aiReasoning: map['aiReasoning'] as String?,
      aiSuggestions: map['aiSuggestions'] != null
          ? List<String>.from(map['aiSuggestions'] as List)
          : null,
      aiScoreBreakdown: map['aiScoreBreakdown'] != null
          ? Map<String, double>.from(
              (map['aiScoreBreakdown'] as Map).map(
                (key, value) =>
                    MapEntry(key.toString(), (value as num).toDouble()),
              ),
            )
          : null,
      aiEcoLevel: map['aiEcoLevel'] as String?,
      aiConfidence: map['aiConfidence'] as String?,
      aiAnalyzed: map['aiAnalyzed'] as bool? ?? false,
      aiAnalyzedAt: map['aiAnalyzedAt'] as Timestamp?,
      adminVerified: map['adminVerified'] as bool?,
      adminFeedback: map['adminFeedback'] as String?,
      adminApprovedScore: (map['adminApprovedScore'] as num?)?.toInt(),
    );
  }

  /// Creates a Product from Firestore DocumentSnapshot
  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Invalid document data');
    }

    // Add document ID to data
    data['id'] = doc.id;

    return Product.fromMap(data);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sellerId': sellerId,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'imageUrls': imageUrls,
      'promotionalImageUrl': promotionalImageUrl,
      'ecoScore': ecoScore,
      'materialDescription': materialDescription,
      'ecoJustification': ecoJustification,
      'verificationVideoUrl': verificationVideoUrl,
      'status': status,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'approvedAt': approvedAt,

      // Additional properties
      'stockQuantity': stockQuantity,
      'weight': weight,
      'dimensions': dimensions,
      'keywords': keywords,
      'condition': condition,
      'allowReturns': allowReturns,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'approvalStatus': approvalStatus,
      'rating': rating,
      'soldCount': soldCount,
      'category': category,

      // AI Analysis fields
      if (aiEcoScore != null) 'aiEcoScore': aiEcoScore,
      if (aiReasoning != null) 'aiReasoning': aiReasoning,
      if (aiSuggestions != null) 'aiSuggestions': aiSuggestions,
      if (aiScoreBreakdown != null) 'aiScoreBreakdown': aiScoreBreakdown,
      if (aiEcoLevel != null) 'aiEcoLevel': aiEcoLevel,
      if (aiConfidence != null) 'aiConfidence': aiConfidence,
      'aiAnalyzed': aiAnalyzed,
      if (aiAnalyzedAt != null) 'aiAnalyzedAt': aiAnalyzedAt,
      if (adminVerified != null) 'adminVerified': adminVerified,
      if (adminFeedback != null) 'adminFeedback': adminFeedback,
      if (adminApprovedScore != null) 'adminApprovedScore': adminApprovedScore,
    };
  }

  // Getter to derive EcoLevel from the ecoScore.
  EcoLevel get ecoLevel => EcoLevelExtension.fromScore(ecoScore);

  Product copyWith({
    String? id,
    String? sellerId,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? categoryId,
    String? categoryName,
    List<String>? imageUrls,
    String? promotionalImageUrl,
    int? ecoScore,
    String? materialDescription,
    String? ecoJustification,
    String? verificationVideoUrl,
    String? status,
    String? rejectionReason,
    Timestamp? createdAt,
    Timestamp? approvedAt,
    Timestamp? updatedAt,

    // Additional properties
    int? stockQuantity,
    double? weight,
    String? dimensions,
    List<String>? keywords,
    String? condition,
    bool? allowReturns,
    bool? isActive,
    bool? isFeatured,
    double? averageRating,
    int? reviewCount,
    String? approvalStatus,
    double? rating,
    int? soldCount,
    String? category,
    // AI Analysis properties
    int? aiEcoScore,
    String? aiReasoning,
    List<String>? aiSuggestions,
    Map<String, double>? aiScoreBreakdown,
    String? aiEcoLevel,
    String? aiConfidence,
    bool? aiAnalyzed,
    Timestamp? aiAnalyzedAt,
    bool? adminVerified,
    String? adminFeedback,
    int? adminApprovedScore,
  }) {
    return Product(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      imageUrls: imageUrls ?? this.imageUrls,
      promotionalImageUrl: promotionalImageUrl ?? this.promotionalImageUrl,
      ecoScore: ecoScore ?? this.ecoScore,
      materialDescription: materialDescription ?? this.materialDescription,
      ecoJustification: ecoJustification ?? this.ecoJustification,
      verificationVideoUrl: verificationVideoUrl ?? this.verificationVideoUrl,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      updatedAt: updatedAt ?? this.updatedAt,

      // Additional properties
      stockQuantity: stockQuantity ?? this.stockQuantity,
      weight: weight ?? this.weight,
      dimensions: dimensions ?? this.dimensions,
      keywords: keywords ?? this.keywords,
      condition: condition ?? this.condition,
      allowReturns: allowReturns ?? this.allowReturns,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      rating: rating ?? this.rating,
      soldCount: soldCount ?? this.soldCount,
      category: category ?? this.category,
      // AI Analysis properties
      aiEcoScore: aiEcoScore ?? this.aiEcoScore,
      aiReasoning: aiReasoning ?? this.aiReasoning,
      aiSuggestions: aiSuggestions ?? this.aiSuggestions,
      aiScoreBreakdown: aiScoreBreakdown ?? this.aiScoreBreakdown,
      aiEcoLevel: aiEcoLevel ?? this.aiEcoLevel,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      aiAnalyzed: aiAnalyzed ?? this.aiAnalyzed,
      aiAnalyzedAt: aiAnalyzedAt ?? this.aiAnalyzedAt,
      adminVerified: adminVerified ?? this.adminVerified,
      adminFeedback: adminFeedback ?? this.adminFeedback,
      adminApprovedScore: adminApprovedScore ?? this.adminApprovedScore,
    );
  }

  static Product mock() {
    return Product(
      id: 'mock-id',
      sellerId: 'mock-seller',
      name: 'สินค้า Mock',
      description: 'รายละเอียดสินค้า Mock',
      price: 99.0,
      stock: 10,
      categoryId: 'mock-category',
      categoryName: 'หมวดหมู่ Mock',
      imageUrls: [
        'https://via.placeholder.com/150',
        'https://via.placeholder.com/150',
      ],
      promotionalImageUrl: 'https://via.placeholder.com/300x150',
      ecoScore: 5,
      materialDescription: 'วัสดุ Mock',
      ecoJustification: 'Justification Mock',
      verificationVideoUrl: 'https://www.youtube.com/watch?v=mockvideo',
      status: 'approved',
      rejectionReason: null,
      createdAt: Timestamp.now(),
      approvedAt: Timestamp.now(),
      updatedAt: Timestamp.now(),

      // Additional properties
      stockQuantity: 10,
      weight: 1.0,
      dimensions: '10x10x10',
      keywords: ['mock', 'สินค้า', 'ตัวอย่าง'],
      condition: 'ใหม่',
      allowReturns: true,
      isActive: true,
      isFeatured: false,
      averageRating: 4.5,
      reviewCount: 10,
      approvalStatus: 'approved',
      rating: 4.5,
      soldCount: 25,
      category: 'หมวดหมู่ Mock',
    );
  }

  // === VALIDATION METHODS ===

  /// Validates if the product can be purchased
  bool get canBePurchased {
    return isValid && isActive && status == 'approved' && stock > 0;
  }

  /// Validates if the product is low in stock (less than 5 items)
  bool get isLowStock => stock > 0 && stock < 5;

  /// Validates if the product has valid images
  bool get hasValidImages {
    return imageUrls.isNotEmpty &&
        imageUrls.every((url) => url.trim().isNotEmpty);
  }

  // === BUSINESS LOGIC METHODS ===

  /// Gets the product's eco level based on eco score
  EcoLevel get ecoLevelRating {
    if (ecoScore >= 90) return EcoLevel.hero;
    if (ecoScore >= 60) return EcoLevel.premium;
    if (ecoScore >= 40) return EcoLevel.standard;
    return EcoLevel.basic;
  }

  /// Gets the display price with currency formatting
  String get formattedPrice {
    return '฿${price.toStringAsFixed(2)}';
  }

  /// Gets the display stock status
  String get stockStatus {
    if (isOutOfStock) return 'หมดสต็อก';
    if (isLowStock) return 'สต็อกเหลือน้อย';
    return 'มีสินค้า';
  }

  /// Gets the product approval status in Thai
  String get statusInThai {
    switch (status) {
      case 'pending_approval':
        return 'รอการอนุมัติ';
      case 'approved':
        return 'อนุมัติแล้ว';
      case 'rejected':
        return 'ปฏิเสธ';
      case 'suspended':
        return 'ระงับการขาย';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }

  /// Checks if the product is recently created (within 7 days)
  bool get isNew {
    if (createdAt == null) return false;
    final now = DateTime.now();
    final productDate = createdAt!.toDate();
    return now.difference(productDate).inDays <= 7;
  }

  /// Checks if the product is featured and should be highlighted
  bool get shouldBeHighlighted {
    return isFeatured && isActive && status == 'approved';
  }

  /// Gets a safe image URL with fallback
  String get safeImageUrl {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return 'https://via.placeholder.com/400x400.png?text=No+Image';
    }
    return url;
  }

  /// Creates a copy of the product with updated fields
  /// (ใช้ copyWith method ที่มีอยู่แล้วในคลาส)

  /// Converts the product to a JSON map for API communication
  Map<String, dynamic> toJson() {
    return toMap();
  }

  /// Creates a Product from JSON (alias for fromMap)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product.fromMap(json);
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price, stock: $stock, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
