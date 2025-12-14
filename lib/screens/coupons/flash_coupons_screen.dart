import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/platform_coupon_provider.dart';
import '../../models/platform_coupon.dart';
import '../../models/advanced_coupon.dart';
import '../../theme/app_colors.dart';

class FlashCouponsScreen extends StatefulWidget {
  const FlashCouponsScreen({super.key});
  @override
  State<FlashCouponsScreen> createState() => _FlashCouponsScreenState();
}

class _FlashCouponsScreenState extends State<FlashCouponsScreen> {
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlatformCouponProvider>().initialize();
    });
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(' Flash Sale คูปอง'),
        backgroundColor: Colors.red,
        elevation: 0,
      ),
      body: Consumer<PlatformCouponProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.red));
          }
          
          final flashCoupons = provider.flashCoupons;
          if (flashCoupons.isEmpty) {
            return const Center(child: Text('ยังไม่มี Flash Sale'));
          }
          
          return RefreshIndicator(
            onRefresh: () async => await provider.initialize(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: flashCoupons.length,
              itemBuilder: (context, index) => _buildFlashCouponCard(flashCoupons[index], provider),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildFlashCouponCard(PlatformCoupon coupon, PlatformCouponProvider provider) {
    final timeLeft = coupon.endDate != null ? coupon.endDate!.difference(DateTime.now()) : Duration.zero;
    final isAlmostGone = coupon.maxClaimsGlobal != null && coupon.maxClaimsGlobal! > 0 && (coupon.currentClaimsGlobal / coupon.maxClaimsGlobal!) > 0.8;
    final isClaimed = provider.claimedCoupons.any((c) => c.id == coupon.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red[700]!, Colors.red[500]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => _showFlashCouponDetails(coupon, provider, isClaimed),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flash_on, color: Colors.yellow, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        coupon.name,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      'ลด ${coupon.value.toStringAsFixed(0)}${coupon.type == CouponType.percentage ? '%' : '฿'}',
                      style: const TextStyle(color: Colors.yellow, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(' เหลือเวลา', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text(
                            _formatDuration(timeLeft),
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (coupon.maxClaimsGlobal != null && coupon.maxClaimsGlobal! > 0) Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isAlmostGone ? ' ใกล้หมด!' : 'เหลือ',
                            style: TextStyle(color: isAlmostGone ? Colors.yellow : Colors.white70, fontSize: 12, fontWeight: isAlmostGone ? FontWeight.bold : FontWeight.normal),
                          ),
                          Text(
                            '${coupon.maxClaimsGlobal! - coupon.currentClaimsGlobal}/${coupon.maxClaimsGlobal}',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (coupon.maxClaimsGlobal != null && coupon.maxClaimsGlobal! > 0) LinearProgressIndicator(
                  value: coupon.currentClaimsGlobal / coupon.maxClaimsGlobal!,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.yellow),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: isClaimed ? null : () => _claimFlashCoupon(coupon, provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                    foregroundColor: Colors.red[900],
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  child: Text(isClaimed ? 'รับแล้ว ' : ' รับทันที!', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  String _formatDuration(Duration duration) {
    if (duration.isNegative) return 'หมดเวลา';
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  void _claimFlashCoupon(PlatformCoupon coupon, PlatformCouponProvider provider) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(' รับคูปองสำเร็จ!'), backgroundColor: Colors.green));
  }
  
  void _showFlashCouponDetails(PlatformCoupon coupon, PlatformCouponProvider provider, bool isClaimed) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flash_on, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text(coupon.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 16),
            Text(coupon.description),
            const SizedBox(height: 16),
            Text(' ขั้นต่ำ: ${coupon.minPurchase.toStringAsFixed(0)}฿', style: const TextStyle(fontWeight: FontWeight.bold)),
            if (coupon.maxDiscount > 0) Text(' ส่วนลดสูงสุด: ${coupon.maxDiscount.toStringAsFixed(0)}฿'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isClaimed ? null : () {
                Navigator.pop(context);
                _claimFlashCoupon(coupon, provider);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size(double.infinity, 48)),
              child: Text(isClaimed ? 'รับแล้ว' : ' รับเลย!'),
            ),
          ],
        ),
      ),
    );
  }
}