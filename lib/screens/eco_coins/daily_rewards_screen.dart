// lib/screens/eco_coins/daily_rewards_screen.dart
// Daily Check-in Screen - Shopee-style

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/eco_coins_enhanced_provider.dart';
import '../../models/eco_coin_enhanced.dart';
import '../../theme/app_colors.dart';

class DailyRewardsScreen extends StatefulWidget {
  const DailyRewardsScreen({super.key});

  @override
  State<DailyRewardsScreen> createState() => _DailyRewardsScreenState();
}

class _DailyRewardsScreenState extends State<DailyRewardsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เช็คอินรายวัน'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: Consumer<EcoCoinsEnhancedProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingCheckIn) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadCheckInStatus(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStreakCard(provider),
                  const SizedBox(height: 16),
                  _buildCheckInCalendar(provider),
                  const SizedBox(height: 16),
                  _buildCheckInButton(provider),
                  const SizedBox(height: 24),
                  _buildHistorySection(provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStreakCard(EcoCoinsEnhancedProvider provider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'สตรีคปัจจุบัน',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: Colors.orange,
                          size: 32,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${provider.currentStreak} วัน',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (provider.hasCheckedInToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.check_circle, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'เช็คอินแล้ว',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(7, (index) {
                final day = index + 1;
                final isCompleted = day <= provider.currentStreak;
                final isCurrent = day == provider.currentStreak + 1 &&
                    !provider.hasCheckedInToday;

                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.white
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: isCurrent
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'วัน $day',
                          style: TextStyle(
                            color: isCompleted
                                ? AppColors.primary
                                : Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          isCompleted
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: isCompleted
                              ? AppColors.primary
                              : Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '+${_getRewardForDay(day)}',
                          style: TextStyle(
                            color: isCompleted
                                ? AppColors.primary
                                : Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInCalendar(EcoCoinsEnhancedProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ปฏิทินเช็คอิน',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: 28,
              itemBuilder: (context, index) {
                final date =
                    DateTime.now().subtract(Duration(days: 27 - index));
                final isCheckedIn = provider.checkInHistory
                    .any((checkIn) => _isSameDay(checkIn.checkInDate, date));
                final isToday = _isSameDay(date, DateTime.now());

                return Container(
                  decoration: BoxDecoration(
                    color: isCheckedIn
                        ? AppColors.primary.withOpacity(0.2)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                        ? Border.all(color: AppColors.primary, width: 2)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isCheckedIn
                              ? AppColors.primary
                              : Colors.grey[600],
                        ),
                      ),
                      if (isCheckedIn)
                        Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 16,
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInButton(EcoCoinsEnhancedProvider provider) {
    if (provider.hasCheckedInToday) {
      return Card(
        color: Colors.green[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700], size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'เช็คอินวันนี้แล้ว!',
                      style: TextStyle(
                        color: Colors.green[900],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'กลับมาใหม่พรุ่งนี้ค่ะ',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 14,
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

    return ScaleTransition(
      scale: _scaleAnimation,
      child: ElevatedButton(
        onPressed: () => _performCheckIn(provider),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.touch_app, size: 28),
            const SizedBox(width: 12),
            Text(
              'เช็คอินวันนี้ รับ ${_getRewardForDay(provider.currentStreak + 1)} เหรียญ',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(EcoCoinsEnhancedProvider provider) {
    if (provider.checkInHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ประวัติการเช็คอิน',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...provider.checkInHistory.take(10).map((checkIn) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Icon(
                  Icons.calendar_today,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              title: Text(
                DateFormat('dd/MM/yyyy').format(checkIn.checkInDate),
              ),
              subtitle: Text('สตรีค: ${checkIn.streakCount} วัน'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${checkIn.coinsEarned}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _performCheckIn(EcoCoinsEnhancedProvider provider) async {
    _controller.forward().then((_) => _controller.reverse());

    final success = await provider.performCheckIn();
    if (success && mounted) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🎉 เช็คอินสำเร็จ!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'คุณได้รับเหรียญเพิ่มแล้ว',
              style: TextStyle(fontSize: 16),
            ),
            const Text(
              'กลับมาเช็คอินพรุ่งนี้เพื่อสตรีคต่อเนื่อง!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('เยี่ยม!'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ข้อมูลการเช็คอิน'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('วิธีการเช็คอิน:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• เช็คอินทุกวันเพื่อสะสมสตรีค'),
              Text('• สตรีคยิ่งยาว รับเหรียญยิ่งเยอะ'),
              Text('• วัน 7 รับเหรียญโบนัส 100!'),
              SizedBox(height: 16),
              Text('รางวัลตามวัน:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('วัน 1: 5 เหรียญ'),
              Text('วัน 2: 10 เหรียญ'),
              Text('วัน 3: 15 เหรียญ'),
              Text('วัน 4: 20 เหรียญ'),
              Text('วัน 5: 30 เหรียญ'),
              Text('วัน 6: 50 เหรียญ'),
              Text('วัน 7: 100 เหรียญ 🎉'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('เข้าใจแล้ว'),
          ),
        ],
      ),
    );
  }

  int _getRewardForDay(int day) {
    const rewards = [5, 10, 15, 20, 30, 50, 100];
    return rewards[(day - 1).clamp(0, 6)];
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

