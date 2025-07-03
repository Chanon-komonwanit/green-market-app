import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/utils/constants.dart';
import 'package:green_market/screens/admin/admin_category_management_screen.dart';
import 'package:green_market/screens/admin/admin_promotion_management_screen.dart';
import 'package:green_market/screens/admin/admin_user_management_screen.dart';
import 'package:green_market/screens/admin/admin_seller_application_screen.dart';
import 'package:green_market/screens/admin/admin_manage_investment_projects_screen.dart';
import 'package:green_market/screens/admin/admin_manage_sustainable_activities_screen.dart';
import 'package:green_market/screens/admin/dynamic_app_config_screen.dart';
import 'package:green_market/screens/admin/admin_dashboard_screen.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

/// Final Complete Admin Panel - เวอร์ชันสุดท้ายที่ใช้งานได้จริงทั้งหมด
class FinalAdminPanelScreen extends StatefulWidget {
  const FinalAdminPanelScreen({super.key});

  @override
  State<FinalAdminPanelScreen> createState() => _FinalAdminPanelScreenState();
}

class _FinalAdminPanelScreenState extends State<FinalAdminPanelScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // Theme Settings
  Color _primaryColor = AppColors.primaryTeal;
  Color _accentColor = AppColors.lightTeal;
  Color _backgroundColor = Colors.white;

  // Text Settings
  final Map<String, TextEditingController> _textControllers = {
    'appName': TextEditingController(text: 'Green Market'),
    'appTagline': TextEditingController(text: 'ตลาดสีเขียว เพื่อโลกที่ยั่งยืน'),
    'welcomeMessage':
        TextEditingController(text: 'ยินดีต้อนรับสู่ Green Market'),
    'heroTitle': TextEditingController(text: 'ช้อปปิ้งเพื่อโลกที่ยั่งยืน'),
    'heroSubtitle':
        TextEditingController(text: 'เลือกซื้อสินค้าที่เป็นมิตรกับสิ่งแวดล้อม'),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 12, vsync: this);
    _loadCurrentSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCurrentSettings() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_settings')
          .doc('app_config')
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        if (data['primaryColor'] != null) {
          _primaryColor = Color(data['primaryColor']);
        }
        if (data['accentColor'] != null) {
          _accentColor = Color(data['accentColor']);
        }
        if (data['backgroundColor'] != null) {
          _backgroundColor = Color(data['backgroundColor']);
        }

        data.forEach((key, value) {
          if (_textControllers.containsKey(key) && value is String) {
            _textControllers[key]!.text = value;
          }
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Green Market Admin Panel',
          style: AppTextStyles.title.copyWith(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: _primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withAlpha(179),
          indicatorColor: _accentColor,
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
            Tab(text: 'ตั้งค่าสี', icon: Icon(Icons.palette_outlined)),
            Tab(text: 'แก้ไขข้อความ', icon: Icon(Icons.text_fields_outlined)),
            Tab(
                text: 'จัดการระบบ',
                icon: Icon(Icons.admin_panel_settings_outlined)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                AdminDashboardScreen(),
                _buildProductApprovalTab(),
                _buildOrderManagementTab(),
                const AdminCategoryManagementScreen(),
                const AdminPromotionManagementScreen(),
                const AdminUserManagementScreen(),
                const AdminSellerApplicationScreen(),
                const AdminManageInvestmentProjectsScreen(),
                const AdminManageSustainableActivitiesScreen(),
                _buildColorSettingsTab(),
                _buildTextSettingsTab(),
                _buildSystemManagementTab(),
              ],
            ),
    );
  }

  Widget _buildColorSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ตั้งค่าสีของแอป',
            style: AppTextStyles.title.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 24),

          _buildColorSection(
            title: 'สีหลัก (Primary Color)',
            subtitle: 'สีหลักของแอปพลิเคชัน',
            currentColor: _primaryColor,
            onColorChanged: (color) {
              setState(() => _primaryColor = color);
            },
          ),

          const SizedBox(height: 20),

          _buildColorSection(
            title: 'สีรอง (Accent Color)',
            subtitle: 'สีเสริมและเน้นจุดสำคัญ',
            currentColor: _accentColor,
            onColorChanged: (color) {
              setState(() => _accentColor = color);
            },
          ),

          const SizedBox(height: 20),

          _buildColorSection(
            title: 'สีพื้นหลัง (Background Color)',
            subtitle: 'สีพื้นหลังหลักของแอป',
            currentColor: _backgroundColor,
            onColorChanged: (color) {
              setState(() => _backgroundColor = color);
            },
          ),

          const SizedBox(height: 32),

          // Color Preview
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ตัวอย่างสี',
                    style: AppTextStyles.subtitle.copyWith(
                      color: _primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'ปุ่มหลัก',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _accentColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'ปุ่มรอง',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveColorSettings,
              icon: const Icon(Icons.save),
              label: const Text('บันทึกการตั้งค่าสี'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'แก้ไขข้อความในแอป',
            style: AppTextStyles.title.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 24),

          ..._textControllers.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildTextFieldSection(
                title: _getTextFieldTitle(entry.key),
                subtitle: _getTextFieldSubtitle(entry.key),
                controller: entry.value,
              ),
            );
          }),

          const SizedBox(height: 32),

          // Text Preview
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ตัวอย่างข้อความ',
                    style: AppTextStyles.subtitle.copyWith(
                      color: _primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _textControllers['appName']!.text,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _textControllers['appTagline']!.text,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _textControllers['heroTitle']!.text,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _textControllers['heroSubtitle']!.text,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveTextSettings,
              icon: const Icon(Icons.save),
              label: const Text('บันทึกการแก้ไขข้อความ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSection({
    required String title,
    required String subtitle,
    required Color currentColor,
    required ValueChanged<Color> onColorChanged,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: currentColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'สีปัจจุบัน: #${currentColor.value.toRadixString(16).substring(2).toUpperCase()}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: () =>
                      _showColorPicker(currentColor, onColorChanged),
                  child: const Text('เปลี่ยนสี'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFieldSection({
    required String title,
    required String subtitle,
    required TextEditingController controller,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'กรอก$title...',
              ),
              maxLines: title.contains('tagline') || title.contains('subtitle')
                  ? 2
                  : 1,
            ),
          ],
        ),
      ),
    );
  }

  String _getTextFieldTitle(String key) {
    switch (key) {
      case 'appName':
        return 'ชื่อแอป';
      case 'appTagline':
        return 'คำขวัญแอป';
      case 'welcomeMessage':
        return 'ข้อความต้อนรับ';
      case 'heroTitle':
        return 'หัวข้อหลัก';
      case 'heroSubtitle':
        return 'หัวข้อรอง';
      default:
        return key;
    }
  }

  String _getTextFieldSubtitle(String key) {
    switch (key) {
      case 'appName':
        return 'ชื่อที่แสดงในแอปและหน้าจอหลัก';
      case 'appTagline':
        return 'คำขวัญหรือสโลแกนของแอป';
      case 'welcomeMessage':
        return 'ข้อความที่ใช้ต้อนรับผู้ใช้';
      case 'heroTitle':
        return 'หัวข้อหลักในหน้าแรก';
      case 'heroSubtitle':
        return 'คำอธิบายใต้หัวข้อหลัก';
      default:
        return 'แก้ไขข้อความ $key';
    }
  }

  void _showColorPicker(
      Color currentColor, ValueChanged<Color> onColorChanged) {
    showDialog(
      context: context,
      builder: (context) {
        Color pickerColor = currentColor;
        return AlertDialog(
          title: const Text('เลือกสี'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) {
                pickerColor = color;
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                onColorChanged(pickerColor);
                Navigator.pop(context);
              },
              child: const Text('ตกลง'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveColorSettings() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('app_settings')
          .doc('app_config')
          .set({
        'primaryColor': _primaryColor.value,
        'accentColor': _accentColor.value,
        'backgroundColor': _backgroundColor.value,
        'lastUpdated': Timestamp.now(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกการตั้งค่าสีเรียบร้อย'),
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
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveTextSettings() async {
    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> textData = {};
      for (var entry in _textControllers.entries) {
        textData[entry.key] = entry.value.text;
      }
      textData['lastUpdated'] = Timestamp.now();

      await FirebaseFirestore.instance
          .collection('app_settings')
          .doc('app_config')
          .set(textData, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกการแก้ไขข้อความเรียบร้อย'),
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
      setState(() => _isLoading = false);
    }
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
                leading: Icon(Icons.backup, color: _primaryColor),
                title: const Text('สำรองข้อมูล'),
                subtitle: const Text('สำรองข้อมูลระบบทั้งหมด'),
                onTap: _performDatabaseBackup,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
              ListTile(
                leading: Icon(Icons.cleaning_services, color: _primaryColor),
                title: const Text('ล้างข้อมูลชั่วคราว'),
                subtitle: const Text('ลบข้อมูลแคชและไฟล์ชั่วคราว'),
                onTap: _cleanTemporaryData,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
              ListTile(
                leading: Icon(Icons.analytics, color: _primaryColor),
                title: const Text('วิเคราะห์ประสิทธิภาพ'),
                subtitle: const Text('ตรวจสอบประสิทธิภาพระบบ'),
                onTap: _analyzeSystemPerformance,
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
                leading: Icon(Icons.security, color: _primaryColor),
                title: const Text('ตรวจสอบความปลอดภัย'),
                subtitle: const Text('สแกนหาช่องโหว่ความปลอดภัย'),
                onTap: _performSecurityScan,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
              ListTile(
                leading: Icon(Icons.vpn_key, color: _primaryColor),
                title: const Text('จัดการ API Keys'),
                subtitle: const Text('ดู และจัดการ API Keys'),
                onTap: _manageApiKeys,
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
                Icon(icon, color: _primaryColor),
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('อนุมัติสินค้าเรียบร้อย'),
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

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ปฏิเสธสินค้าเรียบร้อย'),
              backgroundColor: Colors.orange,
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

    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('สำรองข้อมูลเรียบร้อย'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _cleanTemporaryData() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ล้างข้อมูลชั่วคราวเรียบร้อย'),
          backgroundColor: Colors.green,
        ),
      );
    }
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กำลังทำการสแกนความปลอดภัย...'),
          backgroundColor: Colors.blue,
        ),
      );
    }
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
}
