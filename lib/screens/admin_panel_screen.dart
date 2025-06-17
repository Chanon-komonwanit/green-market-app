// lib/screens/admin_panel_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/category.dart'
    as app_category; // Added for category selection
import 'package:green_market/models/product.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // ยังคง import ไว้สำหรับแพลตฟอร์มอื่น
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:green_market/models/order.dart' as app_order;
import 'package:uuid/uuid.dart'; // Import uuid package
import 'package:green_market/screens/category_management_screen.dart';
import 'package:green_market/screens/admin/approval_list_screen.dart';
import 'package:green_market/screens/admin/order_detail_screen.dart';
import 'package:green_market/screens/admin/seller_application_list_screen.dart'; // Import new screen
import 'package:green_market/screens/admin/user_management_screen.dart'; // Import UserManagementScreen
import 'package:green_market/screens/admin/promotion_management_screen.dart'; // Import PromotionManagementScreen
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for Timestamp

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _materialController = TextEditingController();
  final TextEditingController _ecoJustificationController =
      TextEditingController();
  final TextEditingController _verificationVideoController =
      TextEditingController();
  int _ecoScore = 50; // Default Eco Score
  XFile? _pickedImageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false; // Added for loading state
  bool _approveImmediately = true; // For admin to approve product directly
  String?
      _selectedAdminAddCategoryId; // For category selection in admin add product
  String? _selectedAdminAddCategoryName;
  List<app_category.Category> _adminAddCategories = [];
  bool _isLoadingAdminAddCategories = true;

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
          SnackBar(
              content: Text(
                  'เลือกรูปภาพสำเร็จ: ${pickedFile.name} (Preview อาจไม่แสดงบน Web)')),
        );
      }
    }
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedAdminAddCategoryId == null) {
      // Check for category selection
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
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      String? imageUrl;

      if (_pickedImageFile != null) {
        var uuid = const Uuid(); // Corrected: Uuid() instead of Uuid
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

      final int calculatedLevel =
          firebaseService.calculateLevelFromEcoScore(_ecoScore);

      final newProduct = Product(
        id: '',
        sellerId:
            FirebaseAuth.instance.currentUser!.uid, // Or a generic admin ID
        name: _nameController.text,
        description: _descriptionController.text, // Ensure this is not null
        price: double.parse(_priceController.text),
        imageUrls: imageUrl != null
            ? [imageUrl]
            : [], // Corrected: Use calculatedLevel
        level: calculatedLevel,
        ecoScore: _ecoScore,
        materialDescription: _materialController.text,
        ecoJustification: _ecoJustificationController.text,
        verificationVideoUrl: _verificationVideoController.text.isEmpty
            ? null
            : _verificationVideoController.text,
        isApproved: _approveImmediately,
        categoryId: _selectedAdminAddCategoryId, // Add selected category ID
        categoryName:
            _selectedAdminAddCategoryName, // Add selected category name
        // createdAt and approvedAt will be set by Firestore/server or during approval
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('เกิดข้อผิดพลาดในการเพิ่มสินค้า: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    final firebaseService = Provider.of<FirebaseService>(context);

    return DefaultTabController(
      length: 8, // Updated length for the new Promotion Management tab
      child: Scaffold(
        appBar: AppBar(
          title: Text('แผงควบคุมผู้ดูแลระบบ',
              style: AppTextStyles.title
                  .copyWith(color: AppColors.white, fontSize: 20)),
          backgroundColor: AppColors.primaryTeal,
          iconTheme: const IconThemeData(color: AppColors.white),
          bottom: TabBar(
            isScrollable: true, // Make TabBar scrollable if many tabs
            labelColor: AppColors.white,
            unselectedLabelColor: AppColors.white.withOpacity(0.7),
            indicatorColor: AppColors.lightTeal,
            indicatorWeight: 3.0,
            labelStyle: AppTextStyles.bodyBold.copyWith(fontSize: 14),
            unselectedLabelStyle: AppTextStyles.body.copyWith(fontSize: 14),
            tabs: const [
              Tab(text: 'ภาพรวม', icon: Icon(Icons.dashboard_outlined)),
              Tab(text: 'เพิ่มสินค้า', icon: Icon(Icons.add_box)),
              Tab(text: 'อนุมัติสินค้า', icon: Icon(Icons.check_circle)),
              Tab(text: 'คำสั่งซื้อทั้งหมด', icon: Icon(Icons.receipt_long)),
              Tab(text: 'จัดการหมวดหมู่', icon: Icon(Icons.category)),
              Tab(
                  text: 'โปรโมชัน',
                  icon: Icon(Icons.local_offer_outlined)), // New Promotion Tab
              Tab(
                  text: 'จัดการผู้ใช้',
                  icon: Icon(Icons.manage_accounts_outlined)),
              Tab(
                  text: 'คำขอเปิดร้าน',
                  icon: Icon(Icons.store_mall_directory_outlined)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 0: Admin Dashboard
            _buildAdminDashboard(),
            // Tab 1: Add Product
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(children: [
                  _buildSectionCard(
                    title: 'ข้อมูลพื้นฐานสินค้า',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: _inputDecoration('ชื่อสินค้า'),
                          style: AppTextStyles.body,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณากรอกชื่อสินค้า';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        if (_isLoadingAdminAddCategories)
                          const Center(
                              child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(
                                      color: AppColors.primaryTeal)))
                        else if (_adminAddCategories.isEmpty)
                          const Text('ไม่พบหมวดหมู่ (กรุณาเพิ่มหมวดหมู่ก่อน)')
                        else
                          DropdownButtonFormField<String>(
                            value: _selectedAdminAddCategoryId,
                            decoration: _inputDecoration('เลือกหมวดหมู่สินค้า'),
                            hint: const Text('เลือกหมวดหมู่'),
                            items: _adminAddCategories
                                .map((app_category.Category category) {
                              return DropdownMenuItem<String>(
                                value: category.id,
                                child: Text(category.name,
                                    style: AppTextStyles.body),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedAdminAddCategoryId = value;
                                _selectedAdminAddCategoryName =
                                    _adminAddCategories
                                        .firstWhere(
                                          (cat) => cat.id == value,
                                          orElse: () => app_category.Category(
                                              id: value ?? '',
                                              name: 'Unknown Category',
                                              imageUrl: '',
                                              createdAt: Timestamp.now()),
                                        )
                                        .name;
                              });
                            },
                            validator: (value) =>
                                value == null ? 'กรุณาเลือกหมวดหมู่' : null,
                            style: AppTextStyles.body,
                          ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: _inputDecoration('รายละเอียดสินค้า'),
                          style: AppTextStyles.body,
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณากรอกรายละเอียดสินค้า';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('ราคา (บาท)'),
                          style: AppTextStyles.body,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณากรอกราคา';
                            }
                            if (double.tryParse(value) == null) {
                              return 'กรุณากรอกราคาเป็นตัวเลขที่ถูกต้อง';
                            }
                            if (double.parse(value) <= 0) {
                              return 'ราคาต้องมากกว่า 0';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: 'รายละเอียดเชิงนิเวศและความยั่งยืน',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _materialController,
                          decoration: _inputDecoration(
                              'วัสดุที่ใช้ (เช่น พลาสติกรีไซเคิล, ฝ้ายออร์แกนิก)'),
                          style: AppTextStyles.body,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณากรอกวัสดุที่ใช้';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _ecoJustificationController,
                          decoration: _inputDecoration(
                              'เหตุผลที่สินค้านี้เป็นมิตรต่อสิ่งแวดล้อม'),
                          style: AppTextStyles.body,
                          maxLines: 2,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณาให้เหตุผลความเป็นมิตรต่อสิ่งแวดล้อม';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Text('ระดับ Eco Score (%): $_ecoScore',
                            style: AppTextStyles.bodyBold
                                .copyWith(color: AppColors.primaryTeal)),
                        Slider(
                          value: _ecoScore.toDouble(),
                          min: 1.0,
                          max: 100.0,
                          divisions: 99,
                          label: _ecoScore.toString(),
                          onChanged: (value) {
                            setState(() {
                              _ecoScore = value.toInt();
                            });
                          },
                          activeColor:
                              EcoLevelExtension.fromScore(_ecoScore).color,
                          inactiveColor: AppColors.lightModernGrey,
                        ),
                        SwitchListTile(
                          title: Text('อนุมัติสินค้าทันที',
                              style: AppTextStyles.bodyBold
                                  .copyWith(color: AppColors.modernDarkGrey)),
                          value: _approveImmediately,
                          onChanged: (bool value) {
                            setState(() {
                              _approveImmediately = value;
                            });
                          },
                          activeColor: AppColors.primaryTeal,
                          contentPadding: EdgeInsets.zero,
                          subtitle: Text(
                            _approveImmediately
                                ? 'สินค้าจะแสดงในร้านค้าทันที'
                                : 'สินค้าจะถูกส่งไปรอการอนุมัติ',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.modernGrey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: 'สื่อและการยืนยัน',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _verificationVideoController,
                          decoration: _inputDecoration(
                              'ลิงก์วิดีโอ/รูปภาพยืนยัน (ถ้ามี)'),
                          style: AppTextStyles.body,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.image_outlined,
                              color: AppColors.white),
                          label: Text('เลือกรูปภาพสินค้า',
                              style: AppTextStyles.bodyBold
                                  .copyWith(color: AppColors.white)),
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              backgroundColor: AppColors.lightTeal,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0))),
                        ),
                        if (_pickedImageFile != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: kIsWeb
                                ? Row(
                                    children: [
                                      Icon(Icons.image_outlined,
                                          color: AppColors.modernGrey),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                            'เลือกรูปภาพ: ${_pickedImageFile!.name}',
                                            style: AppTextStyles.body,
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                    ],
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.file(
                                        File(_pickedImageFile!.path),
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover),
                                  ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _addProduct,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0)),
                          textStyle: AppTextStyles.subtitle.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold)),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 3.0,
                              ),
                            )
                          : Text('เพิ่มสินค้าใหม่',
                              style: AppTextStyles.subtitle
                                  .copyWith(color: AppColors.white)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
            const ApprovalListScreen(),
            StreamBuilder<List<app_order.Order>?>(
              stream: firebaseService.getAllOrders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryTeal));
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text(
                          'เกิดข้อผิดพลาดในการโหลดคำสั่งซื้อ: ${snapshot.error}',
                          style: AppTextStyles.body));
                }
                if (!snapshot.hasData ||
                    snapshot.data == null ||
                    snapshot.data!.isEmpty) {
                  return Center(
                      child: Text('ยังไม่มีคำสั่งซื้อในระบบ',
                          style: AppTextStyles.body));
                }
                final allOrders = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: allOrders.length,
                  itemBuilder: (context, index) {
                    final order = allOrders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 6.0, horizontal: 8.0),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.veryLightTeal,
                          child: const Icon(Icons.receipt_long_outlined,
                              color: AppColors.primaryTeal),
                        ),
                        title: Text('คำสั่งซื้อ #${order.id.substring(0, 8)}',
                            style: AppTextStyles.subtitle.copyWith(
                                fontSize: 16, color: AppColors.primaryTeal)),
                        subtitle: Text(
                          'ผู้ซื้อ: ${order.fullName}\n'
                          'วันที่: ${order.orderDate.toDate().toLocal().toString().split('.')[0]}\n'
                          'สถานะ: ${order.status.replaceAll('_', ' ').toUpperCase()}\n'
                          'รวม: ฿${order.totalAmount.toStringAsFixed(2)}',
                          style: AppTextStyles.body.copyWith(
                              fontSize: 12, color: AppColors.modernGrey),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios,
                            color: AppColors.lightModernGrey),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    OrderDetailScreen(order: order)),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
            const CategoryManagementScreen(),
            const PromotionManagementScreen(), // New Promotion Screen
            const UserManagementScreen(),
            const SellerApplicationListScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.subtitle.copyWith(
                  color: AppColors.primaryTeal, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            child,
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String labelText) {
    return InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: AppColors.primaryTeal, width: 2.0)),
        labelStyle: AppTextStyles.body.copyWith(color: AppColors.modernGrey));
  }

  Widget _buildAdminDashboard() {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final tabController = DefaultTabController.of(context);

    Stream<int> pendingProductsStream;
    Stream<int> pendingSellersStream;
    Stream<int> totalOrdersStream;
    Stream<int> totalUsersStream;
    Stream<int> totalProductsStream;

    try {
      pendingProductsStream = firebaseService
          .getPendingProducts()
          .map((products) => products.length);
      pendingSellersStream = firebaseService
          .getPendingSellerApplications()
          .map((applications) => applications.length);
      totalOrdersStream = firebaseService.getTotalOrdersCount();
      totalUsersStream = firebaseService.getTotalUsersCount();
      totalProductsStream = firebaseService.getTotalProductsCount();
    } catch (e) {
      print("Error initializing dashboard streams, using placeholders: $e");
      pendingProductsStream = Stream.value(0);
      pendingSellersStream = Stream.value(0);
      totalOrdersStream = Stream.value(0);
      totalUsersStream = Stream.value(0);
      totalProductsStream = Stream.value(0);
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
            onTap: () {
              tabController.animateTo(2);
            },
          ),
          const SizedBox(height: 16),
          _buildDashboardSummaryCard(
            title: 'คำขอเปิดร้านใหม่',
            countStream: pendingSellersStream,
            icon: Icons.storefront_outlined,
            iconColor: Colors.blue.shade700,
            onTap: () {
              tabController
                  .animateTo(7); // Updated index for Seller Applications
            },
          ),
          const SizedBox(height: 16),
          _buildDashboardSummaryCard(
            title: 'คำสั่งซื้อทั้งหมด',
            countStream: totalOrdersStream,
            icon: Icons.receipt_long_outlined,
            iconColor: Colors.green.shade700,
            onTap: () {
              tabController.animateTo(3);
            },
          ),
          const SizedBox(height: 16),
          _buildDashboardSummaryCard(
            title: 'ผู้ใช้ทั้งหมดในระบบ',
            countStream: totalUsersStream,
            icon: Icons.people_alt_outlined,
            iconColor: Colors.purple.shade700,
            onTap: () {
              tabController.animateTo(6); // Updated index for User Management
            },
          ),
          const SizedBox(height: 16),
          _buildDashboardSummaryCard(
            title: 'สินค้าทั้งหมดในระบบ',
            countStream: totalProductsStream,
            icon: Icons.shopping_bag_outlined,
            iconColor: Colors.teal.shade700,
            onTap: () {
              tabController.animateTo(1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardSummaryCard({
    required String title,
    required Stream<int> countStream,
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
              StreamBuilder<int>(
                stream: countStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2));
                  }
                  return Text((snapshot.data ?? 0).toString(),
                      style: AppTextStyles.title.copyWith(
                          fontWeight: FontWeight.bold,
                          color: iconColor ?? AppColors.primaryTeal));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
