// lib/services/shipping/manual_shipping_provider.dart
import 'package:green_market/services/shipping/shipping_provider.dart';
import 'package:green_market/models/shipping_method.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/services/firebase_service_shipping_extensions.dart';
import 'dart:math';

/// Manual shipping provider for current use
/// Handles all shipping operations through manual processes
/// Ready for API integration in the future
class ManualShippingProvider extends ShippingProvider {
  final FirebaseService _firebaseService;

  ManualShippingProvider(this._firebaseService);

  @override
  String get providerId => 'manual_provider';

  @override
  String get providerName => 'Manual Shipping Management';

  @override
  bool get isApiProvider => false;

  @override
  Future<ShippingResult> createShipment(ShipmentRequest request) async {
    try {
      // Generate tracking number
      final trackingNumber =
          _generateTrackingNumber(request.shippingMethod.carrier);

      // Generate tracking URL
      final trackingUrl =
          _generateTrackingUrl(trackingNumber, request.shippingMethod.carrier);

      // Calculate estimated delivery date
      final estimatedDeliveryDate = DateTime.now().add(
        Duration(days: request.shippingMethod.estimatedDays),
      );

      // Store shipment data in Firestore
      await _firebaseService.updateOrderShippingInfo(
        request.orderId,
        {
          'trackingNumber': trackingNumber,
          'trackingUrl': trackingUrl,
          'shippingCarrier': request.shippingMethod.carrier,
          'shippingMethod': request.shippingMethod.id,
          'estimatedDeliveryDate': Timestamp.fromDate(estimatedDeliveryDate),
          'status': 'processing',
          'createdAt': Timestamp.now(),
          'shipmentData': {
            'senderAddress': _addressToMap(request.senderAddress),
            'receiverAddress': _addressToMap(request.receiverAddress),
            'packages': request.packages.map((p) => _packageToMap(p)).toList(),
            'specialInstructions': request.specialInstructions,
            'requiresSignature': request.requiresSignature,
            'isFragile': request.isFragile,
            'declaredValue': request.declaredValue,
          },
        },
      );

      // Create initial tracking event
      await _createTrackingEvent(
        trackingNumber,
        'created',
        'ได้รับคำสั่งซื้อและเตรียมจัดส่ง',
        LocationInfo(
          name: 'ศูนย์กระจายสินค้า',
          address: request.senderAddress.addressLine1,
          city: request.senderAddress.district,
          province: request.senderAddress.province,
          zipCode: request.senderAddress.zipCode,
        ),
      );

      return ShippingResult(
        success: true,
        trackingNumber: trackingNumber,
        shipmentId: 'manual_${request.orderId}',
        trackingUrl: trackingUrl,
        actualCost: request.shippingMethod.cost,
        estimatedDeliveryDate: estimatedDeliveryDate,
        additionalData: {
          'provider': 'manual',
          'carrier': request.shippingMethod.carrier,
          'service': request.shippingMethod.name,
        },
      );
    } catch (e) {
      return ShippingResult(
        success: false,
        errorMessage: 'เกิดข้อผิดพลาดในการสร้างใบจัดส่ง: $e',
      );
    }
  }

  @override
  Future<TrackingInfo> getTrackingInfo(String trackingNumber) async {
    try {
      // Get tracking events from Firestore
      final eventsSnapshot = await FirebaseFirestore.instance
          .collection('tracking_events')
          .where('trackingNumber', isEqualTo: trackingNumber)
          .orderBy('timestamp', descending: false)
          .get();

      if (eventsSnapshot.docs.isEmpty) {
        throw Exception('ไม่พบข้อมูลการติดตามสำหรับหมายเลข $trackingNumber');
      }

      final events = eventsSnapshot.docs.map((doc) {
        final data = doc.data();
        return TrackingEvent(
          status: data['status'] ?? '',
          description: data['description'] ?? '',
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          location: data['location'] != null
              ? LocationInfo(
                  name: data['location']['name'] ?? '',
                  address: data['location']['address'] ?? '',
                  city: data['location']['city'] ?? '',
                  province: data['location']['province'] ?? '',
                  zipCode: data['location']['zipCode'] ?? '',
                  latitude: data['location']['latitude']?.toDouble(),
                  longitude: data['location']['longitude']?.toDouble(),
                )
              : null,
          employeeName: data['employeeName'],
          remarks: data['remarks'],
        );
      }).toList();

      // Get current status
      final latestEvent = events.last;
      final isDelivered = latestEvent.status == 'delivered';

      return TrackingInfo(
        trackingNumber: trackingNumber,
        currentStatus: latestEvent.status,
        statusDescription: latestEvent.description,
        lastUpdated: latestEvent.timestamp,
        events: events,
        currentLocation: latestEvent.location,
        isDelivered: isDelivered,
        signedBy: isDelivered ? latestEvent.employeeName : null,
      );
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการดึงข้อมูลการติดตาม: $e');
    }
  }

  @override
  Future<List<ShippingRate>> calculateShippingRates(RateRequest request) async {
    // Calculate based on distance and package weight
    final distance =
        _calculateDistance(request.senderAddress, request.receiverAddress);
    final totalWeight = request.packages
        .fold(0.0, (total, pkg) => total + pkg.chargeableWeight);

    final rates = <ShippingRate>[];

    // Standard delivery
    rates.add(ShippingRate(
      serviceId: 'standard_delivery',
      serviceName: 'Standard Delivery',
      carrier: 'Kerry Express',
      cost: _calculateStandardRate(distance, totalWeight),
      estimatedDays: 3,
      features: ['Insurance included', 'Tracking available'],
      description: 'ส่งปกติ ประหยัด',
    ));

    // Express delivery
    rates.add(ShippingRate(
      serviceId: 'express_delivery',
      serviceName: 'Express Delivery',
      carrier: 'J&T Express',
      cost: _calculateExpressRate(distance, totalWeight),
      estimatedDays: 1,
      features: [
        'Insurance included',
        'Tracking available',
        'Priority handling'
      ],
      description: 'ส่งด่วน รวดเร็ว',
    ));

    // COD option
    if (request.declaredValue > 0) {
      rates.add(ShippingRate(
        serviceId: 'cod_delivery',
        serviceName: 'Cash on Delivery',
        carrier: 'Flash Express',
        cost: _calculateCODRate(distance, totalWeight, request.declaredValue),
        estimatedDays: 2,
        features: [
          'Insurance included',
          'Tracking available',
          'Cash collection'
        ],
        description: 'เก็บเงินปลายทาง',
      ));
    }

    return rates;
  }

  @override
  Future<bool> cancelShipment(String shipmentId) async {
    try {
      // Update order status to cancelled
      await _firebaseService.updateOrderStatus(
          shipmentId.replaceAll('manual_', ''), 'cancelled');

      // Add tracking event
      final trackingNumber = await _getTrackingNumberFromShipmentId(shipmentId);
      if (trackingNumber != null) {
        await _createTrackingEvent(
          trackingNumber,
          'cancelled',
          'ยกเลิกการจัดส่ง',
          null,
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<ShippingResult>> createBulkShipments(
      List<ShipmentRequest> requests) async {
    final results = <ShippingResult>[];

    for (final request in requests) {
      try {
        final result = await createShipment(request);
        results.add(result);

        // Add small delay to prevent overwhelming the system
        await Future.delayed(Duration(milliseconds: 100));
      } catch (e) {
        results.add(ShippingResult(
          success: false,
          errorMessage: 'เกิดข้อผิดพลาดในการสร้างใบจัดส่ง: $e',
        ));
      }
    }

    return results;
  }

  @override
  Future<List<TrackingInfo>> getBulkTrackingInfo(
      List<String> trackingNumbers) async {
    final results = <TrackingInfo>[];

    for (final trackingNumber in trackingNumbers) {
      try {
        final info = await getTrackingInfo(trackingNumber);
        results.add(info);
      } catch (e) {
        // Continue with other tracking numbers even if one fails
        continue;
      }
    }

    return results;
  }

  @override
  Future<List<ShippingMethod>> getAvailableShippingMethods() async {
    return ShippingMethod.getDefaultMethods();
  }

  @override
  Future<bool> validateAddress(AddressInfo address) async {
    // Basic validation for now
    return address.fullName.isNotEmpty &&
        address.phoneNumber.isNotEmpty &&
        address.addressLine1.isNotEmpty &&
        address.province.isNotEmpty &&
        address.zipCode.isNotEmpty;
  }

  @override
  Future<List<PickupLocation>> getPickupLocations(String region) async {
    // Return mock pickup locations for now
    return _getMockPickupLocations(region);
  }

  // Helper methods
  String _generateTrackingNumber(String carrier) {
    final random = Random();
    final now = DateTime.now();

    switch (carrier.toLowerCase()) {
      case 'kerry express':
        return 'KE${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${random.nextInt(100000).toString().padLeft(5, '0')}';
      case 'j&t express':
        return 'JT${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${random.nextInt(100000).toString().padLeft(5, '0')}';
      case 'flash express':
        return 'FE${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${random.nextInt(100000).toString().padLeft(5, '0')}';
      case 'ไปรษณีย์ไทย':
        return 'TH${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${random.nextInt(100000).toString().padLeft(5, '0')}';
      default:
        return 'GM${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${random.nextInt(100000).toString().padLeft(5, '0')}';
    }
  }

  String _generateTrackingUrl(String trackingNumber, String carrier) {
    switch (carrier.toLowerCase()) {
      case 'kerry express':
        return 'https://th.kerryexpress.com/track/?track=$trackingNumber';
      case 'j&t express':
        return 'https://www.jtexpress.co.th/index/query/gzquery.html?bills=$trackingNumber';
      case 'flash express':
        return 'https://www.flashexpress.co.th/tracking/?se=$trackingNumber';
      case 'ไปรษณีย์ไทย':
        return 'https://track.thailandpost.co.th/?trackNumber=$trackingNumber';
      default:
        return 'https://green-market.com/tracking/$trackingNumber';
    }
  }

  double _calculateDistance(AddressInfo sender, AddressInfo receiver) {
    // Simple distance calculation based on province
    if (sender.province == receiver.province) {
      return 20.0; // Same province
    } else if (_isNearbyProvince(sender.province, receiver.province)) {
      return 150.0; // Nearby province
    } else {
      return 500.0; // Far province
    }
  }

  bool _isNearbyProvince(String province1, String province2) {
    final centralProvinces = [
      'กรุงเทพมหานคร',
      'นนทบุรี',
      'ปทุมธานี',
      'สมุทรปราการ',
      'สมุทรสาคร',
      'นครปฐม'
    ];

    return centralProvinces.contains(province1) &&
        centralProvinces.contains(province2);
  }

  double _calculateStandardRate(double distance, double weight) {
    double baseRate = 40.0;
    double distanceRate = distance > 100 ? 10.0 : 0.0;
    double weightRate = weight > 2.0 ? (weight - 2.0) * 5.0 : 0.0;

    return baseRate + distanceRate + weightRate;
  }

  double _calculateExpressRate(double distance, double weight) {
    return _calculateStandardRate(distance, weight) * 2.0;
  }

  double _calculateCODRate(
      double distance, double weight, double declaredValue) {
    double baseRate = _calculateStandardRate(distance, weight);
    double codFee = declaredValue * 0.02; // 2% COD fee
    return baseRate + codFee + 10.0; // Additional 10 baht for COD service
  }

  Future<void> _createTrackingEvent(
    String trackingNumber,
    String status,
    String description,
    LocationInfo? location,
  ) async {
    await FirebaseFirestore.instance.collection('tracking_events').add({
      'trackingNumber': trackingNumber,
      'status': status,
      'description': description,
      'timestamp': Timestamp.now(),
      'location': location != null ? _locationToMap(location) : null,
      'employeeName': 'ระบบ Green Market',
      'remarks': null,
    });
  }

  Future<String?> _getTrackingNumberFromShipmentId(String shipmentId) async {
    try {
      final orderId = shipmentId.replaceAll('manual_', '');
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();
      return orderDoc.data()?['trackingNumber'];
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> _addressToMap(AddressInfo address) {
    return {
      'fullName': address.fullName,
      'phoneNumber': address.phoneNumber,
      'addressLine1': address.addressLine1,
      'addressLine2': address.addressLine2,
      'subDistrict': address.subDistrict,
      'district': address.district,
      'province': address.province,
      'zipCode': address.zipCode,
      'email': address.email,
      'companyName': address.companyName,
      'latitude': address.latitude,
      'longitude': address.longitude,
    };
  }

  Map<String, dynamic> _packageToMap(PackageInfo package) {
    return {
      'id': package.id,
      'description': package.description,
      'weight': package.weight,
      'length': package.length,
      'width': package.width,
      'height': package.height,
      'value': package.value,
      'category': package.category,
      'isFragile': package.isFragile,
      'isLiquid': package.isLiquid,
      'isDangerous': package.isDangerous,
    };
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

  List<PickupLocation> _getMockPickupLocations(String region) {
    return [
      PickupLocation(
        id: 'pickup_001',
        name: 'ศูนย์รับฝากพัสดุ Green Market เซ็นทรัลเวิลด์',
        address: '999/9 ถนนพระราม 1 แขวงปทุมวัน',
        city: 'ปทุมวัน',
        province: 'กรุงเทพมหานคร',
        zipCode: '10330',
        phoneNumber: '02-123-4567',
        operatingHours: ['จันทร์-อาทิตย์: 10:00-22:00'],
        availableServices: ['รับฝากพัสดุ', 'ติดตามสถานะ', 'คืนเงิน'],
        latitude: 13.7467,
        longitude: 100.5390,
        distanceKm: 2.5,
      ),
      PickupLocation(
        id: 'pickup_002',
        name: 'ศูนย์รับฝากพัสดุ Green Market สยามพารากอน',
        address: '991 ถนนพระราม 1 แขวงปทุมวัน',
        city: 'ปทุมวัน',
        province: 'กรุงเทพมหานคร',
        zipCode: '10330',
        phoneNumber: '02-234-5678',
        operatingHours: ['จันทร์-อาทิตย์: 10:00-22:00'],
        availableServices: ['รับฝากพัสดุ', 'ติดตามสถานะ', 'คืนเงิน'],
        latitude: 13.7455,
        longitude: 100.5344,
        distanceKm: 3.1,
      ),
    ];
  }
}
