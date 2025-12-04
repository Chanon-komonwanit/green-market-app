// test/shipping_integration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:green_market/models/order.dart' as app_order;
import 'package:green_market/models/order_item.dart';
import 'package:green_market/models/shipping_method.dart';
import 'package:green_market/services/shipping/shipping_service_manager.dart';
import 'package:green_market/services/shipping/manual_shipping_provider.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ใช้วิธี stub แทน Mock เพื่อหลีกเลี่ยงปัญหา sealed classes
class TestFirebaseService implements FirebaseService {
  final Map<String, Map<String, dynamic>> _mockData = {};
  final Map<String, List<Map<String, dynamic>>> _trackingEvents = {};

  TestFirebaseService() {
    // Initialize with test data
    _mockData['sellers/seller-123'] = {
      'shopName': 'Test Shop',
      'phoneNumber': '0812345678',
      'address': '123 Test St',
      'subDistrict': 'Test',
      'district': 'Test',
      'province': 'Bangkok',
      'zipCode': '10100',
    };
  }

  @override
  Future<Map<String, dynamic>?> getSellerData(String sellerId) async {
    return _mockData['sellers/$sellerId'];
  }

  @override
  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    return _mockData['orders/$orderId'];
  }

  @override
  Future<void> updateOrderShippingInfo(
      String orderId, Map<String, dynamic> shippingInfo) async {
    if (_mockData['orders/$orderId'] == null) {
      _mockData['orders/$orderId'] = {};
    }
    _mockData['orders/$orderId']!['shippingInfo'] = shippingInfo;
  }

  @override
  Future<bool> addTrackingEvent(
      String trackingNumber, Map<String, dynamic> eventData) async {
    if (_trackingEvents[trackingNumber] == null) {
      _trackingEvents[trackingNumber] = [];
    }
    _trackingEvents[trackingNumber]!.add(eventData);
    return true;
  }

  @override
  Future<List<Map<String, dynamic>>> getTrackingEvents(
      String trackingNumber) async {
    return _trackingEvents[trackingNumber] ?? [];
  }

  @override
  Future<void> updateOrderStatusInstance(String orderId, String status) async {
    if (_mockData['orders/$orderId'] == null) {
      _mockData['orders/$orderId'] = {};
    }
    _mockData['orders/$orderId']!['status'] = status;
  }

  Map<String, dynamic>? getData(String path) => _mockData[path];

  // Implement other methods
  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value();
}

void main() {
  group('Shipping Integration Tests', () {
    late ShippingServiceManager shippingManager;
    late TestFirebaseService testFirebaseService;

    setUp(() {
      testFirebaseService = TestFirebaseService();
      shippingManager = ShippingServiceManager();
    });

    test('Complete shipping workflow should work end-to-end', () async {
      // Create a test order
      final order = app_order.Order(
        id: 'test-order-123',
        userId: 'user-123',
        orderDate: Timestamp.now(),
        status: 'processing',
        paymentMethod: 'qr_code',
        shippingMethod: 'standard_delivery',
        totalAmount: 150.0,
        shippingFee: 40.0,
        subTotal: 110.0,
        fullName: 'ลูกค้าทดสอบ',
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
            quantity: 2,
            pricePerUnit: 55.0,
            imageUrl: 'https://example.com/image.jpg',
            ecoScore: 85,
            sellerId: 'seller-123',
          ),
        ],
        sellerIds: ['seller-123'],
      );

      // Initialize shipping manager with test service
      await shippingManager.initialize(testFirebaseService);

      // Test 1: Create shipment
      final shipmentResult =
          await shippingManager.createShipmentFromOrder(order);

      print(
          'Shipment result: success=${shipmentResult.success}, trackingNumber=${shipmentResult.trackingNumber}, error=${shipmentResult.errorMessage}');

      expect(shipmentResult.success, true,
          reason: 'Failed: ${shipmentResult.errorMessage}');
      expect(shipmentResult.trackingNumber, isNotNull);
      expect(shipmentResult.trackingNumber!.length, greaterThan(5));

      // Test 2: Get tracking info
      final trackingInfo = await shippingManager.getTrackingInfo(
        shipmentResult.trackingNumber!,
      );

      expect(trackingInfo.trackingNumber, shipmentResult.trackingNumber);
      expect(trackingInfo.currentStatus, isNotNull);

      // Test 3: Calculate shipping rates
      final shippingRates = await shippingManager.calculateShippingRates(
        order,
      );

      expect(shippingRates.isNotEmpty, true);
      expect(shippingRates.first.cost, greaterThan(0));
    });

    test('Shipping method selection should work correctly', () {
      final methods = ShippingMethod.getDefaultMethods();

      // Test all default methods are available
      expect(methods.length, greaterThanOrEqualTo(4));

      // Test method properties
      final standardMethod =
          methods.firstWhere((m) => m.id == 'standard_delivery');
      expect(standardMethod.name, 'Standard Delivery');
      expect(standardMethod.cost, 40.0);
      expect(standardMethod.estimatedDays, 3);
      expect(standardMethod.isActive, true);

      final expressMethod =
          methods.firstWhere((m) => m.id == 'express_delivery');
      expect(expressMethod.name, 'Express Delivery');
      expect(expressMethod.cost, 80.0);
      expect(expressMethod.estimatedDays, 1);
      expect(expressMethod.isActive, true);
    });

    test('Bulk operations should handle multiple orders', () async {
      // Create multiple test orders
      final orders = List.generate(
          3,
          (index) => app_order.Order(
                id: 'test-order-${index + 1}',
                userId: 'user-123',
                orderDate: Timestamp.now(),
                status: 'processing',
                paymentMethod: 'qr_code',
                shippingMethod: 'standard_delivery',
                totalAmount: 100.0 + (index * 10),
                shippingFee: 40.0,
                subTotal: 60.0 + (index * 10),
                fullName: 'ลูกค้าทดสอบ ${index + 1}',
                phoneNumber: '081234567$index',
                addressLine1: '${123 + index} ถนนทดสอบ',
                subDistrict: 'ทดสอบ',
                district: 'ทดสอบ',
                province: 'กรุงเทพมหานคร',
                zipCode: '10100',
                items: [
                  OrderItem(
                    productId: 'product-${index + 1}',
                    productName: 'สินค้าทดสอบ ${index + 1}',
                    quantity: 1,
                    pricePerUnit: 60.0 + (index * 10),
                    imageUrl: 'https://example.com/image${index + 1}.jpg',
                    ecoScore: 85,
                    sellerId: 'seller-123',
                  ),
                ],
                sellerIds: ['seller-123'],
              ));

      // Initialize shipping manager
      await shippingManager.initialize(testFirebaseService);

      // Test bulk shipment creation
      final bulkResults = await shippingManager.createBulkShipments(orders);

      print(
          'Bulk results: ${bulkResults.map((r) => 'success=${r.success}, error=${r.errorMessage}').toList()}');

      expect(bulkResults.length, equals(3));
      expect(bulkResults.every((result) => result.success), true,
          reason:
              'Failed: ${bulkResults.where((r) => !r.success).map((r) => r.errorMessage).join(", ")}');
      expect(
          bulkResults.every((result) => result.trackingNumber != null), true);
    });

    test('Error handling should work correctly', () async {
      // Test with invalid order
      final invalidOrder = app_order.Order(
        id: '', // Invalid empty ID
        userId: 'user-123',
        orderDate: Timestamp.now(),
        status: 'processing',
        paymentMethod: 'qr_code',
        totalAmount: 100.0,
        shippingFee: 40.0,
        subTotal: 60.0,
        fullName: '',
        phoneNumber: '',
        addressLine1: '',
        subDistrict: '',
        district: '',
        province: '',
        zipCode: '',
        items: [],
        sellerIds: [],
      );

      await shippingManager.initialize(testFirebaseService);

      // Test that it handles errors gracefully
      final result =
          await shippingManager.createShipmentFromOrder(invalidOrder);
      expect(result.success, false);
      expect(result.errorMessage, isNotNull);
    });

    test('Shipping analytics should calculate correctly', () {
      // Test data
      final orders = [
        app_order.Order(
          id: 'order-1',
          userId: 'user-1',
          orderDate: Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 1))),
          status: 'delivered',
          paymentMethod: 'qr_code',
          totalAmount: 150.0,
          shippingFee: 40.0,
          subTotal: 110.0,
          fullName: 'ลูกค้า 1',
          phoneNumber: '0812345678',
          addressLine1: '123 ถนนทดสอบ',
          subDistrict: 'ทดสอบ',
          district: 'ทดสอบ',
          province: 'กรุงเทพมหานคร',
          zipCode: '10100',
          items: [
            OrderItem(
              productId: 'product-1',
              productName: 'สินค้า 1',
              quantity: 1,
              pricePerUnit: 110.0,
              imageUrl: 'https://example.com/image1.jpg',
              ecoScore: 85,
              sellerId: 'seller-123',
            ),
          ],
          sellerIds: ['seller-123'],
          shippingMethod: 'standard_delivery',
          shippingCarrier: 'Kerry Express',
          trackingNumber: 'TH123456789',
          shippedAt: Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 1))),
          deliveredAt: Timestamp.now(),
        ),
        app_order.Order(
          id: 'order-2',
          userId: 'user-2',
          orderDate: Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 2))),
          status: 'shipped',
          paymentMethod: 'qr_code',
          totalAmount: 200.0,
          shippingFee: 80.0,
          subTotal: 120.0,
          fullName: 'ลูกค้า 2',
          phoneNumber: '0812345679',
          addressLine1: '456 ถนนทดสอบ',
          subDistrict: 'ทดสอบ',
          district: 'ทดสอบ',
          province: 'กรุงเทพมหานคร',
          zipCode: '10100',
          items: [
            OrderItem(
              productId: 'product-2',
              productName: 'สินค้า 2',
              quantity: 1,
              pricePerUnit: 120.0,
              imageUrl: 'https://example.com/image2.jpg',
              ecoScore: 90,
              sellerId: 'seller-123',
            ),
          ],
          sellerIds: ['seller-123'],
          shippingMethod: 'express_delivery',
          shippingCarrier: 'J&T Express',
          trackingNumber: 'JT987654321',
          shippedAt: Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 2))),
        ),
      ];

      // Test statistics calculation
      final totalOrders = orders.length;
      final deliveredOrders =
          orders.where((o) => o.status == 'delivered').length;
      final totalShippingFee =
          orders.fold(0.0, (total, order) => total + order.shippingFee);
      final totalRevenue =
          orders.fold(0.0, (total, order) => total + order.totalAmount);

      expect(totalOrders, equals(2));
      expect(deliveredOrders, equals(1));
      expect(totalShippingFee, equals(120.0));
      expect(totalRevenue, equals(350.0));

      // Test shipping cost ratio
      final shippingCostRatio = totalShippingFee / totalRevenue;
      expect(shippingCostRatio, closeTo(0.34, 0.01));
    });
  });
}
