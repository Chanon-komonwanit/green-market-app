// lib/screens/seller/wallet_screen.dart
// 💰 Seller Wallet & Withdrawal System - Shopee/TikTok Shop Standard

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  double _balance = 0.0;
  double _pendingBalance = 0.0;
  double _totalEarnings = 0.0;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _bankAccounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadWalletData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWalletData() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Load wallet data
      final walletDoc = await FirebaseFirestore.instance
          .collection('seller_wallets')
          .doc(user.uid)
          .get();

      if (walletDoc.exists) {
        final data = walletDoc.data()!;
        _balance = (data['balance'] as num?)?.toDouble() ?? 0.0;
        _pendingBalance = (data['pendingBalance'] as num?)?.toDouble() ?? 0.0;
        _totalEarnings = (data['totalEarnings'] as num?)?.toDouble() ?? 0.0;
      }

      // Load transactions
      final transactionsSnapshot = await FirebaseFirestore.instance
          .collection('seller_transactions')
          .where('sellerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      _transactions = transactionsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'type': data['type'] ?? '',
          'amount': (data['amount'] as num?)?.toDouble() ?? 0.0,
          'status': data['status'] ?? '',
          'description': data['description'] ?? '',
          'createdAt':
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();

      // Load bank accounts
      final bankSnapshot = await FirebaseFirestore.instance
          .collection('seller_bank_accounts')
          .where('sellerId', isEqualTo: user.uid)
          .get();

      _bankAccounts = bankSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'bankName': data['bankName'] ?? '',
          'accountNumber': data['accountNumber'] ?? '',
          'accountName': data['accountName'] ?? '',
          'isDefault': data['isDefault'] ?? false,
        };
      }).toList();

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading wallet data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'กระเป๋าเงิน',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _tabController.animateTo(1),
            tooltip: 'ประวัติการทำรายการ',
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildBalanceCard(),
        _buildQuickActions(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildTransactionsTab(),
              _buildBankAccountsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ยอดเงินคงเหลือ',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_balance_wallet,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'THB',
                      style: const TextStyle(
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
          const SizedBox(height: 8),
          Text(
            '฿${NumberFormat('#,##0.00').format(_balance)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildBalanceInfo(
                  'รอโอน',
                  '฿${NumberFormat('#,##0.00').format(_pendingBalance)}',
                  Icons.schedule,
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildBalanceInfo(
                  'รายได้ทั้งหมด',
                  '฿${NumberFormat('#,##0.00').format(_totalEarnings)}',
                  Icons.trending_up,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceInfo(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.account_balance,
              label: 'ถอนเงิน',
              color: const Color(0xFF2E7D32),
              onTap: _showWithdrawalDialog,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.add_card,
              label: 'เพิ่มบัญชี',
              color: const Color(0xFF2196F3),
              onTap: _showAddBankAccountDialog,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ภาพรวม',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'รายได้เดือนนี้',
            '฿${NumberFormat('#,##0.00').format(_totalEarnings * 0.3)}',
            Icons.calendar_today,
            Colors.blue,
            '+15.3%',
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            'รายได้สัปดาห์นี้',
            '฿${NumberFormat('#,##0.00').format(_totalEarnings * 0.1)}',
            Icons.date_range,
            Colors.purple,
            '+8.7%',
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            'รายได้วันนี้',
            '฿${NumberFormat('#,##0.00').format(_totalEarnings * 0.02)}',
            Icons.today,
            Colors.orange,
            '+12.1%',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String change,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              change,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'ยังไม่มีรายการ',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return _buildTransactionItem(transaction);
      },
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final type = transaction['type'] as String;
    final amount = transaction['amount'] as double;
    final status = transaction['status'] as String;

    IconData icon;
    Color iconColor;
    String prefix;

    switch (type) {
      case 'withdrawal':
        icon = Icons.call_made;
        iconColor = Colors.red;
        prefix = '-';
        break;
      case 'order':
        icon = Icons.call_received;
        iconColor = Colors.green;
        prefix = '+';
        break;
      case 'refund':
        icon = Icons.replay;
        iconColor = Colors.orange;
        prefix = '-';
        break;
      default:
        icon = Icons.sync_alt;
        iconColor = Colors.grey;
        prefix = '';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['description'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatDateTime(transaction['createdAt'] as DateTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(status),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '$prefix฿${NumberFormat('#,##0.00').format(amount)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: type == 'withdrawal' || type == 'refund'
                  ? Colors.red
                  : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'completed':
        color = Colors.green;
        label = 'สำเร็จ';
        break;
      case 'pending':
        color = Colors.orange;
        label = 'รอดำเนินการ';
        break;
      case 'failed':
        color = Colors.red;
        label = 'ล้มเหลว';
        break;
      default:
        color = Colors.grey;
        label = 'ไม่ทราบสถานะ';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildBankAccountsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'บัญชีธนาคาร',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (_bankAccounts.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Icon(Icons.account_balance,
                      size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'ยังไม่มีบัญชีธนาคาร',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showAddBankAccountDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('เพิ่มบัญชีธนาคาร'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...(_bankAccounts.map((account) => _buildBankAccountCard(account))),
        ],
      ),
    );
  }

  Widget _buildBankAccountCard(Map<String, dynamic> account) {
    final isDefault = account['isDefault'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDefault
            ? Border.all(color: const Color(0xFF2E7D32), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.account_balance,
              color: Color(0xFF2E7D32),
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      account['bankName'] as String,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'หลัก',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  account['accountName'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _maskAccountNumber(account['accountNumber'] as String),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'default':
                  _setDefaultBankAccount(account['id']);
                  break;
                case 'delete':
                  _deleteBankAccount(account['id']);
                  break;
              }
            },
            itemBuilder: (context) => [
              if (!isDefault)
                const PopupMenuItem(
                  value: 'default',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 20),
                      SizedBox(width: 12),
                      Text('ตั้งเป็นบัญชีหลัก'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('ลบบัญชี', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _maskAccountNumber(String accountNumber) {
    if (accountNumber.length <= 4) return accountNumber;
    final visible = accountNumber.substring(accountNumber.length - 4);
    return '•••• $visible';
  }

  void _showWithdrawalDialog() {
    if (_bankAccounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเพิ่มบัญชีธนาคารก่อนถอนเงิน'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final amountController = TextEditingController();
    String? selectedBankId = _bankAccounts.firstWhere(
      (acc) => acc['isDefault'] == true,
      orElse: () => _bankAccounts.first,
    )['id'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ถอนเงิน'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ยอดเงินคงเหลือ: ฿${NumberFormat('#,##0.00').format(_balance)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'จำนวนเงิน',
                prefixText: '฿',
                border: OutlineInputBorder(),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedBankId,
              decoration: const InputDecoration(
                labelText: 'บัญชีธนาคาร',
                border: OutlineInputBorder(),
              ),
              items: _bankAccounts.map<DropdownMenuItem<String>>((account) {
                return DropdownMenuItem<String>(
                  value: account['id'],
                  child: Text(
                    '${account['bankName']} (${_maskAccountNumber(account['accountNumber'])})',
                  ),
                );
              }).toList(),
              onChanged: (value) {
                selectedBankId = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กรุณาระบุจำนวนเงิน'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              if (amount > _balance) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ยอดเงินไม่เพียงพอ'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              _processWithdrawal(amount, selectedBankId!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            child: const Text('ยืนยันถอนเงิน'),
          ),
        ],
      ),
    );
  }

  void _showAddBankAccountDialog() {
    final bankNameController = TextEditingController();
    final accountNumberController = TextEditingController();
    final accountNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เพิ่มบัญชีธนาคาร'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bankNameController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อธนาคาร',
                  hintText: 'เช่น ธนาคารกสิกรไทย',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: accountNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'เลขที่บัญชี',
                  border: OutlineInputBorder(),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: accountNameController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อบัญชี',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (bankNameController.text.isEmpty ||
                  accountNumberController.text.isEmpty ||
                  accountNameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กรุณากรอกข้อมูลให้ครบถ้วน'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              await _addBankAccount(
                bankNameController.text,
                accountNumberController.text,
                accountNameController.text,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            child: const Text('เพิ่มบัญชี'),
          ),
        ],
      ),
    );
  }

  Future<void> _processWithdrawal(double amount, String bankId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Create withdrawal transaction
      await FirebaseFirestore.instance.collection('seller_transactions').add({
        'sellerId': user.uid,
        'type': 'withdrawal',
        'amount': amount,
        'status': 'pending',
        'description': 'ถอนเงิน',
        'bankAccountId': bankId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update wallet balance
      await FirebaseFirestore.instance
          .collection('seller_wallets')
          .doc(user.uid)
          .update({
        'balance': FieldValue.increment(-amount),
        'pendingBalance': FieldValue.increment(amount),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ส่งคำขอถอนเงินสำเร็จ'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );

      _loadWalletData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addBankAccount(
    String bankName,
    String accountNumber,
    String accountName,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final isFirstAccount = _bankAccounts.isEmpty;

      await FirebaseFirestore.instance.collection('seller_bank_accounts').add({
        'sellerId': user.uid,
        'bankName': bankName,
        'accountNumber': accountNumber,
        'accountName': accountName,
        'isDefault': isFirstAccount,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เพิ่มบัญชีธนาคารสำเร็จ'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );

      _loadWalletData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _setDefaultBankAccount(String accountId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Remove default from all accounts
      final batch = FirebaseFirestore.instance.batch();
      for (var account in _bankAccounts) {
        batch.update(
          FirebaseFirestore.instance
              .collection('seller_bank_accounts')
              .doc(account['id']),
          {'isDefault': false},
        );
      }

      // Set new default
      batch.update(
        FirebaseFirestore.instance
            .collection('seller_bank_accounts')
            .doc(accountId),
        {'isDefault': true},
      );

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ตั้งบัญชีหลักสำเร็จ'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );

      _loadWalletData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteBankAccount(String accountId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบบัญชีธนาคาร'),
        content: const Text('คุณต้องการลบบัญชีธนาคารนี้ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('seller_bank_accounts')
          .doc(accountId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ลบบัญชีธนาคารสำเร็จ'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );

      _loadWalletData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'เมื่อสักครู่';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} วันที่แล้ว';
    } else {
      return DateFormat('d MMM yyyy', 'th').format(dateTime);
    }
  }
}
