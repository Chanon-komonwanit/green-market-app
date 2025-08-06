// lib/screens/seller/shop_template_selector_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:green_market/models/shop_customization.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShopTemplateSelectorScreen extends StatefulWidget {
  const ShopTemplateSelectorScreen({super.key});

  @override
  State<ShopTemplateSelectorScreen> createState() =>
      _ShopTemplateSelectorScreenState();
}

class _ShopTemplateSelectorScreenState
    extends State<ShopTemplateSelectorScreen> {
  ScreenShopTheme? _selectedTheme;
  bool _isLoading = false;
  String _selectedCategory = 'ทั้งหมด';

  final List<String> _categories = [
    'ทั้งหมด',
    'ร้านค้าทั่วไป',
    'แฟชั่นและเสื้อผ้า',
    'เทคโนโลยี',
    'ความงาม',
    'อาหารและเครื่องดื่ม',
    'กีฬาและกิจกรรม',
    'บ้านและสวน',
    'เด็กและครอบครัว',
    'แบรนด์หรูหรา',
    'ธรรมชาติและสุขภาพ',
  ];

  // ธีมที่แนะนำสำหรับแต่ละหมวดหมู่
  Map<String, List<ScreenShopTheme>> get _themesByCategory => {
        'ทั้งหมด': [
          ScreenShopTheme.shopeeClassic,
          ScreenShopTheme.fashionBoutique,
          ScreenShopTheme.techStore,
          ScreenShopTheme.beautyCosmetic,
          ScreenShopTheme.foodDelivery,
          ScreenShopTheme.sportsOutdoor,
          ScreenShopTheme.homeDecor,
          ScreenShopTheme.kidsFamily,
          ScreenShopTheme.luxuryBrand,
          ScreenShopTheme.naturalOrganic,
          ScreenShopTheme.vintageRetro,
          ScreenShopTheme.minimalistClean,
        ],
        'ร้านค้าทั่วไป': [
          ScreenShopTheme.shopeeClassic,
          ScreenShopTheme.minimalistClean
        ],
        'แฟชั่นและเสื้อผ้า': [
          ScreenShopTheme.fashionBoutique,
          ScreenShopTheme.luxuryBrand,
          ScreenShopTheme.vintageRetro
        ],
        'เทคโนโลยี': [
          ScreenShopTheme.techStore,
          ScreenShopTheme.minimalistClean
        ],
        'ความงาม': [
          ScreenShopTheme.beautyCosmetic,
          ScreenShopTheme.luxuryBrand
        ],
        'อาหารและเครื่องดื่ม': [
          ScreenShopTheme.foodDelivery,
          ScreenShopTheme.naturalOrganic
        ],
        'กีฬาและกิจกรรม': [
          ScreenShopTheme.sportsOutdoor,
          ScreenShopTheme.minimalistClean
        ],
        'บ้านและสวน': [
          ScreenShopTheme.homeDecor,
          ScreenShopTheme.naturalOrganic,
          ScreenShopTheme.vintageRetro
        ],
        'เด็กและครอบครัว': [
          ScreenShopTheme.kidsFamily,
          ScreenShopTheme.minimalistClean
        ],
        'แบรนด์หรูหรา': [
          ScreenShopTheme.luxuryBrand,
          ScreenShopTheme.fashionBoutique
        ],
        'ธรรมชาติและสุขภาพ': [
          ScreenShopTheme.naturalOrganic,
          ScreenShopTheme.minimalistClean
        ],
      };

  Future<void> _applyTemplate(ScreenShopTheme theme) async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'กรุณาเข้าสู่ระบบ';

      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final template = ShopTemplate.getTemplate(theme);

      // สร้าง ShopCustomization จากเทมเพลต
      final customization = ShopCustomization(
        sellerId: user.uid,
        theme: theme,
        banner: template.defaultBanner,
        sections: [], // เพิ่มได้ภายหลัง
        colors: template.colors,
        layout: template.layout,
        featuredProductIds: [],
        promotions: [],
      );

      // บันทึกลง Firebase
      await firebaseService.saveShopCustomization(customization);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('ใช้ธีม "${template.name}" เรียบร้อยแล้ว!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'ดูหน้าร้าน',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pop(context);
                // เปิดหน้าพรีวิวร้าน
              },
            ),
          ),
        );

        Navigator.pop(context, true); // ส่งค่า true กลับไปว่าเปลี่ยนธีมแล้ว
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('เกิดข้อผิดพลาด: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredThemes = _themesByCategory[_selectedCategory] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกธีมร้านค้า'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header พร้อมคำอธิบาย
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🎨 เลือกธีมสำเร็จรูปแบบ Shopee',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'ธีมพร้อมใช้ที่ออกแบบมาเป็นพิเศษ เปลี่ยนแค่คลิกเดียว!',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Category Filter
          Container(
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
                    label: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.primary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: AppColors.primary),
                  ),
                );
              },
            ),
          ),

          // Templates Grid
          Expanded(
            child: filteredThemes.isEmpty
                ? const Center(
                    child: Text('ไม่มีธีมในหมวดหมู่นี้'),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: filteredThemes.length,
                    itemBuilder: (context, index) {
                      final theme = filteredThemes[index];
                      final template = ShopTemplate.getTemplate(theme);
                      final isSelected = theme == _selectedTheme;

                      return _buildTemplateCard(template, isSelected);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(ShopTemplate template, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTheme = template.theme;
        });
        _showTemplatePreview(template);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Preview Area
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(15)),
                  gradient: LinearGradient(
                    colors: [
                      Color(int.parse(
                          '0xFF${template.colors.primary.substring(1)}')),
                      Color(int.parse(
                          '0xFF${template.colors.secondary.substring(1)}')),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      template.theme.icon,
                      size: 40,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      template.iconEmojis.values.take(3).join(' '),
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ),
            ),
            // Info Area
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.palette,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'พร้อมใช้',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
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

  void _showTemplatePreview(ShopTemplate template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(
                    int.parse('0xFF${template.colors.primary.substring(1)}')),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(template.theme.icon, color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              template.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              template.description,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Preview Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner Preview
                    if (template.defaultBanner != null) ...[
                      const Text(
                        '📱 แบนเนอร์ตัวอย่าง',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(int.parse(
                                  '0xFF${template.colors.primary.substring(1)}')),
                              Color(int.parse(
                                  '0xFF${template.colors.secondary.substring(1)}')),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              template.defaultBanner!.title ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (template.defaultBanner!.subtitle != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                template.defaultBanner!.subtitle!,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Messages Preview
                    const Text(
                      '💬 ข้อความตัวอย่าง',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...template.defaultMessages.map((message) => Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(message),
                        )),
                    const SizedBox(height: 16),

                    // Categories
                    const Text(
                      '🏷️ หมวดหมู่ที่แนะนำ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: template.suggestedCategories
                          .map((category) => Chip(
                                label: Text(
                                  category,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: Color(int.parse(
                                        '0xFF${template.colors.secondary.substring(1)}'))
                                    .withOpacity(0.3),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),

            // Apply Button
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.pop(context);
                          _applyTemplate(template.theme);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(int.parse(
                        '0xFF${template.colors.primary.substring(1)}')),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle),
                            const SizedBox(width: 8),
                            Text('ใช้ธีม "${template.name}"'),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
