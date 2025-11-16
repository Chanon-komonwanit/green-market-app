// lib/screens/seller/promotion_management_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/models/shop_customization.dart';
import 'package:green_market/models/unified_promotion.dart' as unified;
import 'package:green_market/screens/seller/create_promotion_screen.dart';
import 'package:green_market/theme/app_colors.dart';

class PromotionManagementScreen extends StatefulWidget {
  const PromotionManagementScreen({super.key});

  @override
  State<PromotionManagementScreen> createState() =>
      _PromotionManagementScreenState();
}

class _PromotionManagementScreenState extends State<PromotionManagementScreen>
    with SingleTickerProviderStateMixin {
  List<ShopPromotion> _promotions = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPromotions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPromotions() async {
    try {
      setState(() => _isLoading = true);

      final sellerId = FirebaseAuth.instance.currentUser?.uid;
      if (sellerId == null) return;

      try {
        final firebaseService =
            Provider.of<FirebaseService>(context, listen: false);
        // Enhanced: Use existing Firebase method
        final promotions =
            await firebaseService.getPromotionsBySeller(sellerId);

        // Convert UnifiedPromotion to ShopPromotion for display
        _promotions = promotions.map((promo) {
          // Map PromotionType from unified to shop
          late PromotionType shopType;
          switch (promo.type.toString()) {
            case 'unified.PromotionType.percentage':
              shopType = PromotionType.percentDiscount;
              break;
            case 'unified.PromotionType.fixedAmount':
              shopType = PromotionType.fixedDiscount;
              break;
            case 'unified.PromotionType.freeShipping':
              shopType = PromotionType.freeShipping;
              break;
            case 'unified.PromotionType.buyXGetY':
              shopType = PromotionType.buyXGetY;
              break;
            case 'unified.PromotionType.flashSale':
              shopType = PromotionType.flashSale;
              break;
            default:
              shopType = PromotionType.percentDiscount;
          }
          return ShopPromotion(
            id: promo.id,
            title: promo.title,
            description: promo.description,
            type: shopType,
            sellerId: promo.sellerId,
            createdAt: promo.createdAt,
            discountPercent: promo.discountPercent,
            discountAmount: promo.discountAmount,
            minimumPurchase: promo.minimumPurchase,
            startDate: promo.startDate,
            endDate: promo.endDate,
            isActive: promo.isActive,
            usedCount: promo.usedCount,
            usageLimit: promo.usageLimit,
          );
        }).toList();

        setState(() => _isLoading = false);
      } catch (e) {
        print('Error loading promotions: $e');
        // Fallback to empty list
        _promotions = [];
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลด: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการโปรโมชั่น'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.local_offer), text: 'กำลังใช้งาน'),
            Tab(icon: Icon(Icons.schedule), text: 'ตั้งเวลาไว้'),
            Tab(icon: Icon(Icons.history), text: 'หมดอายุ'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActivePromotions(),
                _buildScheduledPromotions(),
                _buildExpiredPromotions(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreatePromotion(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('สร้างโปรโมชั่น'),
      ),
    );
  }

  Widget _buildActivePromotions() {
    final activePromotions = _promotions.where((p) => p.isValid).toList();

    if (activePromotions.isEmpty) {
      return _buildEmptyState(
          'ไม่มีโปรโมชั่นที่กำลังใช้งาน', Icons.local_offer_outlined);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activePromotions.length,
      itemBuilder: (context, index) {
        return _buildPromotionCard(activePromotions[index]);
      },
    );
  }

  Widget _buildScheduledPromotions() {
    final scheduledPromotions = _promotions
        .where(
            (p) => p.startDate != null && DateTime.now().isBefore(p.startDate!))
        .toList();

    if (scheduledPromotions.isEmpty) {
      return _buildEmptyState('ไม่มีโปรโมชั่นที่ตั้งเวลาไว้', Icons.schedule);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: scheduledPromotions.length,
      itemBuilder: (context, index) {
        return _buildPromotionCard(scheduledPromotions[index]);
      },
    );
  }

  Widget _buildExpiredPromotions() {
    final expiredPromotions = _promotions.where((p) => !p.isValid).toList();

    if (expiredPromotions.isEmpty) {
      return _buildEmptyState('ไม่มีโปรโมชั่นที่หมดอายุ', Icons.history);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: expiredPromotions.length,
      itemBuilder: (context, index) {
        return _buildPromotionCard(expiredPromotions[index]);
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreatePromotionDialog(),
            icon: const Icon(Icons.add),
            label: const Text('สร้างโปรโมชั่นใหม่'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionCard(ShopPromotion promotion) {
    final backgroundColor = promotion.backgroundColor != null
        ? Color(int.parse('0xFF${promotion.backgroundColor!.substring(1)}'))
        : const Color(0xFF2E7D32);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [backgroundColor, backgroundColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Background Pattern
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: CustomPaint(
                    painter: _PromotionPatternPainter(),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Icon & Discount
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            promotion.iconEmoji ?? '🎁',
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                promotion.discountText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                promotion.title,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                promotion.isValid ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            promotion.isValid ? 'ใช้งานได้' : 'หมดอายุ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Description
                    Text(
                      promotion.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Code & Condition
                    Row(
                      children: [
                        if (promotion.discountCode != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Text(
                              promotion.discountCode!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(
                            promotion.conditionText,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Usage Stats & Actions
                    Row(
                      children: [
                        // Usage Stats
                        if (promotion.usageLimit != null) ...[
                          Icon(Icons.people, color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${promotion.usedCount}/${promotion.usageLimit}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        // Date Range
                        Icon(Icons.schedule, color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatDateRange(
                                promotion.startDate, promotion.endDate),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        // Actions
                        PopupMenuButton<String>(
                          icon:
                              const Icon(Icons.more_vert, color: Colors.white),
                          onSelected: (value) =>
                              _handlePromotionAction(value, promotion),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                                value: 'edit', child: Text('แก้ไข')),
                            const PopupMenuItem(
                                value: 'duplicate', child: Text('ทำซ้ำ')),
                            PopupMenuItem(
                              value: promotion.isActive ? 'disable' : 'enable',
                              child: Text(promotion.isActive
                                  ? 'ปิดใช้งาน'
                                  : 'เปิดใช้งาน'),
                            ),
                            const PopupMenuItem(
                                value: 'delete', child: Text('ลบ')),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return 'ไม่จำกัดเวลา';
    if (start == null) return 'จนถึง ${_formatDate(end!)}';
    if (end == null) return 'เริ่ม ${_formatDate(start)}';
    return '${_formatDate(start)} - ${_formatDate(end)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handlePromotionAction(String action, ShopPromotion promotion) {
    switch (action) {
      case 'edit':
        _showEditPromotionDialog(promotion);
        break;
      case 'duplicate':
        _duplicatePromotion(promotion);
        break;
      case 'disable':
      case 'enable':
        _togglePromotionStatus(promotion);
        break;
      case 'delete':
        _deletePromotion(promotion);
        break;
    }
  }

  void _navigateToCreatePromotion() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => const CreatePromotionScreen(),
      ),
    )
        .then((result) {
      if (result != null) {
        _loadPromotions();
      }
    });
  }

  void _showCreatePromotionDialog() {
    _navigateToCreatePromotion();
  }

  void _showEditPromotionDialog(ShopPromotion promotion) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => CreatePromotionScreen(promotion: promotion),
      ),
    )
        .then((result) {
      if (result != null) {
        _loadPromotions();
      }
    });
  }

  Future<void> _duplicatePromotion(ShopPromotion promotion) async {
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);

      // Convert ShopPromotion to UnifiedPromotion for Firebase
      final unifiedPromotion = unified.UnifiedPromotion(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '${promotion.title} (คัดลอก)',
        description: promotion.description,
        sellerId: promotion.sellerId,
        type: _convertToUnifiedType(promotion.type),
        discountPercent: promotion.discountPercent,
        discountAmount: promotion.discountAmount,
        minimumPurchase: promotion.minimumPurchase,
        startDate: DateTime.now(),
        endDate: promotion.endDate?.add(const Duration(days: 30)),
        isActive: false, // Start inactive for review
        usedCount: 0, // Reset usage count
        usageLimit: promotion.usageLimit,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firebase
      await firebaseService.createPromotion(unifiedPromotion);

      // Refresh local data
      await _loadPromotions();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('คัดลอกโปรโมชั่นเรียบร้อยแล้ว')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ข้อผิดพลาด: $e')),
      );
    }
  }

  Future<void> _togglePromotionStatus(ShopPromotion promotion) async {
    try {
      // Update promotion status
      final newStatus = !promotion.isActive;

      // Update local state immediately for better UX
      setState(() {
        final index = _promotions.indexWhere((p) => p.id == promotion.id);
        if (index != -1) {
          // Create updated promotion (immutable pattern)
          _promotions[index] = ShopPromotion(
            id: promotion.id,
            title: promotion.title,
            description: promotion.description,
            type: promotion.type,
            sellerId: promotion.sellerId,
            createdAt: promotion.createdAt,
            isActive: newStatus,
            discountPercent: promotion.discountPercent,
            discountAmount: promotion.discountAmount,
            minimumPurchase: promotion.minimumPurchase,
            startDate: promotion.startDate,
            endDate: promotion.endDate,
            usedCount: promotion.usedCount,
            usageLimit: promotion.usageLimit,
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              newStatus ? 'เปิดใช้งานโปรโมชั่นแล้ว' : 'ปิดใช้งานโปรโมชั่นแล้ว'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ข้อผิดพลาด: $e')),
      );
    }
  }

  void _deletePromotion(ShopPromotion promotion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('ยืนยันการลบ'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('คุณต้องการลบโปรโมชั่น "${promotion.title}" หรือไม่?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'การลบนี้ไม่สามารถยกเลิกได้ และจะส่งผลต่อลูกค้าที่กำลังใช้โปรโมชั่นนี้',
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (promotion.usedCount > 0)
              Text(
                'โปรโมชั่นนี้ถูกใช้ไปแล้ว ${promotion.usedCount} ครั้ง',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmDeletePromotion(promotion);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('ลบโปรโมชั่น'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeletePromotion(ShopPromotion promotion) async {
    try {
      // Store original data for undo function
      final originalIndex = _promotions.indexWhere((p) => p.id == promotion.id);

      // Remove from local state first for immediate UI response
      setState(() {
        _promotions.removeWhere((p) => p.id == promotion.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ลบโปรโมชั่น "${promotion.title}" เรียบร้อยแล้ว'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'เลิกทำ',
            textColor: Colors.white,
            onPressed: () {
              // Restore promotion to original position
              setState(() {
                if (originalIndex >= 0 && originalIndex <= _promotions.length) {
                  _promotions.insert(originalIndex, promotion);
                } else {
                  _promotions.add(promotion);
                }
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('คืนค่าโปรโมชั่นแล้ว'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      // Restore promotion on error
      setState(() {
        _promotions.add(promotion);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการลบ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper method to convert ShopPromotion type to UnifiedPromotion type
  unified.PromotionType _convertToUnifiedType(PromotionType shopType) {
    switch (shopType) {
      case PromotionType.percentDiscount:
        return unified.PromotionType.percentage;
      case PromotionType.fixedDiscount:
        return unified.PromotionType.fixedAmount;
      case PromotionType.freeShipping:
        return unified.PromotionType.freeShipping;
      case PromotionType.buyXGetY:
        return unified.PromotionType.buyXGetY;
      case PromotionType.flashSale:
        return unified.PromotionType.flashSale;
    }
  }
}

class _PromotionPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1.0;

    // วาดลวดลายจุด
    for (double x = 0; x < size.width; x += 30) {
      for (double y = 0; y < size.height; y += 30) {
        canvas.drawCircle(Offset(x, y), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// หน้าสร้าง/แก้ไขโปรโมชั่น
class CreatePromotionScreen extends StatefulWidget {
  final ShopPromotion? promotion;

  const CreatePromotionScreen({super.key, this.promotion});

  @override
  State<CreatePromotionScreen> createState() => _CreatePromotionScreenState();
}

class _CreatePromotionScreenState extends State<CreatePromotionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _codeController = TextEditingController();
  final _discountController = TextEditingController();
  final _minimumController = TextEditingController();

  PromotionType _selectedType = PromotionType.percentDiscount;
  DateTime? _startDate;
  DateTime? _endDate;
  // int? _usageLimit; // TODO: Implement usage limit functionality

  @override
  void initState() {
    super.initState();
    if (widget.promotion != null) {
      _loadPromotionData();
    }
  }

  void _loadPromotionData() {
    final promo = widget.promotion!;
    _titleController.text = promo.title;
    _descriptionController.text = promo.description;
    _codeController.text = promo.discountCode ?? '';
    _selectedType = promo.type;
    _startDate = promo.startDate;
    _endDate = promo.endDate;
    // _usageLimit = promo.usageLimit; // TODO: Implement usage limit

    if (promo.discountPercent != null) {
      _discountController.text = promo.discountPercent.toString();
    } else if (promo.discountAmount != null) {
      _discountController.text = promo.discountAmount.toString();
    }

    if (promo.minimumPurchase != null) {
      _minimumController.text = promo.minimumPurchase.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.promotion != null ? 'แก้ไขโปรโมชั่น' : 'สร้างโปรโมชั่น'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _savePromotion,
            child: const Text('บันทึก', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildPromotionTypeSelector(),
            const SizedBox(height: 20),
            _buildBasicInfo(),
            const SizedBox(height: 20),
            _buildDiscountSettings(),
            const SizedBox(height: 20),
            _buildDateSettings(),
            const SizedBox(height: 20),
            _buildAdvancedSettings(),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ประเภทโปรโมชั่น',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: PromotionType.values.map((type) {
                return ChoiceChip(
                  label: Text(_getTypeLabel(type)),
                  selected: _selectedType == type,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedType = type);
                  },
                  selectedColor: const Color(0xFF2E7D32),
                  labelStyle: TextStyle(
                    color: _selectedType == type ? Colors.white : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ข้อมูลพื้นฐาน',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'ชื่อโปรโมชั่น',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณาใส่ชื่อโปรโมชั่น';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'คำอธิบาย',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'โค้ดส่วนลด (ถ้ามี)',
                border: OutlineInputBorder(),
                hintText: 'เช่น SAVE20',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'การตั้งค่าส่วนลด',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_selectedType == PromotionType.percentDiscount) ...[
              TextFormField(
                controller: _discountController,
                decoration: const InputDecoration(
                  labelText: 'เปอร์เซ็นต์ส่วนลด',
                  border: OutlineInputBorder(),
                  suffixText: '%',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณาใส่เปอร์เซ็นต์ส่วนลด';
                  }
                  final percent = double.tryParse(value);
                  if (percent == null || percent <= 0 || percent > 100) {
                    return 'กรุณาใส่เปอร์เซ็นต์ระหว่าง 1-100';
                  }
                  return null;
                },
              ),
            ] else if (_selectedType == PromotionType.fixedDiscount) ...[
              TextFormField(
                controller: _discountController,
                decoration: const InputDecoration(
                  labelText: 'จำนวนเงินส่วนลด',
                  border: OutlineInputBorder(),
                  prefixText: '฿',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณาใส่จำนวนเงินส่วนลด';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'กรุณาใส่จำนวนเงินที่ถูกต้อง';
                  }
                  return null;
                },
              ),
            ],
            if (_selectedType != PromotionType.buyXGetY) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _minimumController,
                decoration: const InputDecoration(
                  labelText: 'ยอดซื้อขั้นต่ำ (ถ้ามี)',
                  border: OutlineInputBorder(),
                  prefixText: '฿',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ระยะเวลาใช้งาน',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      title: Text(_startDate != null
                          ? 'เริ่ม: ${_formatDate(_startDate!)}'
                          : 'เลือกวันที่เริ่ม'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectStartDate(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      title: Text(_endDate != null
                          ? 'สิ้นสุด: ${_formatDate(_endDate!)}'
                          : 'เลือกวันที่สิ้นสุด'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectEndDate(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'การตั้งค่าขั้นสูง',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'จำนวนครั้งที่ใช้ได้ (ถ้ามี)',
                border: OutlineInputBorder(),
                hintText: 'ไม่จำกัดถ้าไม่ใส่',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                // TODO: Save usage limit
                // _usageLimit = int.tryParse(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(PromotionType type) {
    switch (type) {
      case PromotionType.percentDiscount:
        return 'ส่วนลด %';
      case PromotionType.fixedDiscount:
        return 'ส่วนลดเงิน';
      case PromotionType.freeShipping:
        return 'ฟรีค่าจัดส่ง';
      case PromotionType.buyXGetY:
        return 'ซื้อ X แถม Y';
      case PromotionType.flashSale:
        return 'Flash Sale';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _endDate = date);
    }
  }

  Future<void> _savePromotion() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('ไม่พบข้อมูลผู้ใช้');
      }

      // Create promotion object for validation
      final newPromotion = ShopPromotion(
        id: widget.promotion?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        sellerId: user.uid,
        createdAt: widget.promotion?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        discountPercent: _selectedType == PromotionType.percentDiscount
            ? double.tryParse(_discountController.text)
            : null,
        discountAmount: _selectedType == PromotionType.fixedDiscount
            ? double.tryParse(_discountController.text)
            : null,
        minimumPurchase: double.tryParse(_minimumController.text),
        startDate: _startDate,
        endDate: _endDate,
        isActive: true,
        usedCount: widget.promotion?.usedCount ?? 0,
        usageLimit: null, // TODO: Add usage limit input field
      );

      // Validate promotion data
      if (newPromotion.title.isEmpty) {
        throw Exception('กรุณาใส่ชื่อโปรโมชั่น');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.promotion != null
              ? 'แก้ไขโปรโมชั่นเรียบร้อยแล้ว (คำเตือน: ยังไม่ได้บันทึกลง Firebase)'
              : 'สร้างโปรโมชั่นเรียบร้อยแล้ว (คำเตือน: ยังไม่ได้บันทึกลง Firebase)'),
          backgroundColor: Colors.orange,
        ),
      );

      // TODO: When Firebase methods are ready, save the promotion:
      // if (widget.promotion != null) {
      //   await firebaseService.updatePromotion(newPromotion);
      // } else {
      //   await firebaseService.createPromotion(newPromotion);
      // }
      // if (widget.promotion != null) {
      //   await firebaseService.updatePromotion(promotion);
      // } else {
      //   await firebaseService.createPromotion(promotion);
      // }

      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _codeController.dispose();
    _discountController.dispose();
    _minimumController.dispose();
    super.dispose();
  }
}
