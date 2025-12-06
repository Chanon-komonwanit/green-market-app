// lib/models/return_request.dart
// Return/Refund Request Model - ระบบคืนสินค้า/คืนเงิน

import 'package:cloud_firestore/cloud_firestore.dart';

/// Return Request Status
enum ReturnRequestStatus {
  pending, // รอผู้ขายตรวจสอบ
  approved, // อนุมัติ - รอผู้ซื้อส่งคืน
  rejected, // ปฏิเสธ
  shipped, // ผู้ซื้อส่งสินค้าคืนแล้ว
  received, // ผู้ขายรับสินค้าคืนแล้ว
  refunded, // คืนเงินเรียบร้อย
  cancelled, // ยกเลิกคำขอ
}

/// Return Reason - เหตุผลการคืนสินค้า
enum ReturnReason {
  defective, // สินค้าชำรุด/เสียหาย
  wrongItem, // ส่งสินค้าผิด
  notAsDescribed, // ไม่ตรงตามรายละเอียด
  sizeIssue, // ขนาดไม่พอดี
  qualityIssue, // คุณภาพไม่ดี
  changeOfMind, // เปลี่ยนใจ/ไม่ต้องการแล้ว
  other, // อื่นๆ
}

/// Return Request - คำขอคืนสินค้า/เงิน
class ReturnRequest {
  final String id;
  final String orderId;
  final String orderItemId; // สินค้าที่ต้องการคืน (ถ้าคืนบางรายการ)
  final String buyerId;
  final String sellerId;
  final String productId;
  final String productName;
  final String? productImage;
  final int quantity; // จำนวนที่ต้องการคืน
  final double refundAmount; // จำนวนเงินที่จะคืน
  final ReturnRequestStatus status;
  final ReturnReason reason;
  final String? reasonDetail; // รายละเอียดเพิ่มเติม
  final List<String> imageUrls; // รูปภาพประกอบ (สภาพสินค้า)
  final String? trackingNumber; // เลขพัสดุส่งคืน
  final String? rejectionReason; // เหตุผลที่ปฏิเสธ
  final String? sellerNote; // หมายเหตุจากผู้ขาย
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final Timestamp? approvedAt;
  final Timestamp? refundedAt;

  ReturnRequest({
    required this.id,
    required this.orderId,
    required this.orderItemId,
    required this.buyerId,
    required this.sellerId,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.quantity,
    required this.refundAmount,
    required this.status,
    required this.reason,
    this.reasonDetail,
    this.imageUrls = const [],
    this.trackingNumber,
    this.rejectionReason,
    this.sellerNote,
    this.createdAt,
    this.updatedAt,
    this.approvedAt,
    this.refundedAt,
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
      productImage: map['productImage'],
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      refundAmount: (map['refundAmount'] as num?)?.toDouble() ?? 0.0,
      status: _statusFromString(map['status'] as String?),
      reason: _reasonFromString(map['reason'] as String?),
      reasonDetail: map['reasonDetail'],
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      trackingNumber: map['trackingNumber'],
      rejectionReason: map['rejectionReason'],
      sellerNote: map['sellerNote'],
      createdAt: map['createdAt'] as Timestamp?,
      updatedAt: map['updatedAt'] as Timestamp?,
      approvedAt: map['approvedAt'] as Timestamp?,
      refundedAt: map['refundedAt'] as Timestamp?,
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
      if (productImage != null) 'productImage': productImage,
      'quantity': quantity,
      'refundAmount': refundAmount,
      'status': status.name,
      'reason': reason.name,
      if (reasonDetail != null) 'reasonDetail': reasonDetail,
      'imageUrls': imageUrls,
      if (trackingNumber != null) 'trackingNumber': trackingNumber,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (sellerNote != null) 'sellerNote': sellerNote,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
      if (approvedAt != null) 'approvedAt': approvedAt,
      if (refundedAt != null) 'refundedAt': refundedAt,
    };
  }

  static ReturnRequestStatus _statusFromString(String? status) {
    switch (status) {
      case 'pending':
        return ReturnRequestStatus.pending;
      case 'approved':
        return ReturnRequestStatus.approved;
      case 'rejected':
        return ReturnRequestStatus.rejected;
      case 'shipped':
        return ReturnRequestStatus.shipped;
      case 'received':
        return ReturnRequestStatus.received;
      case 'refunded':
        return ReturnRequestStatus.refunded;
      case 'cancelled':
        return ReturnRequestStatus.cancelled;
      default:
        return ReturnRequestStatus.pending;
    }
  }

  static ReturnReason _reasonFromString(String? reason) {
    switch (reason) {
      case 'defective':
        return ReturnReason.defective;
      case 'wrongItem':
        return ReturnReason.wrongItem;
      case 'notAsDescribed':
        return ReturnReason.notAsDescribed;
      case 'sizeIssue':
        return ReturnReason.sizeIssue;
      case 'qualityIssue':
        return ReturnReason.qualityIssue;
      case 'changeOfMind':
        return ReturnReason.changeOfMind;
      case 'other':
        return ReturnReason.other;
      default:
        return ReturnReason.other;
    }
  }

  /// Status display text
  String get statusText {
    switch (status) {
      case ReturnRequestStatus.pending:
        return 'รอตรวจสอบ';
      case ReturnRequestStatus.approved:
        return 'อนุมัติ - รอส่งคืน';
      case ReturnRequestStatus.rejected:
        return 'ปฏิเสธ';
      case ReturnRequestStatus.shipped:
        return 'ส่งคืนแล้ว';
      case ReturnRequestStatus.received:
        return 'ได้รับสินค้าคืนแล้ว';
      case ReturnRequestStatus.refunded:
        return 'คืนเงินเรียบร้อย';
      case ReturnRequestStatus.cancelled:
        return 'ยกเลิก';
    }
  }

  /// Reason display text
  String get reasonText {
    switch (reason) {
      case ReturnReason.defective:
        return 'สินค้าชำรุด/เสียหาย';
      case ReturnReason.wrongItem:
        return 'ส่งสินค้าผิด';
      case ReturnReason.notAsDescribed:
        return 'ไม่ตรงตามรายละเอียด';
      case ReturnReason.sizeIssue:
        return 'ขนาดไม่พอดี';
      case ReturnReason.qualityIssue:
        return 'คุณภาพไม่ดี';
      case ReturnReason.changeOfMind:
        return 'เปลี่ยนใจ/ไม่ต้องการแล้ว';
      case ReturnReason.other:
        return 'อื่นๆ';
    }
  }

  /// Status color
  int get statusColor {
    switch (status) {
      case ReturnRequestStatus.pending:
        return 0xFFF59E0B; // Orange
      case ReturnRequestStatus.approved:
        return 0xFF3B82F6; // Blue
      case ReturnRequestStatus.rejected:
        return 0xFFEF4444; // Red
      case ReturnRequestStatus.shipped:
        return 0xFF8B5CF6; // Purple
      case ReturnRequestStatus.received:
        return 0xFF06B6D4; // Cyan
      case ReturnRequestStatus.refunded:
        return 0xFF10B981; // Green
      case ReturnRequestStatus.cancelled:
        return 0xFF6B7280; // Gray
    }
  }

  /// Can buyer cancel
  bool get canBuyerCancel {
    return status == ReturnRequestStatus.pending ||
        status == ReturnRequestStatus.approved;
  }

  /// Can seller approve/reject
  bool get canSellerReview {
    return status == ReturnRequestStatus.pending;
  }

  /// Can buyer add tracking
  bool get canAddTracking {
    return status == ReturnRequestStatus.approved && trackingNumber == null;
  }

  /// Can seller confirm received
  bool get canConfirmReceived {
    return status == ReturnRequestStatus.shipped;
  }

  /// Can process refund
  bool get canProcessRefund {
    return status == ReturnRequestStatus.received;
  }

  ReturnRequest copyWith({
    String? id,
    String? orderId,
    String? orderItemId,
    String? buyerId,
    String? sellerId,
    String? productId,
    String? productName,
    String? productImage,
    int? quantity,
    double? refundAmount,
    ReturnRequestStatus? status,
    ReturnReason? reason,
    String? reasonDetail,
    List<String>? imageUrls,
    String? trackingNumber,
    String? rejectionReason,
    String? sellerNote,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    Timestamp? approvedAt,
    Timestamp? refundedAt,
  }) {
    return ReturnRequest(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      orderItemId: orderItemId ?? this.orderItemId,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      quantity: quantity ?? this.quantity,
      refundAmount: refundAmount ?? this.refundAmount,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      reasonDetail: reasonDetail ?? this.reasonDetail,
      imageUrls: imageUrls ?? this.imageUrls,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      sellerNote: sellerNote ?? this.sellerNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      refundedAt: refundedAt ?? this.refundedAt,
    );
  }
}

/// Return Request Statistics
class ReturnRequestStats {
  final int totalRequests;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;
  final int refundedCount;
  final double totalRefundAmount;

  ReturnRequestStats({
    this.totalRequests = 0,
    this.pendingCount = 0,
    this.approvedCount = 0,
    this.rejectedCount = 0,
    this.refundedCount = 0,
    this.totalRefundAmount = 0.0,
  });

  factory ReturnRequestStats.fromRequests(List<ReturnRequest> requests) {
    return ReturnRequestStats(
      totalRequests: requests.length,
      pendingCount:
          requests.where((r) => r.status == ReturnRequestStatus.pending).length,
      approvedCount: requests
          .where((r) => r.status == ReturnRequestStatus.approved)
          .length,
      rejectedCount: requests
          .where((r) => r.status == ReturnRequestStatus.rejected)
          .length,
      refundedCount: requests
          .where((r) => r.status == ReturnRequestStatus.refunded)
          .length,
      totalRefundAmount: requests
          .where((r) => r.status == ReturnRequestStatus.refunded)
          .fold(0.0, (sum, r) => sum + r.refundAmount),
    );
  }
}
