// lib/screens/eco_coins_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/eco_coin.dart';
import '../utils/constants.dart';
import '../widgets/eco_coins_widget.dart';

class EcoCoinsScreen extends StatefulWidget {
  final EcoCoinBalance? balance;

  const EcoCoinsScreen({
    Key? key,
    this.balance,
  }) : super(key: key);

  @override
  State<EcoCoinsScreen> createState() => _EcoCoinsScreenState();
}

class _EcoCoinsScreenState extends State<EcoCoinsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late EcoCoinBalance _balance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _balance = widget.balance ?? _getMockBalance();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'เหรียญ Eco',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: _balance.currentTier.color,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // การแจ้งเตือนฟีเจอร์ใหม่
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade100,
                  Colors.green.shade100,
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade300, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '🪙 ระบบเหรียญ Eco - ใช้ซื้อสินค้าและแลกรางวัล',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Header section with balance
          _buildHeaderSection(),

          // Tab bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: _balance.currentTier.color,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: _balance.currentTier.color,
              tabs: const [
                Tab(text: 'ภารกิจ'),
                Tab(text: 'ประวัติ'),
                Tab(text: 'แลกรางวัล'),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMissionsTab(),
                _buildHistoryTab(),
                _buildRewardsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _balance.currentTier.color,
            _balance.currentTier.color.withOpacity(0.8),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          // Balance display
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Current balance
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.eco,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_balance.availableCoins}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Eco Coins',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Tier information
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            _balance.currentTier.icon,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _balance.currentTier.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'x${_balance.currentTier.multiplier}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (_balance.coinsToNextTier > 0) ...[
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'ถึงระดับถัดไป',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${_balance.coinsToNextTier} เหลียญ',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: _calculateProgressToNextTier(),
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionsTab() {
    final missions = _getMockMissions();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Daily missions header
        _buildSectionHeader(
          'ภารกิจรายวัน',
          Icons.today,
          Colors.orange,
        ),
        const SizedBox(height: 12),

        ...missions.where((m) => m.type == EcoCoinMissionType.daily).map(
              (mission) => _buildMissionCard(mission),
            ),

        const SizedBox(height: 24),

        // Weekly missions header
        _buildSectionHeader(
          'ภารกิจรายสัปดาห์',
          Icons.today,
          Colors.purple,
        ),
        const SizedBox(height: 12),

        ...missions.where((m) => m.type == EcoCoinMissionType.weekly).map(
              (mission) => _buildMissionCard(mission),
            ),

        const SizedBox(height: 24),

        // Special missions header
        _buildSectionHeader(
          'ภารกิจพิเศษ',
          Icons.star,
          Colors.amber,
        ),
        const SizedBox(height: 12),

        ...missions.where((m) => m.type == EcoCoinMissionType.special).map(
              (mission) => _buildMissionCard(mission),
            ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    final transactions = _getMockTransactions();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildRewardsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Discount vouchers section
        _buildSectionHeader(
          'คูปองส่วนลด',
          Icons.local_offer,
          Colors.green,
        ),
        const SizedBox(height: 12),

        _buildRewardCard(
          title: 'ส่วนลด 10 บาท',
          description: 'ใช้ได้กับคำสั่งซื้อขั้นต่ำ 100 บาท',
          coinCost: 100,
          icon: Icons.discount,
          color: Colors.green,
        ),

        _buildRewardCard(
          title: 'ส่วนลด 25 บาท',
          description: 'ใช้ได้กับคำสั่งซื้อขั้นต่ำ 250 บาท',
          coinCost: 250,
          icon: Icons.discount,
          color: Colors.orange,
        ),

        _buildRewardCard(
          title: 'ส่วนลด 50 บาท',
          description: 'ใช้ได้กับคำสั่งซื้อขั้นต่ำ 500 บาท',
          coinCost: 500,
          icon: Icons.discount,
          color: Colors.red,
        ),

        const SizedBox(height: 24),

        // Special rewards section
        _buildSectionHeader(
          'รางวัลพิเศษ',
          Icons.redeem,
          Colors.purple,
        ),
        const SizedBox(height: 12),

        _buildRewardCard(
          title: 'ฟรีค่าจัดส่ง',
          description: 'ฟรีค่าจัดส่งสำหรับคำสั่งซื้อถัดไป',
          coinCost: 150,
          icon: Icons.local_shipping,
          color: Colors.blue,
        ),

        _buildRewardCard(
          title: 'สิทธิ์ซื้อสินค้าพิเศษ',
          description: 'เข้าถึงสินค้าจำกัดก่อนใคร',
          coinCost: 1000,
          icon: Icons.stars,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildMissionCard(EcoCoinMission mission) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: mission.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              mission.icon,
              color: mission.color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mission.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.eco,
                    color: AppColors.primaryTeal,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${mission.coinReward}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Progress or claim button would go here
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'กำลังดำเนินการ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(EcoCoin transaction) {
    final isPositive = transaction.type == EcoCoinTransactionType.earned ||
        transaction.type == EcoCoinTransactionType.bonus;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: transaction.type.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              transaction.type.icon,
              color: transaction.type.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.type.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (transaction.description != null)
                  Text(
                    transaction.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                Text(
                  _formatDate(transaction.createdAt.toDate()),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : '-'}${transaction.amount}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isPositive ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard({
    required String title,
    required String description,
    required int coinCost,
    required IconData icon,
    required Color color,
  }) {
    final canAfford = _balance.availableCoins >= coinCost;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: canAfford ? Border.all(color: color.withOpacity(0.3)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.eco,
                    color: AppColors.primaryTeal,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    coinCost.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed:
                    canAfford ? () => _redeemReward(title, coinCost) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canAfford ? color : Colors.grey[300],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  canAfford ? 'แลก' : 'ไม่พอ',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateProgressToNextTier() {
    final nextTier = EcoCoinTier.getNextTier(_balance.totalCoins);
    if (nextTier == null) return 1.0;

    final currentTierMax = _balance.currentTier.maxCoins;
    final nextTierMin = nextTier.minCoins;
    final progress = (_balance.totalCoins - _balance.currentTier.minCoins) /
        (nextTierMin - _balance.currentTier.minCoins);

    return progress.clamp(0.0, 1.0);
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เกี่ยวกับ Eco Coins'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Eco Coins คือเหลียญรางวัลสำหรับการช้อปปิ้งที่เป็นมิตรกับสิ่งแวดล้อม',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('🛍️ ซื้อสินค้า = ได้เหลียญ'),
              Text('📝 รีวิวสินค้า = ได้เหลียญ'),
              Text('🌱 กิจกรรมเป็นมิตรสิ่งแวดล้อม = ได้เหลียญ'),
              Text('📅 เช็คอินรายวัน = ได้เหลียญ'),
              SizedBox(height: 16),
              Text('💰 แลกเหลียญเป็นส่วนลดได้'),
              Text('🚚 แลกฟรีค่าจัดส่งได้'),
              Text('⭐ ปลดล็อกสิทธิพิเศษได้'),
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

  void _redeemReward(String rewardTitle, int coinCost) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการแลกรางวัล'),
        content:
            Text('ต้องการแลก "$rewardTitle" ด้วย $coinCost เหลียญหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showRedemptionSuccess(rewardTitle);
            },
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
  }

  void _showRedemptionSuccess(String rewardTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('แลกรางวัลสำเร็จ!'),
        content:
            Text('คุณได้รับ "$rewardTitle" แล้ว\nตรวจสอบได้ในหน้าคูปองของฉัน'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('เรียบร้อย'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Mock data methods
  EcoCoinBalance _getMockBalance() {
    return EcoCoinBalance(
      userId: 'mock_user',
      totalCoins: 2250,
      availableCoins: 2250,
      expiredCoins: 150,
      lifetimeEarned: 5000,
      lifetimeSpent: 2750,
      currentTier: EcoCoinTier.getCurrentTier(2250),
      coinsToNextTier: EcoCoinTier.getNextTier(2250)?.minCoins != null
          ? EcoCoinTier.getNextTier(2250)!.minCoins - 2250
          : 0,
      lastUpdated: Timestamp.now(),
    );
  }

  List<EcoCoinMission> _getMockMissions() {
    return [
      EcoCoinMission(
        id: '1',
        title: 'เช็คอินรายวัน',
        description: 'เข้าแอปและเช็คอินทุกวัน',
        coinReward: 5,
        type: EcoCoinMissionType.daily,
        requiredProgress: 1,
        validUntil:
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        createdAt: Timestamp.now(),
      ),
      EcoCoinMission(
        id: '2',
        title: 'ซื้อสินค้าเป็นมิตรสิ่งแวดล้อม',
        description: 'ซื้อสินค้า Eco Hero อย่างน้อย 1 ชิ้น',
        coinReward: 50,
        type: EcoCoinMissionType.purchase,
        requiredProgress: 1,
        validUntil:
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        createdAt: Timestamp.now(),
      ),
      EcoCoinMission(
        id: '3',
        title: 'รีวิวสินค้า',
        description: 'เขียนรีวิวสินค้าที่ซื้อแล้ว',
        coinReward: 15,
        type: EcoCoinMissionType.review,
        requiredProgress: 3,
        validUntil:
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        createdAt: Timestamp.now(),
      ),
      EcoCoinMission(
        id: '4',
        title: 'ชำระเงินผ่าน QR Code',
        description: 'ใช้ QR Code Payment สำหรับการชำระเงิน',
        coinReward: 100,
        type: EcoCoinMissionType.special,
        requiredProgress: 1,
        validUntil:
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        createdAt: Timestamp.now(),
      ),
    ];
  }

  List<EcoCoin> _getMockTransactions() {
    return [
      EcoCoin(
        id: '1',
        userId: 'mock_user',
        amount: 25,
        type: EcoCoinTransactionType.earned,
        source: 'purchase',
        description: 'ซื้อสินค้าจำนวน 250 บาท',
        createdAt: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 2))),
      ),
      EcoCoin(
        id: '2',
        userId: 'mock_user',
        amount: 50,
        type: EcoCoinTransactionType.spent,
        source: 'discount',
        description: 'แลกส่วนลด 50 บาท',
        createdAt: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 1))),
      ),
      EcoCoin(
        id: '3',
        userId: 'mock_user',
        amount: 15,
        type: EcoCoinTransactionType.earned,
        source: 'review',
        description: 'เขียนรีวิวสินค้า',
        createdAt: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 2))),
      ),
    ];
  }
}
