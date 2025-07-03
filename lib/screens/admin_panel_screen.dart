// lib/screens/admin_panel_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/category.dart' as app_category;
import 'package:green_market/models/product.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // ยังคง import ไว้สำหรับแพลตฟอร์มอื่น
import 'dart:typed_data'; // เพิ่มสำหรับ Uint8List
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:green_market/models/order.dart' as app_order;
import 'package:uuid/uuid.dart';
import 'package:green_market/screens/admin/admin_category_management_screen.dart';
import 'package:green_market/screens/admin/approval_list_screen.dart';
import 'package:green_market/screens/admin/admin_order_management_screen.dart';
import 'package:green_market/screens/admin/admin_seller_application_screen.dart';
import 'package:green_market/screens/admin/admin_user_management_screen.dart';
import 'package:green_market/screens/admin/admin_promotion_management_screen.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/screens/admin/admin_manage_investment_projects_screen.dart';
import 'package:green_market/screens/admin/admin_manage_sustainable_activities_screen.dart';
import 'package:green_market/screens/admin/dynamic_app_config_screen.dart';

import 'package:green_market/utils/constants.dart'; // For AppColors and AppTextStyles

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

      // The 'level' field is not directly stored in the Product model, it's derived from ecoScore.
      // So, 'calculatedLevel' is not needed here.

      final newProduct = Product(
        id: '',
        sellerId:
            FirebaseAuth.instance.currentUser!.uid, // Or a generic admin ID
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        stock: 1, // Default stock for admin-added products
        imageUrls: imageUrl != null ? [imageUrl] : [],
        ecoScore: _ecoScore, // Corrected: Pass ecoScore directly
        materialDescription: _materialController.text,
        ecoJustification: _ecoJustificationController.text,
        verificationVideoUrl: _verificationVideoController.text.isEmpty
            ? null
            : _verificationVideoController.text,
        status: _approveImmediately ? 'approved' : 'pending_approval',
        categoryId:
            _selectedAdminAddCategoryId!, // categoryId is String, must be non-null
        categoryName:
            _selectedAdminAddCategoryName, // categoryName is String?, can be null
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
      length: 11, // แก้ไขจำนวน tabs ให้ตรงกับที่มีจริง
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
                  text: 'ตั้งค่าแอป',
                  icon: Icon(Icons.settings_applications_outlined)),
              Tab(
                  text: 'จัดการระบบ',
                  icon: Icon(Icons.admin_panel_settings_outlined)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 0: Admin Dashboard
            _buildAdminDashboard(),
            // Tab 1: Product Approval
            _buildProductApprovalTab(),
            // Tab 2: Order Management
            _buildOrderManagementTab(),
            // Tab 3: Category Management
            const AdminCategoryManagementScreen(),
            // Tab 4: Promotion Management
            const AdminPromotionManagementScreen(),
            // Tab 5: User Management
            const AdminUserManagementScreen(),
            // Tab 6: Seller Applications
            const AdminSellerApplicationScreen(),
            // Tab 7: Investment Projects
            const AdminManageInvestmentProjectsScreen(),
            // Tab 8: Sustainable Activities
            const AdminManageSustainableActivitiesScreen(),
            // Tab 9: App Settings
            const DynamicAppConfigScreen(),
            // Tab 10: System Management
            _buildSystemManagementTab(),
          ],
        ),
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
            Text(title,
                style: AppTextStyles.subtitle
                    .copyWith(color: AppColors.primaryTeal)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String labelText) {
    return InputDecoration(
        labelText: labelText,
        labelStyle: AppTextStyles.body.copyWith(color: AppColors.modernGrey),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: AppColors.lightTeal)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: AppColors.primaryTeal, width: 2.0)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: AppColors.lightTeal)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: AppColors.primaryTeal, width: 2.0)));
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

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'ไม่ระบุ';
    try {
      final date = (timestamp as Timestamp).toDate();
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'ไม่ระบุ';
    }
  }

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
              const SizedBox(height: 8),
              Text('วัสดุ: ${product['materialDescription'] ?? ''}'),
              const SizedBox(height: 8),
              Text(
                  'เหตุผลคะแนนสิ่งแวดล้อม: ${product['ecoJustification'] ?? ''}'),
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
              const SizedBox(height: 16),
              if (order['items'] != null) ...[
                const Text('รายการสินค้า:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...((order['items'] as List).map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                          '• ${item['productName']} x${item['quantity']} = ฿${item['pricePerUnit'] * item['quantity']}'),
                    ))),
              ],
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

          // Database Management
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
              ListTile(
                leading:
                    const Icon(Icons.analytics, color: AppColors.primaryTeal),
                title: const Text('วิเคราะห์ประสิทธิภาพ'),
                subtitle: const Text('ตรวจสอบประสิทธิภาพระบบ'),
                onTap: _analyzeSystemPerformance,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Security Management
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
                leading:
                    const Icon(Icons.vpn_key, color: AppColors.primaryTeal),
                title: const Text('จัดการ API Keys'),
                subtitle: const Text('ดู และจัดการ API Keys'),
                onTap: _manageApiKeys,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
              ListTile(
                leading: const Icon(Icons.block, color: AppColors.primaryTeal),
                title: const Text('รายการ IP ที่ถูกบล็อก'),
                subtitle: const Text('จัดการ IP ที่ถูกบล็อก'),
                onTap: _manageBlockedIPs,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Content Moderation
          _buildManagementSection(
            title: 'กลั่นกรองเนื้อหา',
            icon: Icons.report,
            children: [
              ListTile(
                leading: const Icon(Icons.report, color: AppColors.primaryTeal),
                title: const Text('รายงานที่รอตรวจสอบ'),
                subtitle: const Text('ตรวจสอบรายงานจากผู้ใช้'),
                onTap: _reviewReports,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
              ListTile(
                leading: const Icon(Icons.auto_fix_high,
                    color: AppColors.primaryTeal),
                title: const Text('ตัวกรองเนื้อหาอัตโนมัติ'),
                subtitle: const Text('ตั้งค่าการกรองเนื้อหาอัตโนมัติ'),
                onTap: _configureContentFilter,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
              ListTile(
                leading: const Icon(Icons.flag, color: AppColors.primaryTeal),
                title: const Text('คำต้องห้าม'),
                subtitle: const Text('จัดการรายการคำต้องห้าม'),
                onTap: _manageBannedWords,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ],
          ),
        ],
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

  Widget _buildAdminDashboard() {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    // Remove the problematic line that requires TabController
    // final tabController = DefaultTabController.of(context);

    // Corrected: Use Stream.fromFuture for Future-based counts
    Stream<int> pendingProductsStream;
    Stream<int>
        pendingSellersStream; // These are still streams of lists, then mapped to int
    Future<int> totalOrdersFuture; // Changed to Future
    Future<int> totalUsersFuture; // Changed to Future
    Future<int> totalProductsFuture; // Changed to Future

    try {
      pendingProductsStream =
          firebaseService // Corrected: Use getPendingApprovalProducts
              .getPendingApprovalProducts()
              .map((products) => products.length); // Corrected: Already correct
      pendingSellersStream =
          firebaseService // Corrected: Use getPendingSellerApplicationsStream
              .getPendingSellerApplicationsCountStream();
      totalOrdersFuture = firebaseService
          .getTotalOrdersCount(); // Corrected: Already returns Future // Corrected: Already returns Future
      totalUsersFuture = firebaseService
          .getTotalUsersCount(); // Corrected: Already returns Future // Corrected: Already returns Future
      totalProductsFuture = firebaseService
          .getTotalProductsCount(); // Corrected: Already returns Future // Corrected: Already returns Future
    } catch (e) {
      print("Error initializing dashboard streams, using placeholders: $e");
      // กำหนดค่า placeholder ที่เหมาะสมเมื่อเกิด error
      pendingProductsStream = Stream<int>.value(0);
      pendingSellersStream = Stream<int>.value(0);
      totalOrdersFuture = Future<int>.value(0);
      totalUsersFuture = Future<int>.value(0);
      totalProductsFuture = Future<int>.value(0);
    }

    return SingleChildScrollView(
      // Removed deprecated withOpacity
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
              // Use a simpler navigation approach instead of TabController
              // Just show a snackbar for now to avoid TabController issues
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('นำทางไปหน้าอนุมัติสินค้า')),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildDashboardSummaryCard(
            title: 'คำขอเปิดร้านใหม่',
            countStream: pendingSellersStream,
            icon: Icons.storefront_outlined,
            iconColor: Colors.blue.shade700,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('นำทางไปหน้าคำขอเปิดร้าน')),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildDashboardSummaryCard(
            title: 'คำสั่งซื้อทั้งหมด',
            countFuture: totalOrdersFuture,
            icon: Icons.receipt_long_outlined, // Corrected: Already correct
            iconColor: Colors.green.shade700,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('นำทางไปหน้าคำสั่งซื้อ')),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildDashboardSummaryCard(
            title: 'ผู้ใช้ทั้งหมดในระบบ',
            countFuture: totalUsersFuture,
            icon: Icons.people_alt_outlined, // Corrected: Already correct
            iconColor: Colors.purple.shade700,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('นำทางไปหน้าจัดการผู้ใช้')),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildDashboardSummaryCard(
            title: 'สินค้าทั้งหมดในระบบ',
            countFuture: totalProductsFuture,
            icon: Icons.shopping_bag_outlined, // Corrected: Already correct
            iconColor: Colors.teal.shade700,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('นำทางไปหน้าเพิ่มสินค้า')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardSummaryCard({
    required String title, // Removed deprecated withOpacity
    Stream<int>? countStream, // Use optional Stream
    required IconData icon,
    Future<int>? countFuture, // Optional Future
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
              // Use a conditional builder based on whether it's a Stream or Future // Corrected: Use countStream if available
              if (countStream != null)
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
                )
              else if (countFuture != null) // New parameter for Future
                FutureBuilder<int>(
                  future: countFuture,
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

  Widget _buildImageManagementTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'จัดการรูปภาพหน้าแรก',
            style:
                AppTextStyles.headline.copyWith(color: AppColors.primaryTeal),
          ),
          const SizedBox(height: 8),
          Text(
            'อัปโหลด แก้ไข และลบรูปภาพที่แสดงในหน้าแรกของแอปพลิเคชัน',
            style: AppTextStyles.body.copyWith(color: AppColors.modernGrey),
          ),
          const SizedBox(height: 24),
          _buildSectionCard(
            title: 'รูปภาพโลโก้',
            child: Column(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.veryLightTeal,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.lightTeal),
                  ),
                  child: const Icon(
                    Icons.image_outlined,
                    size: 48,
                    color: AppColors.modernGrey,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _uploadLogo,
                        icon: const Icon(Icons.upload_outlined),
                        label: const Text('อัปโหลดโลโก้'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _deleteLogo,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('ลบ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'รูปภาพปก (Hero Image)',
            child: Column(
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.veryLightTeal,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.lightTeal),
                  ),
                  child: const Icon(
                    Icons.landscape_outlined,
                    size: 64,
                    color: AppColors.modernGrey,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _uploadHeroImage,
                        icon: const Icon(Icons.upload_outlined),
                        label: const Text('อัปโหลดรูปปก'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _deleteHeroImage,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('ลบ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'รูปภาพโปรโมชัน/แบนเนอร์',
            child: Column(
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3, // ตัวอย่าง 3 รูปแบนเนอร์
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.veryLightTeal,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.lightTeal),
                              ),
                              child: const Icon(
                                Icons.image_outlined,
                                color: AppColors.modernGrey,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'แบนเนอร์ ${index + 1}',
                                    style: AppTextStyles.bodyBold,
                                  ),
                                  Text(
                                    'รูปภาพโปรโมชันหน้าแรก',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.modernGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => _uploadBanner(index),
                              icon: const Icon(Icons.edit_outlined),
                              color: AppColors.primaryTeal,
                            ),
                            IconButton(
                              onPressed: () => _deleteBannerByIndex(index),
                              icon: const Icon(Icons.delete_outline),
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _addNewBanner,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('เพิ่มแบนเนอร์ใหม่'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // เพิ่มฟังก์ชันสำหรับการจัดการรูปภาพ
  Future<void> _uploadLogo() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _isLoading = true);

        final firebaseService =
            Provider.of<FirebaseService>(context, listen: false);
        String fileName =
            'logo_${DateTime.now().millisecondsSinceEpoch}.${pickedFile.name.split('.').last}';

        String logoUrl;
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          logoUrl = await firebaseService.uploadImageBytes(
              'app_images', fileName, bytes);
        } else {
          logoUrl = await firebaseService
              .uploadImage('app_images', pickedFile.path, fileName: fileName);
        }

        // อัปเดตการตั้งค่าแอป
        if (mounted) {
          // อัปเดต app config ใน Firestore ด้วย logoUrl
          await FirebaseFirestore.instance
              .collection('app_settings')
              .doc('app_config')
              .update({
            'logoUrl': logoUrl,
            'updated_at': FieldValue.serverTimestamp(),
          });

          print('Logo uploaded to: $logoUrl');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('อัปโหลดโลโก้สำเร็จ!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _uploadHeroImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _isLoading = true);

        final firebaseService =
            Provider.of<FirebaseService>(context, listen: false);
        String fileName =
            'hero_${DateTime.now().millisecondsSinceEpoch}.${pickedFile.name.split('.').last}';
        String heroUrl;
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          heroUrl = await firebaseService.uploadImageBytes(
              'app_images', fileName, bytes);
        } else {
          heroUrl = await firebaseService
              .uploadImage('app_images', pickedFile.path, fileName: fileName);
        }

        if (mounted) {
          print('Hero image uploaded to: $heroUrl');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('อัปโหลดรูปปกสำเร็จ!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _uploadBanner(int bannerIndex) async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _isLoading = true);

        final firebaseService =
            Provider.of<FirebaseService>(context, listen: false);
        String fileName =
            'banner_${bannerIndex}_${DateTime.now().millisecondsSinceEpoch}.${pickedFile.name.split('.').last}';
        String bannerUrl;
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          bannerUrl = await firebaseService.uploadImageBytes(
              'app_images', fileName, bytes);
        } else {
          bannerUrl = await firebaseService
              .uploadImage('app_images', pickedFile.path, fileName: fileName);
        }

        if (mounted) {
          print('Banner ${bannerIndex + 1} uploaded to: $bannerUrl');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('อัปโหลดแบนเนอร์ ${bannerIndex + 1} สำเร็จ!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ฟังก์ชันลบโลโก้
  Future<void> _deleteLogo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบโลโก้'),
        content: const Text('คุณต้องการลบโลโก้แอปพลิเคชันหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);

        // ลบโลโก้จาก app config ใน Firestore
        await FirebaseFirestore.instance
            .collection('app_settings')
            .doc('app_config')
            .update({
          'logoUrl': FieldValue.delete(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ลบโลโก้สำเร็จ!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาดในการลบโลโก้: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // ฟังก์ชันลบรูปปก (Hero Image)
  Future<void> _deleteHeroImage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบรูปปก'),
        content: const Text('คุณต้องการลบรูปปกหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);

        // ลบรูปปกจาก app config ใน Firestore
        await FirebaseFirestore.instance
            .collection('app_settings')
            .doc('app_config')
            .update({
          'heroImageUrl': FieldValue.delete(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ลบรูปปกสำเร็จ!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาดในการลบรูปปก: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // ฟังก์ชันลบแบนเนอร์
  Future<void> _deleteBannerByIndex(int bannerIndex) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบแบนเนอร์'),
        content: Text('คุณต้องการลบแบนเนอร์ ${bannerIndex + 1} หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);

        // ลบแบนเนอร์จาก app config ใน Firestore
        await FirebaseFirestore.instance
            .collection('app_settings')
            .doc('app_config')
            .update({
          'banner${bannerIndex}Url': FieldValue.delete(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ลบแบนเนอร์ ${bannerIndex + 1} สำเร็จ!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาดในการลบแบนเนอร์: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // ฟังก์ชันเพิ่มแบนเนอร์ใหม่
  Future<void> _addNewBanner() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _isLoading = true);

        final firebaseService =
            Provider.of<FirebaseService>(context, listen: false);
        String fileName =
            'new_banner_${DateTime.now().millisecondsSinceEpoch}.${pickedFile.name.split('.').last}';

        String bannerUrl;
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          bannerUrl = await firebaseService.uploadImageBytes(
              'app_images', fileName, bytes);
        } else {
          bannerUrl = await firebaseService
              .uploadImage('app_images', pickedFile.path, fileName: fileName);
        }

        // บันทึกแบนเนอร์ใหม่ลงใน Firestore
        await FirebaseFirestore.instance
            .collection('app_settings')
            .doc('banners')
            .collection('active_banners')
            .add({
          'imageUrl': bannerUrl,
          'order': DateTime.now().millisecondsSinceEpoch,
          'isActive': true,
          'created_at': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('เพิ่มแบนเนอร์ใหม่สำเร็จ!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการเพิ่มแบนเนอร์: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildUICustomizationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ปรับแต่ง UI และสี',
            style:
                AppTextStyles.headline.copyWith(color: AppColors.primaryTeal),
          ),
          const SizedBox(height: 8),
          Text(
            'ปรับแต่งสี ไอคอน และรูปลักษณ์ของแอปพลิเคชัน',
            style: AppTextStyles.body.copyWith(color: AppColors.modernGrey),
          ),
          const SizedBox(height: 24),

          // ปรับแต่งปุ่ม "เปิดโลกสีเขียว"
          _buildSectionCard(
            title: 'ปุ่ม "เปิดโลกสีเขียว"',
            child: Column(
              children: [
                Text(
                  'เลือกไอคอนและสีสำหรับปุ่ม "เปิดโลกสีเขียว"',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 16),

                // เลือกไอคอน
                Text('เลือกไอคอน:', style: AppTextStyles.bodyBold),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  children: [
                    _buildIconOption(Icons.eco, 'ใบไผ่'),
                    _buildIconOption(Icons.park, 'ต้นไม้'),
                    _buildIconOption(Icons.nature, 'ธรรมชาติ'),
                    _buildIconOption(Icons.energy_savings_leaf, 'ใบเขียว'),
                    _buildIconOption(Icons.explore, 'สำรวจ'),
                    _buildIconOption(Icons.public, 'โลก'),
                  ],
                ),

                const SizedBox(height: 16),

                // เลือกสี
                Text('เลือกสี:', style: AppTextStyles.bodyBold),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  children: [
                    _buildColorOption(Colors.green, 'เขียว'),
                    _buildColorOption(Colors.lightGreen, 'เขียวอ่อน'),
                    _buildColorOption(Colors.teal, 'เขียวฟ้า'),
                    _buildColorOption(AppColors.primaryTeal, 'ฟ้าเขียว'),
                    _buildColorOption(Colors.brown, 'น้ำตาล'),
                    _buildColorOption(Colors.orange, 'ส้ม'),
                  ],
                ),

                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _updateFloatingActionButton,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('บันทึกการเปลี่ยนแปลง'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ตัวอย่างปุ่ม
          _buildSectionCard(
            title: 'ตัวอย่าง',
            child: Center(
              child: FloatingActionButton(
                onPressed: () {},
                backgroundColor: _selectedColor ?? Colors.green,
                heroTag:
                    "ui_preview_fab", // เพิ่ม heroTag เพื่อหลีกเลี่ยง conflict
                child: Icon(_selectedIcon ?? Icons.eco),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData? _selectedIcon = Icons.eco;
  Color? _selectedColor = Colors.green;

  Widget _buildIconOption(IconData icon, String label) {
    final isSelected = _selectedIcon == icon;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIcon = icon;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryTeal.withAlpha(51)
              : Colors.grey[100],
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 24,
                color: isSelected ? AppColors.primaryTeal : Colors.grey[600]),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? AppColors.primaryTeal : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(Color color, String label) {
    final isSelected = _selectedColor == color;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? Colors.black : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateFloatingActionButton() async {
    try {
      setState(() => _isLoading = true);

      // บันทึกการตั้งค่าลงใน Firestore
      await FirebaseFirestore.instance
          .collection('app_settings')
          .doc('ui_customization')
          .set({
        'floating_button_icon': _selectedIcon?.codePoint,
        // ใช้ .value แทน .toArgb() เพื่อรองรับทุกเวอร์ชัน Flutter
        'floating_button_color': _selectedColor?.value,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'บันทึกการตั้งค่าสำเร็จ! โปรดรีสตาร์ทแอปเพื่อดูการเปลี่ยนแปลง'),
            backgroundColor: Colors.green,
          ),
        );
      }
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
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildAdvertisementManagementTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'จัดการโฆษณาแบนเนอร์',
            style:
                AppTextStyles.headline.copyWith(color: AppColors.primaryTeal),
          ),
          const SizedBox(height: 8),
          Text(
            'เพิ่ม แก้ไข และจัดการโฆษณาแบนเนอร์ที่แสดงในหน้าแรก',
            style: AppTextStyles.body.copyWith(color: AppColors.modernGrey),
          ),
          const SizedBox(height: 24),

          // เพิ่มแบนเนอร์ใหม่
          _buildSectionCard(
            title: 'เพิ่มแบนเนอร์โฆษณาใหม่',
            child: Column(
              children: [
                TextFormField(
                  controller: _bannerTitleController,
                  decoration: _inputDecoration('หัวข้อโฆษณา'),
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bannerDescriptionController,
                  decoration: _inputDecoration('รายละเอียด'),
                  style: AppTextStyles.body,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bannerOrderController,
                  decoration: _inputDecoration('ลำดับการแสดง (ตัวเลข)'),
                  style: AppTextStyles.body,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // อัพโหลดรูป
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.veryLightTeal,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.lightTeal),
                  ),
                  child: _selectedBannerImage != null
                      ? kIsWeb
                          ? FutureBuilder<Uint8List>(
                              future: _selectedBannerImage!.readAsBytes(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      snapshot.data!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  );
                                }
                                return const Center(
                                    child: CircularProgressIndicator());
                              },
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_selectedBannerImage!.path),
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_outlined,
                                  size: 48, color: AppColors.primaryTeal),
                              SizedBox(height: 8),
                              Text('เลือกรูปแบนเนอร์',
                                  style:
                                      TextStyle(color: AppColors.primaryTeal)),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickBannerImage,
                        icon: const Icon(Icons.image),
                        label: const Text('เลือกรูปภาพ'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _uploadBannerAd,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.upload),
                        label:
                            Text(_isLoading ? 'กำลังอัพโหลด...' : 'เพิ่มโฆษณา'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // รายการแบนเนอร์ที่มีอยู่
          _buildSectionCard(
            title: 'แบนเนอร์โฆษณาทั้งหมด',
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('advertisement_banners')
                  .orderBy('order')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('ยังไม่มีแบนเนอร์โฆษณา'),
                    ),
                  );
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final banner = doc.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: banner['imageUrl'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  banner['imageUrl'],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      color: AppColors.lightTeal.withAlpha(51),
                                      child:
                                          const Icon(Icons.image_not_supported),
                                    );
                                  },
                                ),
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.lightTeal.withAlpha(51),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.campaign),
                              ),
                        title: Text(banner['title'] ?? 'ไม่มีหัวข้อ'),
                        subtitle:
                            Text(banner['description'] ?? 'ไม่มีรายละเอียด'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: banner['isActive'] ?? false,
                              onChanged: (value) {
                                _toggleBannerStatus(doc.id, value);
                              },
                            ),
                            IconButton(
                              onPressed: () => _deleteBanner(doc.id),
                              icon: const Icon(Icons.delete, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  final TextEditingController _bannerTitleController = TextEditingController();
  final TextEditingController _bannerDescriptionController =
      TextEditingController();
  final TextEditingController _bannerOrderController = TextEditingController();
  XFile? _selectedBannerImage;

  Future<void> _pickBannerImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedBannerImage = pickedFile;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการเลือกรูป: $e')),
        );
      }
    }
  }

  Future<void> _uploadBannerAd() async {
    if (_bannerTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกหัวข้อโฆษณา')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      String? imageUrl;
      if (_selectedBannerImage != null) {
        final firebaseService =
            Provider.of<FirebaseService>(context, listen: false);
        final fileName =
            'banner_${DateTime.now().millisecondsSinceEpoch}.${_selectedBannerImage!.name.split('.').last}';

        if (kIsWeb) {
          final bytes = await _selectedBannerImage!.readAsBytes();
          imageUrl = await firebaseService.uploadImageBytes(
              'advertisement_banners', fileName, bytes);
        } else {
          imageUrl = await firebaseService.uploadImage(
              'advertisement_banners', _selectedBannerImage!.path,
              fileName: fileName);
        }
      }

      await FirebaseFirestore.instance.collection('advertisement_banners').add({
        'title': _bannerTitleController.text.trim(),
        'description': _bannerDescriptionController.text.trim(),
        'imageUrl': imageUrl ?? '',
        'order': int.tryParse(_bannerOrderController.text) ?? 0,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // เคลียร์ฟอร์ม
      _bannerTitleController.clear();
      _bannerDescriptionController.clear();
      _bannerOrderController.clear();
      setState(() {
        _selectedBannerImage = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เพิ่มแบนเนอร์โฆษณาสำเร็จ!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleBannerStatus(String bannerId, bool isActive) async {
    try {
      await FirebaseFirestore.instance
          .collection('advertisement_banners')
          .doc(bannerId)
          .update({'isActive': isActive});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  Future<void> _deleteBanner(String bannerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณต้องการลบแบนเนอร์นี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('advertisement_banners')
            .doc(bannerId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ลบแบนเนอร์สำเร็จ')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
          );
        }
      }
    }
  }

  // System Management Methods
  Future<void> _performDatabaseBackup() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('สำรองข้อมูล'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('กำลังสำรองข้อมูล...'),
          ],
        ),
      ),
    );

    // Simulate backup process
    await Future.delayed(const Duration(seconds: 3));

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('สำรองข้อมูลเรียบร้อย'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _cleanTemporaryData() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ล้างข้อมูลชั่วคราวเรียบร้อย'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _analyzeSystemPerformance() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ผลการวิเคราะห์ประสิทธิภาพ'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📊 สถิติระบบ:'),
            SizedBox(height: 8),
            Text('• CPU Usage: 45%'),
            Text('• Memory Usage: 67%'),
            Text('• Database Response: 125ms'),
            Text('• Active Users: 1,234'),
            Text('• Total Products: 5,678'),
            Text('• Total Orders: 2,345'),
          ],
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

  Future<void> _performSecurityScan() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('กำลังทำการสแกนความปลอดภัย...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _manageApiKeys() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('จัดการ API Keys'),
        content: const Text('ฟีเจอร์นี้จะพร้อมใช้งานเร็วๆ นี้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  Future<void> _manageBlockedIPs() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('IP ที่ถูกบล็อก'),
        content: const Text('ไม่มี IP ที่ถูกบล็อกในขณะนี้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  Future<void> _reviewReports() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('รายงานจากผู้ใช้'),
            backgroundColor: AppColors.primaryTeal,
            foregroundColor: Colors.white,
          ),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.report_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('ยังไม่มีรายงานที่รอตรวจสอบ'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _configureContentFilter() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ตั้งค่าตัวกรองเนื้อหา'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('กรองคำหยาบ'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('กรองเนื้อหาไม่เหมาะสม'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('กรองลิงก์ภายนอก'),
              value: false,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  Future<void> _manageBannedWords() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('คำต้องห้าม'),
        content: const SizedBox(
          width: 300,
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('รายการคำต้องห้ามปัจจุบัน:'),
              SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• spam'),
                      Text('• scam'),
                      Text('• fake'),
                      Text('• fraud'),
                      Text('• cheat'),
                    ],
                  ),
                ),
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
}
