import 'package:cloud_firestore/cloud_firestore.dart'; // สำหรับ Timestamp
import 'package:green_market/models/order_item.dart'; // สำหรับ OrderItem model (assuming this model exists)

class Order {
  final String id; // Order ID (จะถูกสร้างโดย Firestore)
  final String userId;
  final Timestamp orderDate; // วันที่และเวลาที่สั่งซื้อ
  final String
      status; // pending_payment, processing, shipped, delivered, cancelled, rejected
  final String paymentMethod; // qr_code, cash_on_delivery
  final double totalAmount;
  final double shippingFee;
  final double subTotal;
  final String fullName; // ชื่อ-นามสกุลผู้รับ
  final String phoneNumber;
  final String addressLine1; // ที่อยู่
  final String subDistrict; // แขวง/ตำบล
  final String district; // เขต/อำเภอ
  final String province; // จังหวัด
  final String zipCode; // รหัสไปรษณีย์
  final List<OrderItem> items; // รายการสินค้าในคำสั่งซื้อ
  final List<String> sellerIds; // เพิ่ม field นี้
  final String? note; // หมายเหตุเพิ่มเติม
  final String? paymentSlipUrl; // URL ของสลิปการชำระเงิน
  final String? qrCodeImageUrl; // URL ของ QR Code (ถ้ามี)
  final String? trackingNumber; // หมายเลขติดตามพัสดุ
  final String? trackingUrl; // URL สำหรับติดตามพัสดุ
  final String?
      shippingCarrier; // บริษัทขนส่ง (เช่น Kerry Express, J&T Express)
  final String? shippingMethod; // วิธีการส่ง (เช่น Standard, Express, COD)
  final Timestamp? shippedAt; // วันที่จัดส่ง
  final Timestamp? deliveredAt; // วันที่ส่งถึง
  final Timestamp? updatedAt;

  Order({
    required this.id,
    required this.userId,
    required this.orderDate,
    required this.status,
    required this.paymentMethod,
    required this.totalAmount,
    required this.shippingFee,
    required this.subTotal,
    required this.fullName,
    required this.phoneNumber,
    required this.addressLine1,
    required this.subDistrict,
    required this.district,
    required this.province,
    required this.zipCode,
    required this.items,
    required this.sellerIds,
    this.note,
    this.paymentSlipUrl,
    this.qrCodeImageUrl,
    this.trackingNumber,
    this.trackingUrl,
    this.shippingCarrier,
    this.shippingMethod,
    this.shippedAt,
    this.deliveredAt,
    this.updatedAt,
  });

  // === ENHANCED BUSINESS LOGIC METHODS ===

  /// Comprehensive validation of order data
  bool get isValid {
    return validationErrors.isEmpty;
  }

  /// Get all validation errors for this order
  List<String> get validationErrors {
    final errors = <String>[];

    if (id.trim().isEmpty) errors.add('Order ID is required');
    if (userId.trim().isEmpty) errors.add('User ID is required');
    if (totalAmount <= 0) errors.add('Total amount must be greater than 0');
    if (shippingFee < 0) errors.add('Shipping fee cannot be negative');
    if (subTotal <= 0) errors.add('Subtotal must be greater than 0');
    if (fullName.trim().isEmpty) errors.add('Full name is required');
    if (phoneNumber.trim().isEmpty) errors.add('Phone number is required');
    if (addressLine1.trim().isEmpty) errors.add('Address is required');
    if (subDistrict.trim().isEmpty) errors.add('Sub-district is required');
    if (district.trim().isEmpty) errors.add('District is required');
    if (province.trim().isEmpty) errors.add('Province is required');
    if (zipCode.trim().isEmpty) errors.add('Zip code is required');
    if (items.isEmpty) errors.add('Order must contain at least one item');
    if (sellerIds.isEmpty) errors.add('Order must have at least one seller');
    if (!isValidStatus(status)) errors.add('Invalid order status: $status');
    if (!isValidPaymentMethod(paymentMethod)) {
      errors.add('Invalid payment method: $paymentMethod');
    }

    // Validate phone number format (basic Thai mobile number validation)
    if (!RegExp(r'^[0-9]{10}$')
        .hasMatch(phoneNumber.replaceAll(RegExp(r'[^0-9]'), ''))) {
      errors.add('Invalid phone number format');
    }

    // Validate zip code (Thai zip code is 5 digits)
    if (!RegExp(r'^[0-9]{5}$').hasMatch(zipCode)) {
      errors.add('Zip code must be 5 digits');
    }

    // Validate total amount calculation
    final calculatedTotal = subTotal + shippingFee;
    if ((totalAmount - calculatedTotal).abs() > 0.01) {
      errors.add('Total amount calculation mismatch');
    }

    return errors;
  }

  /// Check if order status is valid
  static bool isValidStatus(String status) {
    const validStatuses = {
      'pending_payment',
      'processing',
      'shipped',
      'delivered',
      'cancelled',
      'rejected'
    };
    return validStatuses.contains(status);
  }

  /// Check if payment method is valid
  static bool isValidPaymentMethod(String method) {
    const validMethods = {'qr_code', 'cash_on_delivery'};
    return validMethods.contains(method);
  }

  /// Check if order can be cancelled
  bool get canBeCancelled {
    const cancellableStatuses = {'pending_payment', 'processing'};
    return cancellableStatuses.contains(status);
  }

  /// Check if order can be shipped
  bool get canBeShipped {
    return status == 'processing';
  }

  /// Check if order can be delivered
  bool get canBeDelivered {
    return status == 'shipped';
  }

  /// Check if order is in final status
  bool get isFinalized {
    const finalStatuses = {'delivered', 'cancelled', 'rejected'};
    return finalStatuses.contains(status);
  }

  /// Check if payment is required
  bool get requiresPayment {
    return status == 'pending_payment';
  }

  /// Check if payment is cash on delivery
  bool get isCashOnDelivery {
    return paymentMethod == 'cash_on_delivery';
  }

  /// Check if payment is QR code
  bool get isQRPayment {
    return paymentMethod == 'qr_code';
  }

  /// Get order status in Thai
  String get statusInThai {
    switch (status) {
      case 'pending_payment':
        return 'รอการชำระเงิน';
      case 'processing':
        return 'กำลังเตรียมสินค้า';
      case 'shipped':
        return 'จัดส่งแล้ว';
      case 'delivered':
        return 'จัดส่งสำเร็จ';
      case 'cancelled':
        return 'ยกเลิกแล้ว';
      case 'rejected':
        return 'ถูกปฏิเสธ';
      default:
        return 'สถานะไม่ทราบ';
    }
  }

  /// Get payment method in Thai
  String get paymentMethodInThai {
    switch (paymentMethod) {
      case 'qr_code':
        return 'โอนเงินผ่าน QR Code';
      case 'cash_on_delivery':
        return 'เก็บเงินปลายทาง';
      default:
        return 'ไม่ระบุ';
    }
  }

  /// Calculate total eco score for this order
  double get totalEcoScore {
    if (items.isEmpty) return 0.0;
    double totalScore = 0.0;
    for (final item in items) {
      totalScore += item.ecoScore * item.quantity;
    }
    return totalScore /
        items.fold<int>(0, (total, item) => total + item.quantity);
  }

  /// Get order age in days
  int get ageInDays {
    return DateTime.now().difference(orderDate.toDate()).inDays;
  }

  /// Check if order is overdue (more than 7 days in pending_payment)
  bool get isOverdue {
    return status == 'pending_payment' && ageInDays > 7;
  }

  /// Get formatted total amount
  String get formattedTotalAmount {
    return '฿${totalAmount.toStringAsFixed(2)}';
  }

  /// Get formatted shipping fee
  String get formattedShippingFee {
    return '฿${shippingFee.toStringAsFixed(2)}';
  }

  /// Get formatted subtotal
  String get formattedSubTotal {
    return '฿${subTotal.toStringAsFixed(2)}';
  }

  /// Get total quantity of items
  int get totalQuantity {
    return items.fold<int>(0, (total, item) => total + item.quantity);
  }

  /// Check if order has tracking information
  bool get hasTracking {
    return trackingNumber != null && trackingNumber!.isNotEmpty;
  }

  /// Get estimated delivery date (7 days from order date)
  DateTime? get estimatedDeliveryDate {
    if (status == 'delivered' && deliveredAt != null) {
      return deliveredAt!.toDate();
    }
    return orderDate.toDate().add(const Duration(days: 7));
  }

  // Factory for Firestore DocumentSnapshot
  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Order.fromMap({
      ...data,
      'id': doc.id, // Use Firestore doc ID
    });
  }

  // Getter for total (for PaymentScreen compatibility)
  double get total => totalAmount;

  // ใช้สำหรับแปลงจาก Map (ที่มาจาก Firestore) ไปเป็น Order object
  factory Order.fromMap(Map<String, dynamic> data) {
    return Order(
      id: data['id'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      orderDate: (data['orderDate'] as Timestamp?) ?? Timestamp.now(),
      status: data['status'] as String? ?? 'unknown',
      paymentMethod: data['paymentMethod'] as String? ?? 'unknown',
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      shippingFee: (data['shippingFee'] as num?)?.toDouble() ?? 0.0,
      subTotal: (data['subTotal'] as num?)?.toDouble() ?? 0.0,
      fullName: data['fullName'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      addressLine1: data['addressLine1'] as String? ?? '',
      subDistrict: data['subDistrict'] as String? ?? '',
      district: data['district'] as String? ?? '',
      province: data['province'] as String? ?? '',
      zipCode: data['zipCode'] as String? ?? '',
      note: data['note'] as String?,
      items: (data['items'] as List<dynamic>?)
              ?.map(
                (itemMap) => OrderItem.fromMap(itemMap as Map<String, dynamic>),
              )
              .toList() ??
          [], // Default to empty list
      sellerIds: List<String>.from(data['sellerIds'] as List<dynamic>? ?? []),
      paymentSlipUrl: data['paymentSlipUrl'] as String?,
      qrCodeImageUrl: data['qrCodeImageUrl'] as String?,
      trackingNumber: data['trackingNumber'] as String?,
      trackingUrl: data['trackingUrl'] as String?,
      shippingCarrier: data['shippingCarrier'] as String?,
      shippingMethod: data['shippingMethod'] as String?,
      shippedAt: data['shippedAt'] as Timestamp?,
      deliveredAt: data['deliveredAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }
  // OPTION 1: Implement the getter to return a formatted address string
  String get fullAddress {
    return '$addressLine1, $subDistrict, $district, $province, $zipCode';
  }

  // ใช้สำหรับแปลงจาก Order object ไปเป็น Map (เพื่อบันทึกลง Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'orderDate': orderDate,
      'status': status,
      'paymentMethod': paymentMethod,
      'totalAmount': totalAmount,
      'shippingFee': shippingFee,
      'subTotal': subTotal,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'addressLine1': addressLine1,
      'subDistrict': subDistrict,
      'district': district,
      'province': province,
      'zipCode': zipCode,
      'note': note,
      'items': items.map((item) => item.toMap()).toList(),
      'sellerIds': sellerIds,
      'paymentSlipUrl':
          paymentSlipUrl, // Will be updated later by payment confirmation
      'qrCodeImageUrl': qrCodeImageUrl,
      'trackingNumber': trackingNumber, // Might be set by seller/admin
      'trackingUrl': trackingUrl, // Might be set by seller/admin
      'shippingCarrier': shippingCarrier, // บริษัทขนส่ง
      'shippingMethod': shippingMethod, // วิธีการส่ง
      'shippedAt': shippedAt, // วันที่จัดส่ง
      'deliveredAt': deliveredAt, // วันที่ส่งถึง
      'updatedAt': updatedAt,
    };
  }

  Order copyWith({
    String? id,
    String? userId,
    Timestamp? orderDate,
    String? status,
    String? paymentMethod,
    double? totalAmount,
    double? shippingFee,
    double? subTotal,
    String? fullName,
    String? phoneNumber,
    String? addressLine1,
    String? subDistrict,
    String? district,
    String? province,
    String? zipCode,
    String? note,
    List<OrderItem>? items,
    List<String>? sellerIds,
    String? paymentSlipUrl,
    String? qrCodeImageUrl,
    String? trackingNumber,
    String? trackingUrl,
    String? shippingCarrier,
    String? shippingMethod,
    Timestamp? shippedAt,
    Timestamp? deliveredAt,
    Timestamp? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      orderDate: orderDate ?? this.orderDate,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      totalAmount: totalAmount ?? this.totalAmount,
      shippingFee: shippingFee ?? this.shippingFee,
      subTotal: subTotal ?? this.subTotal,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      addressLine1: addressLine1 ?? this.addressLine1,
      subDistrict: subDistrict ?? this.subDistrict,
      district: district ?? this.district,
      province: province ?? this.province,
      zipCode: zipCode ?? this.zipCode,
      note: note ?? this.note,
      items: items ?? this.items,
      sellerIds: sellerIds ?? this.sellerIds,
      paymentSlipUrl: paymentSlipUrl ?? this.paymentSlipUrl,
      qrCodeImageUrl: qrCodeImageUrl ?? this.qrCodeImageUrl,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      trackingUrl: trackingUrl ?? this.trackingUrl,
      shippingCarrier: shippingCarrier ?? this.shippingCarrier,
      shippingMethod: shippingMethod ?? this.shippingMethod,
      shippedAt: shippedAt ?? this.shippedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // === ENHANCED UTILITY METHODS ===

  @override
  String toString() {
    return 'Order(id: $id, userId: $userId, status: $status, '
        'totalAmount: $formattedTotalAmount, orderDate: ${orderDate.toDate()}, '
        'items: ${items.length}, sellers: ${sellerIds.length})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Order &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId;

  @override
  int get hashCode => id.hashCode ^ userId.hashCode;

  /// Create a JSON representation for debugging
  Map<String, dynamic> toDebugJson() {
    return {
      'id': id,
      'status': status,
      'statusThai': statusInThai,
      'totalAmount': formattedTotalAmount,
      'itemCount': items.length,
      'sellerCount': sellerIds.length,
      'isValid': isValid,
      'canBeCancelled': canBeCancelled,
      'hasTracking': hasTracking,
      'ageInDays': ageInDays,
      'validationErrors': validationErrors,
    };
  }
}
