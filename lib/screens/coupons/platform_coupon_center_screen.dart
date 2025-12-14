import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/platform_coupon_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/platform_coupon.dart';
import '../../models/advanced_coupon.dart';
import '../../theme/app_colors.dart';

class PlatformCouponCenterScreen extends StatefulWidget {
  const PlatformCouponCenterScreen({super.key});
  @override
  State<PlatformCouponCenterScreen> createState() => _PlatformCouponCenterScreenState();
}

class _PlatformCouponCenterScreenState extends State<PlatformCouponCenterScreen> with SingleTickerProviderStateMixin {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('คูปองแพลตฟอร์ม'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'ทั้งหมด'),
            Tab(text: 'Flash Sale'),
            Tab(text: 'ผู้ใช้ใหม่'),
            Tab(text: 'Eco Hero'),
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
              _buildCouponList(provider.platformCoupons, provider),
              _buildCouponList(provider.flashCoupons, provider),
              _buildCouponList(provider.platformCoupons.where((c) => c.isNewUserOnly).toList(), provider),
              _buildCouponList(provider.platformCoupons.where((c) => c.requiredTier != null).toList(), provider),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildCouponList(List<PlatformCoupon> coupons, PlatformCouponProvider provider) {
    if (coupons.isEmpty) {
      return const Center(child: Text('ไม่มีคูปอง'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: coupons.length,
      itemBuilder: (context, index) => _buildCouponCard(coupons[index], provider),
    );
  }
  
  Widget _buildCouponCard(PlatformCoupon coupon, PlatformCouponProvider provider) {
    final isClaimed = provider.claimedCoupons.any((c) => c.id == coupon.id);
    final progress = coupon.maxClaimsGlobal != null && coupon.maxClaimsGlobal! > 0 ? coupon.currentClaimsGlobal / coupon.maxClaimsGlobal! : 0.0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showCouponDetails(coupon, provider, isClaimed),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: coupon.platformType == PlatformCouponType.flash ? Colors.red : AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getTypeName(coupon.platformType),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  Text('ลด ${coupon.value.toStringAsFixed(0)}${coupon.type == CouponType.percentage ? '%' : '฿'}', 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 8),
              Text(coupon.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('ขั้นต่ำ ${coupon.minPurchase.toStringAsFixed(0)}฿', style: const TextStyle(color: Colors.grey)),
              if (coupon.maxClaimsGlobal != null && coupon.maxClaimsGlobal! > 0) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(value: progress, backgroundColor: Colors.grey[200], color: Colors.red),
                Text('เหลือ ${coupon.maxClaimsGlobal! - coupon.currentClaimsGlobal} ใบ', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  void _showCouponDetails(PlatformCoupon coupon, PlatformCouponProvider provider, bool isClaimed) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(coupon.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(coupon.description),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isClaimed ? null : () async {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('รับคูปองสำเร็จ!'), backgroundColor: Colors.green));
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(double.infinity, 48)),
              child: Text(isClaimed ? 'รับแล้ว' : 'รับคูปอง'),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getTypeName(PlatformCouponType type) {
    switch (type) {
      case PlatformCouponType.flash: return 'Flash';
      case PlatformCouponType.welcome: return 'ต้อนรับ';
      case PlatformCouponType.memberExclusive: return 'สมาชิก';
      case PlatformCouponType.ecoHeroReward: return 'Eco Hero';
      default: return 'คูปอง';
    }
  }
}