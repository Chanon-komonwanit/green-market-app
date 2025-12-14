// lib/screens/eco_coins/spin_wheel_screen.dart
// Lucky Spin Wheel - TikTok/Shopee style

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/eco_coins_enhanced_provider.dart';
import '../../models/eco_coin_enhanced.dart';
import '../../theme/app_colors.dart';

class SpinWheelScreen extends StatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isSpinning = false;
  MiniGameReward? _lastReward;

  final List<WheelSegment> _segments = [
    WheelSegment(coins: 10, color: Colors.red[400]!),
    WheelSegment(coins: 20, color: Colors.orange[400]!),
    WheelSegment(coins: 50, color: Colors.yellow[600]!),
    WheelSegment(coins: 100, color: Colors.green[400]!),
    WheelSegment(coins: 200, color: Colors.blue[400]!),
    WheelSegment(coins: 500, color: Colors.purple[400]!),
    WheelSegment(coins: 1000, color: Colors.pink[400]!, isJackpot: true),
    WheelSegment(coins: 30, color: Colors.teal[400]!),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
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
        title: const Text('วงล้อนำโชค'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: Consumer<EcoCoinsEnhancedProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoCard(provider),
                const SizedBox(height: 24),
                _buildWheel(),
                const SizedBox(height: 32),
                _buildSpinButton(provider),
                if (_lastReward != null) ...[
                  const SizedBox(height: 24),
                  _buildLastRewardCard(),
                ],
                const SizedBox(height: 24),
                _buildStatsCard(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(EcoCoinsEnhancedProvider provider) {
    return Card(
      color: AppColors.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'โอกาสในการหมุนวันนี้',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.hasPlayedGameToday ? '0 / 1' : '1 / 1',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.casino,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
            if (provider.hasPlayedGameToday) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info, color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'คุณได้หมุนวงล้อวันนี้แล้ว กลับมาใหม่พรุ่งนี้!',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
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

  Widget _buildWheel() {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _animation.value * 10 * math.pi,
              child: CustomPaint(
                size: const Size(300, 300),
                painter: WheelPainter(segments: _segments),
              ),
            );
          },
        ),
        // Center pointer
        Positioned(
          top: -10,
          child: Transform.rotate(
            angle: math.pi,
            child: const Icon(
              Icons.arrow_drop_down,
              size: 60,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black45,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
        // Center button
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'SPIN',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpinButton(EcoCoinsEnhancedProvider provider) {
    final canSpin = !provider.hasPlayedGameToday && !_isSpinning;

    return ElevatedButton(
      onPressed: canSpin ? () => _spinWheel(provider) : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        disabledBackgroundColor: Colors.grey[300],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isSpinning ? Icons.hourglass_bottom : Icons.casino,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            _isSpinning
                ? 'กำลังหมุน...'
                : canSpin
                    ? 'หมุนวงล้อ (ฟรี!)'
                    : 'หมดโอกาสวันนี้',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastRewardCard() {
    if (_lastReward == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: _lastReward!.isJackpot
                ? [Colors.amber, Colors.orange]
                : [Colors.green[400]!, Colors.green[600]!],
          ),
        ),
        child: Column(
          children: [
            if (_lastReward!.isJackpot)
              const Text(
                '🎊 JACKPOT! 🎊',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            Text(
              'คุณได้รับ',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_lastReward!.coinsWon}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'เหรียญ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(EcoCoinsEnhancedProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'สถิติการเล่น',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.casino,
                  label: 'รวมการหมุน',
                  value: '${provider.totalGamesPlayed}',
                ),
                _buildStatItem(
                  icon: Icons.emoji_events,
                  label: 'Jackpot',
                  value: '0',
                  color: Colors.amber,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color ?? AppColors.primary, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Future<void> _spinWheel(EcoCoinsEnhancedProvider provider) async {
    setState(() => _isSpinning = true);

    _controller.reset();
    await _controller.forward();

    final reward = await provider.playSpinWheel();
    if (reward != null && mounted) {
      setState(() {
        _lastReward = reward;
        _isSpinning = false;
      });

      await Future.delayed(const Duration(milliseconds: 500));
      _showRewardDialog(reward);
    } else {
      setState(() => _isSpinning = false);
    }
  }

  void _showRewardDialog(MiniGameReward reward) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          reward.isJackpot ? '🎊 JACKPOT! 🎊' : '🎉 ยินดีด้วย!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              reward.isJackpot ? Icons.emoji_events : Icons.stars,
              size: 80,
              color: reward.isJackpot ? Colors.amber : Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              'คุณได้รับ',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '${reward.coinsWon}',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const Text(
              'เหรียญ Eco',
              style: TextStyle(fontSize: 18),
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

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('วิธีการเล่น'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('📍 กติกา:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• หมุนได้ฟรี 1 ครั้งต่อวัน'),
              Text('• สุ่มรับเหรียญ 10-1000'),
              Text('• โอกาส Jackpot 1000 เหรียญ!'),
              SizedBox(height: 16),
              Text('🎁 รางวัล:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• 10 เหรียญ - โอกาส 30%'),
              Text('• 20-50 เหรียญ - โอกาส 50%'),
              Text('• 100-500 เหรียญ - โอกาส 19%'),
              Text('• 1000 เหรียญ - โอกาส 1% 💎'),
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
}

class WheelSegment {
  final int coins;
  final Color color;
  final bool isJackpot;

  WheelSegment({
    required this.coins,
    required this.color,
    this.isJackpot = false,
  });
}

class WheelPainter extends CustomPainter {
  final List<WheelSegment> segments;

  WheelPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = (2 * math.pi) / segments.length;

    for (var i = 0; i < segments.length; i++) {
      final startAngle = i * segmentAngle - math.pi / 2;
      final paint = Paint()
        ..color = segments[i].color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        paint,
      );

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        borderPaint,
      );

      // Draw text
      final textAngle = startAngle + segmentAngle / 2;
      final textRadius = radius * 0.7;
      final textX = center.dx + textRadius * math.cos(textAngle);
      final textY = center.dy + textRadius * math.sin(textAngle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${segments[i].coins}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black45,
                blurRadius: 4,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          textX - textPainter.width / 2,
          textY - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
