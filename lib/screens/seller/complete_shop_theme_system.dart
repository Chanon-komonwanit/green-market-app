// lib/screens/seller/complete_shop_theme_system.dart
// 🎨 Complete Shop Theme System - Shopee/TikTok Style with Live Preview
// ระบบธีมร้านค้าแบบครบวงจร พร้อม Live Preview และปรับแต่งละเอียด

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/theme/app_colors.dart';
import 'package:green_market/models/shop_customization.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/providers/user_provider.dart';

/// ธีมร้านค้าสำหรับ Green Market
enum GreenShopTheme {
  ecoClassic, // ธีมคลาสสิกสีเขียวอ่อน
  naturalOrganic, // ธีมธรรมชาติออร์แกนิค
  modernMinimal, // ธีมโมเดิร์นมินิมอล
  luxuryGreen, // ธีมหรูหราสีเขียว
  vibrantFresh, // ธีมสดใส Fresh
  earthTone, // ธีมโทนดิน
  forestGreen, // ธีมป่าเขียว
  oceanBlue, // ธีมน้ำเงินมหาสมุทร
}

/// ข้อมูลธีม
class ThemeData {
  final GreenShopTheme theme;
  final String name;
  final String description;
  final String category;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color textColor;
  final String backgroundPattern;
  final List<String> features;
  final String previewImage;
  final bool isRecommended;
  final bool isPremium;

  ThemeData({
    required this.theme,
    required this.name,
    required this.description,
    required this.category,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.textColor,
    required this.backgroundPattern,
    required this.features,
    required this.previewImage,
    this.isRecommended = false,
    this.isPremium = false,
  });

  /// รายการธีมทั้งหมด
  static List<ThemeData> get allThemes => [
        // 1. Eco Classic - ธีมหลักของ Green Market
        ThemeData(
          theme: GreenShopTheme.ecoClassic,
          name: 'Eco Classic',
          description:
              'ธีมคลาสสิกของ Green Market สีเขียวอ่อนสบายตา เหมาะกับทุกประเภทสินค้า',
          category: 'ทั่วไป',
          primaryColor: const Color(0xFF10B981), // เขียว Green Market
          secondaryColor: const Color(0xFF34D399),
          accentColor: const Color(0xFFFBBF24),
          backgroundColor: const Color(0xFFF0FDF4),
          textColor: const Color(0xFF065F46),
          backgroundPattern: 'leaf_pattern',
          features: [
            'สีเขียวธรรมชาติ',
            'เน้นความเป็นมิตรกับสิ่งแวดล้อม',
            'เหมาะกับทุกประเภทสินค้า',
            'UI สะอาดตา อ่านง่าย',
          ],
          previewImage: 'eco_classic_preview.jpg',
          isRecommended: true,
        ),

        // 2. Natural Organic - ธีมธรรมชาติออร์แกนิค
        ThemeData(
          theme: GreenShopTheme.naturalOrganic,
          name: 'Natural Organic',
          description:
              'ธีมธรรมชาติ 100% โทนสีน้ำตาล-เขียว เหมาะกับสินค้าออร์แกนิค',
          category: 'อาหาร & สุขภาพ',
          primaryColor: const Color(0xFF92400E), // น้ำตาลไม้
          secondaryColor: const Color(0xFF059669), // เขียวใบไม้
          accentColor: const Color(0xFFFCD34D),
          backgroundColor: const Color(0xFFFFFBEB),
          textColor: const Color(0xFF78350F),
          backgroundPattern: 'organic_texture',
          features: [
            'โทนสีอบอุ่นธรรมชาติ',
            'เน้นความเป็นออร์แกนิค',
            'เหมาะกับสินค้าอาหาร ผักผลไม้',
            'สร้างความน่าเชื่อถือ',
          ],
          previewImage: 'natural_organic_preview.jpg',
        ),

        // 3. Modern Minimal - ธีมโมเดิร์นมินิมอล
        ThemeData(
          theme: GreenShopTheme.modernMinimal,
          name: 'Modern Minimal',
          description: 'ธีมโมเดิร์นเรียบหรู ขาวสะอาด เน้นสินค้าเป็นหลัก',
          category: 'แฟชั่น & ไลฟ์สไตล์',
          primaryColor: const Color(0xFF111827),
          secondaryColor: const Color(0xFF6B7280),
          accentColor: const Color(0xFF10B981),
          backgroundColor: const Color(0xFFFFFFFF),
          textColor: const Color(0xFF1F2937),
          backgroundPattern: 'clean_minimal',
          features: [
            'ดีไซน์เรียบง่าย สะอาดตา',
            'เน้นสินค้าเป็นศูนย์กลาง',
            'เหมาะกับสินค้าแฟชั่น เสื้อผ้า',
            'ดูโปรเฟสชันนัล',
          ],
          previewImage: 'modern_minimal_preview.jpg',
          isRecommended: true,
        ),

        // 4. Luxury Green - ธีมหรูหราสีเขียว
        ThemeData(
          theme: GreenShopTheme.luxuryGreen,
          name: 'Luxury Green',
          description: 'ธีมหรูหรา เขียวเข้ม-ทอง สำหรับแบรนด์พรีเมียม',
          category: 'แบรนด์พรีเมียม',
          primaryColor: const Color(0xFF064E3B), // เขียวเข้ม
          secondaryColor: const Color(0xFFD97706), // ทอง
          accentColor: const Color(0xFFFBBF24),
          backgroundColor: const Color(0xFFF9FAFB),
          textColor: const Color(0xFF1F2937),
          backgroundPattern: 'luxury_pattern',
          features: [
            'สีเขียวเข้มหรูหรา',
            'สีทองเพิ่มความโดดเด่น',
            'เหมาะกับสินค้าพรีเมียม',
            'สร้างภาพลักษณ์แบรนด์ระดับสูง',
          ],
          previewImage: 'luxury_green_preview.jpg',
          isPremium: true,
        ),

        // 5. Vibrant Fresh - ธีมสดใส
        ThemeData(
          theme: GreenShopTheme.vibrantFresh,
          name: 'Vibrant Fresh',
          description: 'ธีมสดใส จี๊ดจ๊าด เหมาะกับสินค้าสำหรับเด็กและวัยรุ่น',
          category: 'เด็ก & ครอบครัว',
          primaryColor: const Color(0xFF10B981),
          secondaryColor: const Color(0xFFEC4899),
          accentColor: const Color(0xFFFCD34D),
          backgroundColor: const Color(0xFFFFFBEB),
          textColor: const Color(0xFF1F2937),
          backgroundPattern: 'fun_pattern',
          features: [
            'สีสันสดใส น่ารัก',
            'เน้นความสนุกสนาน',
            'เหมาะกับสินค้าเด็ก ของเล่น',
            'ดึงดูดความสนใจ',
          ],
          previewImage: 'vibrant_fresh_preview.jpg',
        ),

        // 6. Earth Tone - ธีมโทนดิน
        ThemeData(
          theme: GreenShopTheme.earthTone,
          name: 'Earth Tone',
          description: 'ธีมโทนสีดินอบอุ่น เน้นความเป็นธรรมชาติ',
          category: 'บ้าน & สวน',
          primaryColor: const Color(0xFF78350F),
          secondaryColor: const Color(0xFFA16207),
          accentColor: const Color(0xFF059669),
          backgroundColor: const Color(0xFFFEF3C7),
          textColor: const Color(0xFF451A03),
          backgroundPattern: 'earth_texture',
          features: [
            'สีโทนดินอบอุ่น',
            'สร้างบรรยากาศธรรมชาติ',
            'เหมาะกับสินค้าบ้านและสวน',
            'ดูมีเอกลักษณ์',
          ],
          previewImage: 'earth_tone_preview.jpg',
        ),

        // 7. Forest Green - ธีมป่าเขียว
        ThemeData(
          theme: GreenShopTheme.forestGreen,
          name: 'Forest Green',
          description: 'ธีมป่าไม้สีเขียวเข้ม เน้นความมั่นคง น่าเชื่อถือ',
          category: 'สุขภาพ & ออร์แกนิค',
          primaryColor: const Color(0xFF14532D),
          secondaryColor: const Color(0xFF166534),
          accentColor: const Color(0xFF84CC16),
          backgroundColor: const Color(0xFFF7FEE7),
          textColor: const Color(0xFF14532D),
          backgroundPattern: 'forest_pattern',
          features: [
            'สีเขียวเข้มน่าเชื่อถือ',
            'บรรยากาศป่าธรรมชาติ',
            'เหมาะกับสินค้าสุขภาพ',
            'สร้างความมั่นคง',
          ],
          previewImage: 'forest_green_preview.jpg',
        ),

        // 8. Ocean Blue - ธีมน้ำเงินมหาสมุทร
        ThemeData(
          theme: GreenShopTheme.oceanBlue,
          name: 'Ocean Blue',
          description: 'ธีมสีน้ำเงินสดใส เหมาะกับสินค้ากีฬาและกิจกรรม',
          category: 'กีฬา & กิจกรรม',
          primaryColor: const Color(0xFF0284C7),
          secondaryColor: const Color(0xFF06B6D4),
          accentColor: const Color(0xFF10B981),
          backgroundColor: const Color(0xFFE0F2FE),
          textColor: const Color(0xFF075985),
          backgroundPattern: 'wave_pattern',
          features: [
            'สีน้ำเงินสดใสสบายตา',
            'สร้างความรู้สึกแอคทีฟ',
            'เหมาะกับสินค้ากีฬา',
            'ดูทันสมัยและพลังงาน',
          ],
          previewImage: 'ocean_blue_preview.jpg',
        ),
      ];

  /// ค้นหาธีมตามหมวดหมู่
  static List<ThemeData> getThemesByCategory(String category) {
    if (category == 'ทั้งหมด') return allThemes;
    return allThemes.where((t) => t.category == category).toList();
  }

  /// ค้นหาธีมที่แนะนำ
  static List<ThemeData> get recommendedThemes {
    return allThemes.where((t) => t.isRecommended).toList();
  }
}

/// หน้าจอระบบธีมร้านค้าแบบสมบูรณ์
class CompleteShopThemeSystem extends StatefulWidget {
  final String sellerId;

  const CompleteShopThemeSystem({
    super.key,
    required this.sellerId,
  });

  @override
  State<CompleteShopThemeSystem> createState() =>
      _CompleteShopThemeSystemState();
}

class _CompleteShopThemeSystemState extends State<CompleteShopThemeSystem>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'ทั้งหมด';
  GreenShopTheme? _currentTheme;
  ThemeData? _selectedThemeForPreview;
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _categories = [
    'ทั้งหมด',
    'ทั่วไป',
    'อาหาร & สุขภาพ',
    'แฟชั่น & ไลฟ์สไตล์',
    'แบรนด์พรีเมียม',
    'เด็ก & ครอบครัว',
    'บ้าน & สวน',
    'สุขภาพ & ออร์แกนิค',
    'กีฬา & กิจกรรม',
  ];

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

  Future<void> _loadCurrentTheme() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('shop_customizations')
          .doc(widget.sellerId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        final themeName = data?['theme'] as String?;
        if (themeName != null) {
          _currentTheme = GreenShopTheme.values.firstWhere(
            (t) => t.name == themeName,
            orElse: () => GreenShopTheme.ecoClassic,
          );
        }
      }
    } catch (e) {
      print('Error loading theme: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _applyTheme(ThemeData themeData) async {
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'กรุณาเข้าสู่ระบบ';

      // บันทึกธีมลง Firestore
      await FirebaseFirestore.instance
          .collection('shop_customizations')
          .doc(widget.sellerId)
          .set({
        'theme': themeData.theme.name,
        'themeName': themeData.name,
        'primaryColor': themeData.primaryColor.value,
        'secondaryColor': themeData.secondaryColor.value,
        'accentColor': themeData.accentColor.value,
        'backgroundColor': themeData.backgroundColor.value,
        'textColor': themeData.textColor.value,
        'backgroundPattern': themeData.backgroundPattern,
        'updatedAt': FieldValue.serverTimestamp(),
        'sellerId': widget.sellerId,
      }, SetOptions(merge: true));

      setState(() {
        _currentTheme = themeData.theme;
        _selectedThemeForPreview = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ใช้ธีม "${themeData.name}" เรียบร้อยแล้ว! 🎉',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(
              label: 'ดูหน้าร้าน',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to shop preview
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text('เกิดข้อผิดพลาด: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ธีมร้านค้า'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.palette), text: 'เลือกธีม'),
            Tab(icon: Icon(Icons.star), text: 'แนะนำ'),
            Tab(icon: Icon(Icons.preview), text: 'พรีวิว'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildThemeSelectionTab(),
                _buildRecommendedTab(),
                _buildPreviewTab(),
              ],
            ),
    );
  }

  // ===== TAB 1: เลือกธีม =====
  Widget _buildThemeSelectionTab() {
    return Column(
      children: [
        // Header Banner
        _buildHeaderBanner(),

        // Category Filter
        _buildCategoryFilter(),

        // Theme Grid
        Expanded(
          child: _buildThemeGrid(),
        ),
      ],
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'เลือกธีมสำเร็จรูป',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'ปรับโฉมหน้าร้านของคุณด้วยธีมสวยงามมากมาย',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          if (_currentTheme != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'ธีมปัจจุบัน: ${ThemeData.allThemes.firstWhere((t) => t.theme == _currentTheme).name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedCategory = category);
              },
              backgroundColor: Colors.grey[200],
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildThemeGrid() {
    final themes = ThemeData.getThemesByCategory(_selectedCategory);

    if (themes.isEmpty) {
      return const Center(
        child: Text('ไม่พบธีมในหมวดหมู่นี้'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: themes.length,
      itemBuilder: (context, index) {
        final theme = themes[index];
        final isCurrentTheme = theme.theme == _currentTheme;

        return _buildThemeCard(theme, isCurrentTheme);
      },
    );
  }

  Widget _buildThemeCard(ThemeData theme, bool isCurrentTheme) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedThemeForPreview = theme);
        _tabController.animateTo(2); // ไปที่แท็บพรีวิว
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrentTheme ? AppColors.primary : Colors.grey[300]!,
            width: isCurrentTheme ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Container
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: theme.backgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  // Color Gradient Preview
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.primaryColor,
                          theme.secondaryColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  // Badges
                  if (isCurrentTheme)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'กำลังใช้',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (theme.isPremium)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Premium',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Theme Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      theme.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      theme.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: theme.secondaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: theme.accentColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color: Colors.grey[400],
                        ),
                      ],
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

  // ===== TAB 2: แนะนำ =====
  Widget _buildRecommendedTab() {
    final recommendedThemes = ThemeData.recommendedThemes;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '✨ ธีมแนะนำสำหรับ Green Market',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'ธีมยอดนิยมที่เหมาะกับสินค้าเพื่อสิ่งแวดล้อม',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),
        ...recommendedThemes.map((theme) => _buildRecommendedThemeCard(theme)),
      ],
    );
  }

  Widget _buildRecommendedThemeCard(ThemeData theme) {
    final isCurrentTheme = theme.theme == _currentTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentTheme ? AppColors.primary : Colors.grey[300]!,
          width: isCurrentTheme ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview
          Container(
            height: 150,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.primaryColor, theme.secondaryColor],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Stack(
              children: [
                if (isCurrentTheme)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'กำลังใช้งาน',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        theme.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(Icons.recommend, color: Colors.amber, size: 24),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  theme.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'คุณสมบัติเด่น:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...theme.features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() => _selectedThemeForPreview = theme);
                          _tabController.animateTo(2);
                        },
                        icon: const Icon(Icons.preview),
                        label: const Text('ดูตัวอย่าง'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : () => _applyTheme(theme),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: Text(_isSaving ? 'กำลังบันทึก...' : 'ใช้ธีมนี้'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== TAB 3: พรีวิว =====
  Widget _buildPreviewTab() {
    if (_selectedThemeForPreview == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.preview, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'เลือกธีมเพื่อดูตัวอย่าง',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'กลับไปที่แท็บเลือกธีมและแตะที่ธีมที่ต้องการ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    final theme = _selectedThemeForPreview!;

    return Column(
      children: [
        // Preview Header
        Container(
          padding: const EdgeInsets.all(16),
          color: theme.backgroundColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'ตัวอย่าง: ${theme.name}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _selectedThemeForPreview = null);
                    },
                    icon: Icon(Icons.close, color: theme.textColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                theme.description,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),

        // Live Preview
        Expanded(
          child: Container(
            color: theme.backgroundColor,
            child: _buildLivePreview(theme),
          ),
        ),

        // Action Buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _selectedThemeForPreview = null);
                    _tabController.animateTo(0);
                  },
                  child: const Text('เลือกธีมอื่น'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : () => _applyTheme(theme),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(_isSaving ? 'กำลังบันทึก...' : 'ใช้ธีมนี้'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLivePreview(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Shop Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.primaryColor, theme.secondaryColor],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(Icons.store, color: theme.primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ชื่อร้านค้า',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'ร้านค้าเพื่อสิ่งแวดล้อม',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.favorite_border,
                          color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Category Tabs
          Container(
            height: 50,
            color: theme.backgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['ทั้งหมด', 'สินค้าใหม่', 'ลดราคา', 'ยอดนิยม']
                  .map((cat) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(cat),
                          backgroundColor: cat == 'ทั้งหมด'
                              ? theme.primaryColor
                              : Colors.white,
                          labelStyle: TextStyle(
                            color: cat == 'ทั้งหมด'
                                ? Colors.white
                                : theme.textColor,
                            fontWeight: cat == 'ทั้งหมด'
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),

          // Real Products from Firestore
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .where('sellerId', isEqualTo: widget.sellerId)
                .where('isActive', isEqualTo: true)
                .limit(6)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final products = snapshot.data!.docs;

              // ถ้าไม่มีสินค้า แสดง Placeholder
              return Padding(
                padding: const EdgeInsets.all(16),
                child: products.isEmpty
                    ? _buildPlaceholderProducts(theme)
                    : _buildRealProducts(products, theme),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRealProducts(
      List<QueryDocumentSnapshot> products, ThemeData theme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length > 6 ? 6 : products.length,
      itemBuilder: (context, index) {
        final data = products[index].data() as Map<String, dynamic>;
        final name = data['name'] ?? 'ไม่มีชื่อ';
        final price = data['price'] ?? 0;
        final images = data['images'] as List<dynamic>? ?? [];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: theme.backgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: images.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.network(
                          images[0],
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(
                              Icons.eco,
                              size: 40,
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.eco,
                          size: 40,
                          color: theme.primaryColor,
                        ),
                      ),
              ),
              // Product Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        '฿${_formatNumber(price)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderProducts(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.accentColor),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: theme.accentColor),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'นี่คือตัวอย่าง - เพิ่มสินค้าของคุณเพื่อแสดงผลจริง',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.eco,
                        size: 40,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ตัวอย่างสินค้า',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.textColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '฿199',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatNumber(num number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }
}
