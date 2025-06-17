// lib/models/cart_item.dart
import 'package:green_market/models/product.dart'; // สำหรับ Product model

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  // เมธอดสำหรับเพิ่ม/ลดจำนวนสินค้า
  void incrementQuantity() {
    quantity++;
  }

  void decrementQuantity() {
    if (quantity > 1) {
      quantity--;
    }
  }

  // คำนวณราคารวมของสินค้ารายการนี้
  double get totalPrice => product.price * quantity;
}
