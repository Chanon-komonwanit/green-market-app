// Integration test สำหรับตรวจสอบ Shop Theme System แบบ end-to-end
// รันคำสั่งนี้: flutter test test/shop_theme_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:green_market/models/shop_customization.dart';
import 'package:green_market/services/firebase_service.dart';

void main() {
  group('Shop Theme Integration Tests', () {
    test('Theme change workflow simulation', () async {
      // 1. สร้าง initial customization
      final initialCustomization = ShopCustomization(
        sellerId: 'test-seller-123',
        theme: ScreenShopTheme.greenEco,
        colors: ShopColors(),
        layout: ShopLayout(),
        sections: [],
        promotions: [],
        featuredProductIds: [],
      );

      // 2. Simulate theme change to modernLuxury
      final luxuryCustomization = initialCustomization.copyWith(
        theme: ScreenShopTheme.modernLuxury,
        colors: ShopColors(
          primary: '#1A1A1A',
          secondary: '#D4AF37',
        ),
      );

      // 3. Verify theme changed correctly
      expect(luxuryCustomization.theme, equals(ScreenShopTheme.modernLuxury));
      expect(luxuryCustomization.colors.primary, equals('#1A1A1A'));
      expect(luxuryCustomization.colors.secondary, equals('#D4AF37'));
      expect(
          luxuryCustomization.sellerId, equals(initialCustomization.sellerId));

      print('✅ Theme change workflow simulation passed');
    });

    test('All available themes can be created', () {
      final themes = ScreenShopTheme.values;
      for (final theme in themes) {
        final customization = ShopCustomization(
          sellerId: 'test-seller-${theme.name}',
          theme: theme,
          colors: ShopColors(),
          layout: ShopLayout(),
          sections: [],
          promotions: [],
          featuredProductIds: [],
        );

        expect(customization.theme, equals(theme));
        expect(customization.sellerId, equals('test-seller-${theme.name}'));
      }

      print('✅ All ${themes.length} themes can be created successfully');
      print('   Available themes: ${themes.map((t) => t.name).join(', ')}');
    });

    test('Theme serialization round-trip for all themes', () {
      final themes = ScreenShopTheme.values;

      for (final theme in themes) {
        final original = ShopCustomization(
          sellerId: 'test-seller-${theme.name}',
          theme: theme,
          colors: ShopColors(
            primary: '#${theme.index.toString().padLeft(6, '0')}',
          ),
          layout: ShopLayout(
            gridColumns: theme.index % 3 + 1,
          ),
          sections: [],
          promotions: [],
          featuredProductIds: ['product_${theme.name}'],
        );

        final map = original.toMap();
        final restored = ShopCustomization.fromMap(map);

        expect(restored.theme, equals(original.theme));
        expect(restored.sellerId, equals(original.sellerId));
        expect(restored.colors.primary, equals(original.colors.primary));
        expect(
            restored.layout.gridColumns, equals(original.layout.gridColumns));
        expect(
            restored.featuredProductIds, equals(original.featuredProductIds));
      }

      print('✅ Serialization round-trip works for all themes');
    });

    test('Shop customization validation', () {
      // Test invalid seller ID
      expect(
        () => ShopCustomization(
          sellerId: '',
          theme: ScreenShopTheme.greenEco,
          colors: ShopColors(),
          layout: ShopLayout(),
          sections: [],
          promotions: [],
          featuredProductIds: [],
        ),
        returnsNormally, // Empty seller ID should be allowed but not recommended
      );

      // Test valid customization
      final validCustomization = ShopCustomization(
        sellerId: 'valid-seller-123',
        theme: ScreenShopTheme.modernLuxury,
        colors: ShopColors(primary: '#1A1A1A'),
        layout: ShopLayout(gridColumns: 3),
        sections: [],
        promotions: [],
        featuredProductIds: ['product1', 'product2', 'product3'],
      );

      expect(validCustomization.sellerId, isNotEmpty);
      expect(validCustomization.theme, isNotNull);
      expect(validCustomization.colors, isNotNull);
      expect(validCustomization.layout, isNotNull);
      expect(validCustomization.featuredProductIds.length, equals(3));

      print('✅ Shop customization validation passed');
    });

    test('Shop colors validation', () {
      // Test default colors
      final defaultColors = ShopColors();
      expect(defaultColors.primary, equals('#20C997'));
      expect(defaultColors.secondary, equals('#0EA5E9'));
      expect(defaultColors.background, equals('#FFFFFF'));

      // Test custom colors
      final customColors = ShopColors(
        primary: '#FF5733',
        secondary: '#33FF57',
        accent: '#3357FF',
        background: '#F0F0F0',
        surface: '#E0E0E0',
        text: '#333333',
      );

      final map = customColors.toMap();
      final restored = ShopColors.fromMap(map);

      expect(restored.primary, equals(customColors.primary));
      expect(restored.secondary, equals(customColors.secondary));
      expect(restored.accent, equals(customColors.accent));
      expect(restored.background, equals(customColors.background));
      expect(restored.surface, equals(customColors.surface));
      expect(restored.text, equals(customColors.text));

      print('✅ Shop colors validation passed');
    });

    test('Shop layout validation', () {
      // Test default layout
      final defaultLayout = ShopLayout();
      expect(defaultLayout.gridColumns, equals(2));
      expect(defaultLayout.cardSpacing, equals(8.0));
      expect(defaultLayout.showPrices, isTrue);
      expect(defaultLayout.showRatings, isTrue);
      expect(defaultLayout.compactMode, isFalse);

      // Test custom layout
      final customLayout = ShopLayout(
        gridColumns: 4,
        cardSpacing: 16.5,
        showPrices: false,
        showRatings: false,
        compactMode: true,
        headerStyle: 'modern',
      );

      final map = customLayout.toMap();
      final restored = ShopLayout.fromMap(map);

      expect(restored.gridColumns, equals(customLayout.gridColumns));
      expect(restored.cardSpacing, equals(customLayout.cardSpacing));
      expect(restored.showPrices, equals(customLayout.showPrices));
      expect(restored.showRatings, equals(customLayout.showRatings));
      expect(restored.compactMode, equals(customLayout.compactMode));
      expect(restored.headerStyle, equals(customLayout.headerStyle));

      print('✅ Shop layout validation passed');
    });

    test('Performance test - multiple theme changes', () {
      final stopwatch = Stopwatch()..start();

      ShopCustomization current = ShopCustomization(
        sellerId: 'performance-test',
        theme: ScreenShopTheme.greenEco,
        colors: ShopColors(),
        layout: ShopLayout(),
        sections: [],
        promotions: [],
        featuredProductIds: [],
      );

      // Simulate 100 theme changes
      for (int i = 0; i < 100; i++) {
        final newTheme =
            ScreenShopTheme.values[i % ScreenShopTheme.values.length];
        current = current.copyWith(theme: newTheme);

        // Serialize and deserialize to simulate Firebase operations
        final map = current.toMap();
        current = ShopCustomization.fromMap(map);
      }

      stopwatch.stop();

      expect(current.sellerId, equals('performance-test'));
      expect(stopwatch.elapsedMilliseconds,
          lessThan(1000)); // Should complete within 1 second

      print(
          '✅ Performance test passed: 100 theme changes in ${stopwatch.elapsedMilliseconds}ms');
    });
  });
}
