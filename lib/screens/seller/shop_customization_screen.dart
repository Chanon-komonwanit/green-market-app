// lib/screens/seller/shop_customization_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:green_market/theme/app_colors.dart';
import 'package:green_market/models/shop_customization.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/widgets/product_card.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ShopCustomizationScreen extends StatefulWidget {
  final String sellerId;

  const ShopCustomizationScreen({
    super.key,
    required this.sellerId,
  });

  @override
  State<ShopCustomizationScreen> createState() =>
      _ShopCustomizationScreenState();
}

class _ShopCustomizationScreenState extends State<ShopCustomizationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ShopCustomization? _customization;
  List<Product> _products = [];
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers for banner
  final _bannerTitleController = TextEditingController();
  final _bannerSubtitleController = TextEditingController();
  final _bannerButtonTextController = TextEditingController();
  final _bannerButtonLinkController = TextEditingController();
  XFile? _bannerImageFile;

  // Selected theme and colors
  ScreenShopTheme _selectedTheme = ScreenShopTheme.greenEco;
  ShopColors _shopColors = ShopColors();
  ShopLayout _shopLayout = ShopLayout();

  // Featured products
  List<String> _selectedFeaturedProductIds = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadShopCustomization();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bannerTitleController.dispose();
    _bannerSubtitleController.dispose();
    _bannerButtonTextController.dispose();
    _bannerButtonLinkController.dispose();
    super.dispose();
  }

  Future<void> _loadShopCustomization() async {
    setState(() => _isLoading = true);
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);

      // โหลดการปรับแต่งปัจจุบัน
      _customization =
          await firebaseService.getShopCustomization(widget.sellerId);

      // โหลดสินค้า
      _products = await firebaseService.getProductsBySellerId(widget.sellerId);

      // Set ค่าปัจจุบัน
      if (_customization != null) {
        _selectedTheme = _customization!.theme;
        _shopColors = _customization!.colors;
        _shopLayout = _customization!.layout;
        _selectedFeaturedProductIds =
            List.from(_customization!.featuredProductIds);

        if (_customization!.banner != null) {
          _bannerTitleController.text = _customization!.banner!.title ?? '';
          _bannerSubtitleController.text =
              _customization!.banner!.subtitle ?? '';
          _bannerButtonTextController.text =
              _customization!.banner!.buttonText ?? '';
          _bannerButtonLinkController.text =
              _customization!.banner!.buttonLink ?? '';
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCustomization() async {
    setState(() => _isSaving = true);
    try {
      print('Starting shop customization save for seller: ${widget.sellerId}');
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);

      String? bannerImageUrl;
      if (_bannerImageFile != null) {
        print('Uploading banner image...');
        if (kIsWeb) {
          final bytes = await _bannerImageFile!.readAsBytes();
          bannerImageUrl = await firebaseService.uploadWebImage(
            bytes,
            'shop_banners/${widget.sellerId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
        } else {
          bannerImageUrl = await firebaseService.uploadImageFile(
            File(_bannerImageFile!.path),
            'shop_banners/${widget.sellerId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
        }
        print('Banner image uploaded: $bannerImageUrl');
      } else if (_customization?.banner?.imageUrl != null) {
        bannerImageUrl = _customization!.banner!.imageUrl;
        print('Using existing banner image: $bannerImageUrl');
      }

      final banner = ShopBanner(
        imageUrl: bannerImageUrl,
        title: _bannerTitleController.text.trim().isNotEmpty
            ? _bannerTitleController.text.trim()
            : null,
        subtitle: _bannerSubtitleController.text.trim().isNotEmpty
            ? _bannerSubtitleController.text.trim()
            : null,
        buttonText: _bannerButtonTextController.text.trim().isNotEmpty
            ? _bannerButtonTextController.text.trim()
            : null,
        buttonLink: _bannerButtonLinkController.text.trim().isNotEmpty
            ? _bannerButtonLinkController.text.trim()
            : null,
        isVisible: _bannerTitleController.text.trim().isNotEmpty ||
            bannerImageUrl != null,
      );

      final customization = ShopCustomization(
        sellerId: widget.sellerId,
        theme: _selectedTheme,
        banner: banner,
        sections: [], // TODO: Implement sections
        colors: _shopColors,
        layout: _shopLayout,
        featuredProductIds: _selectedFeaturedProductIds,
        promotions: [], // TODO: Implement promotions
      );

      print('Saving shop customization...');
      await firebaseService.saveShopCustomization(customization);
      print('Shop customization saved successfully');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกการปรับแต่งร้านค้าสำเร็จ!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึก: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ปรับแต่งร้านค้า'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveCustomization,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text('บันทึก', style: TextStyle(color: Colors.white)),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'ธีม'),
            Tab(text: 'แบนเนอร์'),
            Tab(text: 'สินค้าแนะนำ'),
            Tab(text: 'เลย์เอาต์'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildThemeTab(),
                _buildBannerTab(),
                _buildFeaturedProductsTab(),
                _buildLayoutTab(),
              ],
            ),
    );
  }

  Widget _buildThemeTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'เลือกธีมร้านค้า',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: ScreenShopTheme.values.length,
              itemBuilder: (context, index) {
                final theme = ScreenShopTheme.values[index];
                final isSelected = theme == _selectedTheme;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTheme = theme;
                      _shopColors = ShopColors(
                        primary:
                            '#${theme.primaryColor.value.toRadixString(16).substring(2)}',
                        secondary:
                            '#${theme.secondaryColor.value.toRadixString(16).substring(2)}',
                        accent:
                            '#${theme.primaryColor.value.toRadixString(16).substring(2)}',
                        background: '#FFFFFF',
                        surface: '#F8FAFB',
                        text: '#111827',
                      );
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.grayMediumLight,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(
                                colors: [
                                  theme.primaryColor,
                                  theme.secondaryColor,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                theme.icon,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            theme.name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.grayDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'แบนเนอร์ร้านค้า',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Preview
          if (_bannerImageFile != null ||
              _bannerTitleController.text.isNotEmpty ||
              _customization?.banner?.imageUrl != null)
            Container(
              height: 120,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    _getColorFromHex(_shopColors.primary),
                    _getColorFromHex(_shopColors.secondary),
                  ],
                ),
              ),
              child: _bannerImageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: kIsWeb
                          ? Image.network(_bannerImageFile!.path,
                              fit: BoxFit.cover)
                          : Image.file(File(_bannerImageFile!.path),
                              fit: BoxFit.cover),
                    )
                  : _customization?.banner?.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _customization!.banner!.imageUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_bannerTitleController.text.isNotEmpty)
                                Text(
                                  _bannerTitleController.text,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (_bannerSubtitleController.text.isNotEmpty)
                                Text(
                                  _bannerSubtitleController.text,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                            ],
                          ),
                        ),
            ),

          // Banner Image
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('รูปแบนเนอร์'),
            subtitle: Text(_bannerImageFile?.name ?? 'เลือกรูปภาพ'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _pickBannerImage,
          ),

          const SizedBox(height: 16),

          // Banner Text Fields
          Expanded(
            child: ListView(
              children: [
                TextField(
                  controller: _bannerTitleController,
                  decoration: const InputDecoration(
                    labelText: 'หัวข้อแบนเนอร์',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bannerSubtitleController,
                  decoration: const InputDecoration(
                    labelText: 'คำอธิบาย',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bannerButtonTextController,
                  decoration: const InputDecoration(
                    labelText: 'ข้อความปุ่ม',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bannerButtonLinkController,
                  decoration: const InputDecoration(
                    labelText: 'ลิงก์ปุ่ม',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedProductsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'สินค้าแนะนำ (เลือกได้สูงสุด 6 รายการ)',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            'เลือกแล้ว: ${_selectedFeaturedProductIds.length}/6',
            style: TextStyle(color: AppColors.grayMedium),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.7,
              ),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                final isSelected =
                    _selectedFeaturedProductIds.contains(product.id);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedFeaturedProductIds.remove(product.id);
                      } else if (_selectedFeaturedProductIds.length < 6) {
                        _selectedFeaturedProductIds.add(product.id);
                      }
                    });
                  },
                  child: Stack(
                    children: [
                      ProductCard(
                        product: product,
                        onTap: () {}, // Disable navigation
                      ),
                      if (isSelected)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'การจัดวางสินค้า',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('จำนวนคอลัมน์'),
            subtitle: Text('${_shopLayout.gridColumns} คอลัมน์'),
            trailing: DropdownButton<int>(
              value: _shopLayout.gridColumns,
              items: [1, 2, 3].map((columns) {
                return DropdownMenuItem(
                  value: columns,
                  child: Text('$columns คอลัมน์'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _shopLayout = ShopLayout(
                      gridColumns: value,
                      cardSpacing: _shopLayout.cardSpacing,
                      showPrices: _shopLayout.showPrices,
                      showRatings: _shopLayout.showRatings,
                      compactMode: _shopLayout.compactMode,
                      headerStyle: _shopLayout.headerStyle,
                    );
                  });
                }
              },
            ),
          ),
          SwitchListTile(
            title: const Text('แสดงราคา'),
            value: _shopLayout.showPrices,
            onChanged: (value) {
              setState(() {
                _shopLayout = ShopLayout(
                  gridColumns: _shopLayout.gridColumns,
                  cardSpacing: _shopLayout.cardSpacing,
                  showPrices: value,
                  showRatings: _shopLayout.showRatings,
                  compactMode: _shopLayout.compactMode,
                  headerStyle: _shopLayout.headerStyle,
                );
              });
            },
          ),
          SwitchListTile(
            title: const Text('แสดงคะแนนรีวิว'),
            value: _shopLayout.showRatings,
            onChanged: (value) {
              setState(() {
                _shopLayout = ShopLayout(
                  gridColumns: _shopLayout.gridColumns,
                  cardSpacing: _shopLayout.cardSpacing,
                  showPrices: _shopLayout.showPrices,
                  showRatings: value,
                  compactMode: _shopLayout.compactMode,
                  headerStyle: _shopLayout.headerStyle,
                );
              });
            },
          ),
          SwitchListTile(
            title: const Text('โหมดกะทัดรัด'),
            value: _shopLayout.compactMode,
            onChanged: (value) {
              setState(() {
                _shopLayout = ShopLayout(
                  gridColumns: _shopLayout.gridColumns,
                  cardSpacing: _shopLayout.cardSpacing,
                  showPrices: _shopLayout.showPrices,
                  showRatings: _shopLayout.showRatings,
                  compactMode: value,
                  headerStyle: _shopLayout.headerStyle,
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickBannerImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _bannerImageFile = image;
      });
    }
  }

  Color _getColorFromHex(String hex) {
    try {
      return Color(int.parse('0xFF${hex.replaceAll('#', '')}'));
    } catch (e) {
      return AppColors.primary;
    }
  }
}
