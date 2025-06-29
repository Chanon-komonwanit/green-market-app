// lib/screens/admin/dynamic_app_config_screen.dart
// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/models/dynamic_app_config.dart';
import 'package:green_market/providers/app_config_provider.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/app_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class DynamicAppConfigScreen extends StatefulWidget {
  const DynamicAppConfigScreen({super.key});

  @override
  State<DynamicAppConfigScreen> createState() => _DynamicAppConfigScreenState();
}

class _DynamicAppConfigScreenState extends State<DynamicAppConfigScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSaving = false;

  // Basic Info Controllers
  final TextEditingController _appNameController = TextEditingController();
  final TextEditingController _appTaglineController = TextEditingController();
  final TextEditingController _heroTitleController = TextEditingController();
  final TextEditingController _heroSubtitleController = TextEditingController();

  // Contact Controllers
  final TextEditingController _supportEmailController = TextEditingController();
  final TextEditingController _supportPhoneController = TextEditingController();
  final TextEditingController _companyAddressController =
      TextEditingController();
  final TextEditingController _facebookUrlController = TextEditingController();
  final TextEditingController _lineUrlController = TextEditingController();
  final TextEditingController _instagramUrlController = TextEditingController();
  final TextEditingController _twitterUrlController = TextEditingController();

  // Business Settings Controllers
  final TextEditingController _defaultShippingFeeController =
      TextEditingController();
  final TextEditingController _minimumOrderAmountController =
      TextEditingController();
  final TextEditingController _maxCartItemsController = TextEditingController();
  final TextEditingController _productApprovalDaysController =
      TextEditingController();
  final TextEditingController _platformCommissionRateController =
      TextEditingController();

  // Typography Controllers
  final TextEditingController _baseFontSizeController = TextEditingController();
  final TextEditingController _titleFontSizeController =
      TextEditingController();
  final TextEditingController _headingFontSizeController =
      TextEditingController();
  final TextEditingController _captionFontSizeController =
      TextEditingController();

  // Layout Controllers
  final TextEditingController _borderRadiusController = TextEditingController();
  final TextEditingController _cardElevationController =
      TextEditingController();
  final TextEditingController _buttonHeightController = TextEditingController();
  final TextEditingController _inputHeightController = TextEditingController();
  final TextEditingController _spacingController = TextEditingController();
  final TextEditingController _paddingController = TextEditingController();

  // Image Files
  XFile? _logoFile;
  XFile? _faviconFile;
  XFile? _heroImageFile;
  String? _logoUrl;
  String? _faviconUrl;
  String? _heroImageUrl;

  // Colors
  Color _primaryColor = const Color(0xFF4CAF50);
  Color _secondaryColor = const Color(0xFFFF9800);
  Color _accentColor = const Color(0xFF2196F3);
  Color _backgroundColor = const Color(0xFFF5F5F5);
  Color _surfaceColor = const Color(0xFFFFFFFF);
  Color _errorColor = const Color(0xFFF44336);
  Color _successColor = const Color(0xFF4CAF50);
  Color _warningColor = const Color(0xFFFF9800);
  Color _infoColor = const Color(0xFF2196F3);

  // Font Families
  String _primaryFontFamily = 'Sarabun';
  String _secondaryFontFamily = 'Sarabun';

  // Feature Toggles
  bool _enableDarkMode = true;
  bool _enableNotifications = true;
  bool _enableChat = true;
  bool _enableInvestments = true;
  bool _enableSustainableActivities = true;
  bool _enableReviews = true;
  bool _enablePromotions = true;
  bool _enableMultiLanguage = false;

  // Text Content Maps
  final Map<String, TextEditingController> _staticTextControllers = {};
  final Map<String, TextEditingController> _errorMessageControllers = {};
  final Map<String, TextEditingController> _successMessageControllers = {};
  final Map<String, TextEditingController> _labelControllers = {};
  final Map<String, TextEditingController> _placeholderControllers = {};
  final Map<String, TextEditingController> _buttonTextControllers = {};

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadCurrentConfig();
    _initializeTextControllers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _appNameController.dispose();
    _appTaglineController.dispose();
    _heroTitleController.dispose();
    _heroSubtitleController.dispose();
    _supportEmailController.dispose();
    _supportPhoneController.dispose();
    _companyAddressController.dispose();
    _facebookUrlController.dispose();
    _lineUrlController.dispose();
    _instagramUrlController.dispose();
    _twitterUrlController.dispose();
    _defaultShippingFeeController.dispose();
    _minimumOrderAmountController.dispose();
    _maxCartItemsController.dispose();
    _productApprovalDaysController.dispose();
    _platformCommissionRateController.dispose();
    _baseFontSizeController.dispose();
    _titleFontSizeController.dispose();
    _headingFontSizeController.dispose();
    _captionFontSizeController.dispose();
    _borderRadiusController.dispose();
    _cardElevationController.dispose();
    _buttonHeightController.dispose();
    _inputHeightController.dispose();
    _spacingController.dispose();
    _paddingController.dispose();

    // Dispose text content controllers
    for (var controller in _staticTextControllers.values) {
      controller.dispose();
    }
    for (var controller in _errorMessageControllers.values) {
      controller.dispose();
    }
    for (var controller in _successMessageControllers.values) {
      controller.dispose();
    }
    for (var controller in _labelControllers.values) {
      controller.dispose();
    }
    for (var controller in _placeholderControllers.values) {
      controller.dispose();
    }
    for (var controller in _buttonTextControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  void _initializeTextControllers() {
    // Common static texts
    final staticTexts = [
      'welcome_message',
      'app_description',
      'footer_text',
      'terms_link',
      'privacy_link',
      'contact_us',
      'about_us',
      'help_center'
    ];

    final errorMessages = [
      'network_error',
      'validation_error',
      'login_failed',
      'upload_failed',
      'payment_failed',
      'order_failed',
      'general_error'
    ];

    final successMessages = [
      'login_success',
      'order_success',
      'payment_success',
      'upload_success',
      'profile_updated',
      'settings_saved'
    ];

    final labels = [
      'email',
      'password',
      'name',
      'phone',
      'address',
      'product_name',
      'price',
      'description',
      'category',
      'stock'
    ];

    final placeholders = [
      'enter_email',
      'enter_password',
      'enter_name',
      'enter_phone',
      'enter_address',
      'enter_product_name',
      'enter_price',
      'enter_description'
    ];

    final buttonTexts = [
      'login',
      'register',
      'save',
      'cancel',
      'confirm',
      'delete',
      'edit',
      'add_to_cart',
      'checkout',
      'pay_now'
    ];

    for (var key in staticTexts) {
      _staticTextControllers[key] = TextEditingController();
    }
    for (var key in errorMessages) {
      _errorMessageControllers[key] = TextEditingController();
    }
    for (var key in successMessages) {
      _successMessageControllers[key] = TextEditingController();
    }
    for (var key in labels) {
      _labelControllers[key] = TextEditingController();
    }
    for (var key in placeholders) {
      _placeholderControllers[key] = TextEditingController();
    }
    for (var key in buttonTexts) {
      _buttonTextControllers[key] = TextEditingController();
    }
  }

  Future<void> _loadCurrentConfig() async {
    setState(() => _isLoading = true);

    final appConfigProvider =
        Provider.of<AppConfigProvider>(context, listen: false);
    final config = appConfigProvider.config;

    // Load basic info
    _appNameController.text = config.appName;
    _appTaglineController.text = config.appTagline;
    _heroTitleController.text = config.heroTitle;
    _heroSubtitleController.text = config.heroSubtitle;

    // Load contact info
    _supportEmailController.text = config.supportEmail;
    _supportPhoneController.text = config.supportPhone;
    _companyAddressController.text = config.companyAddress;
    _facebookUrlController.text = config.facebookUrl;
    _lineUrlController.text = config.lineUrl;
    _instagramUrlController.text = config.instagramUrl;
    _twitterUrlController.text = config.twitterUrl;

    // Load business settings
    _defaultShippingFeeController.text = config.defaultShippingFee.toString();
    _minimumOrderAmountController.text = config.minimumOrderAmount.toString();
    _maxCartItemsController.text = config.maxCartItems.toString();
    _productApprovalDaysController.text = config.productApprovalDays.toString();
    _platformCommissionRateController.text =
        config.platformCommissionRate.toString();

    // Load typography
    _baseFontSizeController.text = config.baseFontSize.toString();
    _titleFontSizeController.text = config.titleFontSize.toString();
    _headingFontSizeController.text = config.headingFontSize.toString();
    _captionFontSizeController.text = config.captionFontSize.toString();

    // Load layout
    _borderRadiusController.text = config.borderRadius.toString();
    _cardElevationController.text = config.cardElevation.toString();
    _buttonHeightController.text = config.buttonHeight.toString();
    _inputHeightController.text = config.inputHeight.toString();
    _spacingController.text = config.spacing.toString();
    _paddingController.text = config.padding.toString();

    // Load colors
    _primaryColor = config.primaryColor;
    _secondaryColor = config.secondaryColor;
    _accentColor = config.accentColor;
    _backgroundColor = config.backgroundColor;
    _surfaceColor = config.surfaceColor;
    _errorColor = config.errorColor;
    _successColor = config.successColor;
    _warningColor = config.warningColor;
    _infoColor = config.infoColor;

    // Load fonts
    _primaryFontFamily = config.primaryFontFamily;
    _secondaryFontFamily = config.secondaryFontFamily;

    // Load feature toggles
    _enableDarkMode = config.enableDarkMode;
    _enableNotifications = config.enableNotifications;
    _enableChat = config.enableChat;
    _enableInvestments = config.enableInvestments;
    _enableSustainableActivities = config.enableSustainableActivities;
    _enableReviews = config.enableReviews;
    _enablePromotions = config.enablePromotions;
    _enableMultiLanguage = config.enableMultiLanguage;

    // Load image URLs
    _logoUrl = config.logoUrl.isNotEmpty ? config.logoUrl : null;
    _faviconUrl = config.faviconUrl.isNotEmpty ? config.faviconUrl : null;
    _heroImageUrl = config.heroImageUrl.isNotEmpty ? config.heroImageUrl : null;

    // Load text content
    for (var key in _staticTextControllers.keys) {
      _staticTextControllers[key]!.text = config.staticTexts[key] ?? '';
    }
    for (var key in _errorMessageControllers.keys) {
      _errorMessageControllers[key]!.text = config.errorMessages[key] ?? '';
    }
    for (var key in _successMessageControllers.keys) {
      _successMessageControllers[key]!.text = config.successMessages[key] ?? '';
    }
    for (var key in _labelControllers.keys) {
      _labelControllers[key]!.text = config.labels[key] ?? '';
    }
    for (var key in _placeholderControllers.keys) {
      _placeholderControllers[key]!.text = config.placeholders[key] ?? '';
    }
    for (var key in _buttonTextControllers.keys) {
      _buttonTextControllers[key]!.text = config.buttonTexts[key] ?? '';
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('ตั้งค่าแอปพลิเคชัน',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
            )),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'ข้อมูลพื้นฐาน'),
            Tab(text: 'สีและฟอนต์'),
            Tab(text: 'รูปแบบ'),
            Tab(text: 'ฟีเจอร์'),
            Tab(text: 'การค้า'),
            Tab(text: 'ติดต่อ'),
            Tab(text: 'ข้อความ'),
          ],
        ),
        actions: [
          if (_isSaving)
            const Center(child: CircularProgressIndicator())
          else
            IconButton(
              onPressed: _saveConfig,
              icon: const Icon(Icons.save),
              tooltip: 'บันทึกการตั้งค่า',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBasicInfoTab(),
                _buildColorsAndFontsTab(),
                _buildLayoutTab(),
                _buildFeaturesTab(),
                _buildBusinessTab(),
                _buildContactTab(),
                _buildTextContentTab(),
              ],
            ),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('ข้อมูลแอปพลิเคชัน'),
            TextFormField(
              controller: _appNameController,
              decoration: const InputDecoration(
                labelText: 'ชื่อแอปพลิเคชัน',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty == true ? 'กรุณากรอกชื่อแอป' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _appTaglineController,
              decoration: const InputDecoration(
                labelText: 'แท็กไลน์/คำโฆษณา',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('หน้าหลัก'),
            TextFormField(
              controller: _heroTitleController,
              decoration: const InputDecoration(
                labelText: 'หัวข้อหลัก',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _heroSubtitleController,
              decoration: const InputDecoration(
                labelText: 'หัวข้อรอง',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('รูปภาพ'),
            _buildImageUploadSection('โลโก้', _logoUrl, _logoFile, (file) {
              setState(() => _logoFile = file);
            }),
            const SizedBox(height: 16),
            _buildImageUploadSection('Favicon', _faviconUrl, _faviconFile,
                (file) {
              setState(() => _faviconFile = file);
            }),
            const SizedBox(height: 16),
            _buildImageUploadSection(
                'รูปหน้าหลัก', _heroImageUrl, _heroImageFile, (file) {
              setState(() => _heroImageFile = file);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildColorsAndFontsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('สีหลัก'),
          _buildColorPicker('สีหลัก', _primaryColor, (color) {
            setState(() => _primaryColor = color);
          }),
          const SizedBox(height: 16),
          _buildColorPicker('สีรอง', _secondaryColor, (color) {
            setState(() => _secondaryColor = color);
          }),
          const SizedBox(height: 16),
          _buildColorPicker('สีเน้น', _accentColor, (color) {
            setState(() => _accentColor = color);
          }),
          const SizedBox(height: 24),
          _buildSectionHeader('สีระบบ'),
          _buildColorPicker('พื้นหลัง', _backgroundColor, (color) {
            setState(() => _backgroundColor = color);
          }),
          const SizedBox(height: 16),
          _buildColorPicker('พื้นผิว', _surfaceColor, (color) {
            setState(() => _surfaceColor = color);
          }),
          const SizedBox(height: 16),
          _buildColorPicker('ข้อผิดพลาด', _errorColor, (color) {
            setState(() => _errorColor = color);
          }),
          const SizedBox(height: 16),
          _buildColorPicker('สำเร็จ', _successColor, (color) {
            setState(() => _successColor = color);
          }),
          const SizedBox(height: 16),
          _buildColorPicker('คำเตือน', _warningColor, (color) {
            setState(() => _warningColor = color);
          }),
          const SizedBox(height: 16),
          _buildColorPicker('ข้อมูล', _infoColor, (color) {
            setState(() => _infoColor = color);
          }),
          const SizedBox(height: 24),
          _buildSectionHeader('ฟอนต์'),
          _buildFontFamilyDropdown('ฟอนต์หลัก', _primaryFontFamily, (value) {
            setState(() => _primaryFontFamily = value);
          }),
          const SizedBox(height: 16),
          _buildFontFamilyDropdown('ฟอนต์รอง', _secondaryFontFamily, (value) {
            setState(() => _secondaryFontFamily = value);
          }),
          const SizedBox(height: 16),
          TextFormField(
            controller: _baseFontSizeController,
            decoration: const InputDecoration(
              labelText: 'ขนาดฟอนต์พื้นฐาน',
              border: OutlineInputBorder(),
              suffixText: 'px',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleFontSizeController,
            decoration: const InputDecoration(
              labelText: 'ขนาดฟอนต์หัวข้อ',
              border: OutlineInputBorder(),
              suffixText: 'px',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _headingFontSizeController,
            decoration: const InputDecoration(
              labelText: 'ขนาดฟอนต์หัวข้อใหญ่',
              border: OutlineInputBorder(),
              suffixText: 'px',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _captionFontSizeController,
            decoration: const InputDecoration(
              labelText: 'ขนาดฟอนต์คำอธิบาย',
              border: OutlineInputBorder(),
              suffixText: 'px',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('รูปแบบและขนาด'),
          TextFormField(
            controller: _borderRadiusController,
            decoration: const InputDecoration(
              labelText: 'มุมโค้ง',
              border: OutlineInputBorder(),
              suffixText: 'px',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cardElevationController,
            decoration: const InputDecoration(
              labelText: 'เงาการ์ด',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _buttonHeightController,
            decoration: const InputDecoration(
              labelText: 'ความสูงปุ่ม',
              border: OutlineInputBorder(),
              suffixText: 'px',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _inputHeightController,
            decoration: const InputDecoration(
              labelText: 'ความสูงช่องกรอกข้อมูล',
              border: OutlineInputBorder(),
              suffixText: 'px',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _spacingController,
            decoration: const InputDecoration(
              labelText: 'ระยะห่าง',
              border: OutlineInputBorder(),
              suffixText: 'px',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _paddingController,
            decoration: const InputDecoration(
              labelText: 'ระยะขอบ',
              border: OutlineInputBorder(),
              suffixText: 'px',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('ฟีเจอร์ของแอป'),
          _buildFeatureSwitch('เปิดใช้โหมดมืด', _enableDarkMode, (value) {
            setState(() => _enableDarkMode = value);
          }),
          _buildFeatureSwitch('เปิดใช้การแจ้งเตือน', _enableNotifications,
              (value) {
            setState(() => _enableNotifications = value);
          }),
          _buildFeatureSwitch('เปิดใช้แชท', _enableChat, (value) {
            setState(() => _enableChat = value);
          }),
          _buildFeatureSwitch('เปิดใช้การลงทุน', _enableInvestments, (value) {
            setState(() => _enableInvestments = value);
          }),
          _buildFeatureSwitch(
              'เปิดใช้กิจกรรมยั่งยืน', _enableSustainableActivities, (value) {
            setState(() => _enableSustainableActivities = value);
          }),
          _buildFeatureSwitch('เปิดใช้รีวิว', _enableReviews, (value) {
            setState(() => _enableReviews = value);
          }),
          _buildFeatureSwitch('เปิดใช้โปรโมชัน', _enablePromotions, (value) {
            setState(() => _enablePromotions = value);
          }),
          _buildFeatureSwitch('เปิดใช้หลายภาษา', _enableMultiLanguage, (value) {
            setState(() => _enableMultiLanguage = value);
          }),
        ],
      ),
    );
  }

  Widget _buildBusinessTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('การตั้งค่าทางธุรกิจ'),
          TextFormField(
            controller: _defaultShippingFeeController,
            decoration: const InputDecoration(
              labelText: 'ค่าจัดส่งเริ่มต้น',
              border: OutlineInputBorder(),
              suffixText: '฿',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _minimumOrderAmountController,
            decoration: const InputDecoration(
              labelText: 'ยอดสั่งซื้อขั้นต่ำ',
              border: OutlineInputBorder(),
              suffixText: '฿',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _maxCartItemsController,
            decoration: const InputDecoration(
              labelText: 'จำนวนสินค้าสูงสุดในตะกร้า',
              border: OutlineInputBorder(),
              suffixText: 'ชิ้น',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _productApprovalDaysController,
            decoration: const InputDecoration(
              labelText: 'วันในการอนุมัติสินค้า',
              border: OutlineInputBorder(),
              suffixText: 'วัน',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _platformCommissionRateController,
            decoration: const InputDecoration(
              labelText: 'อัตราค่าคอมมิชชั่นแพลตฟอร์ม',
              border: OutlineInputBorder(),
              suffixText: '%',
              helperText: 'ระบุเป็นทศนิยม เช่น 0.05 = 5%',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('ข้อมูลติดต่อ'),
          TextFormField(
            controller: _supportEmailController,
            decoration: const InputDecoration(
              labelText: 'อีเมลสนับสนุน',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _supportPhoneController,
            decoration: const InputDecoration(
              labelText: 'เบอร์โทรสนับสนุน',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _companyAddressController,
            decoration: const InputDecoration(
              labelText: 'ที่อยู่บริษัท',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('โซเชียลมีเดีย'),
          TextFormField(
            controller: _facebookUrlController,
            decoration: const InputDecoration(
              labelText: 'Facebook URL',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.facebook),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lineUrlController,
            decoration: const InputDecoration(
              labelText: 'Line URL',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.chat),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _instagramUrlController,
            decoration: const InputDecoration(
              labelText: 'Instagram URL',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.camera_alt),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _twitterUrlController,
            decoration: const InputDecoration(
              labelText: 'Twitter URL',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.alternate_email),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextContentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextContentSection('ข้อความคงที่', _staticTextControllers),
          const SizedBox(height: 24),
          _buildTextContentSection(
              'ข้อความข้อผิดพลาด', _errorMessageControllers),
          const SizedBox(height: 24),
          _buildTextContentSection('ข้อความสำเร็จ', _successMessageControllers),
          const SizedBox(height: 24),
          _buildTextContentSection('ป้ายกำกับ', _labelControllers),
          const SizedBox(height: 24),
          _buildTextContentSection('ข้อความแนะนำ', _placeholderControllers),
          const SizedBox(height: 24),
          _buildTextContentSection('ข้อความปุ่ม', _buttonTextControllers),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildImageUploadSection(
    String label,
    String? currentUrl,
    XFile? pickedFile,
    Function(XFile?) onFilePicked,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: pickedFile != null
              ? kIsWeb
                  ? FutureBuilder<Uint8List>(
                      future: pickedFile.readAsBytes(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Image.memory(snapshot.data!,
                              fit: BoxFit.cover);
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    )
                  : Image.file(File(pickedFile.path), fit: BoxFit.cover)
              : currentUrl != null && currentUrl.isNotEmpty
                  ? Image.network(currentUrl, fit: BoxFit.cover)
                  : const Center(child: Icon(Icons.image, size: 48)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                final file =
                    await _picker.pickImage(source: ImageSource.gallery);
                onFilePicked(file);
              },
              icon: const Icon(Icons.upload),
              label: const Text('เลือกรูป'),
            ),
            const SizedBox(width: 8),
            if (pickedFile != null ||
                (currentUrl != null && currentUrl.isNotEmpty))
              TextButton(
                onPressed: () => onFilePicked(null),
                child: const Text('ลบรูป'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorPicker(
      String label, Color color, Function(Color) onChanged) {
    return ListTile(
      title: Text(label),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            Color tempColor = color;
            return AlertDialog(
              title: Text('เลือกสี$label'),
              content: SingleChildScrollView(
                child: ColorPicker(
                  pickerColor: color,
                  onColorChanged: (newColor) {
                    tempColor = newColor;
                    onChanged(newColor); // อัปเดตทันที
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // ยืนยันการเปลี่ยนแปลง
                    Navigator.of(context).pop();
                    _applyColorChange(label, tempColor);
                  },
                  child: const Text('ตกลง'),
                ),
                TextButton(
                  onPressed: () {
                    // ยกเลิก - คืนสีเดิม
                    onChanged(color);
                    Navigator.of(context).pop();
                  },
                  child: const Text('ยกเลิก'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _applyColorChange(String label, Color color) async {
    final appConfigProvider =
        Provider.of<AppConfigProvider>(context, listen: false);

    try {
      switch (label) {
        case 'สีหลัก':
          await appConfigProvider.updatePrimaryColor(color);
          break;
        case 'สีรอง':
          await appConfigProvider.updateSecondaryColor(color);
          break;
        case 'สีเน้น':
          await appConfigProvider.updateAccentColor(color);
          break;
        case 'พื้นหลัง':
          await appConfigProvider.updateBackgroundColor(color);
          break;
        case 'พื้นผิว':
          await appConfigProvider.updateSurfaceColor(color);
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('อัปเดต$labelสำเร็จ'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการอัปเดต$label: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildFontFamilyDropdown(
      String label, String value, Function(String) onChanged) {
    final fontFamilies = [
      'Sarabun',
      'Kanit',
      'Prompt',
      'Mitr',
      'Roboto',
      'Arial'
    ];

    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: fontFamilies.map((font) {
        return DropdownMenuItem(
          value: font,
          child: Text(font, style: TextStyle(fontFamily: font)),
        );
      }).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          onChanged(newValue);
        }
      },
    );
  }

  Widget _buildFeatureSwitch(
      String label, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildTextContentSection(
      String title, Map<String, TextEditingController> controllers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title),
        ...controllers.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: TextFormField(
              controller: entry.value,
              decoration: InputDecoration(
                labelText: entry.key.replaceAll('_', ' ').toUpperCase(),
                border: const OutlineInputBorder(),
              ),
              maxLines: entry.key.contains('description') ||
                      entry.key.contains('message')
                  ? 3
                  : 1,
            ),
          );
        }).toList(),
      ],
    );
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final appConfigProvider =
          Provider.of<AppConfigProvider>(context, listen: false);

      // Upload images if needed
      String? logoUrl = _logoUrl;
      String? faviconUrl = _faviconUrl;
      String? heroImageUrl = _heroImageUrl;

      if (_logoFile != null) {
        logoUrl = await _uploadImage(_logoFile!, 'logos');
      }
      if (_faviconFile != null) {
        faviconUrl = await _uploadImage(_faviconFile!, 'favicons');
      }
      if (_heroImageFile != null) {
        heroImageUrl = await _uploadImage(_heroImageFile!, 'hero_images');
      }

      // Create text content maps
      final staticTexts = <String, String>{};
      final errorMessages = <String, String>{};
      final successMessages = <String, String>{};
      final labels = <String, String>{};
      final placeholders = <String, String>{};
      final buttonTexts = <String, String>{};

      for (var entry in _staticTextControllers.entries) {
        if (entry.value.text.isNotEmpty) {
          staticTexts[entry.key] = entry.value.text;
        }
      }
      for (var entry in _errorMessageControllers.entries) {
        if (entry.value.text.isNotEmpty) {
          errorMessages[entry.key] = entry.value.text;
        }
      }
      for (var entry in _successMessageControllers.entries) {
        if (entry.value.text.isNotEmpty) {
          successMessages[entry.key] = entry.value.text;
        }
      }
      for (var entry in _labelControllers.entries) {
        if (entry.value.text.isNotEmpty) {
          labels[entry.key] = entry.value.text;
        }
      }
      for (var entry in _placeholderControllers.entries) {
        if (entry.value.text.isNotEmpty) {
          placeholders[entry.key] = entry.value.text;
        }
      }
      for (var entry in _buttonTextControllers.entries) {
        if (entry.value.text.isNotEmpty) {
          buttonTexts[entry.key] = entry.value.text;
        }
      }

      // Create new config
      final config = DynamicAppConfig(
        id: 'main',
        appName: _appNameController.text,
        appTagline: _appTaglineController.text,
        logoUrl: logoUrl ?? '',
        faviconUrl: faviconUrl ?? '',
        heroImageUrl: heroImageUrl ?? '',
        heroTitle: _heroTitleController.text,
        heroSubtitle: _heroSubtitleController.text,
        primaryColorValue: _primaryColor.value,
        secondaryColorValue: _secondaryColor.value,
        accentColorValue: _accentColor.value,
        backgroundColorValue: _backgroundColor.value,
        surfaceColorValue: _surfaceColor.value,
        errorColorValue: _errorColor.value,
        successColorValue: _successColor.value,
        warningColorValue: _warningColor.value,
        infoColorValue: _infoColor.value,
        primaryFontFamily: _primaryFontFamily,
        secondaryFontFamily: _secondaryFontFamily,
        baseFontSize: double.tryParse(_baseFontSizeController.text) ?? 14.0,
        titleFontSize: double.tryParse(_titleFontSizeController.text) ?? 20.0,
        headingFontSize:
            double.tryParse(_headingFontSizeController.text) ?? 24.0,
        captionFontSize:
            double.tryParse(_captionFontSizeController.text) ?? 12.0,
        borderRadius: double.tryParse(_borderRadiusController.text) ?? 8.0,
        cardElevation: double.tryParse(_cardElevationController.text) ?? 2.0,
        buttonHeight: double.tryParse(_buttonHeightController.text) ?? 48.0,
        inputHeight: double.tryParse(_inputHeightController.text) ?? 56.0,
        spacing: double.tryParse(_spacingController.text) ?? 16.0,
        padding: double.tryParse(_paddingController.text) ?? 16.0,
        enableDarkMode: _enableDarkMode,
        enableNotifications: _enableNotifications,
        enableChat: _enableChat,
        enableInvestments: _enableInvestments,
        enableSustainableActivities: _enableSustainableActivities,
        enableReviews: _enableReviews,
        enablePromotions: _enablePromotions,
        enableMultiLanguage: _enableMultiLanguage,
        defaultShippingFee:
            double.tryParse(_defaultShippingFeeController.text) ?? 50.0,
        minimumOrderAmount:
            double.tryParse(_minimumOrderAmountController.text) ?? 100.0,
        maxCartItems: int.tryParse(_maxCartItemsController.text) ?? 50,
        productApprovalDays:
            int.tryParse(_productApprovalDaysController.text) ?? 7,
        platformCommissionRate:
            double.tryParse(_platformCommissionRateController.text) ?? 0.05,
        supportEmail: _supportEmailController.text,
        supportPhone: _supportPhoneController.text,
        companyAddress: _companyAddressController.text,
        facebookUrl: _facebookUrlController.text,
        lineUrl: _lineUrlController.text,
        instagramUrl: _instagramUrlController.text,
        twitterUrl: _twitterUrlController.text,
        staticTexts: staticTexts,
        errorMessages: errorMessages,
        successMessages: successMessages,
        labels: labels,
        placeholders: placeholders,
        buttonTexts: buttonTexts,
        images: {},
        icons: {},
        createdAt: appConfigProvider.config.createdAt,
        updatedAt: Timestamp.now(),
      );

      await appConfigProvider.updateConfig(config);

      if (mounted) {
        showAppSnackBar(context, 'บันทึกการตั้งค่าสำเร็จ', isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'เกิดข้อผิดพลาด: ${e.toString()}',
            isError: true);
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<String?> _uploadImage(XFile file, String folder) async {
    try {
      const uuid = Uuid();
      final extension = file.name.split('.').last;
      final fileName = '${folder}_${uuid.v4()}.$extension';

      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);

      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        return await firebaseService.uploadWebImage(bytes, fileName);
      } else {
        return await firebaseService.uploadImageFile(File(file.path), fileName);
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
}
