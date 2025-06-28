// lib/models/cart_item.dart

class CartItem {
  final String id; // Can be the same as productId
  final String productId;
  final String name;
  final String imageUrl;
  final double price;
  final int quantity;
  final String sellerId;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.sellerId,
  });

  double get totalPrice => price * quantity;

  CartItem copyWith({
    String? id,
    String? productId,
    String? name,
    String? imageUrl,
    double? price,
    int? quantity,
    String? sellerId,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      sellerId: sellerId ?? this.sellerId,
      // No 'product' parameter needed here anymore
    );
  }

  // Convert a CartItem instance to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
      'sellerId': sellerId,
    };
  }

  // Create a CartItem instance from a Firestore document
  factory CartItem.fromMap(Map<String, dynamic> data) {
    return CartItem(
      id: data['id'] ?? '',
      productId: data['productId'] ?? data['id'] ?? '', // Fallback for old data
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      quantity: data['quantity'] ?? 0,
      sellerId: data['sellerId'] ?? '',
      // No 'product' parameter needed here anymore
    );
  }
}
