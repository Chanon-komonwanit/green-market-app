import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// ระบบการจัดการลูกค้า (Customer Relationship Management - CRM)
/// รองรับการจัดการลูกค้า, ประวัติการซื้อ, การแบ่งกลุ่ม, RFM Analysis
class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  State<CustomerManagementScreen> createState() =>
      _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String sellerId = FirebaseAuth.instance.currentUser!.uid;

  List<CustomerData> _customers = [];
  bool _isLoading = true;

  // Filters
  String _selectedSegment = 'all'; // all, vip, regular, at_risk, lost
  String _sortBy = 'recent'; // recent, spending, frequency

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCustomers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      // โหลดคำสั่งซื้อทั้งหมด
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('sellerId', isEqualTo: sellerId)
          .get();

      // จัดกลุ่มตาม userId
      final Map<String, CustomerData> customerMap = {};

      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String;
        final totalAmount = (data['totalAmount'] as num?)?.toDouble() ?? 0;
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        final status = data['status'] as String;

        if (!customerMap.containsKey(userId)) {
          // สร้างข้อมูลลูกค้าใหม่
          final userDoc =
              await _firestore.collection('users').doc(userId).get();
          final userData = userDoc.data();

          customerMap[userId] = CustomerData(
            userId: userId,
            name: userData?['displayName'] ?? 'ลูกค้า',
            email: userData?['email'] ?? '',
            phone: userData?['phone'] ?? '',
            photoUrl: userData?['profileImage'],
            totalOrders: 0,
            totalSpent: 0,
            averageOrderValue: 0,
            firstOrderDate: createdAt,
            lastOrderDate: createdAt,
            daysSinceLastOrder: 0,
            orders: [],
          );
        }

        // อัปเดตข้อมูล
        final customer = customerMap[userId]!;
        if (status == 'completed' || status == 'delivered') {
          customer.totalOrders++;
          customer.totalSpent += totalAmount;
          customer.orders.add({
            'id': doc.id,
            'amount': totalAmount,
            'date': createdAt,
            'status': status,
            ...data,
          });

          // อัปเดตวันที่
          if (createdAt.isBefore(customer.firstOrderDate)) {
            customer.firstOrderDate = createdAt;
          }
          if (createdAt.isAfter(customer.lastOrderDate)) {
            customer.lastOrderDate = createdAt;
          }
        }
      }

      // คำนวณค่าเฉลี่ยและจัดกลุ่ม
      _customers = customerMap.values.toList();
      for (var customer in _customers) {
        if (customer.totalOrders > 0) {
          customer.averageOrderValue =
              customer.totalSpent / customer.totalOrders;
        }
        customer.daysSinceLastOrder =
            DateTime.now().difference(customer.lastOrderDate).inDays;

        // RFM Segmentation
        customer.segment = _calculateSegment(customer);
      }

      // เรียงลำดับ
      _sortCustomers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _calculateSegment(CustomerData customer) {
    // RFM Analysis (Recency, Frequency, Monetary)
    final recency = customer.daysSinceLastOrder;
    final frequency = customer.totalOrders;
    final monetary = customer.totalSpent;

    // VIP: ซื้อบ่อย, ใช้จ่ายเยอะ, ซื้อล่าสุด
    if (frequency >= 5 && monetary >= 5000 && recency <= 30) {
      return 'vip';
    }
    // Regular: ซื้อปกติ
    else if (frequency >= 2 && recency <= 90) {
      return 'regular';
    }
    // At Risk: เคยซื้อแต่นานไม่ซื้อ
    else if (frequency >= 2 && recency > 90 && recency <= 180) {
      return 'at_risk';
    }
    // Lost: เคยซื้อแต่หายไปนานมาก
    else if (recency > 180) {
      return 'lost';
    }
    // New: ซื้อครั้งแรก
    else {
      return 'new';
    }
  }

  void _sortCustomers() {
    switch (_sortBy) {
      case 'recent':
        _customers.sort((a, b) => b.lastOrderDate.compareTo(a.lastOrderDate));
        break;
      case 'spending':
        _customers.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
        break;
      case 'frequency':
        _customers.sort((a, b) => b.totalOrders.compareTo(a.totalOrders));
        break;
    }
  }

  List<CustomerData> get _filteredCustomers {
    if (_selectedSegment == 'all') {
      return _customers;
    }
    return _customers.where((c) => c.segment == _selectedSegment).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('การจัดการลูกค้า (CRM)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomers,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _sortCustomers();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'recent', child: Text('ซื้อล่าสุด')),
              const PopupMenuItem(
                  value: 'spending', child: Text('ใช้จ่ายสูงสุด')),
              const PopupMenuItem(
                  value: 'frequency', child: Text('ซื้อบ่อยที่สุด')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'ลูกค้าทั้งหมด', icon: Icon(Icons.people, size: 20)),
            Tab(text: 'กลุ่มลูกค้า', icon: Icon(Icons.group_work, size: 20)),
            Tab(text: 'สถิติ', icon: Icon(Icons.analytics, size: 20)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCustomersTab(),
                _buildSegmentsTab(),
                _buildStatsTab(),
              ],
            ),
    );
  }

  // ==================== TAB 1: ลูกค้าทั้งหมด ====================
  Widget _buildCustomersTab() {
    return Column(
      children: [
        _buildSegmentChips(),
        Expanded(
          child: _filteredCustomers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'ยังไม่มีลูกค้า',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCustomers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredCustomers.length,
                    itemBuilder: (context, index) {
                      return _buildCustomerCard(_filteredCustomers[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSegmentChips() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildSegmentChip('ทั้งหมด', 'all', Icons.people, Colors.grey),
            const SizedBox(width: 8),
            _buildSegmentChip('⭐ VIP', 'vip', Icons.star, Colors.amber),
            const SizedBox(width: 8),
            _buildSegmentChip('👥 ปกติ', 'regular', Icons.person, Colors.blue),
            const SizedBox(width: 8),
            _buildSegmentChip(
                '⚠️ เสี่ยงหาย', 'at_risk', Icons.warning, Colors.orange),
            const SizedBox(width: 8),
            _buildSegmentChip('💔 หายไป', 'lost', Icons.person_off, Colors.red),
            const SizedBox(width: 8),
            _buildSegmentChip('🆕 ใหม่', 'new', Icons.fiber_new, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentChip(
      String label, String segment, IconData icon, Color color) {
    final isSelected = _selectedSegment == segment;
    final count = segment == 'all'
        ? _customers.length
        : _customers.where((c) => c.segment == segment).length;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : color),
          const SizedBox(width: 4),
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.3)
                    : color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedSegment = segment;
        });
      },
      selectedColor: color,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildCustomerCard(CustomerData customer) {
    final segmentInfo = _getSegmentInfo(customer.segment);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: segmentInfo['color'].withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () => _showCustomerDetails(customer),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: customer.photoUrl != null
                        ? NetworkImage(customer.photoUrl!)
                        : null,
                    child: customer.photoUrl == null
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                customer.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: segmentInfo['color'].withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                segmentInfo['label'],
                                style: TextStyle(
                                  color: segmentInfo['color'],
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (customer.email.isNotEmpty)
                          Text(
                            customer.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (customer.phone.isNotEmpty)
                          Text(
                            customer.phone,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCustomerStat(
                    Icons.shopping_cart,
                    '${customer.totalOrders}',
                    'คำสั่งซื้อ',
                    Colors.blue,
                  ),
                  _buildCustomerStat(
                    Icons.attach_money,
                    '฿${_formatMoney(customer.totalSpent)}',
                    'ใช้จ่ายรวม',
                    Colors.green,
                  ),
                  _buildCustomerStat(
                    Icons.schedule,
                    '${customer.daysSinceLastOrder} วัน',
                    'ซื้อล่าสุด',
                    Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerStat(
      IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // ==================== TAB 2: กลุ่มลูกค้า ====================
  Widget _buildSegmentsTab() {
    final segments = {
      'vip': _customers.where((c) => c.segment == 'vip').toList(),
      'regular': _customers.where((c) => c.segment == 'regular').toList(),
      'at_risk': _customers.where((c) => c.segment == 'at_risk').toList(),
      'lost': _customers.where((c) => c.segment == 'lost').toList(),
      'new': _customers.where((c) => c.segment == 'new').toList(),
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSegmentCard(
          '⭐ VIP ลูกค้า',
          'ซื้อบ่อย ใช้จ่ายเยอะ',
          segments['vip']!,
          Colors.amber,
          Icons.star,
        ),
        _buildSegmentCard(
          '👥 ลูกค้าปกติ',
          'ซื้อสม่ำเสมอ',
          segments['regular']!,
          Colors.blue,
          Icons.person,
        ),
        _buildSegmentCard(
          '⚠️ เสี่ยงหาย',
          'นานไม่ซื้อ ควรติดตาม',
          segments['at_risk']!,
          Colors.orange,
          Icons.warning,
        ),
        _buildSegmentCard(
          '💔 ลูกค้าหาย',
          'นานมากไม่ซื้อ',
          segments['lost']!,
          Colors.red,
          Icons.person_off,
        ),
        _buildSegmentCard(
          '🆕 ลูกค้าใหม่',
          'ซื้อครั้งแรก',
          segments['new']!,
          Colors.green,
          Icons.fiber_new,
        ),
      ],
    );
  }

  Widget _buildSegmentCard(String title, String description,
      List<CustomerData> customers, Color color, IconData icon) {
    final totalSpent =
        customers.fold<double>(0, (sum, customer) => sum + customer.totalSpent);
    final avgSpent = customers.isEmpty ? 0.0 : (totalSpent / customers.length);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedSegment = customers.first.segment;
            _tabController.animateTo(0);
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          description,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${customers.length}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '฿${_formatMoney(totalSpent)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        'ยอดรวม',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '฿${_formatMoney(avgSpent)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        'เฉลี่ยต่อคน',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== TAB 3: สถิติ ====================
  Widget _buildStatsTab() {
    final totalCustomers = _customers.length;
    final totalRevenue = _customers.fold<double>(
        0, (sum, customer) => sum + customer.totalSpent);
    final avgRevenue =
        totalCustomers > 0 ? (totalRevenue / totalCustomers) : 0.0;
    final totalOrders =
        _customers.fold<int>(0, (sum, customer) => sum + customer.totalOrders);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '📊 สถิติภาพรวม',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '👥',
                '$totalCustomers',
                'ลูกค้าทั้งหมด',
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '💰',
                '฿${_formatMoney(totalRevenue)}',
                'รายได้รวม',
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '📦',
                '$totalOrders',
                'คำสั่งซื้อรวม',
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '💵',
                '฿${_formatMoney(avgRevenue)}',
                'เฉลี่ยต่อคน',
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          '🏆 Top 5 ลูกค้า VIP',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._customers
            .take(5)
            .map((customer) => _buildTopCustomerTile(customer)),
      ],
    );
  }

  Widget _buildStatCard(String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCustomerTile(CustomerData customer) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            customer.photoUrl != null ? NetworkImage(customer.photoUrl!) : null,
        child: customer.photoUrl == null ? const Icon(Icons.person) : null,
      ),
      title: Text(customer.name),
      subtitle: Text('${customer.totalOrders} คำสั่งซื้อ'),
      trailing: Text(
        '฿${_formatMoney(customer.totalSpent)}',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
      onTap: () => _showCustomerDetails(customer),
    );
  }

  // ==================== HELPERS ====================
  Map<String, dynamic> _getSegmentInfo(String segment) {
    switch (segment) {
      case 'vip':
        return {'label': 'VIP', 'color': Colors.amber};
      case 'regular':
        return {'label': 'ปกติ', 'color': Colors.blue};
      case 'at_risk':
        return {'label': 'เสี่ยงหาย', 'color': Colors.orange};
      case 'lost':
        return {'label': 'หายไป', 'color': Colors.red};
      case 'new':
        return {'label': 'ใหม่', 'color': Colors.green};
      default:
        return {'label': 'ทั่วไป', 'color': Colors.grey};
    }
  }

  String _formatMoney(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  void _showCustomerDetails(CustomerData customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: customer.photoUrl != null
                            ? NetworkImage(customer.photoUrl!)
                            : null,
                        child: customer.photoUrl == null
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (customer.email.isNotEmpty)
                              Text(customer.email,
                                  style: const TextStyle(color: Colors.grey)),
                            if (customer.phone.isNotEmpty)
                              Text(customer.phone,
                                  style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '📊 สถิติลูกค้า',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                      'คำสั่งซื้อทั้งหมด', '${customer.totalOrders} คำสั่ง'),
                  _buildDetailRow('ใช้จ่ายรวม',
                      '฿${customer.totalSpent.toStringAsFixed(0)}'),
                  _buildDetailRow('ค่าเฉลี่ยต่อคำสั่ง',
                      '฿${customer.averageOrderValue.toStringAsFixed(0)}'),
                  _buildDetailRow(
                      'ซื้อครั้งแรก',
                      DateFormat('d MMM yyyy', 'th')
                          .format(customer.firstOrderDate)),
                  _buildDetailRow(
                      'ซื้อครั้งล่าสุด',
                      DateFormat('d MMM yyyy', 'th')
                          .format(customer.lastOrderDate)),
                  _buildDetailRow(
                      'นานแล้ว', '${customer.daysSinceLastOrder} วัน'),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Open chat
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('ฟีเจอร์แชทกำลังพัฒนา')),
                            );
                          },
                          icon: const Icon(Icons.chat),
                          label: const Text('แชท'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.close),
                          label: const Text('ปิด'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ==================== MODELS ====================
class CustomerData {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;

  int totalOrders;
  double totalSpent;
  double averageOrderValue;
  DateTime firstOrderDate;
  DateTime lastOrderDate;
  int daysSinceLastOrder;
  String segment; // vip, regular, at_risk, lost, new
  List<Map<String, dynamic>> orders;

  CustomerData({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
    this.totalOrders = 0,
    this.totalSpent = 0,
    this.averageOrderValue = 0,
    required this.firstOrderDate,
    required this.lastOrderDate,
    this.daysSinceLastOrder = 0,
    this.segment = 'new',
    this.orders = const [],
  });
}
