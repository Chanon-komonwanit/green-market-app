import 'package:flutter_test/flutter_test.dart';
import 'package:green_market/models/shop_customization.dart';
import 'package:green_market/services/firebase_service.dart';

void main() {
  group('Firebase Shop Theme Tests', () {
    test('should convert ScreenShopTheme to string correctly', () {
      const theme = ScreenShopTheme.greenEco;
      final themeString = theme.toString().split('.').last;
      expect(themeString, equals('greenEco'));
    });

    test('should have all required theme values', () {
      const themes = [
        ScreenShopTheme.greenEco,
        ScreenShopTheme.modernLuxury,
        ScreenShopTheme.minimalist,
        ScreenShopTheme.techDigital,
        ScreenShopTheme.warmVintage,
        ScreenShopTheme.vibrantYouth,
      ];

      expect(ScreenShopTheme.values.length, equals(6));

      for (final theme in themes) {
        expect(ScreenShopTheme.values.contains(theme), isTrue);
      }
    });

    test('should create ShopCustomization with theme correctly', () {
      const theme = ScreenShopTheme.modernLuxury;
      final customization = ShopCustomization(
        sellerId: 'test_seller',
        theme: theme,
        sections: [],
        colors: ShopColors(),
        layout: ShopLayout(),
        featuredProductIds: [],
        promotions: [],
      );

      expect(customization.theme, equals(theme));
      expect(customization.sellerId, equals('test_seller'));
    });

    test('should convert theme data to map correctly', () {
      const theme = ScreenShopTheme.techDigital;
      final customization = ShopCustomization(
        sellerId: 'test_seller',
        theme: theme,
        sections: [],
        colors: ShopColors(),
        layout: ShopLayout(),
        featuredProductIds: [],
        promotions: [],
      );

      final map = customization.toMap();
      expect(map['theme'], equals('techDigital'));
      expect(map['sellerId'], equals('test_seller'));
    });

    test('should parse theme from map correctly', () {
      final map = {
        'sellerId': 'test_seller',
        'theme': 'warmVintage',
        'sections': [],
        'colors': {},
        'layout': {},
        'featuredProductIds': [],
        'promotions': [],
      };

      final customization = ShopCustomization.fromMap(map);
      expect(customization.theme, equals(ScreenShopTheme.warmVintage));
      expect(customization.sellerId, equals('test_seller'));
    });

    test('should use default theme when invalid theme provided', () {
      final map = {
        'sellerId': 'test_seller',
        'theme': 'invalidTheme',
        'sections': [],
        'colors': {},
        'layout': {},
        'featuredProductIds': [],
        'promotions': [],
      };

      final customization = ShopCustomization.fromMap(map);
      expect(customization.theme, equals(ScreenShopTheme.greenEco));
    });

    group('Theme Properties Tests', () {
      test('should have correct theme names', () {
        expect(ScreenShopTheme.greenEco.name, equals('Green Eco'));
        expect(ScreenShopTheme.modernLuxury.name, equals('Modern Luxury'));
        expect(ScreenShopTheme.minimalist.name, equals('Minimalist'));
        expect(ScreenShopTheme.techDigital.name, equals('Tech Digital'));
        expect(ScreenShopTheme.warmVintage.name, equals('Warm Vintage'));
        expect(ScreenShopTheme.vibrantYouth.name, equals('Vibrant Youth'));
      });

      test('should have correct theme descriptions', () {
        expect(ScreenShopTheme.greenEco.description, isNotEmpty);
        expect(ScreenShopTheme.modernLuxury.description, isNotEmpty);
        expect(ScreenShopTheme.minimalist.description, isNotEmpty);
        expect(ScreenShopTheme.techDigital.description, isNotEmpty);
        expect(ScreenShopTheme.warmVintage.description, isNotEmpty);
        expect(ScreenShopTheme.vibrantYouth.description, isNotEmpty);
      });

      test('should have different colors for each theme', () {
        final themes = ScreenShopTheme.values;
        final colors = themes.map((t) => t.primaryColor).toSet();

        // Each theme should have unique primary colors
        expect(colors.length, equals(themes.length));
      });

      test('should have icons for each theme', () {
        for (final theme in ScreenShopTheme.values) {
          expect(theme.icon, isNotNull);
        }
      });
    });
  });
}
