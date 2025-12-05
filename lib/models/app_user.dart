// lib/models/app_user.dart
// โมเดลสำหรับข้อมูลผู้ใช้ในแอป Green Market
// รองรับผู้ซื้อ, ผู้ขาย, และแอดมิน พร้อมระบบ eco coins และโปรไฟล์โซเชียล
// Enhanced for production with comprehensive validation and error handling

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// Enums for better type safety
enum UserRole { buyer, seller, admin }

enum SellerApplicationStatus { pending, approved, rejected, none }

enum Gender { male, female, other, notSpecified }

// Validation errors enum
enum UserValidationError {
  emptyEmail,
  invalidEmail,
  emptyDisplayName,
  invalidDisplayName,
  invalidPhoneNumber,
  invalidWebsite,
  invalidSocialMedia,
  negativeEcoCoins,
  invalidBio,
  invalidAddress,
}

/// โมเดลสำหรับข้อมูลผู้ใช้ในระบบ Green Market
/// รองรับการจัดการสิทธิ์, โปรไฟล์, และระบบ eco coins
/// Enhanced with comprehensive validation, error handling, and type safety
@immutable
class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? coverPhotoUrl; // เพิ่ม field สำหรับรูปภาพปก
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

  // Enhanced profile fields with validation
  final String? bio;
  final String? address;
  final String? shopDescription;
  final String? motto;
  final double
      ecoCoins; // เปลี่ยนเป็น double เพื่อรองรับ 0.1 เหรียญ (สำหรับตลาด)

  // Eco Influence Score - สำหรับชุมชนสีเขียว (แยกจาก ecoCoins)
  final double ecoInfluenceScore; // คะแนนอิทธิพลชุมชนสีเขียว (0-100)
  final int followersCount; // จำนวนผู้ติดตาม
  final int challengesCompleted; // จำนวนภารกิจที่ทำสำเร็จ
  final int communityPostsCount; // จำนวนโพสต์ในชุมชน
  final int communityEngagement; // การมีส่วนร่วม (likes + comments + shares)
  final double ecoProductsPurchased; // มูลค่าสินค้า ECO ที่ซื้อ
  final DateTime? lastInfluenceUpdate; // อัปเดตคะแนนล่าสุด

  // Content Moderation & Violations
  final int violationCount; // จำนวนครั้งที่ถูกตรวจพบการละเมิด
  final List<Map<String, dynamic>> violationHistory; // ประวัติการละเมิด
  final DateTime? lastViolationDate; // วันที่ถูกตรวจพบล่าสุด
  final double penaltyPercentage; // เปร์เซ็นต์หักคะแนน (0-100%)

  final String? website; // เพิ่ม field สำหรับ website
  final String? facebook; // เพิ่ม field สำหรับ Facebook
  final String? instagram; // เพิ่ม field สำหรับ Instagram
  final String? lineId; // เพิ่ม field สำหรับ Line ID
  final String? gender; // เพิ่ม field สำหรับ เพศ
  final DateTime? lastLoginDate; // เพิ่ม field สำหรับวันที่ล็อกอินล่าสุด
  final int consecutiveLoginDays; // เพิ่ม field สำหรับจำนวนวันล็อกอินติดต่อกัน
  final double
      loginRewardProgress; // เพิ่ม field สำหรับ progress การได้รางวัลจากการล็อกอิน (0.0-1.0)

  // Privacy settings with enhanced control
  final bool showEmail; // เพิ่ม field สำหรับ visibility
  final bool showFacebook;
  final bool showInstagram;
  final bool showLine;

  // Enhanced metadata for production
  final DateTime? lastUpdated;
  final int version; // For optimistic locking
  final Map<String, dynamic>? metadata; // For extensibility

  // Validation state cache (computed properties)
  late final List<UserValidationError> _validationErrors;

  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.coverPhotoUrl, // เพิ่มพารามิเตอร์
    this.isAdmin = false,
    this.isSeller = false,
    this.isSuspended = false,
    this.shopName,
    this.contactEmail,
    this.phoneNumber,
    this.sellerApplicationStatus,
    this.rejectionReason,
    this.sellerApplicationTimestamp,
    required this.createdAt,
    this.bio,
    this.address,
    this.shopDescription,
    this.motto,
    this.ecoCoins = 0.0,
    this.ecoInfluenceScore = 0.0,
    this.followersCount = 0,
    this.challengesCompleted = 0,
    this.communityPostsCount = 0,
    this.communityEngagement = 0,
    this.ecoProductsPurchased = 0.0,
    this.lastInfluenceUpdate,
    this.violationCount = 0,
    this.violationHistory = const [],
    this.lastViolationDate,
    this.penaltyPercentage = 0.0,
    this.website,
    this.facebook,
    this.instagram,
    this.lineId,
    this.gender,
    this.lastLoginDate,
    this.consecutiveLoginDays = 0,
    this.loginRewardProgress = 0.0,
    this.showEmail = false,
    this.showFacebook = false,
    this.showInstagram = false,
    this.showLine = false,
    this.lastUpdated,
    this.version = 1,
    this.metadata,
  }) {
    // Validate on construction and cache validation errors
    _validationErrors = _validateUser();
  }

  // Enhanced getters with type safety
  UserRole get userRole {
    if (isAdmin) return UserRole.admin;
    if (isSeller) return UserRole.seller;
    return UserRole.buyer;
  }

  SellerApplicationStatus get sellerStatus {
    switch (sellerApplicationStatus?.toLowerCase()) {
      case 'pending':
        return SellerApplicationStatus.pending;
      case 'approved':
        return SellerApplicationStatus.approved;
      case 'rejected':
        return SellerApplicationStatus.rejected;
      default:
        return SellerApplicationStatus.none;
    }
  }

  Gender get userGender {
    switch (gender?.toLowerCase()) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      case 'other':
        return Gender.other;
      default:
        return Gender.notSpecified;
    }
  }

  // Validation getters
  bool get isValid => _validationErrors.isEmpty;
  List<UserValidationError> get validationErrors =>
      List.unmodifiable(_validationErrors);
  bool get hasValidationErrors => _validationErrors.isNotEmpty;

  // Getter for profile image URL
  String? get profileImageUrl => photoUrl;

  // Enhanced business logic getters
  bool get canBecomeSeller =>
      !isAdmin && !isSeller && sellerStatus == SellerApplicationStatus.none;
  bool get hasCompletedProfile =>
      isValidBasicInfo && bio != null && address != null;
  bool get isActiveUser => !isSuspended && lastLoginDate != null;
  bool get isRecentlyActive =>
      lastLoginDate != null &&
      DateTime.now().difference(lastLoginDate!).inDays <= 30;

  // A derived property for convenience, but the source of truth are the boolean flags.
  String get role {
    if (isAdmin) return 'admin';
    if (isSeller) return 'seller';
    return 'buyer';
  }

  // Enhanced factory constructor with validation and error handling
  factory AppUser.fromMap(Map<String, dynamic> map, String documentId) {
    try {
      return AppUser(
        id: documentId,
        email: _validateAndParseEmail(map['email']),
        displayName: map['displayName'] as String?,
        photoUrl: map['photoUrl'] as String?,
        coverPhotoUrl: map['coverPhotoUrl'] as String?, // เพิ่ม field
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
        bio: map['bio'] as String?,
        address: map['address'] as String?,
        shopDescription: map['shopDescription'] as String?,
        motto: map['motto'] as String?,
        ecoCoins: _validateAndParseEcoCoins(map['ecoCoins']),
        ecoInfluenceScore:
            (map['ecoInfluenceScore'] as num?)?.toDouble() ?? 0.0,
        followersCount: map['followersCount'] as int? ?? 0,
        challengesCompleted: map['challengesCompleted'] as int? ?? 0,
        communityPostsCount: map['communityPostsCount'] as int? ?? 0,
        communityEngagement: map['communityEngagement'] as int? ?? 0,
        ecoProductsPurchased:
            (map['ecoProductsPurchased'] as num?)?.toDouble() ?? 0.0,
        lastInfluenceUpdate: map['lastInfluenceUpdate'] != null
            ? (map['lastInfluenceUpdate'] as Timestamp).toDate()
            : null,
        violationCount: map['violationCount'] as int? ?? 0,
        violationHistory: (map['violationHistory'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [],
        lastViolationDate: map['lastViolationDate'] != null
            ? (map['lastViolationDate'] as Timestamp).toDate()
            : null,
        penaltyPercentage:
            (map['penaltyPercentage'] as num?)?.toDouble() ?? 0.0,
        website: map['website'] as String?,
        facebook: map['facebook'] as String?,
        instagram: map['instagram'] as String?,
        lineId: map['lineId'] as String?,
        gender: map['gender'] as String?,
        lastLoginDate: map['lastLoginDate'] != null
            ? (map['lastLoginDate'] as Timestamp).toDate()
            : null,
        consecutiveLoginDays: map['consecutiveLoginDays'] as int? ?? 0,
        loginRewardProgress:
            (map['loginRewardProgress'] as num?)?.toDouble() ?? 0.0,
        showEmail: map['showEmail'] as bool? ?? false,
        showFacebook: map['showFacebook'] as bool? ?? false,
        showInstagram: map['showInstagram'] as bool? ?? false,
        showLine: map['showLine'] as bool? ?? false,
        lastUpdated: map['lastUpdated'] != null
            ? (map['lastUpdated'] as Timestamp).toDate()
            : null,
        version: map['version'] as int? ?? 1,
        metadata: map['metadata'] as Map<String, dynamic>?,
      );
    } catch (e) {
      // Log error and return a default user with validation errors
      debugPrint('Error parsing AppUser from map: $e');
      return AppUser(
        id: documentId,
        email: map['email'] as String? ?? 'invalid@example.com',
        createdAt: Timestamp.now(),
      );
    }
  }

  // toMap method updated to not include the id
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'coverPhotoUrl': coverPhotoUrl, // เพิ่ม field
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
      'ecoInfluenceScore': ecoInfluenceScore,
      'followersCount': followersCount,
      'challengesCompleted': challengesCompleted,
      'communityPostsCount': communityPostsCount,
      'communityEngagement': communityEngagement,
      'ecoProductsPurchased': ecoProductsPurchased,
      'lastInfluenceUpdate': lastInfluenceUpdate != null
          ? Timestamp.fromDate(lastInfluenceUpdate!)
          : null,
      'violationCount': violationCount,
      'violationHistory': violationHistory,
      'lastViolationDate': lastViolationDate != null
          ? Timestamp.fromDate(lastViolationDate!)
          : null,
      'penaltyPercentage': penaltyPercentage,
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
      'showEmail': showEmail,
      'showFacebook': showFacebook,
      'showInstagram': showInstagram,
      'showLine': showLine,
      'lastUpdated':
          lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
      'version': version,
      'metadata': metadata,
    };
  }

  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    String? coverPhotoUrl, // เพิ่มพารามิเตอร์
    bool? isSuspended,
    bool? isAdmin,
    bool? isSeller,
    String? shopName,
    String? contactEmail,
    String? phoneNumber,
    String? sellerApplicationStatus,
    String? rejectionReason,
    Timestamp? sellerApplicationTimestamp,
    Timestamp? createdAt,
    String? bio,
    String? address,
    String? shopDescription,
    String? motto,
    double? ecoCoins,
    double? ecoInfluenceScore,
    int? followersCount,
    int? challengesCompleted,
    int? communityPostsCount,
    int? communityEngagement,
    double? ecoProductsPurchased,
    DateTime? lastInfluenceUpdate,
    String? website,
    String? facebook,
    String? instagram,
    String? lineId,
    String? gender,
    DateTime? lastLoginDate,
    int? consecutiveLoginDays,
    double? loginRewardProgress,
    bool? showEmail,
    bool? showFacebook,
    bool? showInstagram,
    bool? showLine,
    DateTime? lastUpdated,
    int? version,
    Map<String, dynamic>? metadata,
  }) {
    return AppUser(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl, // เพิ่ม field
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
      bio: bio ?? this.bio,
      address: address ?? this.address,
      shopDescription: shopDescription ?? this.shopDescription,
      motto: motto ?? this.motto,
      ecoCoins: ecoCoins ?? this.ecoCoins,
      ecoInfluenceScore: ecoInfluenceScore ?? this.ecoInfluenceScore,
      followersCount: followersCount ?? this.followersCount,
      challengesCompleted: challengesCompleted ?? this.challengesCompleted,
      communityPostsCount: communityPostsCount ?? this.communityPostsCount,
      communityEngagement: communityEngagement ?? this.communityEngagement,
      ecoProductsPurchased: ecoProductsPurchased ?? this.ecoProductsPurchased,
      lastInfluenceUpdate: lastInfluenceUpdate ?? this.lastInfluenceUpdate,
      website: website ?? this.website,
      facebook: facebook ?? this.facebook,
      instagram: instagram ?? this.instagram,
      lineId: lineId ?? this.lineId,
      gender: gender ?? this.gender,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      consecutiveLoginDays: consecutiveLoginDays ?? this.consecutiveLoginDays,
      loginRewardProgress: loginRewardProgress ?? this.loginRewardProgress,
      showEmail: showEmail ?? this.showEmail,
      showFacebook: showFacebook ?? this.showFacebook,
      showInstagram: showInstagram ?? this.showInstagram,
      showLine: showLine ?? this.showLine,
      lastUpdated: lastUpdated ?? DateTime.now(), // Auto-update timestamp
      version: version ??
          (this.version + 1), // Increment version for optimistic locking
      metadata: metadata ?? this.metadata,
    );
  }

  /// Validation methods สำหรับตรวจสอบความถูกต้องของข้อมูล

  /// ตรวจสอบว่าข้อมูลพื้นฐานครบถ้วนหรือไม่
  bool get isValidBasicInfo {
    return email.isNotEmpty && displayName != null && displayName!.isNotEmpty;
  }

  /// ตรวจสอบว่าโปรไฟล์ผู้ขายครบถ้วนหรือไม่
  bool get isValidSellerProfile {
    if (!isSeller) return false;
    return shopName != null &&
        shopName!.isNotEmpty &&
        contactEmail != null &&
        contactEmail!.isNotEmpty;
  }

  /// ตรวจสอบว่าสามารถสมัครเป็นผู้ขายได้หรือไม่
  bool get canApplyToBecomeSeller {
    return !isAdmin &&
        !isSeller &&
        sellerApplicationStatus == null &&
        isValidBasicInfo;
  }

  /// ตรวจสอบระดับความสมบูรณ์ของโปรไฟล์ (0.0 - 1.0)
  double get profileCompleteness {
    int completedFields = 0;
    int totalFields = 10;

    if (displayName?.isNotEmpty == true) completedFields++;
    if (photoUrl?.isNotEmpty == true) completedFields++;
    if (bio?.isNotEmpty == true) completedFields++;
    if (address?.isNotEmpty == true) completedFields++;
    if (phoneNumber?.isNotEmpty == true) completedFields++;
    if (website?.isNotEmpty == true) completedFields++;
    if (facebook?.isNotEmpty == true) completedFields++;
    if (instagram?.isNotEmpty == true) completedFields++;
    if (lineId?.isNotEmpty == true) completedFields++;
    if (gender?.isNotEmpty == true) completedFields++;

    return completedFields / totalFields;
  }

  /// ตรวจสอบว่าเป็นผู้ใช้ที่ active หรือไม่
  bool get isActive {
    return !isSuspended &&
        (lastLoginDate == null ||
            DateTime.now().difference(lastLoginDate!).inDays < 90);
  }

  /// ได้รางวัลจากการล็อกอินติดต่อกันหรือไม่
  bool get canGetLoginReward {
    return consecutiveLoginDays >= 7 && loginRewardProgress >= 1.0;
  }

  /// แสดงชื่อที่ใช้ในการแสดงผล
  String get displayNameOrEmail {
    return displayName?.isNotEmpty == true ? displayName! : email;
  }

  /// แสดงสถานะการสมัครผู้ขายแบบ user-friendly
  String get sellerApplicationStatusDisplay {
    switch (sellerApplicationStatus) {
      case 'pending':
        return 'รอการอนุมัติ';
      case 'approved':
        return 'อนุมัติแล้ว';
      case 'rejected':
        return 'ถูกปฏิเสธ';
      default:
        return 'ยังไม่ได้สมัคร';
    }
  }

  /// สร้าง summary ของผู้ใช้สำหรับ logging/audit
  Map<String, dynamic> toSummary() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'role': role,
      'ecoCoins': ecoCoins,
      'isActive': isActiveUser,
      'profileCompleteness': profileCompleteness,
      'lastLoginDate': lastLoginDate?.toIso8601String(),
      'validationErrors': _validationErrors.map((e) => e.toString()).toList(),
    };
  }

  // Static validation helpers
  static String _validateAndParseEmail(dynamic email) {
    final emailStr = email as String? ?? '';
    if (emailStr.isEmpty) {
      throw ArgumentError('Email cannot be empty');
    }
    if (!_isValidEmail(emailStr)) {
      throw ArgumentError('Invalid email format: $emailStr');
    }
    return emailStr.toLowerCase().trim();
  }

  static double _validateAndParseEcoCoins(dynamic ecoCoins) {
    if (ecoCoins == null) return 0.0;
    final coins = (ecoCoins as num).toDouble();
    if (coins < 0) {
      throw ArgumentError('Eco coins cannot be negative: $coins');
    }
    return coins;
  }

  static bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) return true;
    return Uri.tryParse(url) != null && url.startsWith(RegExp(r'https?://'));
  }

  static bool _isValidPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return true;
    return RegExp(r'^\+?[0-9\-\(\)\s]{8,15}$').hasMatch(phone);
  }

  // Comprehensive validation method
  List<UserValidationError> _validateUser() {
    final errors = <UserValidationError>[];

    // Email validation
    if (email.isEmpty) {
      errors.add(UserValidationError.emptyEmail);
    } else if (!_isValidEmail(email)) {
      errors.add(UserValidationError.invalidEmail);
    }

    // Display name validation
    if (displayName?.trim().isEmpty ?? true) {
      errors.add(UserValidationError.emptyDisplayName);
    } else if (displayName!.length > 100) {
      errors.add(UserValidationError.invalidDisplayName);
    }

    // Phone validation
    if (!_isValidPhoneNumber(phoneNumber)) {
      errors.add(UserValidationError.invalidPhoneNumber);
    }

    // Website validation
    if (!_isValidUrl(website)) {
      errors.add(UserValidationError.invalidWebsite);
    }

    // Eco coins validation
    if (ecoCoins < 0) {
      errors.add(UserValidationError.negativeEcoCoins);
    }

    // Bio validation
    if (bio != null && bio!.length > 500) {
      errors.add(UserValidationError.invalidBio);
    }

    // Address validation
    if (address != null && address!.length > 300) {
      errors.add(UserValidationError.invalidAddress);
    }

    return errors;
  }

  // Enhanced utility methods
  AppUser updateLoginStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastLogin = lastLoginDate != null
        ? DateTime(
            lastLoginDate!.year, lastLoginDate!.month, lastLoginDate!.day)
        : null;

    if (lastLogin == null || today.difference(lastLogin).inDays > 1) {
      // Reset streak if more than 1 day gap
      return copyWith(
        lastLoginDate: now,
        consecutiveLoginDays: 1,
        loginRewardProgress: 0.0,
      );
    } else if (today.difference(lastLogin).inDays == 1) {
      // Continue streak
      return copyWith(
        lastLoginDate: now,
        consecutiveLoginDays: consecutiveLoginDays + 1,
        loginRewardProgress: ((consecutiveLoginDays + 1) % 7) / 7.0,
      );
    } else {
      // Same day login, just update timestamp
      return copyWith(lastLoginDate: now);
    }
  }

  AppUser awardEcoCoins(double amount, {String? reason}) {
    if (amount <= 0) return this;

    final newMetadata = Map<String, dynamic>.from(metadata ?? {});
    newMetadata['lastEcoCoinAward'] = {
      'amount': amount,
      'reason': reason ?? 'Unknown',
      'timestamp': DateTime.now().toIso8601String(),
    };

    return copyWith(
      ecoCoins: ecoCoins + amount,
      metadata: newMetadata,
    );
  }

  AppUser spendEcoCoins(double amount) {
    if (amount <= 0 || amount > ecoCoins) {
      throw ArgumentError(
          'Invalid eco coins amount to spend: $amount (available: $ecoCoins)');
    }
    return copyWith(ecoCoins: ecoCoins - amount);
  }

  @override
  String toString() {
    return 'AppUser(id: $id, email: $email, role: $role, ecoCoins: $ecoCoins, '
        'valid: $isValid, version: $version)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser && other.id == id && other.version == version;
  }

  @override
  int get hashCode => Object.hash(id, version);

  // Additional factory constructors for specific use cases
  factory AppUser.newBuyer({
    required String id,
    required String email,
    String? displayName,
    String? photoUrl,
  }) {
    return AppUser(
      id: id,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      createdAt: Timestamp.now(),
      isAdmin: false,
      isSeller: false,
    );
  }

  factory AppUser.newSeller({
    required String id,
    required String email,
    required String displayName,
    required String shopName,
    required String contactEmail,
    String? photoUrl,
    String? shopDescription,
  }) {
    return AppUser(
      id: id,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      createdAt: Timestamp.now(),
      isAdmin: false,
      isSeller: true,
      shopName: shopName,
      contactEmail: contactEmail,
      shopDescription: shopDescription,
      sellerApplicationStatus: 'approved',
      sellerApplicationTimestamp: Timestamp.now(),
    );
  }

  factory AppUser.newAdmin({
    required String id,
    required String email,
    required String displayName,
    String? photoUrl,
  }) {
    return AppUser(
      id: id,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      createdAt: Timestamp.now(),
      isAdmin: true,
      isSeller: false,
    );
  }
}
