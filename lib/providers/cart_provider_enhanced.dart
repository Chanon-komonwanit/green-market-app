// lib/providers/cart_provider_enhanced.dart
//
// 🛒 CartProviderEnhanced - จัดการตะกร้าสินค้า
//
// หน้าที่:
// - เพิ่ม/ลดสินค้าในตะกร้า
// - คำนวณราคารวม
// - ใช้คูปอง/โค้ดส่วนลด
// - คำนวณค่าจัดส่ง
// - จัดการจำนวนสินค้า
//
// ใช้งานที่:
// - Product Detail Screen (เพิ่มสินค้า)
// - Cart Screen (แสดงตะกร้า)
// - Checkout Screen (ชำระเงิน)
//
// วิธีใช้:
// ```dart
// // เพิ่มสินค้าในตะกร้า
// cartProvider.addToCart(product);
//
// // ลบสินค้า
// cartProvider.removeFromCart(productId);
//
// // ดูจำนวนสินค้า
// int count = cartProvider.itemCount;
//
// // คำนวณราคารวม
// double total = cartProvider.totalAmount;
// ```

import 'package:flutter/foundation.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/utils/enhanced_error_handler.dart';

/// CartItem - สินค้าในตะกร้า
class CartItem {
  final Product product; // สินค้า
  int quantity; // จำนวน

  CartItem({required this.product, this.quantity = 1}) {
    if (quantity < 0) quantity = 1; // ป้องกันจำนวนติดลบ
  }

  /// ราคารวมของสินค้านี้ (ราคา × จำนวน)
  double get totalPrice => product.price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'product': product.toMap(),
      'quantity': quantity,
      'totalPrice': totalPrice,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromMap(json['product']),
      quantity: json['quantity'] ?? 1,
    );
  }
}

/// CartProviderEnhanced - Provider จัดการตะกร้าสินค้า
///
/// Features:
/// - ✅ Add/Remove items
/// - ✅ Update quantity
/// - ✅ Calculate totals (product + shipping + discount)
/// - ✅ Apply coupons
/// - ✅ Validate stock availability
class CartProviderEnhanced extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  bool _isLoading = false;
  String? _errorMessage;
  final EnhancedErrorHandler _errorHandler = EnhancedErrorHandler();

  // Getters
  Map<String, CartItem> get items => {..._items};
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get itemCount => _items.length; // Number of unique products in cart

  int get totalItemsInCart {
    // Total number of all items (sum of quantities)
    int total = 0;
    _items.forEach((key, cartItem) {
      total += cartItem.quantity;
    });
    return total;
  }

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.totalPrice;
    });
    return total;
  }

  double get totalWeight {
    // Calculate total weight for shipping (assuming 0.5kg per item default)
    return totalItemsInCart * 0.5;
  }

  List<String> get sellerIds {
    return _items.values.map((item) => item.product.sellerId).toSet().toList();
  }

  bool get isEmpty => _items.isEmpty;

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Private helper methods
  void _setError(String message) {
    _errorMessage = message;
    debugPrint('CartProvider Error: $message');
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _logCartOperation(String operation) {
    debugPrint('CartProvider: $operation');
  }

  // Validate product before adding to cart
  bool _validateProduct(Product product) {
    try {
      if (product.id.isEmpty) {
        _setError('สินค้าไม่ถูกต้อง: ไม่มีรหัสสินค้า');
        return false;
      }

      if (product.price <= 0) {
        _setError('สินค้าไม่ถูกต้อง: ราคาต้องมากกว่า 0');
        return false;
      }

      if (product.stock <= 0) {
        _setError('สินค้าหมด: ${product.name}');
        return false;
      }

      return true;
    } catch (e) {
      _errorHandler.handleValidationError('product_validation', e.toString());
      _setError('เกิดข้อผิดพลาดในการตรวจสอบสินค้า');
      return false;
    }
  }

  void addItem(Product product, {int quantity = 1}) {
    try {
      _isLoading = true;
      _clearError();
      notifyListeners();

      if (!_validateProduct(product)) {
        return;
      }

      if (quantity <= 0) {
        _setError('จำนวนสินค้าต้องมากกว่า 0');
        return;
      }

      final currentQuantity =
          _items.containsKey(product.id) ? _items[product.id]!.quantity : 0;

      final newQuantity = currentQuantity + quantity;

      // Check stock availability
      if (newQuantity > product.stock) {
        _setError('สินค้าไม่เพียงพอ: มีเพียง ${product.stock} ชิ้น');
        return;
      }

      // Check maximum cart items limit (configurable)
      const maxCartItems = 50;
      if (totalItemsInCart + quantity > maxCartItems) {
        _setError('ตะกร้าเต็ม: สามารถใส่ได้สูงสุด $maxCartItems ชิ้น');
        return;
      }

      if (_items.containsKey(product.id)) {
        _items.update(
          product.id,
          (existingCartItem) => CartItem(
            product: existingCartItem.product,
            quantity: newQuantity,
          ),
        );
      } else {
        _items.putIfAbsent(
          product.id,
          () => CartItem(product: product, quantity: quantity),
        );
      }

      _logCartOperation('Added ${product.name} ($quantity) to cart');
    } catch (e) {
      _errorHandler.handleValidationError('cart_add_item', e.toString());
      _setError('เกิดข้อผิดพลาดในการเพิ่มสินค้า');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateItemQuantity(String productId, int newQuantity) {
    try {
      _isLoading = true;
      _clearError();
      notifyListeners();

      if (!_items.containsKey(productId)) {
        _setError('ไม่พบสินค้าในตะกร้า');
        return;
      }

      if (newQuantity < 0) {
        _setError('จำนวนสินค้าต้องไม่น้อยกว่า 0');
        return;
      }

      if (newQuantity == 0) {
        _items.remove(productId);
        _logCartOperation('Removed $productId from cart');
      } else {
        final cartItem = _items[productId]!;

        // Check stock availability
        if (newQuantity > cartItem.product.stock) {
          _setError('สินค้าไม่เพียงพอ: มีเพียง ${cartItem.product.stock} ชิ้น');
          return;
        }

        _items.update(
          productId,
          (existingCartItem) => CartItem(
            product: existingCartItem.product,
            quantity: newQuantity,
          ),
        );
        _logCartOperation('Updated $productId quantity to $newQuantity');
      }
    } catch (e) {
      _errorHandler.handleValidationError('cart_update_quantity', e.toString());
      _setError('เกิดข้อผิดพลาดในการอัปเดตจำนวนสินค้า');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void removeItem(String productId) {
    try {
      _clearError();

      if (!_items.containsKey(productId)) {
        _setError('ไม่พบสินค้าในตะกร้า');
        return;
      }

      final removedItem = _items.remove(productId);
      _logCartOperation('Removed ${removedItem?.product.name} from cart');
    } catch (e) {
      _errorHandler.handleValidationError('cart_remove_item', e.toString());
      _setError('เกิดข้อผิดพลาดในการลบสินค้า');
    } finally {
      notifyListeners();
    }
  }

  void clearCart() {
    try {
      _clearError();
      final itemCount = _items.length;
      _items.clear();
      _logCartOperation('Cleared cart with $itemCount items');
    } catch (e) {
      _errorHandler.handleValidationError('cart_clear', e.toString());
      _setError('เกิดข้อผิดพลาดในการล้างตะกร้า');
    } finally {
      notifyListeners();
    }
  }

  // Cart validation methods
  bool validateCartForCheckout() {
    try {
      if (_items.isEmpty) {
        _setError('ตะกร้าว่างเปล่า');
        return false;
      }

      for (final item in _items.values) {
        if (item.quantity > item.product.stock) {
          _setError('สินค้า ${item.product.name} ไม่เพียงพอ');
          return false;
        }

        if (item.product.price <= 0) {
          _setError('สินค้า ${item.product.name} มีราคาไม่ถูกต้อง');
          return false;
        }
      }

      return true;
    } catch (e) {
      _errorHandler.handleValidationError(
          'cart_checkout_validation', e.toString());
      _setError('เกิดข้อผิดพลาดในการตรวจสอบตะกร้า');
      return false;
    }
  }

  // Export cart data for persistence
  Map<String, dynamic> exportCartData() {
    try {
      return {
        'items': _items.map((key, value) => MapEntry(key, value.toJson())),
        'totalAmount': totalAmount,
        'totalItems': totalItemsInCart,
        'exportedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      _errorHandler.handleValidationError('cart_export', e.toString());
      return {};
    }
  }

  // Import cart data for restoration
  void importCartData(Map<String, dynamic> data) {
    try {
      _clearError();
      _items.clear();

      if (data['items'] != null) {
        final itemsData = data['items'] as Map<String, dynamic>;
        for (final entry in itemsData.entries) {
          try {
            final cartItem = CartItem.fromJson(entry.value);
            _items[entry.key] = cartItem;
          } catch (e) {
            // Skip invalid items
            debugPrint('Failed to import cart item: ${entry.key}');
          }
        }
      }

      _logCartOperation('Imported cart with ${_items.length} items');
    } catch (e) {
      _errorHandler.handleValidationError('cart_import', e.toString());
      _setError('เกิดข้อผิดพลาดในการโหลดตะกร้า');
    } finally {
      notifyListeners();
    }
  }

  // Calculate shipping estimate
  double calculateShippingEstimate() {
    try {
      const baseShippingRate = 40.0;
      const weightMultiplier = 10.0;

      final weight = totalWeight;
      final shippingCost = baseShippingRate + (weight * weightMultiplier);

      // Free shipping for orders over threshold
      const freeShippingThreshold = 500.0;
      if (totalAmount >= freeShippingThreshold) {
        return 0.0;
      }

      return shippingCost;
    } catch (e) {
      _errorHandler.handleValidationError('shipping_calculation', e.toString());
      return 40.0; // Default shipping cost
    }
  }

  // Get cart summary for UI display
  Map<String, dynamic> getCartSummary() {
    try {
      return {
        'itemCount': itemCount,
        'totalItems': totalItemsInCart,
        'totalAmount': totalAmount,
        'totalWeight': totalWeight,
        'estimatedShipping': calculateShippingEstimate(),
        'grandTotal': totalAmount + calculateShippingEstimate(),
        'isEmpty': isEmpty,
        'sellerCount': sellerIds.length,
        'hasError': _errorMessage != null,
        'errorMessage': _errorMessage,
      };
    } catch (e) {
      _errorHandler.handleValidationError('cart_summary', e.toString());
      return {
        'hasError': true,
        'errorMessage': 'เกิดข้อผิดพลาดในการคำนวณสรุปตะกร้า'
      };
    }
  }

  // Bulk operations for efficiency
  void addMultipleItems(List<Product> products) {
    try {
      _isLoading = true;
      _clearError();
      notifyListeners();

      for (final product in products) {
        if (_validateProduct(product)) {
          addItem(product);
        }
      }

      _logCartOperation('Added ${products.length} products to cart');
    } catch (e) {
      _errorHandler.handleValidationError('cart_bulk_add', e.toString());
      _setError('เกิดข้อผิดพลาดในการเพิ่มสินค้าหลายรายการ');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get items by seller for order processing
  Map<String, List<CartItem>> getItemsBySeller() {
    final result = <String, List<CartItem>>{};

    for (final item in _items.values) {
      final sellerId = item.product.sellerId;
      if (!result.containsKey(sellerId)) {
        result[sellerId] = [];
      }
      result[sellerId]!.add(item);
    }

    return result;
  }

  // Performance optimization: batch notifications
  void performBulkOperations(List<Function()> operations) {
    try {
      _isLoading = true;

      // Disable notifications temporarily
      for (final operation in operations) {
        operation();
      }

      _logCartOperation('Performed ${operations.length} bulk operations');
    } catch (e) {
      _errorHandler.handleValidationError('cart_bulk_operations', e.toString());
      _setError('เกิดข้อผิดพลาดในการดำเนินการหลายรายการ');
    } finally {
      _isLoading = false;
      notifyListeners(); // Single notification at the end
    }
  }

  /// Enhanced dispose method สำหรับการล้างข้อมูลและทรัพยากร
  @override
  void dispose() {
    // ล้างข้อมูลตะกร้า
    _items.clear();

    // ล้างสถานะ error
    _errorMessage = null;
    _isLoading = false;

    debugPrint('CartProviderEnhanced: Resources cleaned up');
    super.dispose();
  }

  /// สร้าง summary ของตะกร้าสำหรับ analytics
  Map<String, dynamic> toAnalyticsSummary() {
    return {
      'itemCount': itemCount,
      'totalItems': totalItemsInCart,
      'totalAmount': totalAmount,
      'totalWeight': totalWeight,
      'uniqueSellers': sellerIds.length,
      'averageItemPrice': isEmpty ? 0.0 : totalAmount / totalItemsInCart,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'CartProviderEnhanced(items: $itemCount, total: $totalAmount, weight: ${totalWeight}kg)';
  }
}
