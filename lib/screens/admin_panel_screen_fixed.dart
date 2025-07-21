// lib/screens/admin_panel_screen_fixed.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/category.dart' as app_category;
import 'package:green_market/models/product.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:green_market/screens/admin/admin_category_management_screen.dart';
import 'package:green_market/screens/admin/admin_seller_application_screen.dart';
import 'package:green_market/screens/admin/admin_user_management_screen.dart';
import 'package:green_market/screens/admin/admin_promotion_management_screen.dart';
import 'package:green_market/screens/admin/admin_rewards_management_screen.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/screens/admin/admin_manage_investment_projects_screen.dart';
import 'package:green_market/screens/admin/admin_manage_sustainable_activities_screen.dart';
import 'package:green_market/screens/admin/dynamic_app_config_screen.dart';
import 'package:green_market/utils/constants.dart';
import 'dart:io';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  // ฟังก์ชันบันทึกข้อมูลแบนเนอร์ (ตัวอย่างเบื้องต้น สามารถปรับปรุง logic เพิ่มเติมได้)
  void saveData() async {
    // ตัวอย่าง: บันทึกข้อมูล Banner ไปยัง Firestore จริง
    final bannerData = {
      'title': _bannerTitleController.text,
      'description': _bannerDescriptionController.text,
      'order': int.tryParse(_bannerOrderController.text) ?? 0,
      'imagePath': _selectedBannerImage?.path ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    };
    await FirebaseFirestore.instance.collection('banners').add(bannerData);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกข้อมูลแบนเนอร์สำเร็จ!')),
      );
    }
  }

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _materialController = TextEditingController();
  final TextEditingController _ecoJustificationController =
      TextEditingController();
  final TextEditingController _verificationVideoController =
      TextEditingController();
  final TextEditingController _bannerTitleController = TextEditingController();
  final TextEditingController _bannerDescriptionController =
      TextEditingController();
  final TextEditingController _bannerOrderController = TextEditingController();

  int _ecoScore = 50;
  XFile? _pickedImageFile;
  XFile? _selectedBannerImage;
  XFile? _selectedLogoImage;
  XFile? _selectedBackgroundImage;

  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _approveImmediately = true;

  String? _selectedAdminAddCategoryId;
  String? _selectedAdminAddCategoryName;
  List<app_category.Category> _adminAddCategories = [];
  bool _isLoadingAdminAddCategories = true;

  // UI Customization fields
  final IconData _selectedFloatingActionIcon = Icons.eco;
  final Color _selectedFloatingActionColor = AppColors.primaryTeal;

  @override
  void initState() {
    super.initState();
    _loadAdminAddCategories();
  }

  Future<void> _loadAdminAddCategories() async {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    try {
      final categories = await firebaseService.getCategories().first;
      if (mounted) {
        setState(() {
          _adminAddCategories = categories;
          _isLoadingAdminAddCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAdminAddCategories = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('เกิดข้อผิดพลาดในการโหลดหมวดหมู่ (Admin): $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedImageFile = pickedFile;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เลือกรูปภาพสำเร็จ: ${pickedFile.name}')),
        );
      }
    }
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAdminAddCategoryId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเลือกหมวดหมู่สินค้า')),
        );
      }
      return;
    }

    if (_pickedImageFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเลือกรูปภาพสินค้า')),
        );
      }
      return;
    }

    _formKey.currentState!.save();
    if (mounted) setState(() => _isLoading = true);

    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      String? imageUrl;

      if (_pickedImageFile != null) {
        var uuid = const Uuid();
        String extension = _pickedImageFile!.name.split('.').last;
        String fileName = '${uuid.v4()}.$extension';

        if (kIsWeb) {
          final bytes = await _pickedImageFile!.readAsBytes();
          imageUrl = await firebaseService.uploadImageBytes(
              'product_images', fileName, bytes);
        } else {
          imageUrl = await firebaseService.uploadImage(
              'product_images', _pickedImageFile!.path,
              fileName: fileName);
        }
      }

      final newProduct = Product(
        id: '',
        sellerId: FirebaseAuth.instance.currentUser!.uid,
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        stock: 1,
        imageUrls: imageUrl != null ? [imageUrl] : [],
        ecoScore: _ecoScore,
        materialDescription: _materialController.text,
        ecoJustification: _ecoJustificationController.text,
        verificationVideoUrl: _verificationVideoController.text.isEmpty
            ? null
            : _verificationVideoController.text,
        status: _approveImmediately ? 'approved' : 'pending_approval',
        categoryId: _selectedAdminAddCategoryId!,
        categoryName: _selectedAdminAddCategoryName,
      );

      await firebaseService.addProduct(newProduct);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สินค้าถูกเพิ่มเข้าระบบแล้ว!')),
        );
      }
      _clearForm();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('เกิดข้อผิดพลาดในการเพิ่มสินค้า: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _materialController.clear();
    _ecoJustificationController.clear();
    _verificationVideoController.clear();
    _formKey.currentState?.reset();
    setState(() {
      _pickedImageFile = null;
      _ecoScore = 50;
      _approveImmediately = true;
      _selectedAdminAddCategoryId = null;
      _selectedAdminAddCategoryName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 13,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'แผงควบคุมผู้ดูแลระบบ',
            style: AppTextStyles.title
                .copyWith(color: AppColors.white, fontSize: 20),
          ),
          backgroundColor: AppColors.primaryTeal,
          iconTheme: const IconThemeData(color: AppColors.white),
          bottom: TabBar(
            isScrollable: true,
            labelColor: AppColors.white,
            unselectedLabelColor: AppColors.white.withAlpha(179),
            indicatorColor: AppColors.lightTeal,
            indicatorWeight: 3.0,
            labelStyle: AppTextStyles.bodyBold.copyWith(fontSize: 14),
            unselectedLabelStyle: AppTextStyles.body.copyWith(fontSize: 14),
            tabs: const [
              Tab(text: 'ภาพรวม', icon: Icon(Icons.dashboard_outlined)),
              Tab(text: 'อนุมัติสินค้า', icon: Icon(Icons.check_circle)),
              Tab(text: 'คำสั่งซื้อ', icon: Icon(Icons.receipt_long)),
              Tab(text: 'จัดการหมวดหมู่', icon: Icon(Icons.category)),
              Tab(text: 'โปรโมชัน', icon: Icon(Icons.local_offer_outlined)),
              Tab(
                  text: 'จัดการผู้ใช้',
                  icon: Icon(Icons.manage_accounts_outlined)),
              Tab(
                  text: 'คำขอเปิดร้าน',
                  icon: Icon(Icons.store_mall_directory_outlined)),
              Tab(text: 'โครงการลงทุน', icon: Icon(Icons.savings_outlined)),
              Tab(
                  text: 'กิจกรรมยั่งยืน',
                  icon: Icon(Icons.nature_people_outlined)),
              Tab(
                  text: 'รางวัล Eco Coins',
                  icon: Icon(Icons.card_giftcard_outlined)),
              Tab(
                  text: 'ตั้งค่าแอป',
                  icon: Icon(Icons.settings_applications_outlined)),
              Tab(
                  text: 'จัดการระบบ',
                  icon: Icon(Icons.admin_panel_settings_outlined)),
              Tab(text: 'เครื่องมือเสริม', icon: Icon(Icons.build_outlined)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAdminDashboard(),
            _buildProductApprovalTab(),
            _buildOrderManagementTab(),
            const AdminCategoryManagementScreen(),
            const AdminPromotionManagementScreen(),
            const AdminUserManagementScreen(),
            const AdminSellerApplicationScreen(),
            const AdminManageInvestmentProjectsScreen(),
            const AdminManageSustainableActivitiesScreen(),
            const AdminRewardsManagementScreen(),
            const DynamicAppConfigScreen(),
            _buildSystemManagementTab(),
            _buildAdditionalAdminToolsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminDashboard() {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    Stream<int> pendingProductsStream;
    Stream<int> pendingSellersStream;
    Future<int> totalOrdersFuture;
    Future<int> totalUsersFuture;
    Future<int> totalProductsFuture;

    try {
      pendingProductsStream = firebaseService
          .getPendingApprovalProducts()
          .map((products) => products.length);
      pendingSellersStream =
          firebaseService.getPendingSellerApplicationsCountStream();
      totalOrdersFuture = firebaseService.getTotalOrdersCount();
      totalUsersFuture = firebaseService.getTotalUsersCount();
      totalProductsFuture = firebaseService.getTotalProductsCount();
    } catch (e) {
      pendingProductsStream = Stream<int>.value(0);
      pendingSellersStream = Stream<int>.value(0);
      totalOrdersFuture = Future<int>.value(0);
      totalUsersFuture = Future<int>.value(0);
      totalProductsFuture = Future<int>.value(0);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ภาพรวมระบบ',
            style:
                AppTextStyles.headline.copyWith(color: AppColors.primaryTeal),
          ),
          const SizedBox(height: 8),
          Text(
            'สรุปข้อมูลและรายการที่รอการดำเนินการ',
            style: AppTextStyles.body.copyWith(color: AppColors.modernGrey),
          ),
          const SizedBox(height: 20),
          _buildDashboardSummaryCard(
            title: 'สินค้ากำลังรออนุมัติ',
            countStream: pendingProductsStream,
            icon: Icons.inventory_2_outlined,
            iconColor: Colors.orange.shade700,
          ),
          const SizedBox(height: 16),
          _buildDashboardSummaryCard(
            title: 'คำขอเปิดร้านใหม่',
            countStream: pendingSellersStream,
            icon: Icons.storefront_outlined,
            iconColor: Colors.blue.shade700,
          ),
          const SizedBox(height: 16),
          _buildDashboardSummaryCard(
            title: 'คำสั่งซื้อทั้งหมด',
            countFuture: totalOrdersFuture,
            icon: Icons.receipt_long_outlined,
            iconColor: Colors.green.shade700,
          ),
          const SizedBox(height: 16),
          _buildDashboardSummaryCard(
            title: 'ผู้ใช้ทั้งหมดในระบบ',
            countFuture: totalUsersFuture,
            icon: Icons.people_alt_outlined,
            iconColor: Colors.purple.shade700,
          ),
          const SizedBox(height: 16),
          _buildDashboardSummaryCard(
            title: 'สินค้าทั้งหมดในระบบ',
            countFuture: totalProductsFuture,
            icon: Icons.shopping_bag_outlined,
            iconColor: Colors.teal.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardSummaryCard({
    required String title,
    Stream<int>? countStream,
    Future<int>? countFuture,
    required IconData icon,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: iconColor ?? AppColors.primaryTeal),
              const SizedBox(width: 16),
              Expanded(child: Text(title, style: AppTextStyles.subtitle)),
              if (countStream != null)
                StreamBuilder<int>(
                  stream: countStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }
                    return Text(
                      (snapshot.data ?? 0).toString(),
                      style: AppTextStyles.title.copyWith(
                        fontWeight: FontWeight.bold,
                        color: iconColor ?? AppColors.primaryTeal,
                      ),
                    );
                  },
                )
              else if (countFuture != null)
                FutureBuilder<int>(
                  future: countFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }
                    return Text(
                      (snapshot.data ?? 0).toString(),
                      style: AppTextStyles.title.copyWith(
                        fontWeight: FontWeight.bold,
                        color: iconColor ?? AppColors.primaryTeal,
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductApprovalTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'อนุมัติสินค้า',
            style: AppTextStyles.title.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('status', isEqualTo: 'pending_approval')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ไม่มีสินค้าที่รออนุมัติ',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final product = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: product['imageUrls'] != null &&
                                  (product['imageUrls'] as List).isNotEmpty
                              ? Image.network(
                                  (product['imageUrls'] as List)[0],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image),
                                  ),
                                )
                              : Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image),
                                ),
                        ),
                        title: Text(product['name'] ?? 'ไม่มีชื่อ'),
                        subtitle: Text(
                          'ราคา: ฿${product['price'] ?? 0} | Eco Score: ${product['ecoScore'] ?? 0}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _approveProduct(doc.id),
                              icon:
                                  const Icon(Icons.check, color: Colors.green),
                            ),
                            IconButton(
                              onPressed: () => _rejectProduct(doc.id),
                              icon: const Icon(Icons.close, color: Colors.red),
                            ),
                          ],
                        ),
                        onTap: () => _showProductDetails(product, doc.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderManagementTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'จัดการคำสั่งซื้อ',
            style: AppTextStyles.title.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .orderBy('createdAt', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ไม่มีคำสั่งซื้อ',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final order = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        title: Text('Order #${doc.id.substring(0, 8)}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ยอดรวม: ฿${order['totalAmount'] ?? 0}'),
                            Text('วันที่: ${_formatDate(order['createdAt'])}'),
                          ],
                        ),
                        trailing: _buildOrderStatusChip(order['status']),
                        onTap: () => _showOrderDetails(order, doc.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemManagementTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'จัดการระบบ',
            style: AppTextStyles.title.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 24),
          _buildManagementSection(
            title: 'จัดการฐานข้อมูล',
            icon: Icons.storage,
            children: [
              ListTile(
                leading: const Icon(Icons.backup, color: AppColors.primaryTeal),
                title: const Text('สำรองข้อมูล'),
                subtitle: const Text('สำรองข้อมูลระบบทั้งหมด'),
                onTap: _performDatabaseBackup,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
              ListTile(
                leading: const Icon(Icons.cleaning_services,
                    color: AppColors.primaryTeal),
                title: const Text('ล้างข้อมูลชั่วคราว'),
                subtitle: const Text('ลบข้อมูลแคชและไฟล์ชั่วคราว'),
                onTap: _cleanTemporaryData,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildManagementSection(
            title: 'จัดการความปลอดภัย',
            icon: Icons.security,
            children: [
              ListTile(
                leading:
                    const Icon(Icons.security, color: AppColors.primaryTeal),
                title: const Text('ตรวจสอบความปลอดภัย'),
                subtitle: const Text('สแกนหาช่องโหว่ความปลอดภัย'),
                onTap: _performSecurityScan,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
              ListTile(
                leading: const Icon(Icons.report, color: AppColors.primaryTeal),
                title: const Text('รายงานที่รอตรวจสอบ'),
                subtitle: const Text('ตรวจสอบรายงานจากผู้ใช้'),
                onTap: _reviewReports,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalAdminToolsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'เครื่องมือเสริมสำหรับแอดมิน',
            style:
                AppTextStyles.headline.copyWith(color: AppColors.primaryTeal),
          ),
          const SizedBox(height: 8),
          Text(
            'เครื่องมือเพิ่มเติมสำหรับการจัดการเนื้อหาและระบบ',
            style: AppTextStyles.body.copyWith(color: AppColors.modernGrey),
          ),
          const SizedBox(height: 24),
          _buildSectionCard(
            title: 'จัดการรูปภาพระบบ',
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.image_outlined,
                      color: AppColors.primaryTeal),
                  title: const Text('จัดการรูปภาพหน้าแรก'),
                  subtitle: const Text('อัปโหลดและจัดการรูปภาพที่แสดงในแอป'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _showImageManagementDialog,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.palette_outlined,
                      color: AppColors.primaryTeal),
                  title: const Text('ปรับแต่ง UI และสี'),
                  subtitle: const Text('ตั้งค่าธีม สี และการแสดงผล'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _showUICustomizationDialog,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.ads_click_outlined,
                      color: AppColors.primaryTeal),
                  title: const Text('จัดการโฆษณาแบนเนอร์'),
                  subtitle: const Text('เพิ่ม แก้ไข จัดการโฆษณาในแอป'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _showAdvertisementManagementDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionCard(
            title: 'เพิ่มสินค้าใหม่ (Admin)',
            child: Column(
              children: [
                if (_isLoadingAdminAddCategories)
                  const Center(child: CircularProgressIndicator())
                else
                  DropdownButtonFormField<String>(
                    value: _selectedAdminAddCategoryId,
                    decoration: _inputDecoration('เลือกหมวดหมู่'),
                    items: _adminAddCategories.map((category) {
                      return DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAdminAddCategoryId = value;
                        _selectedAdminAddCategoryName = _adminAddCategories
                            .firstWhere((cat) => cat.id == value)
                            .name;
                      });
                    },
                  ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _showAddProductDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('เพิ่มสินค้าใหม่'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style:
                  AppTextStyles.subtitle.copyWith(color: AppColors.primaryTeal),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildManagementSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primaryTeal),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusChip(String? status) {
    Color color;
    String displayText;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        displayText = 'รอชำระ';
        break;
      case 'confirmed':
        color = Colors.blue;
        displayText = 'ยืนยันแล้ว';
        break;
      case 'shipping':
        color = Colors.purple;
        displayText = 'กำลังจัดส่ง';
        break;
      case 'completed':
        color = Colors.green;
        displayText = 'เสร็จสิ้น';
        break;
      case 'cancelled':
        color = Colors.red;
        displayText = 'ยกเลิก';
        break;
      default:
        color = Colors.grey;
        displayText = 'ไม่ระบุ';
    }

    return Chip(
      label: Text(
        displayText,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  InputDecoration _inputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: AppTextStyles.body.copyWith(color: AppColors.modernGrey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: AppColors.lightTeal),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: AppColors.primaryTeal, width: 2.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: AppColors.lightTeal),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'ไม่ระบุ';
    try {
      final date = (timestamp as Timestamp).toDate();
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'ไม่ระบุ';
    }
  }

  // Dialog methods
  void _showImageManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('จัดการรูปภาพระบบ'),
        content: SizedBox(
          width: 400,
          height: 400,
          child: Column(
            children: [
              _selectedBannerImage != null
                  ? Image.file(
                      File(_selectedBannerImage!.path),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    )
                  : const Text('ยังไม่มีรูปภาพแบนเนอร์'),
              ElevatedButton.icon(
                icon: const Icon(Icons.image),
                label: const Text('เลือกรูปภาพแบนเนอร์'),
                onPressed: () async {
                  final picked =
                      await _picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    setState(() => _selectedBannerImage = picked);
                  }
                },
              ),
              const SizedBox(height: 12),
              _selectedLogoImage != null
                  ? Image.file(
                      File(_selectedLogoImage!.path),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    )
                  : const Text('ยังไม่มีโลโก้'),
              ElevatedButton.icon(
                icon: const Icon(Icons.image),
                label: const Text('เลือกรูปโลโก้'),
                onPressed: () async {
                  final picked =
                      await _picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    setState(() => _selectedLogoImage = picked);
                  }
                },
              ),
              const SizedBox(height: 12),
              _selectedBackgroundImage != null
                  ? Image.file(
                      File(_selectedBackgroundImage!.path),
                      width: 120,
                      height: 60,
                      fit: BoxFit.cover,
                    )
                  : const Text('ยังไม่มีรูปพื้นหลัง'),
              ElevatedButton.icon(
                icon: const Icon(Icons.image),
                label: const Text('เลือกรูปพื้นหลัง'),
                onPressed: () async {
                  final picked =
                      await _picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    setState(() => _selectedBackgroundImage = picked);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  void _showUICustomizationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ปรับแต่ง UI และสี'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: Column(
            children: [
              const Text('Floating Action Button Preview:'),
              const SizedBox(height: 16),
              FloatingActionButton(
                onPressed: () {},
                backgroundColor: _selectedFloatingActionColor,
                child: Icon(_selectedFloatingActionIcon),
              ),
              const SizedBox(height: 24),
              Text('Icon: ${_selectedFloatingActionIcon.codePoint}'),
              Text(
                  'Color: ${_selectedFloatingActionColor.value.toRadixString(16)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  void _showAdvertisementManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('จัดการโฆษณาแบนเนอร์'),
        content: SizedBox(
          width: 400,
          height: 350,
          child: Form(
            child: Column(
              children: [
                TextFormField(
                  controller: _bannerTitleController,
                  decoration: _inputDecoration('ชื่อแบนเนอร์'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bannerDescriptionController,
                  decoration: _inputDecoration('รายละเอียดแบนเนอร์'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bannerOrderController,
                  decoration: _inputDecoration('ลำดับแบนเนอร์'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('บันทึกข้อมูลแบนเนอร์'),
                  onPressed: () {
                    saveData(); // ฟังก์ชันบันทึกข้อมูล (ต้องสร้างเพิ่มถ้ายังไม่มี)
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เพิ่มสินค้าใหม่'),
        content: SizedBox(
          width: 400,
          height: 500,
          child: _buildAddProductForm(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    _addProduct().then((_) => Navigator.pop(context));
                  },
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('เพิ่มสินค้า'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddProductForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration('ชื่อสินค้า'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกชื่อสินค้า';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: _inputDecoration('คำอธิบาย'),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกคำอธิบาย';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: _inputDecoration('ราคา'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกราคา';
                }
                if (double.tryParse(value) == null) {
                  return 'กรุณากรอกราคาที่ถูกต้อง';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _materialController,
              decoration: _inputDecoration('วัสดุที่ใช้'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text('คะแนนสิ่งแวดล้อม: $_ecoScore'),
                ),
                Expanded(
                  child: Slider(
                    value: _ecoScore.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    onChanged: (value) {
                      setState(() {
                        _ecoScore = value.toInt();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: Text(_pickedImageFile == null
                  ? 'เลือกรูปภาพ'
                  : 'รูปภาพถูกเลือกแล้ว'),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('อนุมัติทันที'),
              value: _approveImmediately,
              onChanged: (value) {
                setState(() {
                  _approveImmediately = value ?? true;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDetails(Map<String, dynamic> product, String productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product['name'] ?? 'ไม่มีชื่อ'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('คำอธิบาย: ${product['description'] ?? ''}'),
              const SizedBox(height: 8),
              Text('ราคา: ฿${product['price'] ?? 0}'),
              const SizedBox(height: 8),
              Text('คะแนนสิ่งแวดล้อม: ${product['ecoScore'] ?? 0}'),
              const SizedBox(height: 8),
              Text('หมวดหมู่: ${product['categoryName'] ?? ''}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _approveProduct(productId);
            },
            child: const Text('อนุมัติ'),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(Map<String, dynamic> order, String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('รายละเอียดคำสั่งซื้อ #${orderId.substring(0, 8)}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('สถานะ: ${order['status'] ?? ''}'),
              const SizedBox(height: 8),
              Text('ยอดรวม: ฿${order['totalAmount'] ?? 0}'),
              const SizedBox(height: 8),
              Text('ค่าจัดส่ง: ฿${order['shippingFee'] ?? 0}'),
              const SizedBox(height: 8),
              Text('ที่อยู่จัดส่ง: ${order['shippingAddress'] ?? ''}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  // Product approval methods
  Future<void> _approveProduct(String productId) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .update({
        'status': 'approved',
        'approvedAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('อนุมัติสินค้าเรียบร้อย'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectProduct(String productId) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('เหตุผลการปฏิเสธ'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'กรุณาระบุเหตุผล...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('ปฏิเสธ'),
            ),
          ],
        );
      },
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .update({
          'status': 'rejected',
          'rejectionReason': reason,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ปฏิเสธสินค้าเรียบร้อย'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // System management methods
  Future<void> _performDatabaseBackup() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('เริ่มต้นสำรองข้อมูล...')),
    );
  }

  Future<void> _cleanTemporaryData() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ล้างข้อมูลชั่วคราวเรียบร้อย')),
    );
  }

  Future<void> _performSecurityScan() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('เริ่มตรวจสอบความปลอดภัย...')),
    );
  }

  Future<void> _reviewReports() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ไม่มีรายงานที่รอตรวจสอบ')),
    );
  }
}
