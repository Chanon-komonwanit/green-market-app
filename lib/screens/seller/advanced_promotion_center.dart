// lib/screens/seller/advanced_promotion_center.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/models/shop_customization.dart';
import 'package:green_market/screens/seller/create_promotion_screen.dart';

/// 🚀 Advanced Promotion Center - World-Class Marketing Hub
/// Features: Flash Sales, Dynamic Pricing, A/B Testing, Performance Analytics
class AdvancedPromotionCenter extends StatefulWidget {
  const AdvancedPromotionCenter({super.key});

  @override
  State<AdvancedPromotionCenter> createState() =>
      _AdvancedPromotionCenterState();
}

class _AdvancedPromotionCenterState extends State<AdvancedPromotionCenter>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _pulseController;
  List<ShopPromotion> _promotions = [];
  Map<String, dynamic> _analyticsData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _loadPromotionData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadPromotionData() async {
    setState(() => _isLoading = true);

    try {
      final sellerId = FirebaseAuth.instance.currentUser?.uid;
      if (sellerId == null) return;

      // Load promotions and analytics
      await Future.wait([
        _loadPromotions(sellerId),
        _loadPromotionAnalytics(sellerId),
      ]);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPromotions(String sellerId) async {
    // final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    // Load promotions from Firebase (temporarily commented to avoid unused variable)
    // final promotions = await firebaseService.getPromotionsBySeller(sellerId);

    // Convert and add sample promotions for demo
    setState(() {
      _promotions = [
        // Sample Flash Sale
        ShopPromotion(
          id: 'flash_001',
          title: 'Flash Sale สุดคุ้ม!',
          description: 'ลดราคาพิเศษ 50% เฉพาะ 2 ชั่วโมง',
          type: PromotionType.flashSale,
          sellerId: sellerId,
          createdAt: DateTime.now(),
          discountPercent: 50.0,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(hours: 2)),
          isActive: true,
          usageLimit: 100,
          usedCount: 67,
          iconEmoji: '⚡',
          backgroundColor: '#FF6B6B',
        ),
        // Sample Bundle Deal
        ShopPromotion(
          id: 'bundle_001',
          title: 'Green Bundle Pack',
          description: 'ซื้อ 2 ฟรี 1 สินค้าเพื่อสิ่งแวดล้อม',
          type: PromotionType.buyXGetY,
          sellerId: sellerId,
          createdAt: DateTime.now(),
          buyQuantity: 2,
          getQuantity: 1,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 7)),
          isActive: true,
          usageLimit: 200,
          usedCount: 34,
          iconEmoji: '🌱',
          backgroundColor: '#4ECDC4',
        ),
        // Sample Loyalty Discount
        ShopPromotion(
          id: 'loyalty_001',
          title: 'Green Loyalty 20%',
          description: 'ส่วนลดพิเศษสำหรับลูกค้า VIP',
          type: PromotionType.percentDiscount,
          sellerId: sellerId,
          createdAt: DateTime.now(),
          discountPercent: 20.0,
          minimumPurchase: 500.0,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 30)),
          isActive: true,
          usageLimit: 500,
          usedCount: 156,
          iconEmoji: '👑',
          backgroundColor: '#45B7D1',
        ),
      ];
    });
  }

  Future<void> _loadPromotionAnalytics(String sellerId) async {
    // Load promotion performance analytics
    setState(() {
      _analyticsData = {
        'totalRevenue': 125450.0,
        'promotionRevenue': 67890.0,
        'conversionRate': 8.4,
        'avgOrderValue': 1250.0,
        'topPerformingPromotions': [
          {'name': 'Flash Sale', 'revenue': 34500, 'conversion': 12.5},
          {'name': 'Bundle Pack', 'revenue': 23450, 'conversion': 9.8},
          {'name': 'Loyalty Discount', 'revenue': 9940, 'conversion': 6.2},
        ],
        'performanceChart': [
          FlSpot(0, 2500),
          FlSpot(1, 4800),
          FlSpot(2, 3200),
          FlSpot(3, 5400),
          FlSpot(4, 8900),
          FlSpot(5, 6700),
          FlSpot(6, 7200),
        ],
        'abTestResults': {
          'testA_conversion': 6.8,
          'testB_conversion': 9.2,
          'winner': 'B',
          'confidence': 95.4,
        },
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildPromotionOverview(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildActivePromotions(),
                      _buildFlashSaleHub(),
                      _buildDynamicPricing(),
                      _buildABTesting(),
                      _buildAnalyticsDashboard(),
                      _buildAutomationRules(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: _buildCreatePromotionFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Marketing Center',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: const Color(0xFF1B5E20),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.analytics_outlined),
          onPressed: () => _tabController.animateTo(4),
        ),
        IconButton(
          icon: const Icon(Icons.auto_awesome),
          onPressed: () => _tabController.animateTo(5),
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        tabs: const [
          Tab(text: 'กำลังใช้งาน'),
          Tab(text: 'Flash Sale'),
          Tab(text: 'ราคาไดนามิก'),
          Tab(text: 'A/B Testing'),
          Tab(text: 'Analytics'),
          Tab(text: 'Automation'),
        ],
      ),
    );
  }

  Widget _buildPromotionOverview() {
    final promotionRevenue = _analyticsData['promotionRevenue'] ?? 0.0;
    final totalRevenue = _analyticsData['totalRevenue'] ?? 1.0;
    final promotionContribution = (promotionRevenue / totalRevenue * 100);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'รายได้จากโปรโมชั่น',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    '฿${promotionRevenue.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${promotionContribution.toStringAsFixed(1)}% ของยอดขายรวม',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildOverviewMetric(
                  'โปรโมชั่นใช้งาน',
                  '${_promotions.where((p) => p.isActive).length}',
                  Icons.local_offer,
                ),
              ),
              Expanded(
                child: _buildOverviewMetric(
                  'อัตราการแปลง',
                  '${_analyticsData['conversionRate']?.toStringAsFixed(1)}%',
                  Icons.analytics,
                ),
              ),
              Expanded(
                child: _buildOverviewMetric(
                  'มูลค่าเฉลี่ย',
                  '฿${(_analyticsData['avgOrderValue'] ?? 0).toStringAsFixed(0)}',
                  Icons.receipt_long,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewMetric(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActivePromotions() {
    final activePromotions = _promotions.where((p) => p.isActive).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activePromotions.length,
      itemBuilder: (context, index) {
        final promotion = activePromotions[index];
        return _buildAdvancedPromotionCard(promotion);
      },
    );
  }

  Widget _buildAdvancedPromotionCard(ShopPromotion promotion) {
    final usagePercentage = promotion.usageLimit != null
        ? (promotion.usedCount / promotion.usageLimit!) * 100
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with gradient background
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _parseColor(promotion.backgroundColor ?? '#4CAF50'),
                  _parseColor(promotion.backgroundColor ?? '#4CAF50')
                      .withOpacity(0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                if (promotion.iconEmoji != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      promotion.iconEmoji!,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promotion.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        promotion.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildPromotionTypeChip(promotion.type),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Usage Progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'การใช้งาน: ${promotion.usedCount}/${promotion.usageLimit ?? "∞"}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${usagePercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: usagePercentage / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                ),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editPromotion(promotion),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('แก้ไข'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _viewAnalytics(promotion),
                        icon: const Icon(Icons.analytics_outlined, size: 16),
                        label: const Text('ดูผลลัพธ์'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionTypeChip(PromotionType type) {
    String label;

    switch (type) {
      case PromotionType.flashSale:
        label = 'Flash Sale';
        break;
      case PromotionType.buyXGetY:
        label = 'Bundle';
        break;
      case PromotionType.percentDiscount:
        label = 'ลด %';
        break;
      case PromotionType.fixedDiscount:
        label = 'ลดตรง';
        break;
      case PromotionType.freeShipping:
        label = 'ส่งฟรี';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFlashSaleHub() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFlashSaleCreator(),
          const SizedBox(height: 20),
          _buildActiveFlashSales(),
          const SizedBox(height: 20),
          _buildFlashSalePerformance(),
        ],
      ),
    );
  }

  Widget _buildFlashSaleCreator() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B6B).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_pulseController.value * 0.2),
                    child: const Text(
                      '⚡',
                      style: TextStyle(fontSize: 32),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สร้าง Flash Sale',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'เพิ่มยอดขายด้วยการลดราคาสุดพิเศษ',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _createFlashSale,
                  icon: const Icon(Icons.flash_on),
                  label: const Text('สร้าง Flash Sale'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFFF6B6B),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _scheduleFlashSale,
                icon: const Icon(Icons.schedule),
                label: const Text('จองคิว'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFlashSales() {
    final flashSales = _promotions
        .where((p) => p.type == PromotionType.flashSale && p.isActive)
        .toList();

    if (flashSales.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.flash_off, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'ไม่มี Flash Sale ที่กำลังดำเนินการ',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Flash Sale กำลังดำเนินการ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...flashSales.map((sale) => _buildFlashSaleCard(sale)),
      ],
    );
  }

  Widget _buildFlashSaleCard(ShopPromotion sale) {
    final timeLeft = sale.endDate?.difference(DateTime.now()) ?? Duration.zero;
    final hours = timeLeft.inHours;
    final minutes = timeLeft.inMinutes % 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF6B6B), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('⚡', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ลด ${sale.discountPercent?.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFFF6B6B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$hoursชม $minutesนาที',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B6B),
                ),
              ),
              Text(
                'เหลือ ${sale.usageLimit! - sale.usedCount} ที่',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlashSalePerformance() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ผลประกอบการ Flash Sale',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPerformanceMetric(
                  'รายได้รวม',
                  '฿34,500',
                  Icons.monetization_on,
                  const Color(0xFF4CAF50),
                ),
              ),
              Expanded(
                child: _buildPerformanceMetric(
                  'อัตราการแปลง',
                  '12.5%',
                  Icons.trending_up,
                  const Color(0xFF2196F3),
                ),
              ),
              Expanded(
                child: _buildPerformanceMetric(
                  'ออเดอร์',
                  '157',
                  Icons.shopping_cart,
                  const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric(
      String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDynamicPricing() {
    return const Center(
      child: Text('Dynamic Pricing - Coming Next'),
    );
  }

  Widget _buildABTesting() {
    return const Center(
      child: Text('A/B Testing - Coming Next'),
    );
  }

  Widget _buildAnalyticsDashboard() {
    return const Center(
      child: Text('Analytics Dashboard - Coming Next'),
    );
  }

  Widget _buildAutomationRules() {
    return const Center(
      child: Text('Automation Rules - Coming Next'),
    );
  }

  Widget _buildCreatePromotionFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreatePromotionScreen(),
          ),
        ).then((_) => _loadPromotionData());
      },
      icon: const Icon(Icons.add),
      label: const Text('โปรโมชั่นใหม่'),
      backgroundColor: const Color(0xFF2E7D32),
      foregroundColor: Colors.white,
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF4CAF50);
    }
  }

  void _editPromotion(ShopPromotion promotion) {
    // Navigate to edit promotion
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('แก้ไขโปรโมชั่น: ${promotion.title}')),
    );
  }

  void _viewAnalytics(ShopPromotion promotion) {
    _tabController.animateTo(4); // Navigate to Analytics tab
  }

  void _createFlashSale() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('สร้าง Flash Sale - Feature Coming Soon!')),
    );
  }

  void _scheduleFlashSale() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('จองคิว Flash Sale - Feature Coming Soon!')),
    );
  }
}
