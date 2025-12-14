import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/eco_coins_enhanced_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/eco_coin_enhanced.dart';
import '../../theme/app_colors.dart';

class RedemptionRewardsScreen extends StatefulWidget {
  const RedemptionRewardsScreen({super.key});
  @override
  State<RedemptionRewardsScreen> createState() => _RedemptionRewardsScreenState();
}

class _RedemptionRewardsScreenState extends State<RedemptionRewardsScreen> {
  String _selectedCategory = 'all';
  
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
      appBar: AppBar(title: const Text('แลกของรางวัล'), elevation: 0),
      body: Consumer<EcoCoinsEnhancedProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingRewards) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              _buildBalanceCard(provider),
              _buildCategoryTabs(),
              Expanded(child: _buildRewardsList(provider)),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildBalanceCard(EcoCoinsEnhancedProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('คะแนนของคุณ', style: TextStyle(color: Colors.white70, fontSize: 14)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.eco, color: Colors.white, size: 32),
              Text(' ${provider.ecoCoinBalance.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildCategoryChip('ทั้งหมด', 'all'),
          _buildCategoryChip('คูปอง', 'coupon'),
          _buildCategoryChip('ส่วนลด', 'discount'),
          _buildCategoryChip('ของขวัญ', 'physical'),
        ],
      ),
    );
  }
  
  Widget _buildCategoryChip(String label, String value) {
    final isSelected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) => setState(() => _selectedCategory = value),
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
      ),
    );
  }
  
  Widget _buildRewardsList(EcoCoinsEnhancedProvider provider) {
    final rewards = _selectedCategory == 'all' 
        ? provider.availableRewards 
        : provider.availableRewards.where((r) => r.category == _selectedCategory).toList();
    
    if (rewards.isEmpty) {
      return const Center(child: Text('ไม่มีรางวัล'));
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: rewards.length,
      itemBuilder: (context, index) => _buildRewardCard(rewards[index], provider),
    );
  }
  
  Widget _buildRewardCard(RedemptionReward reward, EcoCoinsEnhancedProvider provider) {
    final canAfford = provider.ecoCoinBalance >= reward.coinsCost;
    return Card(
      child: InkWell(
        onTap: () => _showRewardDetails(reward, provider, canAfford),
        child: Column(
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Icon(Icons.card_giftcard, size: 48, color: AppColors.primary),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(reward.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2),
                  Row(
                    children: [
                      Icon(Icons.eco, size: 16, color: canAfford ? AppColors.primary : Colors.grey),
                      Text(' ${reward.coinsCost.toString()}', style: TextStyle(fontWeight: FontWeight.bold, color: canAfford ? AppColors.primary : Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showRewardDetails(RedemptionReward reward, EcoCoinsEnhancedProvider provider, bool canAfford) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(reward.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(reward.description),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: canAfford ? () async {
                Navigator.pop(context);
                final success = await provider.redeemReward(reward.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? 'แลกสำเร็จ!' : 'ไม่สามารถแลกได้'), backgroundColor: success ? Colors.green : Colors.red),
                  );
                }
              } : null,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(double.infinity, 48)),
              child: const Text('แลกเลย!'),
            ),
          ],
        ),
      ),
    );
  }
}