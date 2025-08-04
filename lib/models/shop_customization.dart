// lib/models/shop_customization.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ShopCustomization {
  final String sellerId;
  final ScreenShopTheme theme;
  final ShopBanner? banner;
  final List<ShopSection> sections;
  final ShopColors colors;
  final ShopLayout layout;
  final List<String> featuredProductIds;
  final List<ShopPromotion> promotions;
  final Timestamp? updatedAt;
  final Timestamp? createdAt;

  ShopCustomization({
    required this.sellerId,
    required this.theme,
    this.banner,
    required this.sections,
    required this.colors,
    required this.layout,
    required this.featuredProductIds,
    required this.promotions,
    this.updatedAt,
    this.createdAt,
  });

  factory ShopCustomization.fromMap(Map<String, dynamic> map) {
    return ShopCustomization(
      sellerId: map['sellerId'] ?? '',
      theme: ScreenShopTheme.values.firstWhere(
        (e) => e.toString().split('.').last == map['theme'],
        orElse: () => ScreenShopTheme.greenEco,
      ),
      banner: map['banner'] != null ? ShopBanner.fromMap(map['banner']) : null,
      sections: List<ShopSection>.from(
        map['sections']?.map((x) => ShopSection.fromMap(x)) ?? [],
      ),
      colors: ShopColors.fromMap(map['colors'] ?? {}),
      layout: ShopLayout.fromMap(map['layout'] ?? {}),
      featuredProductIds: List<String>.from(map['featuredProductIds'] ?? []),
      promotions: List<ShopPromotion>.from(
        map['promotions']?.map((x) => ShopPromotion.fromMap(x)) ?? [],
      ),
      updatedAt: map['updatedAt'] is Timestamp ? map['updatedAt'] : null,
      createdAt: map['createdAt'] is Timestamp ? map['createdAt'] : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'theme': theme.toString().split('.').last,
      'banner': banner?.toMap(),
      'sections': sections.map((x) => x.toMap()).toList(),
      'colors': colors.toMap(),
      'layout': layout.toMap(),
      'featuredProductIds': featuredProductIds,
      'promotions': promotions.map((x) => x.toMap()).toList(),
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  ShopCustomization copyWith({
    String? sellerId,
    ScreenShopTheme? theme,
    ShopBanner? banner,
    List<ShopSection>? sections,
    ShopColors? colors,
    ShopLayout? layout,
    List<String>? featuredProductIds,
    List<ShopPromotion>? promotions,
    Timestamp? updatedAt,
    Timestamp? createdAt,
  }) {
    return ShopCustomization(
      sellerId: sellerId ?? this.sellerId,
      theme: theme ?? this.theme,
      banner: banner ?? this.banner,
      sections: sections ?? this.sections,
      colors: colors ?? this.colors,
      layout: layout ?? this.layout,
      featuredProductIds: featuredProductIds ?? this.featuredProductIds,
      promotions: promotions ?? this.promotions,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum ScreenShopTheme {
  greenEco,
  modernLuxury,
  minimalist,
  techDigital,
  warmVintage,
  vibrantYouth,
}

extension ScreenShopThemeExtension on ScreenShopTheme {
  String get name {
    switch (this) {
      case ScreenShopTheme.greenEco:
        return 'Green Eco';
      case ScreenShopTheme.modernLuxury:
        return 'Modern Luxury';
      case ScreenShopTheme.minimalist:
        return 'Minimalist';
      case ScreenShopTheme.techDigital:
        return 'Tech Digital';
      case ScreenShopTheme.warmVintage:
        return 'Warm Vintage';
      case ScreenShopTheme.vibrantYouth:
        return 'Vibrant Youth';
    }
  }

  String get description {
    switch (this) {
      case ScreenShopTheme.greenEco:
        return 'ธีมเน้นธรรมชาติและความยั่งยืน';
      case ScreenShopTheme.modernLuxury:
        return 'ธีมหรูหราและทันสมัย';
      case ScreenShopTheme.minimalist:
        return 'ธีมเรียบง่ายและสะอาดตา';
      case ScreenShopTheme.techDigital:
        return 'ธีมเทคโนโลยีและดิจิทัล';
      case ScreenShopTheme.warmVintage:
        return 'ธีมอบอุ่นและคลาสสิก';
      case ScreenShopTheme.vibrantYouth:
        return 'ธีมสดใสและเยาวชน';
    }
  }

  Color get primaryColor {
    switch (this) {
      case ScreenShopTheme.greenEco:
        return const Color(0xFF2E7D32);
      case ScreenShopTheme.modernLuxury:
        return const Color(0xFF1A1A1A);
      case ScreenShopTheme.minimalist:
        return const Color(0xFF424242);
      case ScreenShopTheme.techDigital:
        return const Color(0xFF0D47A1);
      case ScreenShopTheme.warmVintage:
        return const Color(0xFF8D6E63);
      case ScreenShopTheme.vibrantYouth:
        return const Color(0xFFE91E63);
    }
  }

  Color get secondaryColor {
    switch (this) {
      case ScreenShopTheme.greenEco:
        return const Color(0xFF66BB6A);
      case ScreenShopTheme.modernLuxury:
        return const Color(0xFFD4AF37);
      case ScreenShopTheme.minimalist:
        return const Color(0xFF9E9E9E);
      case ScreenShopTheme.techDigital:
        return const Color(0xFF1976D2);
      case ScreenShopTheme.warmVintage:
        return const Color(0xFFBCAAA4);
      case ScreenShopTheme.vibrantYouth:
        return const Color(0xFFFF4081);
    }
  }

  IconData get icon {
    switch (this) {
      case ScreenShopTheme.greenEco:
        return Icons.eco;
      case ScreenShopTheme.modernLuxury:
        return Icons.diamond;
      case ScreenShopTheme.minimalist:
        return Icons.minimize;
      case ScreenShopTheme.techDigital:
        return Icons.computer;
      case ScreenShopTheme.warmVintage:
        return Icons.auto_awesome;
      case ScreenShopTheme.vibrantYouth:
        return Icons.palette;
    }
  }
}

class ShopBanner {
  final String? imageUrl;
  final String? title;
  final String? subtitle;
  final String? buttonText;
  final String? buttonLink;
  final bool isVisible;

  ShopBanner({
    this.imageUrl,
    this.title,
    this.subtitle,
    this.buttonText,
    this.buttonLink,
    this.isVisible = true,
  });

  factory ShopBanner.fromMap(Map<String, dynamic> map) {
    return ShopBanner(
      imageUrl: map['imageUrl'],
      title: map['title'],
      subtitle: map['subtitle'],
      buttonText: map['buttonText'],
      buttonLink: map['buttonLink'],
      isVisible: map['isVisible'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'title': title,
      'subtitle': subtitle,
      'buttonText': buttonText,
      'buttonLink': buttonLink,
      'isVisible': isVisible,
    };
  }
}

class ShopSection {
  final String id;
  final String title;
  final SectionType type;
  final List<String> productIds;
  final int order;
  final bool isVisible;
  final Map<String, dynamic> settings;

  ShopSection({
    required this.id,
    required this.title,
    required this.type,
    required this.productIds,
    required this.order,
    this.isVisible = true,
    this.settings = const {},
  });

  factory ShopSection.fromMap(Map<String, dynamic> map) {
    return ShopSection(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      type: SectionType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => SectionType.products,
      ),
      productIds: List<String>.from(map['productIds'] ?? []),
      order: map['order'] ?? 0,
      isVisible: map['isVisible'] ?? true,
      settings: Map<String, dynamic>.from(map['settings'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type.toString().split('.').last,
      'productIds': productIds,
      'order': order,
      'isVisible': isVisible,
      'settings': settings,
    };
  }
}

enum SectionType {
  products,
  banner,
  carousel,
  grid,
  list,
  featured,
  newArrivals,
  bestSellers,
  categories,
}

class ShopColors {
  final String primary;
  final String secondary;
  final String accent;
  final String background;
  final String surface;
  final String text;

  ShopColors({
    this.primary = '#20C997',
    this.secondary = '#0EA5E9',
    this.accent = '#F59E0B',
    this.background = '#FFFFFF',
    this.surface = '#F8FAFB',
    this.text = '#111827',
  });

  factory ShopColors.fromMap(Map<String, dynamic> map) {
    return ShopColors(
      primary: map['primary'] ?? '#20C997',
      secondary: map['secondary'] ?? '#0EA5E9',
      accent: map['accent'] ?? '#F59E0B',
      background: map['background'] ?? '#FFFFFF',
      surface: map['surface'] ?? '#F8FAFB',
      text: map['text'] ?? '#111827',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'primary': primary,
      'secondary': secondary,
      'accent': accent,
      'background': background,
      'surface': surface,
      'text': text,
    };
  }
}

class ShopLayout {
  final int gridColumns;
  final double cardSpacing;
  final bool showPrices;
  final bool showRatings;
  final bool compactMode;
  final String headerStyle;

  ShopLayout({
    this.gridColumns = 2,
    this.cardSpacing = 8.0,
    this.showPrices = true,
    this.showRatings = true,
    this.compactMode = false,
    this.headerStyle = 'standard',
  });

  factory ShopLayout.fromMap(Map<String, dynamic> map) {
    return ShopLayout(
      gridColumns: map['gridColumns'] ?? 2,
      cardSpacing: (map['cardSpacing'] ?? 8.0).toDouble(),
      showPrices: map['showPrices'] ?? true,
      showRatings: map['showRatings'] ?? true,
      compactMode: map['compactMode'] ?? false,
      headerStyle: map['headerStyle'] ?? 'standard',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gridColumns': gridColumns,
      'cardSpacing': cardSpacing,
      'showPrices': showPrices,
      'showRatings': showRatings,
      'compactMode': compactMode,
      'headerStyle': headerStyle,
    };
  }
}

class ShopPromotion {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? discountCode;
  final double? discountPercent;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;

  ShopPromotion({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.discountCode,
    this.discountPercent,
    this.startDate,
    this.endDate,
    this.isActive = true,
  });

  factory ShopPromotion.fromMap(Map<String, dynamic> map) {
    return ShopPromotion(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      discountCode: map['discountCode'],
      discountPercent: map['discountPercent']?.toDouble(),
      startDate: map['startDate']?.toDate(),
      endDate: map['endDate']?.toDate(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'discountCode': discountCode,
      'discountPercent': discountPercent,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isActive': isActive,
    };
  }
}
