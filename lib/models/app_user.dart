// lib/models/app_user.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool isSuspended;
  final bool isAdmin;
  final bool isSeller;
  final String? sellerApplicationStatus; // 'pending', 'approved', 'rejected'
  final String? shopName; // Added for seller application
  final String? contactEmail; // Added for seller application
  final String? phoneNumber; // Added phoneNumber
  final String? rejectionReason; // Added rejectionReason for seller application
  final Timestamp? sellerApplicationTimestamp;
  final Timestamp createdAt;

  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.isAdmin = false,
    this.isSeller = false,
    this.isSuspended = false,
    this.shopName,
    this.contactEmail,
    this.phoneNumber, // Added to constructor
    this.sellerApplicationStatus,
    this.rejectionReason,
    this.sellerApplicationTimestamp,
    required this.createdAt,
  });

  // A derived property for convenience, but the source of truth are the boolean flags.
  String get role {
    if (isAdmin) return 'admin';
    if (isSeller) return 'seller';
    return 'buyer';
  }

  // Factory constructor updated to take documentId separately
  factory AppUser.fromMap(Map<String, dynamic> map, String documentId) {
    return AppUser(
      id: documentId,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      isAdmin: map['isAdmin'] as bool? ?? false,
      isSeller: map['isSeller'] as bool? ?? false,
      isSuspended: map['isSuspended'] as bool? ?? false,
      shopName: map['shopName'] as String?,
      contactEmail: map['contactEmail'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      sellerApplicationStatus: map['sellerApplicationStatus'] as String?,
      rejectionReason: map['rejectionReason'] as String?,
      sellerApplicationTimestamp:
          map['sellerApplicationTimestamp'] as Timestamp?,
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  // toMap method updated to not include the id
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isAdmin': isAdmin,
      'isSeller': isSeller,
      'isSuspended': isSuspended,
      'shopName': shopName,
      'contactEmail': contactEmail,
      'phoneNumber': phoneNumber,
      'sellerApplicationStatus': sellerApplicationStatus,
      'rejectionReason': rejectionReason,
      'sellerApplicationTimestamp': sellerApplicationTimestamp,
      'createdAt': createdAt,
    };
  }

  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    bool? isSuspended,
    bool? isAdmin,
    bool? isSeller,
    String? shopName,
    String? contactEmail,
    String? phoneNumber, // Added to copyWith
    String? sellerApplicationStatus,
    String? rejectionReason,
    Timestamp? sellerApplicationTimestamp,
    Timestamp? createdAt,
  }) {
    return AppUser(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isAdmin: isAdmin ?? this.isAdmin,
      isSeller: isSeller ?? this.isSeller,
      isSuspended: isSuspended ?? this.isSuspended,
      shopName: shopName ?? this.shopName,
      contactEmail: contactEmail ?? this.contactEmail,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      sellerApplicationStatus:
          sellerApplicationStatus ?? this.sellerApplicationStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      sellerApplicationTimestamp:
          sellerApplicationTimestamp ?? this.sellerApplicationTimestamp,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
