import 'package:cloud_firestore/cloud_firestore.dart';

class Seller {
  final String id;
  final String shopName;
  final String contactEmail;
  final String phoneNumber;
  final String status; // e.g., 'active', 'inactive', 'suspended'
  final double rating;
  final int totalRatings;
  final Timestamp createdAt;
  // --- Added fields to fix errors ---
  final String? shopImageUrl;
  final String? shopCoverUrl;
  final String? shopDescription;
  final String? website;
  final String? socialMediaLink;
  final String? openHours;
  final String? address;
  final String? shopTemplate; // เทมเพจร้านค้า

  Seller({
    required this.id,
    required this.shopName,
    required this.contactEmail,
    required this.phoneNumber,
    required this.status,
    required this.rating,
    required this.totalRatings,
    required this.createdAt,
    this.shopImageUrl,
    this.shopCoverUrl,
    this.shopDescription,
    this.website,
    this.socialMediaLink,
    this.openHours,
    this.address,
    this.shopTemplate,
  });

  // Getters for compatibility
  String get businessName => shopName;
  String get businessDescription => shopDescription ?? '';
  String get contactPhone => phoneNumber;

  factory Seller.fromMap(Map<String, dynamic> map) {
    return Seller(
      id: map['id'] ?? '',
      shopName: map['shopName'] ?? '',
      contactEmail: map['contactEmail'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      status: map['status'] ?? 'inactive',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: map['totalRatings'] ?? 0,
      createdAt: map['createdAt'] ?? Timestamp.now(),
      shopImageUrl: map['shopImageUrl'],
      shopCoverUrl: map['shopCoverUrl'],
      shopDescription: map['shopDescription'],
      website: map['website'],
      socialMediaLink: map['socialMediaLink'],
      openHours: map['openHours'],
      address: map['address'],
      shopTemplate: map['shopTemplate'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shopName': shopName,
      'contactEmail': contactEmail,
      'phoneNumber': phoneNumber,
      'status': status,
      'rating': rating,
      'totalRatings': totalRatings,
      'createdAt': createdAt,
      'shopImageUrl': shopImageUrl,
      'shopCoverUrl': shopCoverUrl,
      'shopDescription': shopDescription,
      'website': website,
      'socialMediaLink': socialMediaLink,
      'openHours': openHours,
      'address': address,
      'shopTemplate': shopTemplate,
    };
  }

  // Get a formatted string of when the seller joined
  String get joinedDateFormatted {
    return '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}';
  }

  // Method to update seller's wallet balance
  Future<void> updateWalletBalance(
      String projectId, String userId, double amount) async {
    // Implementation for updating the wallet balance
  }
}
