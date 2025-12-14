// lib/screens/coupons/coupon_center_screen.dart
// Coupon Center - Browse all available coupons

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/platform_coupon_provider.dart';
import '../../models/platform_coupon.dart';
import '../../theme/app_colors.dart';
import '../../models/advanced_coupon.dart';

class CouponCenterScreen extends StatefulWidget {
  const CouponCenterScreen({super.key});

  @override
  State<CouponCenterScreen> createState() => _CouponCenterScreenState();
}

class _CouponCenterScreenState extends State<CouponCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlatformCouponProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ศูนย์คูปอง'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'ทั้งหมด'),
            Tab(text: 'Flash Coupons'),
            Tab(text: 'สมาชิกพิเศษ'),
            Tab(text: 'ใกล้หมดอายุ'),
          ],
        ),
      ),
      body: Consumer<PlatformCouponProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildAllCoupons(provider),
              _buildFlashCoupons(provider),
              _buildMemberCoupons(provider),
              _buildExpiringSoon(provider),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/my-coupons'),
        icon: const Icon(Icons.loyalty),
        label: const Text('คูปองของฉัน'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildAllCoupons(PlatformCouponProvider provider) {
    if (provider.platformCoupons.isEmpty) {
      return _buildEmptyState('ไม่มีคูปองในขณะนี้');
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadPlatformCoupons(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.platformCoupons.length,
        itemBuilder: (context, index) {
          return _buildCouponCard(provider.platformCoupons[index], provider);
        },
      ),
    );
  }

  Widget _buildFlashCoupons(PlatformCouponProvider provider) {
    final flashCoupons = provider.flashCoupons;

    if (flashCoupons.isEmpty) {
      return _buildEmptyState('ไม่มี Flash Coupon ในขณะนี้');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: flashCoupons.length,
      itemBuilder: (context, index) {
        return _buildFlashCouponCard(flashCoupons[index], provider);
      },
    );
  }

  Widget _buildMemberCoupons(PlatformCouponProvider provider) {
    final memberCoupons = provider.getCouponsByType(
      PlatformCouponType.memberExclusive,
    );

    if (memberCoupons.isEmpty) {
      return _buildEmptyState('ไม่มีคูปองสมาชิกพิเศษ');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: memberCoupons.length,
      itemBuilder: (context, index) {
        return _buildCouponCard(memberCoupons[index], provider);
      },
    );
  }

  Widget _buildExpiringSoon(PlatformCouponProvider provider) {
    final expiringSoon = provider.getExpiringSoonCoupons();

    if (expiringSoon.isEmpty) {
      return _buildEmptyState('ไม่มีคูปองที่ใกล้หมดอายุ');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: expiringSoon.length,
      itemBuilder: (context, index) {
        return _buildCouponCard(expiringSoon[index], provider);
      },
    );
  }

  Widget _buildCouponCard(PlatformCoupon coupon, PlatformCouponProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showCouponDetails(coupon, provider),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _getCouponColor(coupon.platformType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getCouponIcon(coupon.platformType),
                      color: _getCouponColor(coupon.platformType),
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getDiscountText(coupon),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getCouponColor(coupon.platformType),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coupon.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      coupon.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          coupon.endDate != null
                              ? 'ถึง ${DateFormat('dd/MM/yy').format(coupon.endDate!)}'
                              : 'ไม่มีกำหนด',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _claimCoupon(coupon, provider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('รับ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlashCouponCard(PlatformCoupon coupon, PlatformCouponProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.orange[400]!, Colors.red[400]!],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.flash_on, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'FLASH COUPON',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (coupon.isAlmostGone)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ใกล้หมด!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                coupon.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getDiscountText(coupon),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (coupon.maxClaimsGlobal != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'จำนวนคงเหลือ',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          '${coupon.claimPercentage.toInt()}% ถูกรับไปแล้ว',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: coupon.claimPercentage / 100,
                      backgroundColor: Colors.white30,
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: provider.isClaiming
                      ? null
                      : () => _huntFlashCoupon(coupon, provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'รีบรับเลย!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.loyalty, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Future<void> _claimCoupon(
    PlatformCoupon coupon,
    PlatformCouponProvider provider,
  ) async {
    final success = await provider.claimCoupon(coupon.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('รับคูปองสำเร็จ!')),
      );
    } else if (mounted && provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!)),
      );
    }
  }

  Future<void> _huntFlashCoupon(
    PlatformCoupon coupon,
    PlatformCouponProvider provider,
  ) async {
    final success = await provider.huntFlashCoupon(coupon.id);
    if (success && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('🎉 ยินดีด้วย!'),
          content: const Text('คุณได้รับ Flash Coupon แล้ว!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('เยี่ยม!'),
            ),
          ],
        ),
      );
    } else if (mounted && provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCouponDetails(PlatformCoupon coupon, PlatformCouponProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  coupon.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow('ส่วนลด', _getDiscountText(coupon)),
                _buildDetailRow(
                  'ยอดขั้นต่ำ',
                  '฿${coupon.minPurchase.toStringAsFixed(0)}',
                ),
                if (coupon.maxDiscount > 0)
                  _buildDetailRow(
                    'ส่วนลดสูงสุด',
                    '฿${coupon.maxDiscount.toStringAsFixed(0)}',
                  ),
                _buildDetailRow(
                  'ใช้ได้ถึง',
                  coupon.endDate != null
                      ? DateFormat('dd/MM/yyyy').format(coupon.endDate!)
                      : 'ไม่มีกำหนด',
                ),
                const SizedBox(height: 16),
                const Text(
                  'รายละเอียด',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(coupon.description),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _claimCoupon(coupon, provider);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'รับคูปอง',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _getDiscountText(PlatformCoupon coupon) {
    switch (coupon.type) {
      case CouponType.percentage:
        return '${coupon.value.toInt()}%';
      case CouponType.fixedAmount:
        return '฿${coupon.value.toInt()}';
      case CouponType.freeShipping:
        return 'ส่งฟรี';
      case CouponType.buyXGetY:
        return 'Buy X Get Y';
    }
  }

  IconData _getCouponIcon(PlatformCouponType type) {
    switch (type) {
      case PlatformCouponType.welcome:
        return Icons.waving_hand;
      case PlatformCouponType.festival:
        return Icons.celebration;
      case PlatformCouponType.flash:
        return Icons.flash_on;
      case PlatformCouponType.memberExclusive:
        return Icons.workspace_premium;
      case PlatformCouponType.ecoHeroReward:
        return Icons.eco;
      case PlatformCouponType.referral:
        return Icons.people;
      case PlatformCouponType.apology:
        return Icons.favorite;
      case PlatformCouponType.birthday:
        return Icons.cake;
      case PlatformCouponType.anniversary:
        return Icons.star;
      case PlatformCouponType.vipMonthly:
        return Icons.diamond;
    }
  }

  Color _getCouponColor(PlatformCouponType type) {
    switch (type) {
      case PlatformCouponType.welcome:
        return Colors.blue;
      case PlatformCouponType.festival:
        return Colors.purple;
      case PlatformCouponType.flash:
        return Colors.orange;
      case PlatformCouponType.memberExclusive:
        return Colors.amber;
      case PlatformCouponType.ecoHeroReward:
        return Colors.green;
      case PlatformCouponType.referral:
        return Colors.teal;
      case PlatformCouponType.apology:
        return Colors.pink;
      case PlatformCouponType.birthday:
        return Colors.red;
      case PlatformCouponType.anniversary:
        return Colors.indigo;
      case PlatformCouponType.vipMonthly:
        return Colors.deepPurple;
    }
  }
}


