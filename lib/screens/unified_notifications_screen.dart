// lib/screens/unified_notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:green_market/screens/investment_notifications_screen.dart';
import 'package:green_market/screens/activity_notifications_screen.dart';

/// Unified Notifications Screen - รวมการแจ้งเตือนทั้งหมด
class UnifiedNotificationsScreen extends StatefulWidget {
  const UnifiedNotificationsScreen({super.key});

  @override
  State<UnifiedNotificationsScreen> createState() =>
      _UnifiedNotificationsScreenState();
}

class _UnifiedNotificationsScreenState extends State<UnifiedNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _investmentUnreadCount = 0;
  int _activityUnreadCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUnreadCounts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadCounts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // นับการแจ้งเตือนการลงทุนที่ยังไม่ได้อ่าน
    final investmentSnapshot = await FirebaseFirestore.instance
        .collection('investment_notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .get();

    // นับการแจ้งเตือนกิจกรรมที่ยังไม่ได้อ่าน
    final activitySnapshot = await FirebaseFirestore.instance
        .collection('activity_notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .get();

    if (mounted) {
      setState(() {
        _investmentUnreadCount = investmentSnapshot.docs.length;
        _activityUnreadCount = activitySnapshot.docs.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text(
          'การแจ้งเตือน',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF059669),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.trending_up_rounded, size: 20),
                  const SizedBox(width: 8),
                  const Text('การลงทุน'),
                  if (_investmentUnreadCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_investmentUnreadCount',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.volunteer_activism_rounded, size: 20),
                  const SizedBox(width: 8),
                  const Text('กิจกรรม'),
                  if (_activityUnreadCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_activityUnreadCount',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          InvestmentNotificationsScreen(),
          ActivityNotificationsScreen(),
        ],
      ),
    );
  }
}
