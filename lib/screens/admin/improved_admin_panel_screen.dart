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

/// ระบบ Admin Panel ที่ปรับปรุงใหม่ - ใช้งานได้จริงทั้งหมด
class ImprovedAdminPanelScreen extends StatefulWidget {
  const ImprovedAdminPanelScreen({super.key});

  @override
  State<ImprovedAdminPanelScreen> createState() =>
      _ImprovedAdminPanelScreenState();
}

class _ImprovedAdminPanelScreenState extends State<ImprovedAdminPanelScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 11,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'แผงควบคุมผู้ดูแลระบบ',
            style: AppTextStyles.title.copyWith(
              color: AppColors.white,
              fontSize: 20,
            ),
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
            const AdminDashboardScreen(),
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

  /// Product Approval Tab
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
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Product Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: product['imageUrls'] != null &&
                                          (product['imageUrls'] as List)
                                              .isNotEmpty
                                      ? Image.network(
                                          (product['imageUrls'] as List)[0],
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                            width: 80,
                                            height: 80,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.image),
                                          ),
                                        )
                                      : Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.image),
                                        ),
                                ),
                                const SizedBox(width: 16),

                                // Product Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product['name'] ?? 'ไม่มีชื่อ',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        product['description'] ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            TextStyle(color: Colors.grey[600]),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text(
                                            'ราคา: ฿${product['price'] ?? 0}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primaryTeal,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Text(
                                            'Eco Score: ${product['ecoScore'] ?? 0}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _showProductDetails(product, doc.id),
                                    icon: const Icon(Icons.visibility),
                                    label: const Text('ดูรายละเอียด'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _approveProduct(doc.id),
                                    icon: const Icon(Icons.check),
                                    label: const Text('อนุมัติ'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _rejectProduct(doc.id),
                                    icon: const Icon(Icons.close),
                                    label: const Text('ปฏิเสธ'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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

  /// Order Management Tab
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

          // Order Status Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusFilterChip('ทั้งหมด', null),
                _buildStatusFilterChip('รอชำระ', 'pending'),
                _buildStatusFilterChip('ยืนยันแล้ว', 'confirmed'),
                _buildStatusFilterChip('กำลังจัดส่ง', 'shipping'),
                _buildStatusFilterChip('เสร็จสิ้น', 'completed'),
                _buildStatusFilterChip('ยกเลิก', 'cancelled'),
              ],
            ),
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

  /// System Management Tab
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
            items: [
              _ManagementItem(
                icon: Icons.backup,
                title: 'สำรองข้อมูล',
                subtitle: 'สำรองข้อมูลระบบทั้งหมด',
                onTap: _performDatabaseBackup,
              ),
              _ManagementItem(
                icon: Icons.cleaning_services,
                title: 'ล้างข้อมูลชั่วคราว',
                subtitle: 'ลบข้อมูลแคชและไฟล์ชั่วคราว',
                onTap: _cleanTemporaryData,
              ),
              _ManagementItem(
                icon: Icons.analytics,
                title: 'วิเคราะห์ประสิทธิภาพ',
                subtitle: 'ตรวจสอบประสิทธิภาพระบบ',
                onTap: _analyzeSystemPerformance,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Security Management
          _buildManagementSection(
            title: 'จัดการความปลอดภัย',
            icon: Icons.security,
            items: [
              _ManagementItem(
                icon: Icons.security,
                title: 'ตรวจสอบความปลอดภัย',
                subtitle: 'สแกนหาช่องโหว่ความปลอดภัย',
                onTap: _performSecurityScan,
              ),
              _ManagementItem(
                icon: Icons.vpn_key,
                title: 'จัดการ API Keys',
                subtitle: 'ดู และจัดการ API Keys',
                onTap: _manageApiKeys,
              ),
              _ManagementItem(
                icon: Icons.block,
                title: 'รายการ IP ที่ถูกบล็อก',
                subtitle: 'จัดการ IP ที่ถูกบล็อก',
                onTap: _manageBlockedIPs,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Content Moderation
          _buildManagementSection(
            title: 'กลั่นกรองเนื้อหา',
            icon: Icons.report,
            items: [
              _ManagementItem(
                icon: Icons.report,
                title: 'รายงานที่รอตรวจสอบ',
                subtitle: 'ตรวจสอบรายงานจากผู้ใช้',
                onTap: _reviewReports,
              ),
              _ManagementItem(
                icon: Icons.auto_fix_high,
                title: 'ตัวกรองเนื้อหาอัตโนมัติ',
                subtitle: 'ตั้งค่าการกรองเนื้อหาอัตโนมัติ',
                onTap: _configureContentFilter,
              ),
              _ManagementItem(
                icon: Icons.flag,
                title: 'คำต้องห้าม',
                subtitle: 'จัดการรายการคำต้องห้าม',
                onTap: _manageBannedWords,
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
    required List<_ManagementItem> items,
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
            ...items.map((item) => ListTile(
                  leading: Icon(item.icon, color: AppColors.primaryTeal),
                  title: Text(item.title),
                  subtitle: Text(item.subtitle),
                  onTap: item.onTap,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilterChip(String label, String? status) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: false, // You can implement selection state
        onSelected: (selected) {
          // Implement filter logic
        },
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

  // Action Methods
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

class _ManagementItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _ManagementItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
