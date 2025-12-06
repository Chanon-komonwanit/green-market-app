// lib/screens/seller/ultimate_shop_theme_system.dart
// 🎨🔥 ULTIMATE Shop Theme System - World-Class E-commerce Platform Level
// ระบบธีมร้านค้าระดับ Shopee/Lazada/Amazon - แต่ละธีมมีเอกลักษณ์เฉพาะตัว

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

/// 🎨 8 ธีมระดับ World-Class แต่ละธีมมีเอกลักษณ์เฉพาะตัว
enum UltimateShopTheme {
  ecoClassic, // 🌿 ธีมคลาสสิก Green Market
  naturalOrganic, // 🌾 ธีมธรรมชาติออร์แกนิค
  modernMinimal, // ⚡ ธีมโมเดิร์นมินิมอล
  luxuryGreen, // 💎 ธีมหรูหรา Premium
  vibrantFresh, // 🌈 ธีมสดใส Shopee Style
  earthTone, // 🏔️ ธีมโทนดินธรรมชาติ
  forestGreen, // 🌲 ธีมป่าเขียวขจี
  oceanBlue, // 🌊 ธีมมหาสมุทรสีฟ้า
}

/// 📦 ข้อมูลธีมแบบครบวงจร
class UltimateThemeConfig {
  final UltimateShopTheme theme;
  final String name;
  final String nameEn;
  final String description;
  final String tagline;
  final IconData icon;
  final String emoji;

  // 🎨 สีหลัก
  final Color primaryColor;
  final Color primaryDark;
  final Color primaryLight;
  final Color secondaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textPrimaryColor;
  final Color textSecondaryColor;

  // ✨ UI Style
  final double borderRadius;
  final double cardElevation;
  final String fontFamily;
  final FontWeight titleFontWeight;
  final String buttonStyle; // 'rounded', 'sharp', 'pill', 'neo'
  final String layoutStyle; // 'grid', 'list', 'masonry', 'card'

  // 🖼️ ลูกเล่นพิเศษ
  final bool hasGradient;
  final bool hasPattern;
  final bool hasAnimation;
  final bool hasShadow;
  final String patternType;
  final List<Color>? gradientColors;

  // 🎭 ปุ่มและไอคอนสไตล์
  final String iconStyle; // 'filled', 'outlined', 'rounded', 'sharp'
  final double iconSize;
  final Color iconColor;

  // 📱 Layout Configuration
  final bool isFullWidth;
  final EdgeInsets contentPadding;
  final double productCardAspectRatio;

  // 🏆 พิเศษ
  final bool isPremium;
  final bool isRecommended;
  final List<String> bestFor;
  final List<String> features;

  const UltimateThemeConfig({
    required this.theme,
    required this.name,
    required this.nameEn,
    required this.description,
    required this.tagline,
    required this.icon,
    required this.emoji,
    required this.primaryColor,
    required this.primaryDark,
    required this.primaryLight,
    required this.secondaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textPrimaryColor,
    required this.textSecondaryColor,
    required this.borderRadius,
    required this.cardElevation,
    required this.fontFamily,
    required this.titleFontWeight,
    required this.buttonStyle,
    required this.layoutStyle,
    required this.hasGradient,
    required this.hasPattern,
    required this.hasAnimation,
    required this.hasShadow,
    required this.patternType,
    this.gradientColors,
    required this.iconStyle,
    required this.iconSize,
    required this.iconColor,
    required this.isFullWidth,
    required this.contentPadding,
    required this.productCardAspectRatio,
    this.isPremium = false,
    this.isRecommended = false,
    required this.bestFor,
    required this.features,
  });

  /// 🎨 รายการธีมทั้งหมด 8 แบบ
  static List<UltimateThemeConfig> get allThemes => [
        // 1. 🌿 ECO CLASSIC - ธีมหลัก Green Market Style
        UltimateThemeConfig(
          theme: UltimateShopTheme.ecoClassic,
          name: 'Eco Classic',
          nameEn: 'Eco Classic',
          description: 'ธีมคลาสสิกของ Green Market สไตล์เป็นมิตรกับสิ่งแวดล้อม',
          tagline: '🌿 ธรรมชาติ สะอาด เรียบง่าย',
          icon: Icons.eco,
          emoji: '🌿',
          primaryColor: Color(0xFF10B981),
          primaryDark: Color(0xFF059669),
          primaryLight: Color(0xFF34D399),
          secondaryColor: Color(0xFF6EE7B7),
          accentColor: Color(0xFFFBBF24),
          backgroundColor: Color(0xFFF0FDF4),
          surfaceColor: Colors.white,
          textPrimaryColor: Color(0xFF065F46),
          textSecondaryColor: Color(0xFF6B7280),
          borderRadius: 12.0,
          cardElevation: 2.0,
          fontFamily: 'Prompt',
          titleFontWeight: FontWeight.w600,
          buttonStyle: 'rounded',
          layoutStyle: 'grid',
          hasGradient: false,
          hasPattern: true,
          hasAnimation: true,
          hasShadow: true,
          patternType: 'leaf',
          iconStyle: 'rounded',
          iconSize: 20.0,
          iconColor: Color(0xFF10B981),
          isFullWidth: false,
          contentPadding: EdgeInsets.all(16),
          productCardAspectRatio: 0.75,
          isRecommended: true,
          bestFor: ['สินค้าทั่วไป', 'สินค้า Eco', 'มือใหม่'],
          features: [
            'UI สะอาดตา',
            'สีเขียวธรรมชาติ',
            'อ่านง่าย',
            'เหมาะทุกสินค้า',
          ],
        ),

        // 2. 🌾 NATURAL ORGANIC - ธีมธรรมชาติออร์แกนิค
        UltimateThemeConfig(
          theme: UltimateShopTheme.naturalOrganic,
          name: 'Natural Organic',
          nameEn: 'Natural Organic',
          description:
              'ธีมธรรมชาติ 100% โทนสีน้ำตาล-เขียว สำหรับสินค้าออร์แกนิค',
          tagline: '🌾 ออร์แกนิค บริสุทธิ์ ธรรมชาติ',
          icon: Icons.grass,
          emoji: '🌾',
          primaryColor: Color(0xFF92400E),
          primaryDark: Color(0xFF78350F),
          primaryLight: Color(0xFFC2410C),
          secondaryColor: Color(0xFF059669),
          accentColor: Color(0xFFFCD34D),
          backgroundColor: Color(0xFFFFFBEB),
          surfaceColor: Color(0xFFFEF3C7),
          textPrimaryColor: Color(0xFF78350F),
          textSecondaryColor: Color(0xFF92400E),
          borderRadius: 16.0,
          cardElevation: 4.0,
          fontFamily: 'Sarabun',
          titleFontWeight: FontWeight.w700,
          buttonStyle: 'pill',
          layoutStyle: 'masonry',
          hasGradient: true,
          hasPattern: true,
          hasAnimation: true,
          hasShadow: true,
          patternType: 'organic',
          gradientColors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
          iconStyle: 'filled',
          iconSize: 22.0,
          iconColor: Color(0xFF92400E),
          isFullWidth: true,
          contentPadding: EdgeInsets.all(20),
          productCardAspectRatio: 0.8,
          bestFor: ['อาหารออร์แกนิค', 'สุขภาพ', 'ธรรมชาติ'],
          features: [
            'โทนสีอบอุ่น',
            'เน้นความบริสุทธิ์',
            'สไตล์ธรรมชาติ',
            'Layout Masonry',
          ],
        ),

        // 3. ⚡ MODERN MINIMAL - ธีมโมเดิร์นมินิมอล
        UltimateThemeConfig(
          theme: UltimateShopTheme.modernMinimal,
          name: 'Modern Minimal',
          nameEn: 'Modern Minimal',
          description: 'ธีมโมเดิร์นมินิมอล สไตล์ Apple/Tesla ดูหรู premium',
          tagline: '⚡ โมเดิร์น มินิมอล ทันสมัย',
          icon: Icons.design_services,
          emoji: '⚡',
          primaryColor: Color(0xFF0F172A),
          primaryDark: Color(0xFF020617),
          primaryLight: Color(0xFF334155),
          secondaryColor: Color(0xFF10B981),
          accentColor: Color(0xFF3B82F6),
          backgroundColor: Color(0xFFFAFAFA),
          surfaceColor: Colors.white,
          textPrimaryColor: Color(0xFF0F172A),
          textSecondaryColor: Color(0xFF64748B),
          borderRadius: 8.0,
          cardElevation: 0.0,
          fontFamily: 'Kanit',
          titleFontWeight: FontWeight.w500,
          buttonStyle: 'sharp',
          layoutStyle: 'grid',
          hasGradient: false,
          hasPattern: false,
          hasAnimation: true,
          hasShadow: false,
          patternType: 'none',
          iconStyle: 'outlined',
          iconSize: 18.0,
          iconColor: Color(0xFF0F172A),
          isFullWidth: false,
          contentPadding: EdgeInsets.all(12),
          productCardAspectRatio: 0.9,
          bestFor: ['เทคโนโลยี', 'แฟชั่น', 'ของตกแต่ง'],
          features: [
            'ดีไซน์สะอาด',
            'พื้นที่ว่างเยอะ',
            'ดูหรูมีคลาส',
            'สไตล์มินิมอล',
          ],
        ),

        // 4. 💎 LUXURY GREEN - ธีมหรูหรา Premium
        UltimateThemeConfig(
          theme: UltimateShopTheme.luxuryGreen,
          name: 'Luxury Green',
          nameEn: 'Luxury Green',
          description: 'ธีมหรูหรา Premium สไตล์แบรนด์ชั้นนำ สีเขียวเข้ม-ทอง',
          tagline: '💎 หรูหรา พรีเมียม เอกสิทธิ์',
          icon: Icons.diamond,
          emoji: '💎',
          primaryColor: Color(0xFF064E3B),
          primaryDark: Color(0xFF022C22),
          primaryLight: Color(0xFF047857),
          secondaryColor: Color(0xFFD97706),
          accentColor: Color(0xFFFBBF24),
          backgroundColor: Color(0xFF0C0A09),
          surfaceColor: Color(0xFF1C1917),
          textPrimaryColor: Color(0xFFFAFAF9),
          textSecondaryColor: Color(0xFFD6D3D1),
          borderRadius: 20.0,
          cardElevation: 8.0,
          fontFamily: 'Montserrat',
          titleFontWeight: FontWeight.w700,
          buttonStyle: 'neo',
          layoutStyle: 'card',
          hasGradient: true,
          hasPattern: true,
          hasAnimation: true,
          hasShadow: true,
          patternType: 'luxury',
          gradientColors: [
            Color(0xFF064E3B),
            Color(0xFF022C22),
            Color(0xFF000000)
          ],
          iconStyle: 'filled',
          iconSize: 24.0,
          iconColor: Color(0xFFFBBF24),
          isFullWidth: true,
          contentPadding: EdgeInsets.all(24),
          productCardAspectRatio: 0.7,
          isPremium: true,
          bestFor: ['สินค้าหรู', 'แบรนด์ชั้นนำ', 'ของขวัญ'],
          features: [
            'ดูหรูหราสุดๆ',
            'สีเข้ม-ทองสง่า',
            'เหมาะสินค้า Premium',
            'มีลูกเล่นเยอะ',
          ],
        ),

        // 5. 🌈 VIBRANT FRESH - ธีมสดใส Shopee/TikTok Style
        UltimateThemeConfig(
          theme: UltimateShopTheme.vibrantFresh,
          name: 'Vibrant Fresh',
          nameEn: 'Vibrant Fresh',
          description:
              'ธีมสดใส สีสันสะดุดตา สไตล์ Shopee/TikTok ดึงดูดความสนใจ',
          tagline: '🌈 สดใส สะดุดตา น่าช็อป',
          icon: Icons.auto_awesome,
          emoji: '🌈',
          primaryColor: Color(0xFFEF4444),
          primaryDark: Color(0xFFDC2626),
          primaryLight: Color(0xFFF87171),
          secondaryColor: Color(0xFFF59E0B),
          accentColor: Color(0xFF8B5CF6),
          backgroundColor: Color(0xFFFFF1F2),
          surfaceColor: Colors.white,
          textPrimaryColor: Color(0xFF991B1B),
          textSecondaryColor: Color(0xFF7C2D12),
          borderRadius: 24.0,
          cardElevation: 6.0,
          fontFamily: 'Kanit',
          titleFontWeight: FontWeight.w800,
          buttonStyle: 'pill',
          layoutStyle: 'grid',
          hasGradient: true,
          hasPattern: true,
          hasAnimation: true,
          hasShadow: true,
          patternType: 'vibrant',
          gradientColors: [
            Color(0xFFFEE2E2),
            Color(0xFFFFF1F2),
            Color(0xFFFFFBEB)
          ],
          iconStyle: 'rounded',
          iconSize: 26.0,
          iconColor: Color(0xFFEF4444),
          isFullWidth: false,
          contentPadding: EdgeInsets.all(16),
          productCardAspectRatio: 0.75,
          isRecommended: true,
          bestFor: ['แฟชั่น', 'ของเล่น', 'ของขวัญ'],
          features: [
            'สีสันสดใส',
            'ดึงดูดสายตา',
            'สไตล์วัยรุ่น',
            'แอนิเมชั่นเยอะ',
          ],
        ),

        // 6. 🏔️ EARTH TONE - ธีมโทนดินธรรมชาติ
        UltimateThemeConfig(
          theme: UltimateShopTheme.earthTone,
          name: 'Earth Tone',
          nameEn: 'Earth Tone',
          description: 'ธีมโทนสีดิน น้ำตาล เบจ สำหรับสินค้า Handmade/Craft',
          tagline: '🏔️ โทนดิน อบอุ่น Handmade',
          icon: Icons.landscape,
          emoji: '🏔️',
          primaryColor: Color(0xFF8B4513),
          primaryDark: Color(0xFF654321),
          primaryLight: Color(0xFFA0522D),
          secondaryColor: Color(0xFFDEB887),
          accentColor: Color(0xFFD2691E),
          backgroundColor: Color(0xFFF5F5DC),
          surfaceColor: Color(0xFFFAF0E6),
          textPrimaryColor: Color(0xFF654321),
          textSecondaryColor: Color(0xFF8B4513),
          borderRadius: 18.0,
          cardElevation: 3.0,
          fontFamily: 'Sarabun',
          titleFontWeight: FontWeight.w600,
          buttonStyle: 'rounded',
          layoutStyle: 'masonry',
          hasGradient: true,
          hasPattern: true,
          hasAnimation: false,
          hasShadow: true,
          patternType: 'earth',
          gradientColors: [Color(0xFFF5F5DC), Color(0xFFFAF0E6)],
          iconStyle: 'filled',
          iconSize: 20.0,
          iconColor: Color(0xFF8B4513),
          isFullWidth: true,
          contentPadding: EdgeInsets.all(18),
          productCardAspectRatio: 0.85,
          bestFor: ['Handmade', 'Craft', 'ของตกแต่ง'],
          features: [
            'โทนสีอบอุ่น',
            'เหมาะสินค้าทำมือ',
            'สไตล์ Rustic',
            'Layout Masonry',
          ],
        ),

        // 7. 🌲 FOREST GREEN - ธีมป่าเขียวขจี
        UltimateThemeConfig(
          theme: UltimateShopTheme.forestGreen,
          name: 'Forest Green',
          nameEn: 'Forest Green',
          description:
              'ธีมป่าเขียวขจี สีเขียวเข้ม สำหรับสินค้าเกี่ยวกับธรรมชาติ',
          tagline: '🌲 ป่าเขียว ธรรมชาติ สดชื่น',
          icon: Icons.forest,
          emoji: '🌲',
          primaryColor: Color(0xFF14532D),
          primaryDark: Color(0xFF052E16),
          primaryLight: Color(0xFF166534),
          secondaryColor: Color(0xFF22C55E),
          accentColor: Color(0xFF84CC16),
          backgroundColor: Color(0xFFF0FDF4),
          surfaceColor: Color(0xFFDCFCE7),
          textPrimaryColor: Color(0xFF14532D),
          textSecondaryColor: Color(0xFF166534),
          borderRadius: 14.0,
          cardElevation: 4.0,
          fontFamily: 'Prompt',
          titleFontWeight: FontWeight.w700,
          buttonStyle: 'rounded',
          layoutStyle: 'grid',
          hasGradient: true,
          hasPattern: true,
          hasAnimation: true,
          hasShadow: true,
          patternType: 'forest',
          gradientColors: [
            Color(0xFFF0FDF4),
            Color(0xFFDCFCE7),
            Color(0xFFBBF7D0)
          ],
          iconStyle: 'rounded',
          iconSize: 22.0,
          iconColor: Color(0xFF14532D),
          isFullWidth: false,
          contentPadding: EdgeInsets.all(16),
          productCardAspectRatio: 0.8,
          bestFor: ['พืช', 'สวน', 'ธรรมชาติ'],
          features: [
            'สีเขียวเข้มสดชื่น',
            'บรรยากาศป่า',
            'เหมาะสินค้าต้นไม้',
            'สดชื่นตาลดอุณหภูมิ',
          ],
        ),

        // 8. 🌊 OCEAN BLUE - ธีมมหาสมุทรสีฟ้า
        UltimateThemeConfig(
          theme: UltimateShopTheme.oceanBlue,
          name: 'Ocean Blue',
          nameEn: 'Ocean Blue',
          description: 'ธีมมหาสมุทรสีฟ้า เย็นตา สงบ สำหรับสินค้าทะเล/น้ำ',
          tagline: '🌊 มหาสมุทร สงบ เย็นสบาย',
          icon: Icons.waves,
          emoji: '🌊',
          primaryColor: Color(0xFF0369A1),
          primaryDark: Color(0xFF075985),
          primaryLight: Color(0xFF0284C7),
          secondaryColor: Color(0xFF06B6D4),
          accentColor: Color(0xFF22D3EE),
          backgroundColor: Color(0xFFF0F9FF),
          surfaceColor: Color(0xFFE0F2FE),
          textPrimaryColor: Color(0xFF075985),
          textSecondaryColor: Color(0xFF0369A1),
          borderRadius: 16.0,
          cardElevation: 5.0,
          fontFamily: 'Sarabun',
          titleFontWeight: FontWeight.w600,
          buttonStyle: 'pill',
          layoutStyle: 'card',
          hasGradient: true,
          hasPattern: true,
          hasAnimation: true,
          hasShadow: true,
          patternType: 'wave',
          gradientColors: [
            Color(0xFFF0F9FF),
            Color(0xFFE0F2FE),
            Color(0xFFBAE6FD)
          ],
          iconStyle: 'rounded',
          iconSize: 21.0,
          iconColor: Color(0xFF0369A1),
          isFullWidth: true,
          contentPadding: EdgeInsets.all(18),
          productCardAspectRatio: 0.75,
          bestFor: ['อาหารทะเล', 'เครื่องดื่ม', 'สปา'],
          features: [
            'สีฟ้าเย็นตา',
            'บรรยากาศทะเล',
            'สงบผ่อนคลาย',
            'เหมาะสินค้าน้ำ',
          ],
        ),
      ];

  /// 🔍 ค้นหาธีมจาก enum
  static UltimateThemeConfig? getTheme(UltimateShopTheme theme) {
    try {
      return allThemes.firstWhere((t) => t.theme == theme);
    } catch (e) {
      return null;
    }
  }

  /// 📦 แปลง Theme เป็น Map สำหรับบันทึก Firestore
  Map<String, dynamic> toFirestoreMap() {
    return {
      'theme': theme.name,
      'themeName': name,
      'themeNameEn': nameEn,
      'primaryColor': primaryColor.value,
      'primaryDark': primaryDark.value,
      'primaryLight': primaryLight.value,
      'secondaryColor': secondaryColor.value,
      'accentColor': accentColor.value,
      'backgroundColor': backgroundColor.value,
      'surfaceColor': surfaceColor.value,
      'textPrimaryColor': textPrimaryColor.value,
      'textSecondaryColor': textSecondaryColor.value,
      'borderRadius': borderRadius,
      'cardElevation': cardElevation,
      'fontFamily': fontFamily,
      'buttonStyle': buttonStyle,
      'layoutStyle': layoutStyle,
      'hasGradient': hasGradient,
      'hasPattern': hasPattern,
      'hasAnimation': hasAnimation,
      'hasShadow': hasShadow,
      'patternType': patternType,
      'iconStyle': iconStyle,
      'iconSize': iconSize,
      'iconColor': iconColor.value,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

/// 🎨 Ultimate Shop Theme System Screen
class UltimateShopThemeSystem extends StatefulWidget {
  final String sellerId;

  const UltimateShopThemeSystem({super.key, required this.sellerId});

  @override
  State<UltimateShopThemeSystem> createState() =>
      _UltimateShopThemeSystemState();
}

class _UltimateShopThemeSystemState extends State<UltimateShopThemeSystem>
    with SingleTickerProviderStateMixin {
  UltimateShopTheme _currentTheme = UltimateShopTheme.ecoClassic;
  UltimateThemeConfig? _selectedThemeForPreview;
  bool _isLoading = true;
  bool _isSaving = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCurrentTheme();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 📥 โหลดธีมปัจจุบัน
  Future<void> _loadCurrentTheme() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('shop_customizations')
          .doc(widget.sellerId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null && data['theme'] != null) {
          final themeName = data['theme'] as String;
          final theme = UltimateShopTheme.values.firstWhere(
            (t) => t.name == themeName,
            orElse: () => UltimateShopTheme.ecoClassic,
          );
          setState(() => _currentTheme = theme);
        }
      }
    } catch (e) {
      print('❌ Error loading theme: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 💾 บันทึกธีม
  Future<void> _applyTheme(UltimateThemeConfig themeConfig) async {
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw 'กรุณาเข้าสู่ระบบ';
      }

      // บันทึกลง Firestore
      await FirebaseFirestore.instance
          .collection('shop_customizations')
          .doc(widget.sellerId)
          .set(themeConfig.toFirestoreMap(), SetOptions(merge: true));

      // อัพเดท State
      setState(() {
        _currentTheme = themeConfig.theme;
        _selectedThemeForPreview = null;
      });

      // แจ้งเตือนสำเร็จ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(themeConfig.emoji, style: TextStyle(fontSize: 20)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ใช้ธีม "${themeConfig.name}" สำเร็จ! 🎉',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: themeConfig.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'ดูหน้าร้าน',
              textColor: Colors.white,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        );
      }

      // Haptic Feedback
      HapticFeedback.mediumImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('กำลังโหลด...')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentThemeConfig = UltimateThemeConfig.getTheme(_currentTheme) ??
        UltimateThemeConfig.allThemes.first;

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            Text(currentThemeConfig.emoji, style: TextStyle(fontSize: 24)),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ธีมร้านค้า',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'ธีมปัจจุบัน: ${currentThemeConfig.name}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.grid_view), text: 'แกลเลอรี่'),
            Tab(icon: Icon(Icons.palette), text: 'รายละเอียด'),
            Tab(icon: Icon(Icons.preview), text: 'ตัวอย่าง'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildThemeGallery(),
          _buildThemeDetails(currentThemeConfig),
          _buildLivePreview(_selectedThemeForPreview ?? currentThemeConfig),
        ],
      ),
    );
  }

  /// 🎨 แกลเลอรี่ธีมทั้งหมด
  Widget _buildThemeGallery() {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: UltimateThemeConfig.allThemes.length,
      itemBuilder: (context, index) {
        final theme = UltimateThemeConfig.allThemes[index];
        final isActive = theme.theme == _currentTheme;

        return _buildThemeCard(theme, isActive);
      },
    );
  }

  /// 🎴 การ์ดธีม
  Widget _buildThemeCard(UltimateThemeConfig theme, bool isActive) {
    return GestureDetector(
      onTap: () => setState(() => _selectedThemeForPreview = theme),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(theme.borderRadius),
          border: Border.all(
            color: isActive ? theme.primaryColor : Colors.grey[300]!,
            width: isActive ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? theme.primaryColor.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isActive ? 12 : 4,
              offset: Offset(0, isActive ? 4 : 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: theme.hasGradient && theme.gradientColors != null
                    ? LinearGradient(colors: theme.gradientColors!)
                    : null,
                color: theme.hasGradient ? null : theme.backgroundColor,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(theme.borderRadius),
                ),
              ),
              child: Column(
                children: [
                  Text(theme.emoji, style: TextStyle(fontSize: 40)),
                  SizedBox(height: 8),
                  Text(
                    theme.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.textPrimaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (isActive)
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '✓ กำลังใช้งาน',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Tags
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: theme.bestFor.take(2).map((tag) {
                        return Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    Spacer(),
                    ElevatedButton(
                      onPressed: _isSaving ? null : () => _applyTheme(theme),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(theme.borderRadius),
                        ),
                      ),
                      child: _isSaving
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(isActive ? 'กำลังใช้งาน' : 'ใช้ธีมนี้'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📋 รายละเอียดธีม
  Widget _buildThemeDetails(UltimateThemeConfig theme) {
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: theme.hasGradient && theme.gradientColors != null
                ? LinearGradient(colors: theme.gradientColors!)
                : null,
            color: theme.hasGradient ? null : theme.backgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(theme.emoji, style: TextStyle(fontSize: 60)),
              SizedBox(height: 16),
              Text(
                theme.name,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: theme.textPrimaryColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                theme.tagline,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        SizedBox(height: 24),

        // Description
        _buildDetailCard(
          'คำอธิบาย',
          Icons.description,
          theme.primaryColor,
          Text(
            theme.description,
            style: TextStyle(fontSize: 15, height: 1.6),
          ),
        ),

        SizedBox(height: 16),

        // Best For
        _buildDetailCard(
          'เหมาะสำหรับ',
          Icons.shopping_bag,
          theme.secondaryColor,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: theme.bestFor.map((item) {
              return Chip(
                label: Text(item),
                backgroundColor: theme.primaryColor.withOpacity(0.1),
                labelStyle: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),

        SizedBox(height: 16),

        // Features
        _buildDetailCard(
          'คุณสมบัติเด่น',
          Icons.star,
          theme.accentColor,
          Column(
            children: theme.features.map((feature) {
              return Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: theme.primaryColor, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        SizedBox(height: 16),

        // Color Palette
        _buildDetailCard(
          'พาเลทสี',
          Icons.palette,
          theme.primaryColor,
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildColorChip('หลัก', theme.primaryColor),
              _buildColorChip('รอง', theme.secondaryColor),
              _buildColorChip('เน้น', theme.accentColor),
              _buildColorChip('พื้นหลัง', theme.backgroundColor),
            ],
          ),
        ),

        SizedBox(height: 24),

        // Apply Button
        SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : () => _applyTheme(theme),
            icon: Icon(_isSaving ? Icons.hourglass_empty : Icons.check_circle),
            label: Text(
              _isSaving ? 'กำลังบันทึก...' : 'ใช้ธีมนี้',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(theme.borderRadius),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard(
    String title,
    IconData icon,
    Color color,
    Widget child,
  ) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildColorChip(String label, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  /// 👁️ Live Preview
  Widget _buildLivePreview(UltimateThemeConfig theme) {
    return Container(
      color: theme.backgroundColor,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: theme.hasGradient && theme.gradientColors != null
                    ? LinearGradient(colors: theme.gradientColors!)
                    : null,
                color: theme.hasGradient ? null : theme.surfaceColor,
                borderRadius: BorderRadius.circular(theme.borderRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: theme.primaryColor,
                        child: Text(
                          theme.emoji,
                          style: TextStyle(fontSize: 28),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ร้าน ${theme.name}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: theme.titleFontWeight,
                                color: theme.textPrimaryColor,
                              ),
                            ),
                            Text(
                              theme.tagline,
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      _buildPreviewButton('ติดตาม', theme, isPrimary: true),
                      SizedBox(width: 12),
                      _buildPreviewButton('แชท', theme),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Products Section
            Text(
              'สินค้าแนะนำ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.textPrimaryColor,
              ),
            ),
            SizedBox(height: 12),

            // Product Grid
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: theme.productCardAspectRatio,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                return _buildPreviewProductCard(theme, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewButton(String label, UltimateThemeConfig theme,
      {bool isPrimary = false}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? theme.primaryColor : Colors.transparent,
          border: isPrimary ? null : Border.all(color: theme.primaryColor),
          borderRadius: BorderRadius.circular(
            theme.buttonStyle == 'pill'
                ? 24
                : theme.buttonStyle == 'sharp'
                    ? 8
                    : 12,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isPrimary ? Colors.white : theme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewProductCard(UltimateThemeConfig theme, int index) {
    final products = [
      'สินค้า Eco',
      'สินค้าออร์แกนิค',
      'สินค้าธรรมชาติ',
      'สินค้า Premium'
    ];
    final prices = ['฿299', '฿599', '฿399', '฿899'];

    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(theme.borderRadius),
        boxShadow: theme.hasShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: theme.cardElevation * 2,
                  offset: Offset(0, theme.cardElevation),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: theme.backgroundColor,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(theme.borderRadius),
              ),
            ),
            child: Center(
              child: Text(
                theme.emoji,
                style: TextStyle(fontSize: 48),
              ),
            ),
          ),
          // Info
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  products[index],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  prices[index],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
