import 'package:cloud_firestore/cloud_firestore.dart';

/// Model สำหรับคูปองส่วนลดขั้นสูง - รองรับ Auto-apply และ Target Products
class AdvancedCoupon {
  final String id;
  final String sellerId;
  final String code;
  final String name;
  final String description;

  // ประเภทและมูลค่าส่วนลด
  final CouponType type;
  final double value;

  // เงื่อนไขการใช้งาน
  final double minPurchase;
  final double maxDiscount;
  final int usageLimit; // 0 = unlimited
  final int usedCount;
  final int perUserLimit; // จำกัดต่อผู้ใช้ 1 คน (0 = unlimited)

  // ช่วงเวลาใช้งาน
  final DateTime? startDate;
  final DateTime? endDate;

  // สถานะ
  final bool isActive;

  // ฟีเจอร์ขั้นสูง
  final bool autoApply; // ใช้อัตโนมัติเมื่อตรงเงื่อนไข
  final CouponTargetType targetType; // all, category, products, newCustomers
  final List<String> targetProductIds; // สินค้าที่กำหนดเฉพาะ
  final List<String> targetCategories; // หมวดหมู่ที่กำหนดเฉพาะ

  final bool requireMinItems; // ต้องซื้อขั้นต่ำ X ชิ้น
  final int minItems;

  final bool stackable; // ใช้ร่วมกับคูปองอื่นได้หรือไม่
  final int priority; // ลำดับความสำคัญ (ใช้เมื่อมีหลายคูปอง auto-apply)

  // ข้อมูลเพิ่มเติม
  final DateTime createdAt;
  final DateTime updatedAt;

  final Map<String, dynamic>? analyticsData; // สถิติการใช้งาน

  AdvancedCoupon({
    required this.id,
    required this.sellerId,
    required this.code,
    required this.name,
    this.description = '',
    required this.type,
    required this.value,
    this.minPurchase = 0,
    this.maxDiscount = 0,
    this.usageLimit = 0,
    this.usedCount = 0,
    this.perUserLimit = 0,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.autoApply = false,
    this.targetType = CouponTargetType.all,
    this.targetProductIds = const [],
    this.targetCategories = const [],
    this.requireMinItems = false,
    this.minItems = 0,
    this.stackable = false,
    this.priority = 0,
    required this.createdAt,
    required this.updatedAt,
    this.analyticsData,
  });

  /// ตรวจสอบว่าคูปองใช้ได้หรือไม่
  bool isValid({DateTime? checkDate}) {
    final now = checkDate ?? DateTime.now();

    // ตรวจสอบสถานะ active
    if (!isActive) return false;

    // ตรวจสอบจำนวนการใช้งาน
    if (usageLimit > 0 && usedCount >= usageLimit) return false;

    // ตรวจสอบช่วงเวลา
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;

    return true;
  }

  /// ตรวจสอบว่าตะกร้าสินค้าตรงเงื่อนไขหรือไม่
  bool canApplyToCart({
    required List<CartItem> cartItems,
    required double subtotal,
  }) {
    if (!isValid()) return false;

    // ตรวจสอบยอดขั้นต่ำ
    if (subtotal < minPurchase) return false;

    // ตรวจสอบจำนวนสินค้าขั้นต่ำ
    if (requireMinItems) {
      final totalItems = cartItems.fold<int>(
        0,
        (sum, item) => sum + item.quantity,
      );
      if (totalItems < minItems) return false;
    }

    // ตรวจสอบว่ามีสินค้าที่ถูก target หรือไม่
    switch (targetType) {
      case CouponTargetType.all:
        return true;

      case CouponTargetType.category:
        return cartItems
            .any((item) => targetCategories.contains(item.product.category));

      case CouponTargetType.products:
        return cartItems
            .any((item) => targetProductIds.contains(item.product.id));

      case CouponTargetType.newCustomers:
        // ต้องตรวจสอบจาก user profile
        return false;
    }
  }

  /// คำนวณส่วนลดที่ได้รับ
  double calculateDiscount({
    required List<CartItem> cartItems,
    required double subtotal,
  }) {
    if (!canApplyToCart(cartItems: cartItems, subtotal: subtotal)) {
      return 0;
    }

    double discount = 0;

    // คำนวณยอดรวมที่ใช้ส่วนลดได้ (เฉพาะสินค้าที่ target)
    double eligibleAmount = subtotal;

    if (targetType != CouponTargetType.all) {
      eligibleAmount = 0;
      for (var item in cartItems) {
        if (_isProductEligible(item.product)) {
          eligibleAmount += item.product.price * item.quantity;
        }
      }
    }

    // คำนวณส่วนลดตามประเภท
    switch (type) {
      case CouponType.percentage:
        discount = eligibleAmount * (value / 100);
        // จำกัดส่วนลดสูงสุด
        if (maxDiscount > 0 && discount > maxDiscount) {
          discount = maxDiscount;
        }
        break;

      case CouponType.fixedAmount:
        discount = value;
        // ไม่เกินยอดที่ซื้อ
        if (discount > eligibleAmount) {
          discount = eligibleAmount;
        }
        break;

      case CouponType.freeShipping:
        // ไม่คำนวณที่นี่ ต้องจัดการที่ shipping screen
        discount = 0;
        break;

      case CouponType.buyXGetY:
        // ต้องมีการคำนวณพิเศษ
        discount = _calculateBuyXGetY(cartItems);
        break;
    }

    return discount;
  }

  bool _isProductEligible(Product product) {
    switch (targetType) {
      case CouponTargetType.all:
        return true;
      case CouponTargetType.category:
        return targetCategories.contains(product.category);
      case CouponTargetType.products:
        return targetProductIds.contains(product.id);
      case CouponTargetType.newCustomers:
        return true; // จัดการแยกต่างหาก
    }
  }

  double _calculateBuyXGetY(List<CartItem> items) {
    // ตัวอย่างง่ายๆ: Buy 2 Get 1 Free (ของที่ถูกที่สุด)
    // ต้องปรับตาม business logic จริง
    double discount = 0;
    // TODO: Implement Buy X Get Y logic
    return discount;
  }

  /// แปลงเป็น Map สำหรับบันทึก Firestore
  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'code': code,
      'name': name,
      'description': description,
      'type': type.name,
      'value': value,
      'minPurchase': minPurchase,
      'maxDiscount': maxDiscount,
      'usageLimit': usageLimit,
      'usedCount': usedCount,
      'perUserLimit': perUserLimit,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isActive': isActive,
      'autoApply': autoApply,
      'targetType': targetType.name,
      'targetProductIds': targetProductIds,
      'targetCategories': targetCategories,
      'requireMinItems': requireMinItems,
      'minItems': minItems,
      'stackable': stackable,
      'priority': priority,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'analyticsData': analyticsData,
    };
  }

  /// สร้าง AdvancedCoupon จาก Map
  factory AdvancedCoupon.fromMap(Map<String, dynamic> map, String id) {
    return AdvancedCoupon(
      id: id,
      sellerId: map['sellerId'] as String,
      code: map['code'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      type: CouponType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CouponType.percentage,
      ),
      value: (map['value'] as num).toDouble(),
      minPurchase: (map['minPurchase'] as num?)?.toDouble() ?? 0,
      maxDiscount: (map['maxDiscount'] as num?)?.toDouble() ?? 0,
      usageLimit: (map['usageLimit'] as int?) ?? 0,
      usedCount: (map['usedCount'] as int?) ?? 0,
      perUserLimit: (map['perUserLimit'] as int?) ?? 0,
      startDate: (map['startDate'] as Timestamp?)?.toDate(),
      endDate: (map['endDate'] as Timestamp?)?.toDate(),
      isActive: map['isActive'] as bool? ?? true,
      autoApply: map['autoApply'] as bool? ?? false,
      targetType: CouponTargetType.values.firstWhere(
        (e) => e.name == map['targetType'],
        orElse: () => CouponTargetType.all,
      ),
      targetProductIds: List<String>.from(map['targetProductIds'] ?? []),
      targetCategories: List<String>.from(map['targetCategories'] ?? []),
      requireMinItems: map['requireMinItems'] as bool? ?? false,
      minItems: (map['minItems'] as int?) ?? 0,
      stackable: map['stackable'] as bool? ?? false,
      priority: (map['priority'] as int?) ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      analyticsData: map['analyticsData'] as Map<String, dynamic>?,
    );
  }

  /// สร้างสำเนาพร้อมแก้ไข
  AdvancedCoupon copyWith({
    String? sellerId,
    String? code,
    String? name,
    String? description,
    CouponType? type,
    double? value,
    double? minPurchase,
    double? maxDiscount,
    int? usageLimit,
    int? usedCount,
    int? perUserLimit,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    bool? autoApply,
    CouponTargetType? targetType,
    List<String>? targetProductIds,
    List<String>? targetCategories,
    bool? requireMinItems,
    int? minItems,
    bool? stackable,
    int? priority,
    DateTime? updatedAt,
    Map<String, dynamic>? analyticsData,
  }) {
    return AdvancedCoupon(
      id: id,
      sellerId: sellerId ?? this.sellerId,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      value: value ?? this.value,
      minPurchase: minPurchase ?? this.minPurchase,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      usageLimit: usageLimit ?? this.usageLimit,
      usedCount: usedCount ?? this.usedCount,
      perUserLimit: perUserLimit ?? this.perUserLimit,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      autoApply: autoApply ?? this.autoApply,
      targetType: targetType ?? this.targetType,
      targetProductIds: targetProductIds ?? this.targetProductIds,
      targetCategories: targetCategories ?? this.targetCategories,
      requireMinItems: requireMinItems ?? this.requireMinItems,
      minItems: minItems ?? this.minItems,
      stackable: stackable ?? this.stackable,
      priority: priority ?? this.priority,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      analyticsData: analyticsData ?? this.analyticsData,
    );
  }
}

// ==================== ENUMS ====================

/// ประเภทคูปอง
enum CouponType {
  percentage, // ลด %
  fixedAmount, // ลดเงินจำนวนคงที่
  freeShipping, // ฟรีค่าจัดส่ง
  buyXGetY, // ซื้อ X แถม Y
}

/// เป้าหมายของคูปอง
enum CouponTargetType {
  all, // สินค้าทั้งหมด
  category, // หมวดหมู่เฉพาะ
  products, // สินค้าเฉพาะ
  newCustomers, // ลูกค้าใหม่เท่านั้น
}

// ==================== HELPER CLASSES ====================

/// สินค้าในตะกร้า (สำหรับการคำนวณ)
class CartItem {
  final Product product;
  final int quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });
}

/// ข้อมูลสินค้าพื้นฐาน
class Product {
  final String id;
  final String name;
  final String category;
  final double price;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
  });
}
