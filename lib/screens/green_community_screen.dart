// lib/screens/green_community_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import '../utils/constants.dart';
// import '../utils/app_text_styles.dart' as app_text_styles;
import 'create_community_post_screen.dart';
import 'feed_screen.dart';
import 'community_profile_screen.dart';
import 'community_notifications_screen.dart';
import 'community_chat_list_screen.dart';
import '../widgets/community_quick_actions.dart';
import 'eco_challenges_screen.dart';
import 'eco_influence_screen.dart';

class GreenCommunityScreen extends StatefulWidget {
  const GreenCommunityScreen({super.key});

  @override
  State<GreenCommunityScreen> createState() => _GreenCommunityScreenState();
}

class _GreenCommunityScreenState extends State<GreenCommunityScreen>
    with SingleTickerProviderStateMixin {
  String _searchKeyword = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black12,
        toolbarHeight: 56, // ลดความสูง
        title: Row(
          children: [
            // ไอคอนเดียว ไม่มีกล่อง
            Icon(
              Icons.groups_3_rounded,
              color: Color(0xFF10B981),
              size: 28,
            ),
            SizedBox(width: 10),
            Text(
              'ชุมชนสีเขียว',
              style: TextStyle(
                fontSize: 20, // ย่อลง
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
                letterSpacing: -0.3,
              ),
            ),
            Spacer(),
            // จำนวนสมาชิก - แบบกระทัดรัด
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                final memberCount = snapshot.data?.docs.length ?? 0;
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people_alt_rounded,
                        color: Color(0xFF10B981),
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        memberCount.toString().replaceAllMapped(
                              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                              (Match m) => '${m[1]},',
                            ),
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          // Eco Influence - คะแนนอิทธิพลชุมชน (ขยายขนาด)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EcoInfluenceScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber[200]!,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.amber[700],
                      size: 28,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'อิทธิพล',
                      style: TextStyle(
                        color: Colors.amber[900],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Notifications - ขยายขนาด
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommunityNotificationsScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color(0xFF10B981).withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_rounded,
                      color: Color(0xFF10B981),
                      size: 28,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'แจ้งเตือน',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(90), // ลดความสูง
          child: Column(
            children: [
              // Search bar - ย่อลง
              Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '🔍 ค้นหาโพสต์...',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Color(0xFF10B981),
                        size: 22,
                      ),
                      suffixIcon: _searchKeyword.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey[400]),
                              onPressed: () {
                                setState(() {
                                  _searchKeyword = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Color(0xFF10B981),
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchKeyword = value.trim();
                      });
                    },
                  ),
                ),
              ),
              // TabBar - ปรับให้กระทัดรัด
              Container(
                margin: EdgeInsets.fromLTRB(16, 0, 16, 8), // ลด margin
                padding: EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  onTap: (index) {},
                  indicator: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[600],
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  tabs: [
                    Tab(
                      height: 40, // ลดความสูง
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.home_rounded, size: 18),
                          SizedBox(width: 6),
                          Text('ฟีด'),
                        ],
                      ),
                    ),
                    Tab(
                      height: 40, // ลดความสูง
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_rounded, size: 18),
                          SizedBox(width: 6),
                          Text('โปรไฟล์'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          FeedScreen(searchKeyword: _searchKeyword),
          CommunityProfileScreen(hideCreatePostButton: true),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF10B981).withOpacity(0.4),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          heroTag: 'create_post',
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateCommunityPostScreen(),
              ),
            );
            if (result == true && mounted) {
              setState(() {});
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: Icon(Icons.edit_rounded, size: 24),
          label: Text(
            'สร้างโพสต์',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
