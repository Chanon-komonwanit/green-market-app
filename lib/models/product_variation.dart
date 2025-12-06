// lib/models/product_variation.dart
// Product Variations Model - สินค้าหลายตัวเลือก (Size, Color, etc.)

import 'package:cloud_firestore/cloud_firestore.dart';

/// ตัวเลือกสินค้า (เช่น Size, Color, Material)
class ProductVariationOption {
  final String name; // "Size", "Color", "Material"
  final List<String> values; // ["S", "M", "L"] หรือ ["Red", "Blue", "Green"]
  final List<String>? imageUrls; // รูปภาพตามแต่ละค่า (optional)

  ProductVariationOption({
    required this.name,
    required this.values,
    this.imageUrls,
  });

  factory ProductVariationOption.fromMap(Map<String, dynamic> map) {
    return ProductVariationOption(
      name: map['name'] ?? '',
      values: List<String>.from(map['values'] ?? []),
      imageUrls:
          map['imageUrls'] != null ? List<String>.from(map['imageUrls']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'values': values,
      if (imageUrls != null) 'imageUrls': imageUrls,
    };
  }
}

/// รูปแบบสินค้าแต่ละแบบ (Variation)
class ProductVariation {
  final String id;
  final String productId;
  final Map<String, String> attributes; // {"Size": "M", "Color": "Red"}
  final double price;
  final int stock;
  final String? sku; // Stock Keeping Unit
  final String? imageUrl; // รูปภาพของ variation นี้
  final bool isActive;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  ProductVariation({
    required this.id,
    required this.productId,
    required this.attributes,
    required this.price,
    required this.stock,
    this.sku,
    this.imageUrl,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductVariation.fromMap(Map<String, dynamic> map) {
    return ProductVariation(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      attributes: Map<String, String>.from(map['attributes'] ?? {}),
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      sku: map['sku'],
      imageUrl: map['imageUrl'],
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] as Timestamp?,
      updatedAt: map['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'attributes': attributes,
      'price': price,
      'stock': stock,
      if (sku != null) 'sku': sku,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }

  ProductVariation copyWith({
    String? id,
    String? productId,
    Map<String, String>? attributes,
    double? price,
    int? stock,
    String? sku,
    String? imageUrl,
    bool? isActive,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return ProductVariation(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      attributes: attributes ?? this.attributes,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      sku: sku ?? this.sku,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// ตรวจสอบว่าสินค้ามีสต็อกหรือไม่
  bool get hasStock => stock > 0 && isActive;

  /// สถานะสต็อก
  String get stockStatus {
    if (!isActive) return 'ปิดขาย';
    if (stock == 0) return 'หมดสต็อก';
    if (stock < 10) return 'สต็อกเหลือน้อย';
    return 'มีสินค้า';
  }

  /// แสดง attributes เป็นข้อความ
  String get attributesDisplay {
    return attributes.entries.map((e) => '${e.key}: ${e.value}').join(', ');
  }
}

/// Product With Variations - สินค้าที่มี variations
class ProductWithVariations {
  final String productId;
  final List<ProductVariationOption> options; // ตัวเลือกที่มี (Size, Color)
  final List<ProductVariation> variations; // Variations ทั้งหมด
  final bool hasVariations; // มี variations หรือไม่

  ProductWithVariations({
    required this.productId,
    required this.options,
    required this.variations,
  }) : hasVariations = variations.isNotEmpty;

  factory ProductWithVariations.fromMap(Map<String, dynamic> map) {
    return ProductWithVariations(
      productId: map['productId'] ?? '',
      options: (map['options'] as List?)
              ?.map((o) => ProductVariationOption.fromMap(o))
              .toList() ??
          [],
      variations: (map['variations'] as List?)
              ?.map((v) => ProductVariation.fromMap(v))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'options': options.map((o) => o.toMap()).toList(),
      'variations': variations.map((v) => v.toMap()).toList(),
    };
  }

  /// ค้นหา variation จาก attributes
  ProductVariation? findVariation(Map<String, String> selectedAttributes) {
    return variations.firstWhere(
      (v) => _attributesMatch(v.attributes, selectedAttributes),
      orElse: () => variations.first,
    );
  }

  bool _attributesMatch(Map<String, String> attr1, Map<String, String> attr2) {
    if (attr1.length != attr2.length) return false;
    for (var key in attr1.keys) {
      if (attr1[key] != attr2[key]) return false;
    }
    return true;
  }

  /// จำนวนสต็อกรวม
  int get totalStock => variations.fold(0, (sum, v) => sum + v.stock);

  /// ราคาต่ำสุด
  double get minPrice {
    if (variations.isEmpty) return 0;
    return variations.map((v) => v.price).reduce((a, b) => a < b ? a : b);
  }

  /// ราคาสูงสุด
  double get maxPrice {
    if (variations.isEmpty) return 0;
    return variations.map((v) => v.price).reduce((a, b) => a > b ? a : b);
  }

  /// แสดงช่วงราคา
  String get priceRange {
    if (variations.isEmpty) return '฿0';
    if (minPrice == maxPrice) {
      return '฿${minPrice.toStringAsFixed(2)}';
    }
    return '฿${minPrice.toStringAsFixed(2)} - ฿${maxPrice.toStringAsFixed(2)}';
  }

  /// จำนวน variations ทั้งหมด
  int get variationCount => variations.length;

  /// จำนวน variations ที่มีสต็อก
  int get availableVariationCount => variations.where((v) => v.hasStock).length;
}

/// Variation Selector - สำหรับเลือก Variation ในหน้า Product Detail
class VariationSelection {
  final Map<String, String> selectedAttributes;
  final ProductVariation? selectedVariation;

  VariationSelection({
    this.selectedAttributes = const {},
    this.selectedVariation,
  });

  VariationSelection copyWith({
    Map<String, String>? selectedAttributes,
    ProductVariation? selectedVariation,
  }) {
    return VariationSelection(
      selectedAttributes: selectedAttributes ?? this.selectedAttributes,
      selectedVariation: selectedVariation ?? this.selectedVariation,
    );
  }

  /// ตรวจสอบว่าเลือกครบหรือยัง
  bool isComplete(List<ProductVariationOption> options) {
    return options
        .every((option) => selectedAttributes.containsKey(option.name));
  }
}
