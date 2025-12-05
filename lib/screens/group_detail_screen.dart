// lib/screens/group_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/models/community_post.dart';
import 'package:green_market/widgets/post_card_widget.dart';
import 'package:green_market/utils/constants.dart';
import 'package:green_market/screens/create_community_post_screen.dart';

/// Group Detail Screen - รายละเอียดกลุ่ม
/// แสดง Feed ของกลุ่ม, สมาชิก, และการตั้งค่า
class GroupDetailScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _groupData;
  bool _isLoading = true;
  bool _isMember = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadGroupData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('community_groups')
          .doc(widget.groupId)
          .get();

      if (doc.exists) {
        final currentUser = context.read<UserProvider>().currentUser;
        final members = List<String>.from(doc.data()?['members'] ?? []);

        setState(() {
          _groupData = doc.data();
          _isMember = currentUser != null && members.contains(currentUser.id);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading group: $e');
    }
  }

  Future<void> _toggleMembership() async {
    final currentUser = context.read<UserProvider>().currentUser;
    if (currentUser == null) return;

    try {
      if (_isMember) {
        // Leave group
        await FirebaseFirestore.instance
            .collection('community_groups')
            .doc(widget.groupId)
            .update({
          'members': FieldValue.arrayRemove([currentUser.id]),
          'memberCount': FieldValue.increment(-1),
        });

        setState(() => _isMember = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ออกจากกลุ่มแล้ว')),
          );
        }
      } else {
        // Join group
        await FirebaseFirestore.instance
            .collection('community_groups')
            .doc(widget.groupId)
            .update({
          'members': FieldValue.arrayUnion([currentUser.id]),
          'memberCount': FieldValue.increment(1),
        });

        setState(() => _isMember = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('เข้าร่วมกลุ่มแล้ว')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error toggling membership: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('กำลังโหลด...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_groupData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ไม่พบกลุ่ม')),
        body: const Center(child: Text('ไม่พบข้อมูลกลุ่ม')),
      );
    }

    final name = _groupData!['name'] ?? 'ไม่มีชื่อ';
    final coverUrl = _groupData!['coverImageUrl'];
    final memberCount = _groupData!['memberCount'] ?? 0;
    final isPublic = _groupData!['isPublic'] ?? true;

    return Scaffold(
      backgroundColor: AppColors.surfaceGray,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 250,
              pinned: true,
              backgroundColor: AppColors.primaryTeal,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Cover image
                    if (coverUrl != null)
                      Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildDefaultCover(),
                      )
                    else
                      _buildDefaultCover(),

                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),

                    // Group info
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Icon(
                                isPublic ? Icons.public : Icons.lock,
                                color: Colors.white,
                                size: 24,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.people,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$memberCount สมาชิก',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'โพสต์'),
                  Tab(text: 'สมาชิก'),
                  Tab(text: 'เกี่ยวกับ'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPostsTab(),
            _buildMembersTab(),
            _buildAboutTab(),
          ],
        ),
      ),
      floatingActionButton: _isMember
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateCommunityPostScreen(),
                  ),
                );
                if (result == true && mounted) {
                  setState(() {});
                }
              },
              backgroundColor: AppColors.primaryTeal,
              icon: const Icon(Icons.add),
              label: const Text('โพสต์'),
            )
          : null,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _toggleMembership,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isMember ? Colors.grey[300] : AppColors.primaryTeal,
              foregroundColor: _isMember ? Colors.black87 : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _isMember ? 'ออกจากกลุ่ม' : 'เข้าร่วมกลุ่ม',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultCover() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryTeal, AppColors.accentGreen],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.group,
          size: 80,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPostsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community_posts')
          .where('groupId', isEqualTo: widget.groupId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.article_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'ยังไม่มีโพสต์ในกลุ่ม',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                if (_isMember) ...[
                  const SizedBox(height: 8),
                  Text(
                    'เป็นคนแรกที่โพสต์กันเลย!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final postData =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final post = CommunityPost.fromMap(
              postData,
              snapshot.data!.docs[index].id,
            );

            return PostCardWidget(
              post: post,
              onLike: () => setState(() {}),
            );
          },
        );
      },
    );
  }

  Widget _buildMembersTab() {
    final members = List<String>.from(_groupData!['members'] ?? []);

    if (members.isEmpty) {
      return const Center(
        child: Text('ยังไม่มีสมาชิก'),
      );
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadMembers(members),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('ไม่พบข้อมูลสมาชิก'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final member = snapshot.data![index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryTeal.withOpacity(0.2),
                  backgroundImage: member['photoUrl'] != null
                      ? NetworkImage(member['photoUrl'])
                      : null,
                  child: member['photoUrl'] == null
                      ? Text(
                          (member['displayName'] ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primaryTeal,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                title: Text(member['displayName'] ?? 'ไม่ระบุชื่อ'),
                subtitle: member['bio'] != null
                    ? Text(
                        member['bio'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                trailing: member['isAdmin'] == true
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warningAmber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Admin',
                          style: TextStyle(
                            color: AppColors.warningAmber,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
                onTap: () {
                  // Navigate to profile
                  Navigator.pushNamed(
                    context,
                    '/community_profile',
                    arguments: member['id'],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAboutTab() {
    final description = _groupData!['description'] ?? '';
    final createdAt = _groupData!['createdAt'] as Timestamp?;
    final rules = List<String>.from(_groupData!['rules'] ?? []);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Description
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primaryTeal),
                    SizedBox(width: 8),
                    Text(
                      'เกี่ยวกับกลุ่ม',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  description.isNotEmpty ? description : 'ไม่มีคำอธิบาย',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Stats
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bar_chart, color: AppColors.primaryTeal),
                    SizedBox(width: 8),
                    Text(
                      'สถิติ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildStatRow(
                    'สมาชิก', '${_groupData!['memberCount'] ?? 0} คน'),
                _buildStatRow(
                    'โพสต์', '${_groupData!['postCount'] ?? 0} โพสต์'),
                if (createdAt != null)
                  _buildStatRow(
                    'สร้างเมื่อ',
                    _formatDate(createdAt.toDate()),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Rules
        if (rules.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.gavel, color: AppColors.primaryTeal),
                      SizedBox(width: 8),
                      Text(
                        'กฎกลุ่ม',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...rules.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.key + 1}. ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Expanded(child: Text(entry.value)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadMembers(
      List<String> memberIds) async {
    final List<Map<String, dynamic>> members = [];

    for (final id in memberIds) {
      try {
        final doc =
            await FirebaseFirestore.instance.collection('users').doc(id).get();

        if (doc.exists) {
          members.add({
            'id': doc.id,
            ...doc.data()!,
          });
        }
      } catch (e) {
        debugPrint('Error loading member $id: $e');
      }
    }

    return members;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 7) {
      return '${difference.inDays} วันที่แล้ว';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} สัปดาห์ที่แล้ว';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} เดือนที่แล้ว';
    } else {
      return '${(difference.inDays / 365).floor()} ปีที่แล้ว';
    }
  }
}
