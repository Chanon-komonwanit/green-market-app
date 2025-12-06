// lib/screens/seller/coupon_management_screen.dart
// 🎫 Coupon & Voucher Management - Shopee/TikTok Shop Standard

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CouponManagementScreen extends StatefulWidget {
  const CouponManagementScreen({super.key});

  @override
  State<CouponManagementScreen> createState() => _CouponManagementScreenState();
}

class _CouponManagementScreenState extends State<CouponManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _coupons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCoupons();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCoupons() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('seller_coupons')
          .where('sellerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      _coupons = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'code': data['code'] ?? '',
          'name': data['name'] ?? '',
          'type': data['type'] ?? 'percentage', // percentage, fixed
          'value': (data['value'] as num?)?.toDouble() ?? 0.0,
          'minPurchase': (data['minPurchase'] as num?)?.toDouble() ?? 0.0,
          'maxDiscount': (data['maxDiscount'] as num?)?.toDouble() ?? 0.0,
          'usageLimit': (data['usageLimit'] as num?)?.toInt() ?? 0,
          'usedCount': (data['usedCount'] as num?)?.toInt() ?? 0,
          'startDate': (data['startDate'] as Timestamp?)?.toDate(),
          'endDate': (data['endDate'] as Timestamp?)?.toDate(),
          'isActive': data['isActive'] ?? true,
          'createdAt':
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading coupons: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getFilteredCoupons() {
    final now = DateTime.now();

    switch (_tabController.index) {
      case 0: // ทั้งหมด
        return _coupons;
      case 1: // กำลังใช้งาน
        return _coupons.where((c) {
          final startDate = c['startDate'] as DateTime?;
          final endDate = c['endDate'] as DateTime?;
          return c['isActive'] == true &&
              (startDate == null || startDate.isBefore(now)) &&
              (endDate == null || endDate.isAfter(now));
        }).toList();
      case 2: // กำลังจะมา
        return _coupons.where((c) {
          final startDate = c['startDate'] as DateTime?;
          return c['isActive'] == true &&
              startDate != null &&
              startDate.isAfter(now);
        }).toList();
      case 3: // หมดอายุ
        return _coupons.where((c) {
          final endDate = c['endDate'] as DateTime?;
          return !c['isActive'] || (endDate != null && endDate.isBefore(now));
        }).toList();
      default:
        return _coupons;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'คูปองส่วนลด',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'ทั้งหมด'),
            Tab(text: 'กำลังใช้งาน'),
            Tab(text: 'กำลังจะมา'),
            Tab(text: 'หมดอายุ'),
          ],
        ),
      ),
      body: _isLoading ? _buildLoadingState() : _buildCouponsList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateCouponDialog,
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add),
        label: const Text('สร้างคูปอง'),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
      ),
    );
  }

  Widget _buildCouponsList() {
    final filteredCoupons = _getFilteredCoupons();

    if (filteredCoupons.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadCoupons,
      color: const Color(0xFF2E7D32),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filteredCoupons.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildCouponCard(filteredCoupons[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'ยังไม่มีคูปอง',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showCreateCouponDialog,
            icon: const Icon(Icons.add),
            label: const Text('สร้างคูปองแรก'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponCard(Map<String, dynamic> coupon) {
    final type = coupon['type'] as String;
    final value = coupon['value'] as double;
    final usedCount = coupon['used Count'] as int;
    final usageLimit = coupon['usageLimit'] as int;
    final isActive = coupon['isActive'] as bool;

    final now = DateTime.now();
    final startDate = coupon['startDate'] as DateTime?;
    final endDate = coupon['endDate'] as DateTime?;

    bool isExpired = !isActive || (endDate != null && endDate.isBefore(now));
    bool isUpcoming = isActive && startDate != null && startDate.isAfter(now);

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isExpired) {
      statusColor = Colors.grey;
      statusText = 'หมดอายุ';
      statusIcon = Icons.cancel;
    } else if (isUpcoming) {
      statusColor = Colors.blue;
      statusText = 'กำลังจะมา';
      statusIcon = Icons.schedule;
    } else {
      statusColor = Colors.green;
      statusText = 'กำลังใช้งาน';
      statusIcon = Icons.check_circle;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.1),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showCouponDetails(coupon),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        Icon(Icons.local_offer, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          coupon['name'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(statusIcon, size: 14, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditCouponDialog(coupon);
                          break;
                        case 'toggle':
                          _toggleCouponStatus(coupon['id'], !isActive);
                          break;
                        case 'delete':
                          _deleteCoupon(coupon['id']);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 20),
                            SizedBox(width: 12),
                            Text('แก้ไข'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              isActive
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(isActive ? 'ปิดใช้งาน' : 'เปิดใช้งาน'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                size: 20, color: Colors.red),
                            SizedBox(width: 12),
                            Text('ลบ', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Coupon Code
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.grey[300]!, style: BorderStyle.solid),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        coupon['code'] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: Color(0xFF2E7D32),
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: coupon['code'] as String),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('คัดลอกโค้ดแล้ว'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      tooltip: 'คัดลอกโค้ด',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Discount Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5722).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.discount,
                        color: Color(0xFFFF5722), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type == 'percentage'
                                ? 'ส่วนลด ${value.toInt()}%'
                                : 'ส่วนลด ฿${NumberFormat('#,##0').format(value)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF5722),
                            ),
                          ),
                          if (coupon['minPurchase'] > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              'ซื้อขั้นต่ำ ฿${NumberFormat('#,##0').format(coupon['minPurchase'])}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                          if (type == 'percentage' &&
                              coupon['maxDiscount'] > 0) ...[
                            const SizedBox(height: 2),
                            Text(
                              'ลดสูงสุด ฿${NumberFormat('#,##0').format(coupon['maxDiscount'])}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Usage Stats & Dates
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      Icons.people_outline,
                      'ใช้แล้ว $usedCount/${usageLimit == 0 ? "∞" : usageLimit}',
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      Icons.calendar_today,
                      endDate != null
                          ? 'หมดเขต ${DateFormat('d/M/yy').format(endDate)}'
                          : 'ไม่มีวันหมดอายุ',
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateCouponDialog() {
    _showCouponFormDialog(null);
  }

  void _showEditCouponDialog(Map<String, dynamic> coupon) {
    _showCouponFormDialog(coupon);
  }

  void _showCouponFormDialog(Map<String, dynamic>? existingCoupon) {
    final isEdit = existingCoupon != null;

    final nameController = TextEditingController(
      text: existingCoupon?['name'] ?? '',
    );
    final codeController = TextEditingController(
      text: existingCoupon?['code'] ?? '',
    );
    final valueController = TextEditingController(
      text: existingCoupon?['value']?.toString() ?? '',
    );
    final minPurchaseController = TextEditingController(
      text: existingCoupon?['minPurchase']?.toString() ?? '',
    );
    final maxDiscountController = TextEditingController(
      text: existingCoupon?['maxDiscount']?.toString() ?? '',
    );
    final usageLimitController = TextEditingController(
      text: existingCoupon?['usageLimit']?.toString() ?? '',
    );

    String selectedType = existingCoupon?['type'] ?? 'percentage';
    DateTime? startDate = existingCoupon?['startDate'];
    DateTime? endDate = existingCoupon?['endDate'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'แก้ไขคูปอง' : 'สร้างคูปองใหม่'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อคูปอง',
                    hintText: 'เช่น ส่วนลดช่วงเปิดร้าน',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'รหัสคูปอง',
                    hintText: 'เช่น WELCOME50',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'ประเภทส่วนลด',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'percentage',
                      child: Text('เปอร์เซ็นต์ (%)'),
                    ),
                    DropdownMenuItem(
                      value: 'fixed',
                      child: Text('จำนวนเงิน (฿)'),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: valueController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: selectedType == 'percentage'
                        ? 'เปอร์เซ็นต์ส่วนลด'
                        : 'จำนวนเงินส่วนลด',
                    suffixText: selectedType == 'percentage' ? '%' : '฿',
                    border: const OutlineInputBorder(),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: minPurchaseController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'ยอดซื้อขั้นต่ำ (ไม่บังคับ)',
                    suffixText: '฿',
                    border: OutlineInputBorder(),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
                if (selectedType == 'percentage') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: maxDiscountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'ส่วนลดสูงสุด (ไม่บังคับ)',
                      suffixText: '฿',
                      border: OutlineInputBorder(),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: usageLimitController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'จำนวนครั้งที่ใช้ได้ (0 = ไม่จำกัด)',
                    border: OutlineInputBorder(),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('วันที่เริ่มต้น'),
                  subtitle: Text(
                    startDate != null
                        ? DateFormat('d MMMM yyyy', 'th').format(startDate!)
                        : 'ไม่กำหนด',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (startDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setDialogState(() {
                              startDate = null;
                            });
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() {
                              startDate = date;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('วันที่สิ้นสุด'),
                  subtitle: Text(
                    endDate != null
                        ? DateFormat('d MMMM yyyy', 'th').format(endDate!)
                        : 'ไม่กำหนด',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (endDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setDialogState(() {
                              endDate = null;
                            });
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDate ??
                                (startDate ?? DateTime.now())
                                    .add(const Duration(days: 7)),
                            firstDate: startDate ?? DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() {
                              endDate = date;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty ||
                    codeController.text.isEmpty ||
                    valueController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('กรุณากรอกข้อมูลที่จำเป็น'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                if (isEdit) {
                  _updateCoupon(
                    existingCoupon['id'],
                    nameController.text,
                    codeController.text,
                    selectedType,
                    double.parse(valueController.text),
                    double.tryParse(minPurchaseController.text) ?? 0,
                    double.tryParse(maxDiscountController.text) ?? 0,
                    int.tryParse(usageLimitController.text) ?? 0,
                    startDate,
                    endDate,
                  );
                } else {
                  _createCoupon(
                    nameController.text,
                    codeController.text,
                    selectedType,
                    double.parse(valueController.text),
                    double.tryParse(minPurchaseController.text) ?? 0,
                    double.tryParse(maxDiscountController.text) ?? 0,
                    int.tryParse(usageLimitController.text) ?? 0,
                    startDate,
                    endDate,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
              ),
              child: Text(isEdit ? 'บันทึก' : 'สร้างคูปอง'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCouponDetails(Map<String, dynamic> coupon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(coupon['name'] as String),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('รหัส', coupon['code']),
              _buildDetailRow(
                'ส่วนลด',
                coupon['type'] == 'percentage'
                    ? '${coupon['value'].toInt()}%'
                    : '฿${NumberFormat('#,##0').format(coupon['value'])}',
              ),
              if (coupon['minPurchase'] > 0)
                _buildDetailRow(
                  'ซื้อขั้นต่ำ',
                  '฿${NumberFormat('#,##0').format(coupon['minPurchase'])}',
                ),
              if (coupon['type'] == 'percentage' && coupon['maxDiscount'] > 0)
                _buildDetailRow(
                  'ลดสูงสุด',
                  '฿${NumberFormat('#,##0').format(coupon['maxDiscount'])}',
                ),
              _buildDetailRow(
                'จำกัดการใช้',
                coupon['usageLimit'] == 0
                    ? 'ไม่จำกัด'
                    : '${coupon['usageLimit']} ครั้ง',
              ),
              _buildDetailRow('ใช้ไปแล้ว', '${coupon['usedCount']} ครั้ง'),
              if (coupon['startDate'] != null)
                _buildDetailRow(
                  'เริ่มต้น',
                  DateFormat('d MMMM yyyy', 'th').format(coupon['startDate']),
                ),
              if (coupon['endDate'] != null)
                _buildDetailRow(
                  'สิ้นสุด',
                  DateFormat('d MMMM yyyy', 'th').format(coupon['endDate']),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createCoupon(
    String name,
    String code,
    String type,
    double value,
    double minPurchase,
    double maxDiscount,
    int usageLimit,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('seller_coupons').add({
        'sellerId': user.uid,
        'name': name,
        'code': code.toUpperCase(),
        'type': type,
        'value': value,
        'minPurchase': minPurchase,
        'maxDiscount': maxDiscount,
        'usageLimit': usageLimit,
        'usedCount': 0,
        'startDate': startDate != null ? Timestamp.fromDate(startDate) : null,
        'endDate': endDate != null ? Timestamp.fromDate(endDate) : null,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('สร้างคูปองสำเร็จ'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );

      _loadCoupons();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateCoupon(
    String couponId,
    String name,
    String code,
    String type,
    double value,
    double minPurchase,
    double maxDiscount,
    int usageLimit,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('seller_coupons')
          .doc(couponId)
          .update({
        'name': name,
        'code': code.toUpperCase(),
        'type': type,
        'value': value,
        'minPurchase': minPurchase,
        'maxDiscount': maxDiscount,
        'usageLimit': usageLimit,
        'startDate': startDate != null ? Timestamp.fromDate(startDate) : null,
        'endDate': endDate != null ? Timestamp.fromDate(endDate) : null,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('แก้ไขคูปองสำเร็จ'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );

      _loadCoupons();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleCouponStatus(String couponId, bool newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('seller_coupons')
          .doc(couponId)
          .update({'isActive': newStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(newStatus ? 'เปิดใช้งานคูปองแล้ว' : 'ปิดใช้งานคูปองแล้ว'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );

      _loadCoupons();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteCoupon(String couponId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบคูปอง'),
        content: const Text('คุณต้องการลบคูปองนี้ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('seller_coupons')
          .doc(couponId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ลบคูปองสำเร็จ'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );

      _loadCoupons();
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
