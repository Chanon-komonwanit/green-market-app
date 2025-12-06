import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:async';

/// ระบบโปรโมชั่นขั้นสูง - Advanced Promotions Management
/// รองรับ Flash Sale, Bundle Deal, Buy X Get Y, Time-limited Offers
class AdvancedPromotionsScreen extends StatefulWidget {
  const AdvancedPromotionsScreen({super.key});

  @override
  State<AdvancedPromotionsScreen> createState() =>
      _AdvancedPromotionsScreenState();
}

class _AdvancedPromotionsScreenState extends State<AdvancedPromotionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _sellerId;

  List<Map<String, dynamic>> _promotions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _sellerId = FirebaseAuth.instance.currentUser?.uid;
    if (_sellerId != null) {
      _loadPromotions();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPromotions() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestore
          .collection('advanced_promotions')
          .where('sellerId', isEqualTo: _sellerId)
          .orderBy('createdAt', descending: true)
          .get();

      _promotions = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getFilteredPromotions() {
    final now = DateTime.now();

    List<Map<String, dynamic>> filtered = _promotions;

    // Filter by tab
    switch (_tabController.index) {
      case 0: // กำลังใช้งาน
        filtered = filtered.where((p) {
          final endDate = (p['endDate'] as Timestamp?)?.toDate();
          return p['isActive'] == true &&
              (endDate == null || endDate.isAfter(now));
        }).toList();
        break;
      case 1: // สิ้นสุดแล้ว
        filtered = filtered.where((p) {
          final endDate = (p['endDate'] as Timestamp?)?.toDate();
          return p['isActive'] == false ||
              (endDate != null && endDate.isBefore(now));
        }).toList();
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('โปรโมชั่น'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPromotions,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) => setState(() {}),
          tabs: const [
            Tab(icon: Icon(Icons.play_circle_outline), text: 'กำลังใช้งาน'),
            Tab(icon: Icon(Icons.check_circle_outline), text: 'สิ้นสุดแล้ว'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePromotionDialog(),
        icon: const Icon(Icons.add),
        label: const Text('สร้างโปรโมชั่น'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildPromotionsList(),
    );
  }

  Widget _buildPromotionsList() {
    final filteredPromotions = _getFilteredPromotions();

    if (filteredPromotions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_outlined,
                size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'ยังไม่มีโปรโมชั่น',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showCreatePromotionDialog(),
              icon: const Icon(Icons.add),
              label: const Text('สร้างโปรโมชั่นแรก'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPromotions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredPromotions.length,
        itemBuilder: (context, index) {
          return _buildPromotionCard(filteredPromotions[index]);
        },
      ),
    );
  }

  Widget _buildPromotionCard(Map<String, dynamic> promotion) {
    final type = promotion['type'] as String;
    final name = promotion['name'] as String;
    final isActive = promotion['isActive'] as bool? ?? true;
    final startDate = (promotion['startDate'] as Timestamp?)?.toDate();
    final endDate = (promotion['endDate'] as Timestamp?)?.toDate();

    final now = DateTime.now();
    bool isRunning = isActive &&
        (startDate == null || startDate.isBefore(now)) &&
        (endDate == null || endDate.isAfter(now));
    bool isUpcoming = isActive && startDate != null && startDate.isAfter(now);
    bool isEnded = !isActive || (endDate != null && endDate.isBefore(now));

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isEnded) {
      statusColor = Colors.grey;
      statusText = 'สิ้นสุดแล้ว';
      statusIcon = Icons.cancel;
    } else if (isUpcoming) {
      statusColor = Colors.orange;
      statusText = 'กำลังจะมา';
      statusIcon = Icons.schedule;
    } else if (isRunning) {
      statusColor = Colors.green;
      statusText = 'กำลังดำเนินการ';
      statusIcon = Icons.play_circle;
    } else {
      statusColor = Colors.grey;
      statusText = 'ปิดใช้งาน';
      statusIcon = Icons.pause_circle;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 2),
      ),
      child: InkWell(
        onTap: () => _showPromotionDetails(promotion),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildTypeIcon(type),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(statusIcon, size: 14, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('แก้ไข'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              isActive ? Icons.pause : Icons.play_arrow,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(isActive ? 'ปิดใช้งาน' : 'เปิดใช้งาน'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('ลบ', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditPromotionDialog(promotion);
                          break;
                        case 'toggle':
                          _togglePromotion(promotion['id'], !isActive);
                          break;
                        case 'delete':
                          _deletePromotion(promotion['id']);
                          break;
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildPromotionDetails(promotion),
              if (isRunning && endDate != null) ...[
                const SizedBox(height: 12),
                _buildCountdownTimer(endDate),
              ],
              const SizedBox(height: 12),
              _buildPromotionStats(promotion),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'flash_sale':
        icon = Icons.flash_on;
        color = Colors.orange;
        break;
      case 'bundle':
        icon = Icons.inventory_2;
        color = Colors.blue;
        break;
      case 'buy_x_get_y':
        icon = Icons.card_giftcard;
        color = Colors.purple;
        break;
      default:
        icon = Icons.local_offer;
        color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildPromotionDetails(Map<String, dynamic> promotion) {
    final type = promotion['type'] as String;

    switch (type) {
      case 'flash_sale':
        return _buildFlashSaleDetails(promotion);
      case 'bundle':
        return _buildBundleDetails(promotion);
      case 'buy_x_get_y':
        return _buildBuyXGetYDetails(promotion);
      default:
        return const SizedBox();
    }
  }

  Widget _buildFlashSaleDetails(Map<String, dynamic> promotion) {
    final discount = promotion['discount'] ?? 0;
    final discountType = promotion['discountType'] ?? 'percentage';
    final stock = promotion['stock'] ?? 0;
    final sold = promotion['sold'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                discountType == 'percentage'
                    ? 'ลด $discount%'
                    : 'ลด ฿$discount',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: stock > 0 ? sold / stock : 0,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
          const SizedBox(height: 4),
          Text(
            'ขายแล้ว $sold / $stock ชิ้น',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBundleDetails(Map<String, dynamic> promotion) {
    final products = promotion['products'] as List? ?? [];
    final bundlePrice = promotion['bundlePrice'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'ชุดสินค้า ${products.length} รายการ',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'ราคาชุด ฿${bundlePrice.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyXGetYDetails(Map<String, dynamic> promotion) {
    final buyQuantity = promotion['buyQuantity'] ?? 0;
    final getQuantity = promotion['getQuantity'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard, color: Colors.purple, size: 20),
          const SizedBox(width: 8),
          Text(
            'ซื้อ $buyQuantity แถม $getQuantity',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownTimer(DateTime endDate) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final remaining = endDate.difference(DateTime.now());

        if (remaining.isNegative) {
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_off, color: Colors.red, size: 16),
                SizedBox(width: 4),
                Text(
                  'หมดเวลาแล้ว',
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }

        final days = remaining.inDays;
        final hours = remaining.inHours % 24;
        final minutes = remaining.inMinutes % 60;
        final seconds = remaining.inSeconds % 60;

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer, color: Colors.red, size: 16),
              const SizedBox(width: 8),
              Text(
                days > 0
                    ? '$days วัน $hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
                    : '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPromotionStats(Map<String, dynamic> promotion) {
    final views = promotion['views'] ?? 0;
    final clicks = promotion['clicks'] ?? 0;
    final sold = promotion['sold'] ?? 0;

    return Row(
      children: [
        _buildStatChip(Icons.visibility, '$views', 'ดู'),
        const SizedBox(width: 8),
        _buildStatChip(Icons.touch_app, '$clicks', 'คลิก'),
        const SizedBox(width: 8),
        _buildStatChip(Icons.shopping_cart, '$sold', 'ขาย'),
      ],
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _showCreatePromotionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เลือกประเภทโปรโมชั่น'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flash_on, color: Colors.orange),
              title: const Text('Flash Sale'),
              subtitle: const Text('ลดราคาพิเศษ จำนวนจำกัด'),
              onTap: () {
                Navigator.pop(context);
                _showFlashSaleForm();
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2, color: Colors.blue),
              title: const Text('Bundle Deal'),
              subtitle: const Text('ขายชุดสินค้า ราคาพิเศษ'),
              onTap: () {
                Navigator.pop(context);
                _showBundleForm();
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_giftcard, color: Colors.purple),
              title: const Text('Buy X Get Y'),
              subtitle: const Text('ซื้อครบแถมฟรี'),
              onTap: () {
                Navigator.pop(context);
                _showBuyXGetYForm();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFlashSaleForm() {
    final nameController = TextEditingController();
    final discountController = TextEditingController();
    final stockController = TextEditingController();
    String discountType = 'percentage';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('⚡ สร้าง Flash Sale'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อโปรโมชั่น',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: discountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'ส่วนลด',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: discountType,
                      items: const [
                        DropdownMenuItem(value: 'percentage', child: Text('%')),
                        DropdownMenuItem(value: 'fixed', child: Text('฿')),
                      ],
                      onChanged: (value) {
                        setState(() => discountType = value!);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: stockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'จำนวนสินค้า',
                    border: OutlineInputBorder(),
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
              onPressed: () async {
                await _firestore.collection('advanced_promotions').add({
                  'sellerId': _sellerId,
                  'type': 'flash_sale',
                  'name': nameController.text,
                  'discount': double.tryParse(discountController.text) ?? 0,
                  'discountType': discountType,
                  'stock': int.tryParse(stockController.text) ?? 0,
                  'sold': 0,
                  'views': 0,
                  'clicks': 0,
                  'isActive': true,
                  'startDate': Timestamp.now(),
                  'endDate': Timestamp.fromDate(
                      DateTime.now().add(const Duration(days: 1))),
                  'createdAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
                _loadPromotions();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ สร้าง Flash Sale สำเร็จ')),
                );
              },
              child: const Text('สร้าง'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBundleForm() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📦 สร้าง Bundle Deal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อชุดสินค้า',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'ราคาชุด (฿)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('เลือกสินค้าใน Bundle (Coming Soon)',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _firestore.collection('advanced_promotions').add({
                'sellerId': _sellerId,
                'type': 'bundle',
                'name': nameController.text,
                'bundlePrice': double.tryParse(priceController.text) ?? 0,
                'products': [],
                'sold': 0,
                'views': 0,
                'clicks': 0,
                'isActive': true,
                'startDate': Timestamp.now(),
                'createdAt': FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
              _loadPromotions();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ สร้าง Bundle Deal สำเร็จ')),
              );
            },
            child: const Text('สร้าง'),
          ),
        ],
      ),
    );
  }

  void _showBuyXGetYForm() {
    final nameController = TextEditingController();
    final buyController = TextEditingController(text: '2');
    final getController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎁 สร้าง Buy X Get Y'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อโปรโมชั่น',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: buyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'ซื้อ (X)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('แถม', style: TextStyle(fontSize: 16)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: getController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'แถม (Y)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
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
            onPressed: () async {
              await _firestore.collection('advanced_promotions').add({
                'sellerId': _sellerId,
                'type': 'buy_x_get_y',
                'name': nameController.text,
                'buyQuantity': int.tryParse(buyController.text) ?? 2,
                'getQuantity': int.tryParse(getController.text) ?? 1,
                'sold': 0,
                'views': 0,
                'clicks': 0,
                'isActive': true,
                'startDate': Timestamp.now(),
                'createdAt': FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
              _loadPromotions();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ สร้าง Buy X Get Y สำเร็จ')),
              );
            },
            child: const Text('สร้าง'),
          ),
        ],
      ),
    );
  }

  void _showPromotionDetails(Map<String, dynamic> promotion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              promotion['type'] == 'flash_sale'
                  ? Icons.flash_on
                  : promotion['type'] == 'bundle'
                      ? Icons.inventory
                      : Icons.card_giftcard,
              color: Colors.orange,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                promotion['name'] ?? 'โปรโมชั่น',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('ประเภท', _getPromotionTypeText(promotion['type'])),
              _buildDetailItem('คำอธิบาย', promotion['description'] ?? '-'),
              _buildDetailItem(
                'ส่วนลด',
                promotion['type'] == 'flash_sale'
                    ? '${promotion['discountPercent']}%'
                    : promotion['type'] == 'bundle'
                        ? '฿${promotion['bundlePrice']}'
                        : 'ซื้อ ${promotion['buyQuantity']} แถม ${promotion['getQuantity']}',
              ),
              _buildDetailItem(
                'ระยะเวลา',
                '${_formatDate(promotion['startDate'])} - ${_formatDate(promotion['endDate'])}',
              ),
              _buildDetailItem(
                'สถานะ',
                promotion['isActive'] == true ? '✅ เปิดใช้งาน' : '⏸️ ปิดใช้งาน',
              ),
              if (promotion['products'] != null)
                _buildDetailItem(
                  'สินค้า',
                  '${(promotion['products'] as List).length} รายการ',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showEditPromotionDialog(promotion);
            },
            icon: const Icon(Icons.edit),
            label: const Text('แก้ไข'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _getPromotionTypeText(String type) {
    switch (type) {
      case 'flash_sale':
        return '⚡ Flash Sale';
      case 'bundle':
        return '📦 ชุดสินค้า';
      case 'buy_x_get_y':
        return '🎁 ซื้อ X แถม Y';
      default:
        return type;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      final DateTime dt = date is Timestamp ? date.toDate() : date;
      return DateFormat('d MMM yyyy', 'th').format(dt);
    } catch (e) {
      return '-';
    }
  }

  void _showEditPromotionDialog(Map<String, dynamic> promotion) {
    final nameController = TextEditingController(text: promotion['name']);
    final descController = TextEditingController(text: promotion['description']);
    bool isActive = promotion['isActive'] ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('✏️ แก้ไขโปรโมชั่น'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อโปรโมชั่น',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'คำอธิบาย',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('เปิดใช้งาน'),
                  value: isActive,
                  onChanged: (value) {
                    setState(() => isActive = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await _firestore
                      .collection('advanced_promotions')
                      .doc(promotion['id'])
                      .update({
                    'name': nameController.text,
                    'description': descController.text,
                    'isActive': isActive,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ บันทึกเรียบร้อยแล้ว'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadPromotions();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePromotion(String id, bool isActive) async {
    try {
      await _firestore
          .collection('advanced_promotions')
          .doc(id)
          .update({'isActive': isActive});
      _loadPromotions();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isActive ? '✅ เปิดใช้งานแล้ว' : '⏸️ ปิดใช้งานแล้ว'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  Future<void> _deletePromotion(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณต้องการลบโปรโมชั่นนี้หรือไม่?'),
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

    if (confirm == true) {
      try {
        await _firestore.collection('advanced_promotions').doc(id).delete();
        _loadPromotions();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🗑️ ลบโปรโมชั่นแล้ว')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }
}
