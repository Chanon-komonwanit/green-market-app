// lib/models/order_item.dart
// ใช้สำหรับรายการสินค้าแต่ละชิ้นที่อยู่ในคำสั่งซื้อ
class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double pricePerUnit;
  final String imageUrl;
  final int ecoScore;
  final String sellerId; // Added sellerId

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.pricePerUnit,
    required this.imageUrl,
    required this.ecoScore,
    required this.sellerId, // Added to constructor
  });

  // ใช้สำหรับแปลงจาก Map (ที่มาจาก Firestore) ไปเป็น OrderItem object
  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      quantity: data['quantity'] ?? 0,
      pricePerUnit: (data['pricePerUnit'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      ecoScore: data['ecoScore'] ?? 0,
      sellerId: data['sellerId'] ?? '', // Retrieve sellerId
    );
  }

  // ใช้สำหรับแปลงจาก OrderItem object ไปเป็น Map (เพื่อบันทึกลง Firestore)
  Map<String, dynamic> toMap() {
    return {
      'productId': productId, // ID ของสินค้า
      'productName': productName, // ชื่อสินค้า
      'quantity': quantity,
      'pricePerUnit': pricePerUnit,
      'imageUrl': imageUrl,
      'ecoScore': ecoScore,
      'sellerId': sellerId, // ID ของผู้ขายสินค้านี้
    };
  }
}
