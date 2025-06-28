// lib/models/order_item.dart
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp if needed

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
    required this.sellerId,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] as String,
      productName: map['productName'] as String,
      quantity: map['quantity'] as int,
      pricePerUnit: (map['pricePerUnit'] as num).toDouble(),
      imageUrl: map['imageUrl'] as String,
      ecoScore: map['ecoScore'] as int,
      sellerId: map['sellerId'] as String? ??
          '', // Default to empty string if not found
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'pricePerUnit': pricePerUnit,
      'imageUrl': imageUrl,
      'ecoScore': ecoScore,
      'sellerId': sellerId,
    };
  }

  OrderItem copyWith({
    String? productId,
    String? productName,
    int? quantity,
    double? pricePerUnit,
    String? imageUrl,
    int? ecoScore,
    String? sellerId,
  }) {
    return OrderItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      imageUrl: imageUrl ?? this.imageUrl,
      ecoScore: ecoScore ?? this.ecoScore,
      sellerId: sellerId ?? this.sellerId,
    );
  }
}
