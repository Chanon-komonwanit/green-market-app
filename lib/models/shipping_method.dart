// lib/models/shipping_method.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ShippingMethod {
  final String id;
  final String name;
  final String description;
  final String carrier; // บริษัทขนส่ง
  final double cost;
  final int estimatedDays;
  final bool supportsCOD; // รองรับเก็บเงินปลายทาง
  final bool isActive;
  final String? iconUrl;
  final List<String> availableRegions; // พื้นที่ที่ส่งได้

  ShippingMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.carrier,
    required this.cost,
    required this.estimatedDays,
    this.supportsCOD = false,
    this.isActive = true,
    this.iconUrl,
    this.availableRegions = const [],
  });

  factory ShippingMethod.fromMap(Map<String, dynamic> data, String documentId) {
    return ShippingMethod(
      id: documentId,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      carrier: data['carrier'] as String? ?? '',
      cost: (data['cost'] as num?)?.toDouble() ?? 0.0,
      estimatedDays: data['estimatedDays'] as int? ?? 3,
      supportsCOD: data['supportsCOD'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
      iconUrl: data['iconUrl'] as String?,
      availableRegions:
          List<String>.from(data['availableRegions'] as List? ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'carrier': carrier,
      'cost': cost,
      'estimatedDays': estimatedDays,
      'supportsCOD': supportsCOD,
      'isActive': isActive,
      'iconUrl': iconUrl,
      'availableRegions': availableRegions,
    };
  }

  String get deliveryTimeText {
    if (estimatedDays == 1) {
      return 'ส่งภายใน 1 วัน';
    } else if (estimatedDays <= 3) {
      return 'ส่งภายใน $estimatedDays วัน';
    } else {
      return 'ส่งภายใน $estimatedDays วัน';
    }
  }

  String get costText {
    return cost == 0 ? 'ฟรี' : '฿${cost.toStringAsFixed(0)}';
  }

  // Predefined shipping methods (เหมือน Shopee)
  static List<ShippingMethod> getDefaultMethods() {
    return [
      ShippingMethod(
        id: 'standard_delivery',
        name: 'Standard Delivery',
        description: 'ส่งปกติ ประหยัด',
        carrier: 'Kerry Express',
        cost: 40,
        estimatedDays: 3,
        supportsCOD: true,
        availableRegions: ['กรุงเทพฯ', 'ปริมณฑล', 'ต่างจังหวัด'],
      ),
      ShippingMethod(
        id: 'express_delivery',
        name: 'Express Delivery',
        description: 'ส่งด่วน รวดเร็ว',
        carrier: 'J&T Express',
        cost: 80,
        estimatedDays: 1,
        supportsCOD: true,
        availableRegions: ['กรุงเทพฯ', 'ปริมณฑล'],
      ),
      ShippingMethod(
        id: 'free_shipping',
        name: 'Free Shipping',
        description: 'ฟรีค่าส่ง (สำหรับสินค้าครบ 500 บาท)',
        carrier: 'ไปรษณีย์ไทย',
        cost: 0,
        estimatedDays: 5,
        supportsCOD: false,
        availableRegions: ['ทั่วประเทศ'],
      ),
      ShippingMethod(
        id: 'cod_delivery',
        name: 'Cash on Delivery',
        description: 'เก็บเงินปลายทาง',
        carrier: 'Flash Express',
        cost: 60,
        estimatedDays: 2,
        supportsCOD: true,
        availableRegions: ['กรุงเทพฯ', 'ปริมณฑล', 'ต่างจังหวัด'],
      ),
    ];
  }
}
