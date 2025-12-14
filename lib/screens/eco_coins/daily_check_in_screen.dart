import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/eco_coins_enhanced_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';

class DailyCheckInScreen extends StatefulWidget {
  const DailyCheckInScreen({super.key});
  @override
  State<DailyCheckInScreen> createState() => _DailyCheckInScreenState();
}

class _DailyCheckInScreenState extends State<DailyCheckInScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.uid ?? '';
      if (userId.isNotEmpty) {
        context.read<EcoCoinsEnhancedProvider>().initialize(userId);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เช็คอินรายวัน'),
        elevation: 0,
        backgroundColor: AppColors.primary,
      ),
      body: Consumer<EcoCoinsEnhancedProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingCheckIn) return const Center(child: CircularProgressIndicator());
          
          final canCheckIn = !provider.hasCheckedInToday;
          final streak = provider.currentStreak;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStreakCard(streak),
                const SizedBox(height: 16),
                _buildCheckInButton(context, provider, canCheckIn),
                const SizedBox(height: 24),
                _buildWeeklyProgress(provider),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildStreakCard(int streak) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.local_fire_department, color: Colors.orange, size: 48),
          const SizedBox(height: 8),
          Text('$streak วัน', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const Text('สตรีคต่อเนื่อง', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
  
  Widget _buildCheckInButton(BuildContext context, EcoCoinsEnhancedProvider provider, bool canCheckIn) {
    return ElevatedButton(
      onPressed: canCheckIn ? () async {
        final success = await provider.performCheckIn();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'เช็คอินสำเร็จ! +10 คะแนน' : 'เช็คอินไม่สำเร็จ'), backgroundColor: success ? Colors.green : Colors.red));
        }
      } : null,
      style: ElevatedButton.styleFrom(backgroundColor: canCheckIn ? AppColors.primary : Colors.grey, minimumSize: const Size(double.infinity, 56)),
      child: Text(canCheckIn ? 'เช็คอินวันนี้' : 'เช็คอินแล้วในวันนี้ '),
    );
  }
  
  Widget _buildWeeklyProgress(EcoCoinsEnhancedProvider provider) {
    return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Weekly Progress Placeholder')));
  }
}