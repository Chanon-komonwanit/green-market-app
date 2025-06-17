// lib/models/shipping_address.dart
class ShippingAddress {
  final String fullName;
  final String phoneNumber;
  final String addressLine1;
  final String subDistrict;
  final String district;
  final String province;
  final String zipCode;
  final String? note;

  ShippingAddress({
    required this.fullName,
    required this.phoneNumber,
    required this.addressLine1,
    required this.subDistrict,
    required this.district,
    required this.province,
    required this.zipCode,
    this.note,
  });

  // Optional: if you need to convert to map for Firestore or other uses
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'addressLine1': addressLine1,
      'subDistrict': subDistrict,
      'district': district,
      'province': province,
      'zipCode': zipCode,
      'note': note,
    };
  }

  // Optional: factory constructor from map
  factory ShippingAddress.fromMap(Map<String, dynamic> map) {
    return ShippingAddress(
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      addressLine1: map['addressLine1'] ?? '',
      subDistrict: map['subDistrict'] ?? '',
      district: map['district'] ?? '',
      province: map['province'] ?? '',
      zipCode: map['zipCode'] ?? '',
      note: map['note'],
    );
  }
}
