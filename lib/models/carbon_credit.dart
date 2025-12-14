// lib/models/carbon_credit.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for carbon credit status
enum CarbonCreditStatus {
  available, // พร้อมขาย
  pending, // รอการตรวจสอบ
  sold, // ขายแล้ว
  retired, // ใช้แล้ว (offset carbon)
}

/// Enum for carbon credit type
enum CarbonCreditType {
  renewable, // พลังงานหมุนเวียน
  forestry, // ป่าไม้
  energy, // ประสิทธิภาพพลังงาน
  waste, // การจัดการขยะ
  agriculture, // เกษตรกรรม
}

/// Model for Carbon Credit
class CarbonCredit {
  final String id;
  final String sellerId; // ผู้ขาย
  final String sellerName;
  final String? buyerId; // ผู้ซื้อ (null ถ้ายังไม่ขาย)
  final String? buyerName;
  final double tonsCO2; // จำนวนตัน CO2
  final double pricePerTon; // ราคาต่อตัน
  final CarbonCreditType type;
  final CarbonCreditStatus status;
  final String projectName; // ชื่อโครงการที่สร้างเครดิต
  final String description;
  final String certificateUrl; // URL ของใบรับรอง
  final DateTime createdAt;
  final DateTime? soldAt;
  final DateTime? retiredAt;
  final Timestamp? verifiedAt; // วันที่ตรวจสอบ

  CarbonCredit({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    this.buyerId,
    this.buyerName,
    required this.tonsCO2,
    required this.pricePerTon,
    required this.type,
    required this.status,
    required this.projectName,
    required this.description,
    required this.certificateUrl,
    required this.createdAt,
    this.soldAt,
    this.retiredAt,
    this.verifiedAt,
  });

  /// Calculate total price
  double get totalPrice => tonsCO2 * pricePerTon;

  /// Check if available for purchase
  bool get isAvailable => status == CarbonCreditStatus.available;

  /// Check if verified
  bool get isVerified => verifiedAt != null;

  /// Format status for display
  String get statusText {
    switch (status) {
      case CarbonCreditStatus.available:
        return 'พร้อมขาย';
      case CarbonCreditStatus.pending:
        return 'รอการตรวจสอบ';
      case CarbonCreditStatus.sold:
        return 'ขายแล้ว';
      case CarbonCreditStatus.retired:
        return 'ใช้แล้ว';
    }
  }

  /// Format type for display
  String get typeText {
    switch (type) {
      case CarbonCreditType.renewable:
        return 'พลังงานหมุนเวียน';
      case CarbonCreditType.forestry:
        return 'ป่าไม้';
      case CarbonCreditType.energy:
        return 'ประสิทธิภาพพลังงาน';
      case CarbonCreditType.waste:
        return 'การจัดการขยะ';
      case CarbonCreditType.agriculture:
        return 'เกษตรกรรม';
    }
  }

  factory CarbonCredit.fromMap(Map<String, dynamic> map) {
    return CarbonCredit(
      id: map['id'] as String? ?? '',
      sellerId: map['sellerId'] as String? ?? '',
      sellerName: map['sellerName'] as String? ?? 'Unknown',
      buyerId: map['buyerId'] as String?,
      buyerName: map['buyerName'] as String?,
      tonsCO2: (map['tonsCO2'] as num?)?.toDouble() ?? 0.0,
      pricePerTon: (map['pricePerTon'] as num?)?.toDouble() ?? 0.0,
      type: CarbonCreditType.values.firstWhere(
        (e) => e.name == (map['type'] as String?),
        orElse: () => CarbonCreditType.renewable,
      ),
      status: CarbonCreditStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String?),
        orElse: () => CarbonCreditStatus.pending,
      ),
      projectName: map['projectName'] as String? ?? '',
      description: map['description'] as String? ?? '',
      certificateUrl: map['certificateUrl'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      soldAt: (map['soldAt'] as Timestamp?)?.toDate(),
      retiredAt: (map['retiredAt'] as Timestamp?)?.toDate(),
      verifiedAt: map['verifiedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'tonsCO2': tonsCO2,
      'pricePerTon': pricePerTon,
      'type': type.name,
      'status': status.name,
      'projectName': projectName,
      'description': description,
      'certificateUrl': certificateUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'soldAt': soldAt != null ? Timestamp.fromDate(soldAt!) : null,
      'retiredAt': retiredAt != null ? Timestamp.fromDate(retiredAt!) : null,
      'verifiedAt': verifiedAt,
    };
  }

  CarbonCredit copyWith({
    String? id,
    String? sellerId,
    String? sellerName,
    String? buyerId,
    String? buyerName,
    double? tonsCO2,
    double? pricePerTon,
    CarbonCreditType? type,
    CarbonCreditStatus? status,
    String? projectName,
    String? description,
    String? certificateUrl,
    DateTime? createdAt,
    DateTime? soldAt,
    DateTime? retiredAt,
    Timestamp? verifiedAt,
  }) {
    return CarbonCredit(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      tonsCO2: tonsCO2 ?? this.tonsCO2,
      pricePerTon: pricePerTon ?? this.pricePerTon,
      type: type ?? this.type,
      status: status ?? this.status,
      projectName: projectName ?? this.projectName,
      description: description ?? this.description,
      certificateUrl: certificateUrl ?? this.certificateUrl,
      createdAt: createdAt ?? this.createdAt,
      soldAt: soldAt ?? this.soldAt,
      retiredAt: retiredAt ?? this.retiredAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }

  /// Validation
  bool validate() {
    return id.isNotEmpty &&
        sellerId.isNotEmpty &&
        tonsCO2 > 0 &&
        pricePerTon > 0 &&
        projectName.isNotEmpty;
  }
}
