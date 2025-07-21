import 'package:flutter_test/flutter_test.dart';
import 'package:green_market/providers/cart_provider.dart';
import 'package:green_market/models/product.dart';

void main() {
  group('CartProvider', () {
    test('initial cart is empty', () {
      final cartProvider = CartProvider();
      expect(cartProvider.items.isEmpty, true);
    });

    test('add item increases cart length', () {
      final cartProvider = CartProvider();
      final product = Product(
        id: 'p1',
        sellerId: 's1',
        name: 'Test Product',
        description: 'desc',
        price: 10.0,
        stock: 5,
        categoryId: 'c1',
        imageUrls: [],
        promotionalImageUrl: null,
        updatedAt: null,
        ecoScore: 80,
        materialDescription: 'Eco material',
        ecoJustification: 'Sustainable',
      );
      cartProvider.addItem(product);
      expect(cartProvider.items.length, 1);
    });

    test('remove item decreases cart length', () {
      final cartProvider = CartProvider();
      final product = Product(
        id: 'p1',
        sellerId: 's1',
        name: 'Test Product',
        description: 'desc',
        price: 10.0,
        stock: 5,
        categoryId: 'c1',
        imageUrls: [],
        promotionalImageUrl: null,
        updatedAt: null,
        ecoScore: 80,
        materialDescription: 'Eco material',
        ecoJustification: 'Sustainable',
      );
      cartProvider.addItem(product);
      cartProvider.removeItem(product.id);
      expect(cartProvider.items.isEmpty, true);
    });

    test('clear cart removes all items', () {
      final cartProvider = CartProvider();
      final product1 = Product(
        id: 'p1',
        sellerId: 's1',
        name: 'Test Product',
        description: 'desc',
        price: 10.0,
        stock: 5,
        categoryId: 'c1',
        imageUrls: [],
        promotionalImageUrl: null,
        updatedAt: null,
        ecoScore: 80,
        materialDescription: 'Eco material',
        ecoJustification: 'Sustainable',
      );
      final product2 = Product(
        id: 'p2',
        sellerId: 's2',
        name: 'Test Product 2',
        description: 'desc2',
        price: 20.0,
        stock: 10,
        categoryId: 'c2',
        imageUrls: [],
        promotionalImageUrl: null,
        updatedAt: null,
        ecoScore: 90,
        materialDescription: 'Eco material 2',
        ecoJustification: 'Recycled',
      );
      cartProvider.addItem(product1);
      cartProvider.addItem(product2);
      cartProvider.clearCart();
      expect(cartProvider.items.isEmpty, true);
    });
  });
}
