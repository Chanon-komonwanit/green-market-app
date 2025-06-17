// lib/models/order.dart
import 'package:cloud_firestore/cloud_firestore.dart'; // สำหรับ Timestamp
import 'package:green_market/models/order_item.dart'; // สำหรับ OrderItem model

class Order {
  final String id; // Order ID (จะถูกสร้างโดย Firestore)
  final String userId;
  final Timestamp orderDate; // วันที่และเวลาที่สั่งซื้อ
  final String
      status; // pending_payment, processing, shipped, delivered, cancelled
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
  final String? note; // หมายเหตุเพิ่มเติม
  final List<OrderItem> items; // รายการสินค้าในคำสั่งซื้อ
  final List<String> sellerIds; // เพิ่ม field นี้
  final String? paymentSlipUrl; // URL ของสลิปการชำระเงิน
  final String? qrCodeImageUrl; // URL ของ QR Code (ถ้ามี)
  final String? trackingNumber; // หมายเลขติดตามพัสดุ
  final String? trackingUrl; // URL สำหรับติดตามพัสดุ

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
    this.note,
    required this.items,
    required this.sellerIds,
    this.paymentSlipUrl,
    this.qrCodeImageUrl,
    this.trackingNumber,
    this.trackingUrl,
  });

  // ใช้สำหรับแปลงจาก Map (ที่มาจาก Firestore) ไปเป็น Order object
  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw StateError(
          'Failed to parse order from Firestore: data is null for doc ${doc.id}');
    }
    final shippingAddress =
        data['shippingAddress'] as Map<String, dynamic>? ?? {};

    return Order(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      orderDate: (data['orderDate'] as Timestamp?) ?? Timestamp.now(),
      status: data['status'] as String? ?? 'unknown',
      paymentMethod: data['paymentMethod'] as String? ?? 'unknown',
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      shippingFee: (data['shippingFee'] as num?)?.toDouble() ?? 0.0,
      subTotal: (data['subTotal'] as num?)?.toDouble() ?? 0.0,
      // Prioritize reading from the nested shippingAddress map
      fullName: shippingAddress['fullName'] as String? ??
          data['fullName'] as String? ??
          '',
      phoneNumber: shippingAddress['phoneNumber'] as String? ??
          data['phoneNumber'] as String? ??
          '',
      addressLine1: shippingAddress['addressLine1'] as String? ??
          data['addressLine1'] as String? ??
          '',
      subDistrict: shippingAddress['subDistrict'] as String? ??
          data['subDistrict'] as String? ??
          '',
      district: shippingAddress['district'] as String? ??
          data['district'] as String? ??
          '',
      province: shippingAddress['province'] as String? ??
          data['province'] as String? ??
          '',
      zipCode: shippingAddress['zipCode'] as String? ??
          data['zipCode'] as String? ??
          '',
      note: shippingAddress['note'] as String? ??
          data['note'] as String?, // Note can also be in shippingAddress
      items: (data['items'] as List<dynamic>?)
              ?.map((itemMap) =>
                  OrderItem.fromMap(itemMap as Map<String, dynamic>))
              .toList() ??
          [], // Default to empty list
      sellerIds: List<String>.from(data['sellerIds'] as List<dynamic>? ?? []),
      paymentSlipUrl: data['paymentSlipUrl'] as String?,
      qrCodeImageUrl: data['qrCodeImageUrl'] as String?,
      trackingNumber: data['trackingNumber'] as String?,
      trackingUrl: data['trackingUrl'] as String?,
    );
  }
  // OPTION 1: Implement the getter to return a formatted address string
  String get fullAddress {
    return '$addressLine1, $subDistrict, $district, $province, $zipCode';
  }
  // OPTION 2: If not used, simply remove the line below.
  // String? get address => null; // Remove this line if not used or implement as above

  // ใช้สำหรับแปลงจาก Order object ไปเป็น Map (เพื่อบันทึกลง Firestore)
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'orderDate': orderDate,
      'status': status,
      'paymentMethod': paymentMethod,
      'totalAmount': totalAmount,
      'shippingFee': shippingFee,
      'subTotal': subTotal,
      'shippingAddress': {
        // เก็บเป็น Map ย่อยใน Firestore
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'addressLine1': addressLine1,
        'subDistrict': subDistrict,
        'district': district,
        'province': province,
        'zipCode': zipCode,
        'note': note,
      },
      'items': items.map((item) => item.toMap()).toList(),
      'sellerIds': sellerIds,
      'paymentSlipUrl':
          paymentSlipUrl, // Will be updated later by payment confirmation
      'qrCodeImageUrl': qrCodeImageUrl, // Might be set during checkout
      'trackingNumber': trackingNumber, // Might be set by seller/admin
      'trackingUrl': trackingUrl, // Might be set by seller/admin
    };
  }
}
