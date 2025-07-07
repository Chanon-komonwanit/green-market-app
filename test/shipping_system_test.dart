// test/shipping_system_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:green_market/models/order.dart' as app_order;
import 'package:green_market/models/order_item.dart';
import 'package:green_market/models/shipping_method.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('Shipping System Tests', () {
    test('Order model should handle shipping fields correctly', () {
      final order = app_order.Order(
        id: 'test-order-123',
        userId: 'user-123',
        orderDate: Timestamp.now(),
        status: 'shipped',
        paymentMethod: 'qr_code',
        totalAmount: 100.0,
        shippingFee: 20.0,
        subTotal: 80.0,
        fullName: 'ผู้ทดสอบ',
        phoneNumber: '0812345678',
        addressLine1: '123 ถนนทดสอบ',
        subDistrict: 'ทดสอบ',
        district: 'ทดสอบ',
        province: 'กรุงเทพมหานคร',
        zipCode: '10100',
        items: [
          OrderItem(
            productId: 'product-123',
            productName: 'สินค้าทดสอบ',
            quantity: 1,
            pricePerUnit: 80.0,
            imageUrl: 'https://example.com/image.jpg',
            ecoScore: 85,
            sellerId: 'seller-123',
          ),
        ],
        sellerIds: ['seller-123'],
        trackingNumber: 'TH123456789',
        trackingUrl: 'https://example.com/track/TH123456789',
        shippingCarrier: 'Kerry Express',
        shippingMethod: 'standard',
        shippedAt: Timestamp.now(),
      );

      expect(order.trackingNumber, 'TH123456789');
      expect(order.shippingCarrier, 'Kerry Express');
      expect(order.shippingMethod, 'standard');
      expect(order.trackingUrl, 'https://example.com/track/TH123456789');
      expect(order.shippedAt, isNotNull);
    });

    test('ShippingMethod model should provide correct default methods', () {
      final standardMethod = ShippingMethod.getDefaultMethods().first;
      expect(standardMethod.id, 'standard_delivery');
      expect(standardMethod.name, 'Standard Delivery');
      expect(standardMethod.estimatedDays, 3);
      expect(standardMethod.cost, 40.0);
      expect(standardMethod.isActive, true);
    });

    test('ShippingMethod should calculate fees correctly', () {
      final methods = ShippingMethod.getDefaultMethods();
      final standardMethod =
          methods.firstWhere((m) => m.id == 'standard_delivery');
      final expressMethod =
          methods.firstWhere((m) => m.id == 'express_delivery');

      expect(standardMethod.cost, 40.0);
      expect(expressMethod.cost, 80.0);
      expect(standardMethod.cost < expressMethod.cost, true);
    });

    test('ShippingMethod should provide correct display information', () {
      final methods = ShippingMethod.getDefaultMethods();
      final codMethod = methods.firstWhere((m) => m.id == 'cod_delivery');

      expect(codMethod.name, 'Cash on Delivery');
      expect(codMethod.description, 'เก็บเงินปลายทาง');
      expect(codMethod.cost, 60.0);
    });
  });
}
