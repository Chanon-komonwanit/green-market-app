// lib/services/shipping/shipping_service_manager.dart
import 'package:green_market/services/shipping/shipping_provider.dart';
import 'package:green_market/services/shipping/manual_shipping_provider.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/services/firebase_service_shipping_extensions.dart';
import 'package:green_market/models/order.dart' as app_order;
import 'package:green_market/models/order_item.dart';
import 'package:green_market/models/shipping_method.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Central manager for all shipping operations
/// Handles provider selection and shipping workflow
class ShippingServiceManager {
  static final ShippingServiceManager _instance =
      ShippingServiceManager._internal();
  factory ShippingServiceManager() => _instance;
  ShippingServiceManager._internal();

  late final FirebaseService _firebaseService;
  late final ShippingProvider _currentProvider;

  bool _isInitialized = false;

  /// Initialize the shipping service manager
  Future<void> initialize(FirebaseService firebaseService) async {
    if (_isInitialized) return;

    _firebaseService = firebaseService;

    // For now, use manual provider
    // In future, can switch based on configuration
    _currentProvider = ManualShippingProvider(_firebaseService);

    _isInitialized = true;
  }

  /// Get current shipping provider
  ShippingProvider get currentProvider {
    if (!_isInitialized) {
      throw Exception('ShippingServiceManager not initialized');
    }
    return _currentProvider;
  }

  /// Create shipment from order
  Future<ShippingResult> createShipmentFromOrder(app_order.Order order) async {
    try {
      // Get seller address
      final senderAddress = await _getSellerAddress(order.sellerIds.first);

      // Create receiver address from order
      final receiverAddress = AddressInfo.fromOrder(order);

      // Create packages from order items
      final packages = _createPackagesFromOrderItems(order.items);

      // Get shipping method
      final shippingMethod = await _getShippingMethodById(
          order.shippingMethod ?? 'standard_delivery');

      // Create payment info
      final paymentInfo = PaymentInfo(
        method: order.paymentMethod,
        amount: order.totalAmount,
      );

      // Create shipment request
      final request = ShipmentRequest(
        orderId: order.id,
        sellerId: order.sellerIds.first,
        senderAddress: senderAddress,
        receiverAddress: receiverAddress,
        packages: packages,
        shippingMethod: shippingMethod,
        paymentInfo: paymentInfo,
        specialInstructions: order.note,
        requiresSignature:
            order.totalAmount > 5000, // Require signature for high value orders
        declaredValue: order.totalAmount,
      );

      // Create shipment
      final result = await _currentProvider.createShipment(request);

      // Update order status if successful
      if (result.success) {
        try {
          await _firebaseService.updateOrderStatusInstance(order.id, 'shipped');
        } catch (e) {
          // Log but don't fail if status update fails
          print('Warning: Failed to update order status: $e');
        }
      }

      return result;
    } catch (e) {
      return ShippingResult(
        success: false,
        errorMessage: 'เกิดข้อผิดพลาดในการสร้างใบจัดส่ง: $e',
      );
    }
  }

  /// Get tracking information
  Future<TrackingInfo> getTrackingInfo(String trackingNumber) async {
    return await _currentProvider.getTrackingInfo(trackingNumber);
  }

  /// Calculate shipping rates for order
  Future<List<ShippingRate>> calculateShippingRates(
      app_order.Order order) async {
    try {
      // Get seller address
      final senderAddress = await _getSellerAddress(order.sellerIds.first);

      // Create receiver address from order
      final receiverAddress = AddressInfo.fromOrder(order);

      // Create packages from order items
      final packages = _createPackagesFromOrderItems(order.items);

      // Create rate request
      final request = RateRequest(
        senderAddress: senderAddress,
        receiverAddress: receiverAddress,
        packages: packages,
        declaredValue: order.totalAmount,
      );

      return await _currentProvider.calculateShippingRates(request);
    } catch (e) {
      return [];
    }
  }

  /// Get available shipping methods
  Future<List<ShippingMethod>> getAvailableShippingMethods() async {
    return await _currentProvider.getAvailableShippingMethods();
  }

  /// Validate shipping address
  Future<bool> validateShippingAddress(AddressInfo address) async {
    return await _currentProvider.validateAddress(address);
  }

  /// Get pickup locations
  Future<List<PickupLocation>> getPickupLocations(String region) async {
    return await _currentProvider.getPickupLocations(region);
  }

  /// Create bulk shipments
  Future<List<ShippingResult>> createBulkShipments(
      List<app_order.Order> orders) async {
    final requests = <ShipmentRequest>[];

    for (final order in orders) {
      try {
        final senderAddress = await _getSellerAddress(order.sellerIds.first);
        final receiverAddress = AddressInfo.fromOrder(order);
        final packages = _createPackagesFromOrderItems(order.items);
        final shippingMethod = await _getShippingMethodById(
            order.shippingMethod ?? 'standard_delivery');
        final paymentInfo = PaymentInfo(
          method: order.paymentMethod,
          amount: order.totalAmount,
        );

        requests.add(ShipmentRequest(
          orderId: order.id,
          sellerId: order.sellerIds.first,
          senderAddress: senderAddress,
          receiverAddress: receiverAddress,
          packages: packages,
          shippingMethod: shippingMethod,
          paymentInfo: paymentInfo,
          specialInstructions: order.note,
          requiresSignature: order.totalAmount > 5000,
          declaredValue: order.totalAmount,
        ));
      } catch (e) {
        // Skip this order if there's an error
        continue;
      }
    }

    return await _currentProvider.createBulkShipments(requests);
  }

  /// Cancel shipment
  Future<bool> cancelShipment(String orderId) async {
    return await _currentProvider.cancelShipment('manual_$orderId');
  }

  /// Get shipping statistics
  Future<Map<String, dynamic>> getShippingStatistics({
    String? sellerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _firebaseService.getShippingStatistics(
      sellerId: sellerId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Update tracking status manually
  Future<void> updateTrackingStatus(
    String trackingNumber,
    String status,
    String description, {
    LocationInfo? location,
    String? employeeName,
    String? remarks,
  }) async {
    await _firebaseService.addTrackingEvent(trackingNumber, {
      'status': status,
      'description': description,
      'location': location != null ? _locationToMap(location) : null,
      'employeeName': employeeName ?? 'ผู้ขาย',
      'remarks': remarks,
    });
  }

  /// Generate shipping labels for orders
  Future<List<ShippingLabel>> generateShippingLabels(
      List<app_order.Order> orders) async {
    final labels = <ShippingLabel>[];

    for (final order in orders) {
      try {
        final label = await _generateShippingLabel(order);
        labels.add(label);
      } catch (e) {
        // Skip if error generating label
        continue;
      }
    }

    return labels;
  }

  /// Get orders needing shipping labels
  Future<List<Map<String, dynamic>>> getOrdersNeedingLabels(
      String sellerId) async {
    return await _firebaseService.getOrdersNeedingLabels(sellerId);
  }

  // Helper methods
  Future<AddressInfo> _getSellerAddress(String sellerId) async {
    try {
      final data = await _firebaseService.getSellerData(sellerId);

      if (data == null) {
        throw Exception('Seller not found');
      }

      return AddressInfo(
        fullName: data['shopName'] ?? '',
        phoneNumber: data['phoneNumber'] ?? '',
        addressLine1: data['address'] ?? '',
        subDistrict: data['subDistrict'] ?? '',
        district: data['district'] ?? '',
        province: data['province'] ?? '',
        zipCode: data['zipCode'] ?? '',
        companyName: data['shopName'],
      );
    } catch (e) {
      // Return default address if seller not found
      return AddressInfo(
        fullName: 'Green Market',
        phoneNumber: '02-123-4567',
        addressLine1: '123 ถนนสุขุมวิท',
        subDistrict: 'คลองเตย',
        district: 'คลองเตย',
        province: 'กรุงเทพมหานคร',
        zipCode: '10110',
        companyName: 'Green Market Co., Ltd.',
      );
    }
  }

  List<PackageInfo> _createPackagesFromOrderItems(List<OrderItem> items) {
    return items
        .map((item) => PackageInfo(
              id: item.productId,
              description: item.productName,
              weight: 0.5, // Default weight
              length: 10.0, // Default dimensions
              width: 10.0,
              height: 5.0,
              value: item.pricePerUnit * item.quantity,
              category: 'general',
            ))
        .toList();
  }

  Future<ShippingMethod> _getShippingMethodById(String methodId) async {
    try {
      final methods = await _currentProvider.getAvailableShippingMethods();
      return methods.firstWhere(
        (method) => method.id == methodId,
        orElse: () => methods.first,
      );
    } catch (e) {
      // Return default method if Firebase fails
      return ShippingMethod(
        id: 'standard_delivery',
        name: 'Standard Delivery',
        description: 'มาตรฐาน 3-5 วัน',
        cost: 40.0,
        estimatedDays: 3,
        carrier: 'Kerry Express',
        isActive: true,
      );
    }
  }

  Future<ShippingLabel> _generateShippingLabel(app_order.Order order) async {
    return ShippingLabel(
      orderId: order.id,
      trackingNumber: order.trackingNumber ?? 'N/A',
      senderName: 'Green Market',
      senderAddress: '123 ถนนสุขุมวิท คลองเตย กรุงเทพมหานคร 10110',
      receiverName: order.fullName,
      receiverAddress:
          '${order.addressLine1}, ${order.subDistrict}, ${order.district}, ${order.province} ${order.zipCode}',
      receiverPhone: order.phoneNumber,
      shippingMethod: order.shippingMethod ?? 'standard_delivery',
      carrier: order.shippingCarrier ?? 'Kerry Express',
      weight: '0.5 kg',
      value: order.totalAmount,
      specialInstructions: order.note,
      barcode: _generateBarcode(order.trackingNumber ?? order.id),
      createdAt: DateTime.now(),
    );
  }

  String _generateBarcode(String trackingNumber) {
    // Simple barcode generation - in real implementation, use proper barcode library
    return trackingNumber.replaceAll(RegExp(r'[^0-9]'), '');
  }

  Map<String, dynamic> _locationToMap(LocationInfo location) {
    return {
      'name': location.name,
      'address': location.address,
      'city': location.city,
      'province': location.province,
      'zipCode': location.zipCode,
      'latitude': location.latitude,
      'longitude': location.longitude,
    };
  }
}

/// Shipping label data model
class ShippingLabel {
  final String orderId;
  final String trackingNumber;
  final String senderName;
  final String senderAddress;
  final String receiverName;
  final String receiverAddress;
  final String receiverPhone;
  final String shippingMethod;
  final String carrier;
  final String weight;
  final double value;
  final String? specialInstructions;
  final String barcode;
  final DateTime createdAt;

  ShippingLabel({
    required this.orderId,
    required this.trackingNumber,
    required this.senderName,
    required this.senderAddress,
    required this.receiverName,
    required this.receiverAddress,
    required this.receiverPhone,
    required this.shippingMethod,
    required this.carrier,
    required this.weight,
    required this.value,
    this.specialInstructions,
    required this.barcode,
    required this.createdAt,
  });
}
