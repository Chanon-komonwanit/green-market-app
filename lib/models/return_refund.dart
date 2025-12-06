// lib/models/return_refund.dart
// Return & Refund Models - ระบบคืนสินค้าและคืนเงิน

import 'package:cloud_firestore/cloud_firestore.dart';

/// Return Request - คำขอคืนสินค้า
class ReturnRequest {
  final String id;
  final String orderId;
  final String orderItemId; // รายการสินค้าที่ต้องการคืน
  final String buyerId;
  final String sellerId;
  final String productId;
  final String productName;
  final String? productImageUrl;
  final int quantity;
  final double amount; // จำนวนเงินที่จะคืน
  
  final String reason; // สาเหตุการคืนสินค้า
  final String description; // รายละเอียดเพิ่มเติม
  final List<String> imageUrls; // รูปภาพประกอบ
  
  final String status; // pending, approved, rejected, completed, cancelled
  final String? rejectionReason; // เหตุผลที่ปฏิเสธ
  
  final Timestamp? requestedAt;
  final Timestamp? respondedAt;
  final Timestamp? completedAt;
  
  // Tracking Info
  final String? trackingNumber; // หมายเลขพัสดุส่งคืน
  final String? shippingCarrier; // ขนส่ง
  
  ReturnRequest({
    required this.id,
    required this.orderId,
    required this.orderItemId,
    required this.buyerId,
    required this.sellerId,
    required this.productId,
    required this.productName,
    this.productImageUrl,
    required this.quantity,
    required this.amount,
    required this.reason,
    required this.description,
    this.imageUrls = const [],
    this.status = 'pending',
    this.rejectionReason,
    this.requestedAt,
    this.respondedAt,
    this.completedAt,
    this.trackingNumber,
    this.shippingCarrier,
  });

  factory ReturnRequest.fromMap(Map<String, dynamic> map) {
    return ReturnRequest(
      id: map['id'] ?? '',
      orderId: map['orderId'] ?? '',
      orderItemId: map['orderItemId'] ?? '',
      buyerId: map['buyerId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImageUrl: map['productImageUrl'],
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      reason: map['reason'] ?? '',
      description: map['description'] ?? '',
      imageUrls: (map['imageUrls'] as List?)?.cast<String>() ?? [],
      status: map['status'] ?? 'pending',
      rejectionReason: map['rejectionReason'],
      requestedAt: map['requestedAt'] as Timestamp?,
      respondedAt: map['respondedAt'] as Timestamp?,
      completedAt: map['completedAt'] as Timestamp?,
      trackingNumber: map['trackingNumber'],
      shippingCarrier: map['shippingCarrier'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'orderItemId': orderItemId,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'productId': productId,
      'productName': productName,
      if (productImageUrl != null) 'productImageUrl': productImageUrl,
      'quantity': quantity,
      'amount': amount,
      'reason': reason,
      'description': description,
      'imageUrls': imageUrls,
      'status': status,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      'requestedAt': requestedAt ?? FieldValue.serverTimestamp(),
      if (respondedAt != null) 'respondedAt': respondedAt,
      if (completedAt != null) 'completedAt': completedAt,
      if (trackingNumber != null) 'trackingNumber': trackingNumber,
      if (shippingCarrier != null) 'shippingCarrier': shippingCarrier,
    };
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return 'รอตรวจสอบ';
      case 'approved':
        return 'อนุมัติแล้ว';
      case 'rejected':
        return 'ปฏิเสธ';
      case 'completed':
        return 'คืนเงินแล้ว';
      case 'cancelled':
        return 'ยกเลิก';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }

  ReturnRequest copyWith({
    String? id,
    String? orderId,
    String? orderItemId,
    String? buyerId,
    String? sellerId,
    String? productId,
    String? productName,
    String? productImageUrl,
    int? quantity,
    double? amount,
    String? reason,
    String? description,
    List<String>? imageUrls,
    String? status,
    String? rejectionReason,
    Timestamp? requestedAt,
    Timestamp? respondedAt,
    Timestamp? completedAt,
    String? trackingNumber,
    String? shippingCarrier,
  }) {
    return ReturnRequest(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      orderItemId: orderItemId ?? this.orderItemId,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      quantity: quantity ?? this.quantity,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      requestedAt: requestedAt ?? this.requestedAt,
      respondedAt: respondedAt ?? this.respondedAt,
      completedAt: completedAt ?? this.completedAt,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      shippingCarrier: shippingCarrier ?? this.shippingCarrier,
    );
  }
}

/// Refund Transaction - ธุรกรรมคืนเงิน
class RefundTransaction {
  final String id;
  final String returnRequestId;
  final String orderId;
  final String buyerId;
  final String sellerId;
  final double amount;
  final String method; // wallet, original_payment
  final String status; // pending, completed, failed
  final Timestamp? processedAt;
  final String? failureReason;

  RefundTransaction({
    required this.id,
    required this.returnRequestId,
    required this.orderId,
    required this.buyerId,
    required this.sellerId,
    required this.amount,
    this.method = 'wallet',
    this.status = 'pending',
    this.processedAt,
    this.failureReason,
  });

  factory RefundTransaction.fromMap(Map<String, dynamic> map) {
    return RefundTransaction(
      id: map['id'] ?? '',
      returnRequestId: map['returnRequestId'] ?? '',
      orderId: map['orderId'] ?? '',
      buyerId: map['buyerId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      method: map['method'] ?? 'wallet',
      status: map['status'] ?? 'pending',
      processedAt: map['processedAt'] as Timestamp?,
      failureReason: map['failureReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'returnRequestId': returnRequestId,
      'orderId': orderId,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'amount': amount,
      'method': method,
      'status': status,
      if (processedAt != null) 'processedAt': processedAt,
      if (failureReason != null) 'failureReason': failureReason,
    };
  }
}

/// Return Reasons - เหตุผลการคืนสินค้า
class ReturnReasons {
  static const List<Map<String, String>> reasons = [
    {'value': 'wrong_item', 'label': 'ได้รับสินค้าผิด'},
    {'value': 'defective', 'label': 'สินค้าชำรุด/เสียหาย'},
    {'value': 'not_as_described', 'label': 'สินค้าไม่ตรงตามที่อธิบาย'},
    {'value': 'missing_parts', 'label': 'สินค้าขาดชิ้นส่วน'},
    {'value': 'quality_issue', 'label': 'คุณภาพไม่ดี'},
    {'value': 'changed_mind', 'label': 'เปลี่ยนใจ/ไม่ต้องการแล้ว'},
    {'value': 'late_delivery', 'label': 'ได้รับช้าเกินไป'},
    {'value': 'other', 'label': 'อื่นๆ'},
  ];

  static String getLabel(String value) {
    final reason = reasons.firstWhere(
      (r) => r['value'] == value,
      orElse: () => {'value': value, 'label': 'อื่นๆ'},
    );
    return reason['label']!;
  }
}
