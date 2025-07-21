import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/utils/constants.dart';

class Product {
  // ...fields and constructor remain unchanged...

  // Factory for Firestore DocumentSnapshot
  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product.fromMap({
      ...data,
      'id': doc.id, // Use Firestore doc ID
    });
  }

  // Returns the first image URL or promotional image if available
  String? get imageUrl {
    if (promotionalImageUrl != null && promotionalImageUrl!.isNotEmpty) {
      return promotionalImageUrl;
    }
    if (imageUrls.isNotEmpty) {
      return imageUrls.first;
    }
    return null;
  }

  // Returns the flash sale end time if available (assumes updatedAt is used for flash sale end)
  DateTime? get flashSaleEndTime {
    // If you have a dedicated flashSaleEndTime field, use it here
    // For now, fallback to updatedAt as a placeholder
    return updatedAt?.toDate();
  }

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

  // Additional properties for edit screen
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

    // Additional properties
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
  });

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
    );
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
    };
  }

  // Getter to check if the product is approved based on its status.
  bool get isApproved => status == 'approved';

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
      isFeatured: true,
      averageRating: 4.5,
      reviewCount: 100,
      approvalStatus: 'approved',
    );
  }
}
