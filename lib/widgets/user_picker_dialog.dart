// lib/widgets/user_picker_dialog.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/constants.dart';

/// Dialog for selecting users to tag in posts
/// Shows friends first, then all users
class UserPickerDialog extends StatefulWidget {
  final List<String> alreadySelectedIds;
  final String currentUserId;

  const UserPickerDialog({
    super.key,
    required this.alreadySelectedIds,
    required this.currentUserId,
  });

  @override
  State<UserPickerDialog> createState() => _UserPickerDialogState();
}

class _UserPickerDialogState extends State<UserPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _selectedUserIds = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedUserIds = List.from(widget.alreadySelectedIds);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'แท็กเพื่อน',
                  style: AppTextStyles.headline,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ค้นหาเพื่อน...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase().trim();
                });
              },
            ),

            const SizedBox(height: 16),

            // Selected users chips
            if (_selectedUserIds.isNotEmpty)
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedUserIds.length,
                  itemBuilder: (context, index) {
                    return _buildSelectedUserChip(_selectedUserIds[index]);
                  },
                ),
              ),

            if (_selectedUserIds.isNotEmpty) const Divider(),

            // User list
            Expanded(
              child: _buildUserList(),
            ),

            const SizedBox(height: 16),

            // Done button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _selectedUserIds),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'เสร็จสิ้น (${_selectedUserIds.length})',
                  style: AppTextStyles.bodyBold.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedUserChip(String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        if (userData == null) return const SizedBox.shrink();

        final displayName = userData['displayName'] ?? 'Unknown';

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Chip(
            avatar: CircleAvatar(
              backgroundImage: userData['photoUrl'] != null
                  ? CachedNetworkImageProvider(userData['photoUrl'])
                  : null,
              child: userData['photoUrl'] == null
                  ? Text(displayName[0].toUpperCase())
                  : null,
            ),
            label: Text(displayName),
            deleteIcon: const Icon(Icons.close, size: 18),
            onDeleted: () {
              setState(() {
                _selectedUserIds.remove(userId);
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildUserList() {
    // Get friends first, then all users
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, isNotEqualTo: widget.currentUserId)
          .limit(100)
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
                  Icons.people_outline,
                  size: 64,
                  color: AppColors.graySecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'ไม่พบผู้ใช้',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.graySecondary,
                  ),
                ),
              ],
            ),
          );
        }

        // Filter users by search query
        final users = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final displayName =
              (data['displayName'] ?? '').toString().toLowerCase();
          final username = (data['username'] ?? '').toString().toLowerCase();
          return _searchQuery.isEmpty ||
              displayName.contains(_searchQuery) ||
              username.contains(_searchQuery);
        }).toList();

        if (users.isEmpty) {
          return Center(
            child: Text(
              'ไม่พบผู้ใช้ที่ค้นหา',
              style: AppTextStyles.body.copyWith(
                color: AppColors.graySecondary,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userData = users[index].data() as Map<String, dynamic>;
            final userId = users[index].id;
            final isSelected = _selectedUserIds.contains(userId);

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: userData['photoUrl'] != null
                    ? CachedNetworkImageProvider(userData['photoUrl'])
                    : null,
                child: userData['photoUrl'] == null
                    ? Text((userData['displayName'] ?? 'U')[0].toUpperCase())
                    : null,
              ),
              title: Text(userData['displayName'] ?? 'Unknown User'),
              subtitle: userData['bio'] != null
                  ? Text(
                      userData['bio'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              trailing: Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected
                    ? AppColors.primaryTeal
                    : AppColors.graySecondary,
              ),
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedUserIds.remove(userId);
                  } else {
                    if (_selectedUserIds.length < 20) {
                      _selectedUserIds.add(userId);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('สามารถแท็กได้สูงสุด 20 คน'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                });
              },
            );
          },
        );
      },
    );
  }
}
