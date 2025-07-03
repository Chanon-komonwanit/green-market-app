// lib/screens/eco_rewards_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:green_market/models/eco_reward.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/widgets/enhanced_eco_coins_widget.dart';

class EcoRewardsScreen extends StatefulWidget {
  const EcoRewardsScreen({super.key});

  @override
  State<EcoRewardsScreen> createState() => _EcoRewardsScreenState();
}

class _EcoRewardsScreenState extends State<EcoRewardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isRedeeming = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // เพิ่มเป็น 3 tabs
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FDF8),
      appBar: AppBar(
        title: const Text(
          'รางวัล Eco Coins',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
              icon: Icon(Icons.login),
              text: 'ล็อกอินรับเหรียญ',
            ),
            Tab(
              icon: Icon(Icons.card_giftcard),
              text: 'รางวัลทั้งหมด',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'ประวัติการแลก',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Eco Coins Status
          Container(
            margin: const EdgeInsets.all(16),
            child: const EnhancedEcoCoinsWidget(),
          ),

          // โซนแรกรางวัลเด่น (Featured Rewards)
          _buildFeaturedRewardsSection(),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLoginRewardTab(), // เพิ่มแท็บล็อกอินรับเหรียญ
                _buildRewardsTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // แท็บล็อกอินรับเหรียญ (ปลอดภัยต่อการแฮ็ก)
  Widget _buildLoginRewardTab() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final currentUser = userProvider.currentUser;

        if (currentUser == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.login, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text('กรุณาเข้าสู่ระบบเพื่อรับเหรียญ',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // การ์ดสถานะล็อกอินประจำวัน
              _buildDailyLoginCard(currentUser),

              const SizedBox(height: 16),

              // การ์ดเงื่อนไขและความปลอดภัย
              _buildSecurityInfoCard(),

              const SizedBox(height: 16),

              // ประวัติการได้รับเหรียญ
              _buildLoginHistoryCard(currentUser),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDailyLoginCard(currentUser) {
    final now = DateTime.now();
    final lastLogin = currentUser.lastLoginDate;
    final consecutiveDays = currentUser.consecutiveLoginDays ?? 0;

    // ตรวจสอบว่าสามารถรับเหรียญได้หรือไม่ (ปลอดภัยด้วย server-side validation)
    final canClaimToday = _canClaimDailyReward(lastLogin, now);
    final daysUntilReward = 15 - (consecutiveDays % 15);
    final progressPercent = (consecutiveDays % 15) / 15.0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF43A047).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ล็อกอินประจำวัน',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ล็อกอิน 1 วัน = 0.1 เหรียญ (ครบ 15 วัน = 1 เหรียญ)',
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

            const SizedBox(height: 24),

            // Progress Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progressPercent,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 8,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ล็อกอินติดต่อกัน: $consecutiveDays วัน',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'อีก $daysUntilReward วัน',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ปุ่มรับเหรียญ
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canClaimToday && !_isRedeeming
                    ? () => _claimDailyReward(currentUser)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      canClaimToday ? Colors.white : Colors.white30,
                  foregroundColor:
                      canClaimToday ? const Color(0xFF43A047) : Colors.white70,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isRedeeming
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        canClaimToday ? 'รับเหรียญวันนี้' : 'รับแล้ววันนี้',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            if (consecutiveDays >= 15) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events,
                        color: Colors.yellow, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'คุณสามารถรับเหรียญได้ ${(consecutiveDays / 15).floor()} เหรียญ!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.security,
                    color: Color(0xFF1976D2),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'ระบบความปลอดภัย',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E2E2E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'เราใช้ระบบความปลอดภัยระดับสูงเพื่อป้องกันการโกงและแฮ็ก:',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildSecurityItem(
                '🔒 Server-side Validation: ตรวจสอบที่เซิร์ฟเวอร์'),
            _buildSecurityItem('⏰ Time Verification: ตรวจสอบเวลาจริง'),
            _buildSecurityItem('🔍 Anti-Cheat Detection: ตรวจจับการโกง'),
            _buildSecurityItem('📱 Device Fingerprinting: ตรวจสอบอุปกรณ์'),
            _buildSecurityItem('🛡️ Rate Limiting: จำกัดการเรียกใช้'),
            _buildSecurityItem('📊 Audit Logging: บันทึกการใช้งาน'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: const Color(0xFFFFB74D).withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Color(0xFFFF8F00), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'การพยายามโกงหรือแฮ็กระบบจะถูกบันทึกและอาจทำให้บัญชีถูกระงับ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFE65100),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginHistoryCard(currentUser) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF43A047).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.history,
                    color: Color(0xFF43A047),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'สถิติการรับเหรียญ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E2E2E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'เหรียญทั้งหมด',
                    '${currentUser.ecoCoins ?? 0}',
                    Icons.eco,
                    const Color(0xFFB8860B),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'ล็อกอินติดต่อกัน',
                    '${currentUser.consecutiveLoginDays ?? 0} วัน',
                    Icons.calendar_today,
                    const Color(0xFF43A047),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'เหรียญจากล็อกอิน',
                    '${((currentUser.consecutiveLoginDays ?? 0) / 15).floor()}',
                    Icons.login,
                    const Color(0xFF1976D2),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'ล็อกอินครั้งล่าสุด',
                    currentUser.lastLoginDate != null
                        ? _formatDate(currentUser.lastLoginDate!)
                        : 'ยังไม่เคย',
                    Icons.access_time,
                    const Color(0xFF9C27B0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ฟังก์ชันตรวจสอบว่าสามารถรับเหรียญได้หรือไม่ (ปลอดภัย)
  bool _canClaimDailyReward(DateTime? lastLogin, DateTime now) {
    if (lastLogin == null) return true;

    // ตรวจสอบว่าเป็นวันใหม่หรือไม่
    final lastLoginDate =
        DateTime(lastLogin.year, lastLogin.month, lastLogin.day);
    final todayDate = DateTime(now.year, now.month, now.day);

    return todayDate.isAfter(lastLoginDate);
  }

  // ฟังก์ชันรับเหรียญประจำวัน (ปลอดภัยด้วย server validation)
  Future<void> _claimDailyReward(currentUser) async {
    setState(() {
      _isRedeeming = true;
    });

    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // เรียกใช้ฟังก์ชันที่ปลอดภัยจาก Firebase Service
      final result =
          await firebaseService.claimDailyLoginReward(currentUser.id);

      if (result['success'] == true) {
        // รีเฟรชข้อมูลผู้ใช้
        await userProvider.loadUserData(currentUser.id);

        final message = result['message'] ?? '';

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: const Color(0xFF43A047),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        final errorMessage = result['message'] ?? 'ไม่สามารถรับเหรียญได้';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRedeeming = false;
        });
      }
    }
  }

  // โซนแรกรางวัลเด่น
  Widget _buildFeaturedRewardsSection() {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // หัวข้อโซนแรกรางวัล
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFF8DC)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.stars,
                  color: Color(0xFFB8860B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'แรกรางวัลเด่น',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // เปลี่ยนไปแท็บรางวัลทั้งหมด
                  _tabController.animateTo(1);
                },
                child: const Text(
                  'ดูทั้งหมด',
                  style: TextStyle(
                    color: Color(0xFF43A047),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // รายการแรกรางวัลแนวนอน
          StreamBuilder<List<EcoReward>>(
            stream: firebaseService.getEcoRewards(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('ไม่สามารถโหลดรางวัลได้'),
                  ),
                );
              }

              final rewards = snapshot.data ?? [];

              if (rewards.isEmpty) {
                return Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.card_giftcard_outlined,
                            size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('ยังไม่มีรางวัลในขณะนี้',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }

              // เลือกรางวัล 3-5 อันแรกสำหรับแสดงในโซนเด่น
              final featuredRewards = rewards.take(4).toList();

              return SizedBox(
                height: 280,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: featuredRewards.length,
                  itemBuilder: (context, index) {
                    final reward = featuredRewards[index];
                    return _buildFeaturedRewardCard(reward, index == 0);
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // การ์ดรางวัลแบบเด่น (แนวนอน)
  Widget _buildFeaturedRewardCard(EcoReward reward, bool isFirst) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final currentUser = userProvider.currentUser;
        final userCoins = currentUser?.ecoCoins ?? 0.0;
        final canRedeem =
            userCoins >= reward.requiredCoins && reward.isAvailable;

        return Container(
          width: isFirst ? 220 : 180, // การ์ดแรกใหญ่กว่า
          margin: EdgeInsets.only(
            right: 12,
            left: isFirst ? 0 : 0,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isFirst
                    ? const Color(0xFFFFD700).withOpacity(0.3)
                    : Colors.black.withOpacity(0.1),
                blurRadius: isFirst ? 15 : 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: isFirst
                ? Border.all(color: const Color(0xFFFFD700), width: 2)
                : Border.all(color: Colors.grey[200]!, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ป้าย "เด่น" สำหรับรางวัลแรก
              if (isFirst)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                    ),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(14)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'แรกแนะนำ',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

              // รูปรางวัล
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: isFirst
                      ? const Radius.circular(14)
                      : const Radius.circular(14),
                ),
                child: AspectRatio(
                  aspectRatio: isFirst ? 16 / 10 : 16 / 12,
                  child: reward.imageUrl.isNotEmpty
                      ? Image.network(
                          reward.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[100],
                              child: const Center(
                                child: Icon(Icons.card_giftcard,
                                    size: 40, color: Colors.grey),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[100],
                          child: const Center(
                            child: Icon(Icons.card_giftcard,
                                size: 40, color: Colors.grey),
                          ),
                        ),
                ),
              ),

              // ข้อมูลรางวัล
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reward.title,
                        style: TextStyle(
                          fontSize: isFirst ? 16 : 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E2E2E),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // เหรียญที่ต้องใช้
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFF8DC)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFB8860B), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.eco,
                                color: Color(0xFFB8860B), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${reward.requiredCoins}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB8860B),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // ปุ่มแลก
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: canRedeem && !_isRedeeming
                              ? () => _redeemReward(reward)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canRedeem
                                ? (isFirst
                                    ? const Color(0xFFFFD700)
                                    : const Color(0xFF43A047))
                                : Colors.grey,
                            foregroundColor: isFirst
                                ? const Color(0xFFB8860B)
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            canRedeem ? 'แลก' : 'ไม่พอ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isFirst ? 14 : 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRewardsTab() {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return StreamBuilder<List<EcoReward>>(
      stream: firebaseService.getEcoRewards(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
              ],
            ),
          );
        }

        final rewards = snapshot.data ?? [];

        if (rewards.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.card_giftcard_outlined,
                    size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('ยังไม่มีรางวัลในขณะนี้',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
                SizedBox(height: 8),
                Text('รางวัลใหม่จะเพิ่มเร็วๆ นี้',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rewards.length,
          itemBuilder: (context, index) {
            final reward = rewards[index];
            return _buildRewardCard(reward);
          },
        );
      },
    );
  }

  Widget _buildRewardCard(EcoReward reward) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final currentUser = userProvider.currentUser;
        final userCoins = currentUser?.ecoCoins ?? 0;
        final canRedeem =
            userCoins >= reward.requiredCoins && reward.isAvailable;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: canRedeem
                  ? const Color(0xFF43A047).withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // รูปรางวัล
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: reward.imageUrl.isNotEmpty
                      ? Image.network(
                          reward.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[100],
                              child: const Center(
                                child: Icon(
                                  Icons.card_giftcard,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[100],
                          child: const Center(
                            child: Icon(
                              Icons.card_giftcard,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                ),
              ),

              // ข้อมูลรางวัล
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            reward.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E2E2E),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFF8DC)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFB8860B),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.eco,
                                color: Color(0xFFB8860B),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${reward.requiredCoins}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB8860B),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Text(
                      reward.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // สถานะและจำนวน
                    Row(
                      children: [
                        if (reward.quantity > 0) ...[
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'เหลือ ${reward.remainingQuantity}/${reward.quantity}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getRewardTypeColor(reward.rewardType)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getRewardTypeText(reward.rewardType),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getRewardTypeColor(reward.rewardType),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ปุ่มแลก
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: canRedeem && !_isRedeeming
                            ? () => _redeemReward(reward)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              canRedeem ? const Color(0xFF43A047) : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isRedeeming
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                canRedeem
                                    ? 'แลกรางวัล'
                                    : userCoins < reward.requiredCoins
                                        ? 'เหรียญไม่เพียงพอ'
                                        : 'ไม่สามารถแลกได้',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;

    if (currentUser == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text('กรุณาเข้าสู่ระบบ', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return StreamBuilder<List<RewardRedemption>>(
      stream: firebaseService.getUserRedemptions(currentUser.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
              ],
            ),
          );
        }

        final redemptions = snapshot.data ?? [];

        if (redemptions.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('ยังไม่มีประวัติการแลกรางวัล',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: redemptions.length,
          itemBuilder: (context, index) {
            final redemption = redemptions[index];
            return _buildRedemptionCard(redemption);
          },
        );
      },
    );
  }

  Widget _buildRedemptionCard(RewardRedemption redemption) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getStatusColor(redemption.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getStatusIcon(redemption.status),
            color: _getStatusColor(redemption.status),
            size: 24,
          ),
        ),
        title: Text(
          redemption.rewardTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.eco, size: 16, color: Color(0xFFB8860B)),
                const SizedBox(width: 4),
                Text(
                  '${redemption.coinsUsed} เหรียญ',
                  style: const TextStyle(
                    color: Color(0xFFB8860B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  _formatDate(redemption.redeemedAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(redemption.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getStatusText(redemption.status),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(redemption.status),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _redeemReward(EcoReward reward) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;

    if (currentUser == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ยืนยันการแลกรางวัล'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('คุณต้องการแลกรางวัล "${reward.title}" หรือไม่?'),
            const SizedBox(height: 8),
            Text('ใช้เหรียญ: ${reward.requiredCoins} เหรียญ'),
            Text('เหรียญที่มี: ${currentUser.ecoCoins} เหรียญ'),
            Text(
                'เหรียญคงเหลือ: ${currentUser.ecoCoins - reward.requiredCoins} เหรียญ'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF43A047),
              foregroundColor: Colors.white,
            ),
            child: const Text('แลกเลย'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isRedeeming = true;
    });

    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      await firebaseService.redeemEcoReward(currentUser.id, reward.id);

      // รีเฟรชข้อมูลผู้ใช้
      await userProvider.loadUserData(currentUser.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('แลกรางวัล "${reward.title}" สำเร็จ!'),
            backgroundColor: const Color(0xFF43A047),
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
      if (mounted) {
        setState(() {
          _isRedeeming = false;
        });
      }
    }
  }

  Color _getRewardTypeColor(String type) {
    switch (type) {
      case 'physical':
        return const Color(0xFF2E7D32);
      case 'digital':
        return const Color(0xFF1976D2);
      case 'discount':
        return const Color(0xFFE91E63);
      case 'service':
        return const Color(0xFFFF6F00);
      default:
        return Colors.grey;
    }
  }

  String _getRewardTypeText(String type) {
    switch (type) {
      case 'physical':
        return 'ของจริง';
      case 'digital':
        return 'ดิจิทัล';
      case 'discount':
        return 'ส่วนลด';
      case 'service':
        return 'บริการ';
      default:
        return 'อื่นๆ';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'approved':
        return const Color(0xFF2196F3);
      case 'delivered':
        return const Color(0xFF4CAF50);
      case 'cancelled':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'approved':
        return Icons.check_circle_outline;
      case 'delivered':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'รอดำเนินการ';
      case 'approved':
        return 'อนุมัติแล้ว';
      case 'delivered':
        return 'ส่งแล้ว';
      case 'cancelled':
        return 'ยกเลิก';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Helper widget สำหรับแสดงรายการความปลอดภัย
  Widget _buildSecurityItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
