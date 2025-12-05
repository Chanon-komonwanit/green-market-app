// lib/screens/community_groups_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/utils/constants.dart';
import 'package:green_market/widgets/modern_animations.dart';
import 'package:green_market/widgets/modern_dialogs.dart';

/// Community Groups Screen - แบบ Facebook Groups
/// สร้างและเข้าร่วมกลุ่มตามความสนใจ
class CommunityGroupsScreen extends StatefulWidget {
  const CommunityGroupsScreen({super.key});

  @override
  State<CommunityGroupsScreen> createState() => _CommunityGroupsScreenState();
}

class _CommunityGroupsScreenState extends State<CommunityGroupsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'กลุ่มชุมชน',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF1F2937)),
            onPressed: _showSearchDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryTeal, AppColors.accentGreen],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[600],
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: 'กลุ่มของฉัน'),
            Tab(text: 'แนะนำ'),
            Tab(text: 'ค้นพบ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyGroups(),
          _buildSuggestedGroups(),
          _buildDiscoverGroups(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateGroupDialog,
        backgroundColor: AppColors.primaryTeal,
        icon: const Icon(Icons.add),
        label: const Text('สร้างกลุ่ม'),
      ),
    );
  }

  Widget _buildMyGroups() {
    final currentUser = context.watch<UserProvider>().currentUser;
    if (currentUser == null) {
      return _buildEmptyState('กรุณาเข้าสู่ระบบ');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community_groups')
          .where('members', arrayContains: currentUser.id)
          .orderBy('lastActivityAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildLoadingState();
        }

        final groups = snapshot.data!.docs;

        if (groups.isEmpty) {
          return _buildEmptyState('คุณยังไม่ได้เข้าร่วมกลุ่มใด');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index].data() as Map<String, dynamic>;
            final groupId = groups[index].id;

            return FadeInAnimation(
              delay: Duration(milliseconds: index * 100),
              child: _buildGroupCard(groupId, group, isJoined: true),
            );
          },
        );
      },
    );
  }

  Widget _buildSuggestedGroups() {
    final currentUser = context.watch<UserProvider>().currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community_groups')
          .where('isPublic', isEqualTo: true)
          .orderBy('memberCount', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildLoadingState();
        }

        final groups = snapshot.data!.docs;

        // Filter out groups user is already in
        final filteredGroups = groups.where((doc) {
          final members = List<String>.from(
            (doc.data() as Map<String, dynamic>)['members'] ?? [],
          );
          return currentUser == null || !members.contains(currentUser.id);
        }).toList();

        if (filteredGroups.isEmpty) {
          return _buildEmptyState('ไม่มีกลุ่มแนะนำ');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredGroups.length,
          itemBuilder: (context, index) {
            final group = filteredGroups[index].data() as Map<String, dynamic>;
            final groupId = filteredGroups[index].id;

            return FadeInAnimation(
              delay: Duration(milliseconds: index * 100),
              child: _buildGroupCard(groupId, group, isJoined: false),
            );
          },
        );
      },
    );
  }

  Widget _buildDiscoverGroups() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community_groups')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildLoadingState();
        }

        final groups = snapshot.data!.docs;

        if (groups.isEmpty) {
          return _buildEmptyState('ยังไม่มีกลุ่ม');
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index].data() as Map<String, dynamic>;
            final groupId = groups[index].id;

            return FadeInAnimation(
              delay: Duration(milliseconds: index * 50),
              child: _buildGroupGridCard(groupId, group),
            );
          },
        );
      },
    );
  }

  Widget _buildGroupCard(String groupId, Map<String, dynamic> group,
      {required bool isJoined}) {
    final name = group['name'] ?? 'ไม่มีชื่อ';
    final description = group['description'] ?? '';
    final coverUrl = group['coverImageUrl'];
    final memberCount = group['memberCount'] ?? 0;
    final postCount = group['postCount'] ?? 0;
    final isPublic = group['isPublic'] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: coverUrl != null
                ? Image.network(
                    coverUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultCover();
                    },
                  )
                : _buildDefaultCover(),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      isPublic ? Icons.public : Icons.lock,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '$memberCount สมาชิก',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.article, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '$postCount โพสต์',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isJoined
                        ? () => _viewGroup(groupId)
                        : () => _joinGroup(groupId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isJoined ? AppColors.primaryTeal : Colors.white,
                      foregroundColor:
                          isJoined ? Colors.white : AppColors.primaryTeal,
                      side: isJoined
                          ? null
                          : BorderSide(color: AppColors.primaryTeal),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isJoined ? 'เข้าชมกลุ่ม' : 'เข้าร่วม',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupGridCard(String groupId, Map<String, dynamic> group) {
    final name = group['name'] ?? 'ไม่มีชื่อ';
    final coverUrl = group['coverImageUrl'];
    final memberCount = group['memberCount'] ?? 0;

    return GestureDetector(
      onTap: () => _viewGroup(groupId),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: coverUrl != null
                    ? Image.network(
                        coverUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultCover();
                        },
                      )
                    : _buildDefaultCover(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '$memberCount',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
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
    );
  }

  Widget _buildDefaultCover() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryTeal, AppColors.accentGreen],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.group,
          size: 48,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 250,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.group_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppColors.primaryTeal),
            const SizedBox(width: 12),
            const Text(
              'ค้นหากลุ่ม',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'ชื่อกลุ่ม...',
            prefixIcon: const Icon(Icons.search_rounded),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onSubmitted: (value) {
            Navigator.pop(context);
            // TODO: Implement search functionality with value
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.group_add_rounded, color: AppColors.primaryTeal),
            const SizedBox(width: 12),
            const Text(
              'สร้างกลุ่มใหม่',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'ชื่อกลุ่ม',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'คำอธิบาย',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กรุณากรอกชื่อกลุ่ม')),
                );
                return;
              }

              // Create group
              final currentUserId =
                  context.read<UserProvider>().currentUser?.id;
              if (currentUserId == null) return;

              await FirebaseFirestore.instance
                  .collection('community_groups')
                  .add({
                'name': nameController.text.trim(),
                'description': descController.text.trim(),
                'creatorId': currentUserId,
                'memberIds': [currentUserId],
                'memberCount': 1,
                'createdAt': FieldValue.serverTimestamp(),
                'isActive': true,
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('สร้างกลุ่มเรียบร้อยแล้ว')),
                );
                setState(() {}); // Refresh list
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
            ),
            child:
                const Text('สร้าง', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _joinGroup(String groupId) async {
    final currentUser = context.read<UserProvider>().currentUser;
    if (currentUser == null) {
      ModernDialog.showError(
        context: context,
        title: 'กรุณาเข้าสู่ระบบ',
        message: 'คุณต้องเข้าสู่ระบบก่อนเข้าร่วมกลุ่ม',
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('community_groups')
          .doc(groupId)
          .update({
        'members': FieldValue.arrayUnion([currentUser.id]),
        'memberCount': FieldValue.increment(1),
      });

      ModernDialog.showSuccess(
        context: context,
        title: 'เข้าร่วมสำเร็จ!',
        message: 'คุณได้เข้าร่วมกลุ่มแล้ว',
      );
    } catch (e) {
      ModernDialog.showError(
        context: context,
        title: 'เกิดข้อผิดพลาด',
        message: e.toString(),
      );
    }
  }

  void _viewGroup(String groupId) {
    Navigator.pushNamed(
      context,
      '/group_detail',
      arguments: groupId,
    );
  }
}
