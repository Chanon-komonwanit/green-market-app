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
}
