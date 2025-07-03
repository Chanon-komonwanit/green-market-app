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

  // New fields for enhanced profile
  final String? bio;
  final String? address;
  final String? shopDescription;
  final String? motto;
  final double ecoCoins; // เปลี่ยนเป็น double เพื่อรองรับ 0.1 เหรียญ
  final String? website; // เพิ่ม field สำหรับ website
  final String? facebook; // เพิ่ม field สำหรับ Facebook
  final String? instagram; // เพิ่ม field สำหรับ Instagram
  final String? lineId; // เพิ่ม field สำหรับ Line ID
  final String? gender; // เพิ่ม field สำหรับ เพศ
  final DateTime? lastLoginDate; // เพิ่ม field สำหรับวันที่ล็อกอินล่าสุด
  final int consecutiveLoginDays; // เพิ่ม field สำหรับจำนวนวันล็อกอินติดต่อกัน
  final double
  loginRewardProgress; // เพิ่ม field สำหรับ progress การได้รางวัลจากการล็อกอิน (0.0-1.0)

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
    // New fields in constructor
    this.bio,
    this.address,
    this.shopDescription,
    this.motto,
    this.ecoCoins = 0.0, // เปลี่ยนเป็น double และ default 0.0
    this.website, // เพิ่ม field ใน constructor
    this.facebook, // เพิ่ม field ใน constructor
    this.instagram, // เพิ่ม field ใน constructor
    this.lineId, // เพิ่ม field ใน constructor
    this.gender, // เพิ่ม field ใน constructor
    this.lastLoginDate, // เพิ่ม field ใน constructor
    this.consecutiveLoginDays = 0, // เพิ่ม field ใน constructor
    this.loginRewardProgress = 0.0, // เพิ่ม field ใน constructor
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
      // New fields
      bio: map['bio'] as String?,
      address: map['address'] as String?,
      shopDescription: map['shopDescription'] as String?,
      motto: map['motto'] as String?,
      ecoCoins:
          (map['ecoCoins'] as num?)?.toDouble() ?? 0.0, // เปลี่ยนรองรับ double
      website: map['website'] as String?, // เพิ่ม field ใน fromMap
      facebook: map['facebook'] as String?, // เพิ่ม field ใน fromMap
      instagram: map['instagram'] as String?, // เพิ่ม field ใน fromMap
      lineId: map['lineId'] as String?, // เพิ่ม field ใน fromMap
      gender: map['gender'] as String?, // เพิ่ม field ใน fromMap
      lastLoginDate: map['lastLoginDate'] != null
          ? (map['lastLoginDate'] as Timestamp).toDate()
          : null, // เพิ่ม field ใน fromMap
      consecutiveLoginDays:
          map['consecutiveLoginDays'] as int? ?? 0, // เพิ่ม field ใน fromMap
      loginRewardProgress:
          (map['loginRewardProgress'] as num?)?.toDouble() ??
          0.0, // เพิ่ม field ใน fromMap
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
      // New fields
      'bio': bio,
      'address': address,
      'shopDescription': shopDescription,
      'motto': motto,
      'ecoCoins': ecoCoins, // เพิ่ม field ใน toMap
      'website': website, // เพิ่ม field ใน toMap
      'facebook': facebook, // เพิ่ม field ใน toMap
      'instagram': instagram, // เพิ่ม field ใน toMap
      'lineId': lineId, // เพิ่ม field ใน toMap
      'gender': gender, // เพิ่ม field ใน toMap
      'lastLoginDate': lastLoginDate != null
          ? Timestamp.fromDate(lastLoginDate!)
          : null, // เพิ่ม field ใน toMap
      'consecutiveLoginDays': consecutiveLoginDays, // เพิ่ม field ใน toMap
      'loginRewardProgress': loginRewardProgress, // เพิ่ม field ใน toMap
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
    // New fields in copyWith
    String? bio,
    String? address,
    String? shopDescription,
    String? motto,
    double? ecoCoins, // เปลี่ยนเป็น double
    String? website, // เพิ่ม field ใน copyWith
    String? facebook, // เพิ่ม field ใน copyWith
    String? instagram, // เพิ่ม field ใน copyWith
    String? lineId, // เพิ่ม field ใน copyWith
    String? gender, // เพิ่ม field ใน copyWith
    DateTime? lastLoginDate, // เพิ่ม field ใน copyWith
    int? consecutiveLoginDays, // เพิ่ม field ใน copyWith
    double? loginRewardProgress, // เพิ่ม field ใน copyWith
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
      // New fields
      bio: bio ?? this.bio,
      address: address ?? this.address,
      shopDescription: shopDescription ?? this.shopDescription,
      motto: motto ?? this.motto,
      ecoCoins: ecoCoins ?? this.ecoCoins, // เพิ่ม field ใน copyWith return
      website: website ?? this.website, // เพิ่ม field ใน copyWith return
      facebook: facebook ?? this.facebook, // เพิ่ม field ใน copyWith return
      instagram: instagram ?? this.instagram, // เพิ่ม field ใน copyWith return
      lineId: lineId ?? this.lineId, // เพิ่ม field ใน copyWith return
      gender: gender ?? this.gender, // เพิ่ม field ใน copyWith return
      lastLoginDate:
          lastLoginDate ?? this.lastLoginDate, // เพิ่ม field ใน copyWith return
      consecutiveLoginDays:
          consecutiveLoginDays ??
          this.consecutiveLoginDays, // เพิ่ม field ใน copyWith return
      loginRewardProgress:
          loginRewardProgress ??
          this.loginRewardProgress, // เพิ่ม field ใน copyWith return
    );
  }
}
