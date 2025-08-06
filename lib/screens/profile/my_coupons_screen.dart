// lib/screens/profile/my_coupons_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:green_market/providers/coupon_provider.dart';
import 'package:green_market/models/user_coupon.dart';
import 'package:green_market/theme/app_colors.dart';

class MyCouponsScreen extends StatefulWidget {
  const MyCouponsScreen({super.key});

  @override
  State<MyCouponsScreen> createState() => _MyCouponsScreenState();
}

class _MyCouponsScreenState extends State<MyCouponsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CouponProvider>().loadUserCoupons();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'โค้ดของฉัน',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showAddCouponDialog,
            icon: const Icon(Icons.add),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'ใช้ได้'),
            Tab(text: 'ใช้แล้ว'),
            Tab(text: 'หมดอายุ'),
          ],
        ),
      ),
      body: Consumer<CouponProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildCouponList(provider.availableCoupons),
              _buildCouponList(provider.usedCoupons),
              _buildCouponList(provider.expiredCoupons),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCouponList(List<UserCoupon> coupons) {
    if (coupons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_offer_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'ไม่มีโค้ดส่วนลด',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: coupons.length,
      itemBuilder: (context, index) {
        return _buildCouponCard(coupons[index]);
      },
    );
  }

  Widget _buildCouponCard(UserCoupon coupon) {
    final promotion = coupon.promotion;
    final isAvailable = coupon.status == CouponStatus.available;
    final isUsed = coupon.status == CouponStatus.used;
    final isExpired = coupon.status == CouponStatus.expired;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: _getCouponGradient(coupon.status),
          ),
          child: Row(
            children: [
              // Left side - discount info
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (promotion.iconEmoji != null) ...[
                            Text(
                              promotion.iconEmoji!,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              promotion.discountText,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isExpired || isUsed
                                    ? Colors.grey[600]
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                          if (isUsed)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ใช้แล้ว',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          else if (isExpired)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'หมดอายุ',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        promotion.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isExpired || isUsed
                              ? Colors.grey[600]
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        promotion.conditionText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (promotion.endDate != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'หมดอายุ ${_formatDate(promotion.endDate!)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Right side - code and action
              Container(
                width: 80,
                height: 120,
                decoration: BoxDecoration(
                  gradient: _getCouponGradient(coupon.status),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (promotion.discountCode != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          promotion.discountCode!,
                          style: TextStyle(
                            color: isAvailable
                                ? AppColors.primary
                                : Colors.grey[600],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (isAvailable) ...[
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _copyCode(promotion.discountCode!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'คัดลอก',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  LinearGradient _getCouponGradient(CouponStatus status) {
    switch (status) {
      case CouponStatus.available:
        return LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.8),
            AppColors.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case CouponStatus.used:
        return LinearGradient(
          colors: [
            Colors.grey[400]!,
            Colors.grey[500]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case CouponStatus.expired:
        return LinearGradient(
          colors: [
            Colors.red[300]!,
            Colors.red[400]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case CouponStatus.disabled:
        return LinearGradient(
          colors: [
            Colors.grey[300]!,
            Colors.grey[400]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('คัดลอกโค้ด $code แล้ว'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showAddCouponDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เพิ่มโค้ดส่วนลด'),
        content: TextField(
          controller: _codeController,
          decoration: const InputDecoration(
            hintText: 'กรอกโค้ดส่วนลด',
            prefixIcon: Icon(Icons.local_offer),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: _addCoupon,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('เพิ่ม'),
          ),
        ],
      ),
    );
  }

  void _addCoupon() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    final provider = context.read<CouponProvider>();

    try {
      final coupon = await provider.findCouponByCode(code);
      if (coupon != null) {
        await provider.collectCoupon(coupon.promotion);
        if (mounted) {
          Navigator.pop(context);
          _codeController.clear();
          _showMessage('เพิ่มโค้ดส่วนลดสำเร็จ!', isError: false);
        }
      } else {
        _showMessage('ไม่พบโค้ดส่วนลดนี้');
      }
    } catch (e) {
      _showMessage('เกิดข้อผิดพลาด: ${e.toString()}');
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : AppColors.primary,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year + 543}';
  }
}
