// lib/services/shipping/shipping_provider.dart
import 'package:green_market/models/order.dart' as app_order;
import 'package:green_market/models/shipping_method.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Base class for all shipping providers
/// This allows easy switching between Manual and API providers
abstract class ShippingProvider {
  String get providerId;
  String get providerName;
  bool get isApiProvider;

  // Core shipping operations
  Future<ShippingResult> createShipment(ShipmentRequest request);
  Future<TrackingInfo> getTrackingInfo(String trackingNumber);
  Future<List<ShippingRate>> calculateShippingRates(RateRequest request);
  Future<bool> cancelShipment(String shipmentId);

  // Batch operations for efficiency
  Future<List<ShippingResult>> createBulkShipments(
      List<ShipmentRequest> requests);
  Future<List<TrackingInfo>> getBulkTrackingInfo(List<String> trackingNumbers);

  // Provider-specific features
  Future<List<ShippingMethod>> getAvailableShippingMethods();
  Future<bool> validateAddress(AddressInfo address);
  Future<List<PickupLocation>> getPickupLocations(String region);
}

/// Request model for creating shipments
class ShipmentRequest {
  final String orderId;
  final String sellerId;
  final AddressInfo senderAddress;
  final AddressInfo receiverAddress;
  final List<PackageInfo> packages;
  final ShippingMethod shippingMethod;
  final PaymentInfo paymentInfo;
  final String? specialInstructions;
  final bool requiresSignature;
  final bool isFragile;
  final double declaredValue;

  ShipmentRequest({
    required this.orderId,
    required this.sellerId,
    required this.senderAddress,
    required this.receiverAddress,
    required this.packages,
    required this.shippingMethod,
    required this.paymentInfo,
    this.specialInstructions,
    this.requiresSignature = false,
    this.isFragile = false,
    this.declaredValue = 0.0,
  });
}

/// Request model for calculating shipping rates
class RateRequest {
  final AddressInfo senderAddress;
  final AddressInfo receiverAddress;
  final List<PackageInfo> packages;
  final DateTime? preferredDeliveryDate;
  final bool requiresSignature;
  final bool isFragile;
  final double declaredValue;

  RateRequest({
    required this.senderAddress,
    required this.receiverAddress,
    required this.packages,
    this.preferredDeliveryDate,
    this.requiresSignature = false,
    this.isFragile = false,
    this.declaredValue = 0.0,
  });
}

/// Result model for shipping operations
class ShippingResult {
  final bool success;
  final String? trackingNumber;
  final String? shipmentId;
  final String? labelUrl;
  final String? trackingUrl;
  final String? errorMessage;
  final double? actualCost;
  final DateTime? estimatedDeliveryDate;
  final Map<String, dynamic>? additionalData;

  ShippingResult({
    required this.success,
    this.trackingNumber,
    this.shipmentId,
    this.labelUrl,
    this.trackingUrl,
    this.errorMessage,
    this.actualCost,
    this.estimatedDeliveryDate,
    this.additionalData,
  });
}

/// Comprehensive tracking information
class TrackingInfo {
  final String trackingNumber;
  final String currentStatus;
  final String statusDescription;
  final DateTime lastUpdated;
  final List<TrackingEvent> events;
  final LocationInfo? currentLocation;
  final DateTime? estimatedDeliveryDate;
  final String? deliveryInstructions;
  final bool isDelivered;
  final String? signedBy;
  final String? deliveryPhotoUrl;
  final String? failureReason;

  TrackingInfo({
    required this.trackingNumber,
    required this.currentStatus,
    required this.statusDescription,
    required this.lastUpdated,
    required this.events,
    this.currentLocation,
    this.estimatedDeliveryDate,
    this.deliveryInstructions,
    this.isDelivered = false,
    this.signedBy,
    this.deliveryPhotoUrl,
    this.failureReason,
  });
}

/// Individual tracking event
class TrackingEvent {
  final String status;
  final String description;
  final DateTime timestamp;
  final LocationInfo? location;
  final String? employeeName;
  final String? remarks;

  TrackingEvent({
    required this.status,
    required this.description,
    required this.timestamp,
    this.location,
    this.employeeName,
    this.remarks,
  });
}

/// Location information
class LocationInfo {
  final String name;
  final String address;
  final String city;
  final String province;
  final String zipCode;
  final double? latitude;
  final double? longitude;

  LocationInfo({
    required this.name,
    required this.address,
    required this.city,
    required this.province,
    required this.zipCode,
    this.latitude,
    this.longitude,
  });
}

/// Address information
class AddressInfo {
  final String fullName;
  final String phoneNumber;
  final String addressLine1;
  final String? addressLine2;
  final String subDistrict;
  final String district;
  final String province;
  final String zipCode;
  final String? email;
  final String? companyName;
  final double? latitude;
  final double? longitude;

  AddressInfo({
    required this.fullName,
    required this.phoneNumber,
    required this.addressLine1,
    this.addressLine2,
    required this.subDistrict,
    required this.district,
    required this.province,
    required this.zipCode,
    this.email,
    this.companyName,
    this.latitude,
    this.longitude,
  });

  factory AddressInfo.fromOrder(app_order.Order order) {
    return AddressInfo(
      fullName: order.fullName,
      phoneNumber: order.phoneNumber,
      addressLine1: order.addressLine1,
      subDistrict: order.subDistrict,
      district: order.district,
      province: order.province,
      zipCode: order.zipCode,
    );
  }
}

/// Package information
class PackageInfo {
  final String id;
  final String description;
  final double weight;
  final double length;
  final double width;
  final double height;
  final double value;
  final String? category;
  final bool isFragile;
  final bool isLiquid;
  final bool isDangerous;

  PackageInfo({
    required this.id,
    required this.description,
    required this.weight,
    required this.length,
    required this.width,
    required this.height,
    required this.value,
    this.category,
    this.isFragile = false,
    this.isLiquid = false,
    this.isDangerous = false,
  });

  double get volumetricWeight => (length * width * height) / 5000;
  double get chargeableWeight =>
      weight > volumetricWeight ? weight : volumetricWeight;
}

/// Payment information
class PaymentInfo {
  final String method; // prepaid, cod, account
  final double amount;
  final String currency;
  final String? accountNumber;
  final String? reference;

  PaymentInfo({
    required this.method,
    required this.amount,
    this.currency = 'THB',
    this.accountNumber,
    this.reference,
  });
}

/// Shipping rate information
class ShippingRate {
  final String serviceId;
  final String serviceName;
  final String carrier;
  final double cost;
  final int estimatedDays;
  final DateTime? cutoffTime;
  final bool availableToday;
  final List<String> features;
  final String? description;

  ShippingRate({
    required this.serviceId,
    required this.serviceName,
    required this.carrier,
    required this.cost,
    required this.estimatedDays,
    this.cutoffTime,
    this.availableToday = true,
    this.features = const [],
    this.description,
  });
}

/// Pickup location information
class PickupLocation {
  final String id;
  final String name;
  final String address;
  final String city;
  final String province;
  final String zipCode;
  final String phoneNumber;
  final List<String> operatingHours;
  final List<String> availableServices;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;

  PickupLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.province,
    required this.zipCode,
    required this.phoneNumber,
    required this.operatingHours,
    required this.availableServices,
    this.latitude,
    this.longitude,
    this.distanceKm,
  });
}
