// lib/widgets/post_reactions.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

/// Post Reactions Widget (Facebook-style)
/// แสดงและจัดการ reactions แบบ Facebook (Love, Wow, Haha, Sad, Angry)
class PostReactions extends StatefulWidget {
  final String postId;
  final String currentUserId;
  final Map<String, dynamic> reactions;
  final Function(ReactionType type) onReact;

  const PostReactions({
    super.key,
    required this.postId,
    required this.currentUserId,
    required this.reactions,
    required this.onReact,
  });

  @override
  State<PostReactions> createState() => _PostReactionsState();
}

class _PostReactionsState extends State<PostReactions> {
  bool _isExpanded = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isExpanded = false;
  }

  void _showReactionPicker() {
    if (_isExpanded) {
      _removeOverlay();
      return;
    }

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isExpanded = true);
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: 320,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(-120, -size.height - 60),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ReactionType.values.map((type) {
                  return _buildReactionButton(type);
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReactionButton(ReactionType type) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: InkWell(
            onTap: () {
              widget.onReact(type);
              _removeOverlay();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    type.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    type.label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  ReactionType? _getCurrentUserReaction() {
    for (var type in ReactionType.values) {
      final users = widget.reactions[type.name] as List? ?? [];
      if (users.contains(widget.currentUserId)) {
        return type;
      }
    }
    return null;
  }

  int _getTotalReactions() {
    int total = 0;
    for (var type in ReactionType.values) {
      final users = widget.reactions[type.name] as List? ?? [];
      total += users.length;
    }
    return total;
  }

  List<ReactionType> _getTopReactions() {
    final counts = <ReactionType, int>{};
    for (var type in ReactionType.values) {
      final users = widget.reactions[type.name] as List? ?? [];
      if (users.isNotEmpty) {
        counts[type] = users.length;
      }
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(3).map((e) => e.key).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentReaction = _getCurrentUserReaction();
    final totalReactions = _getTotalReactions();
    final topReactions = _getTopReactions();

    return CompositedTransformTarget(
      link: _layerLink,
      child: Row(
        children: [
          // Like/React Button
          InkWell(
            onTap: () {
              if (currentReaction == null) {
                widget.onReact(ReactionType.like);
              } else {
                widget.onReact(ReactionType.like); // Toggle off
              }
            },
            onLongPress: _showReactionPicker,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (currentReaction != null)
                    Text(
                      currentReaction.emoji,
                      style: const TextStyle(fontSize: 20),
                    )
                  else
                    Icon(
                      Icons.thumb_up_outlined,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                  const SizedBox(width: 6),
                  Text(
                    currentReaction?.label ?? 'ถูกใจ',
                    style: TextStyle(
                      color: currentReaction != null
                          ? currentReaction.color
                          : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Reaction Count & Icons
          if (totalReactions > 0) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _showReactionDetails(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top reaction emojis
                    ...topReactions.take(3).map((type) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Text(
                          type.emoji,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }),
                    const SizedBox(width: 4),
                    Text(
                      totalReactions.toString(),
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showReactionDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ReactionDetailsSheet(
        postId: widget.postId,
        reactions: widget.reactions,
      ),
    );
  }
}

/// Reaction Details Sheet
class ReactionDetailsSheet extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> reactions;

  const ReactionDetailsSheet({
    super.key,
    required this.postId,
    required this.reactions,
  });

  @override
  State<ReactionDetailsSheet> createState() => _ReactionDetailsSheetState();
}

class _ReactionDetailsSheetState extends State<ReactionDetailsSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<ReactionType> _tabs = [ReactionType.all, ...ReactionType.values];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'รีแอคชัน',
                style: AppTextStyles.headline,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),

          // Tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primaryTeal,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primaryTeal,
            tabs: _tabs.map((type) {
              final count = type == ReactionType.all
                  ? _getTotalCount()
                  : (widget.reactions[type.name] as List?)?.length ?? 0;

              return Tab(
                child: Row(
                  children: [
                    if (type != ReactionType.all)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(type.emoji,
                            style: const TextStyle(fontSize: 18)),
                      ),
                    Text(type == ReactionType.all ? 'ทั้งหมด' : type.label),
                    const SizedBox(width: 4),
                    Text('($count)', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            }).toList(),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((type) {
                return _buildReactionList(type);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  int _getTotalCount() {
    int total = 0;
    for (var type in ReactionType.values) {
      total += (widget.reactions[type.name] as List?)?.length ?? 0;
    }
    return total;
  }

  Widget _buildReactionList(ReactionType type) {
    List<String> userIds = [];

    if (type == ReactionType.all) {
      for (var t in ReactionType.values) {
        userIds
            .addAll((widget.reactions[t.name] as List?)?.cast<String>() ?? []);
      }
    } else {
      userIds = (widget.reactions[type.name] as List?)?.cast<String>() ?? [];
    }

    if (userIds.isEmpty) {
      return const Center(child: Text('ยังไม่มีรีแอคชัน'));
    }

    return ListView.builder(
      itemCount: userIds.length,
      itemBuilder: (context, index) {
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(userIds[index])
              .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const ListTile(
                leading: CircleAvatar(child: Icon(Icons.person)),
                title: Text('กำลังโหลด...'),
              );
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>?;
            final displayName = userData?['displayName'] ?? 'ผู้ใช้';
            final photoUrl = userData?['photoUrl'] as String?;

            return ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? Text(displayName[0].toUpperCase())
                    : null,
              ),
              title: Text(displayName),
              trailing: type == ReactionType.all
                  ? _getUserReactionIcon(userIds[index])
                  : null,
            );
          },
        );
      },
    );
  }

  Widget? _getUserReactionIcon(String userId) {
    for (var type in ReactionType.values) {
      final users = widget.reactions[type.name] as List? ?? [];
      if (users.contains(userId)) {
        return Text(type.emoji, style: const TextStyle(fontSize: 20));
      }
    }
    return null;
  }
}

/// Reaction Types
enum ReactionType {
  like,
  love,
  haha,
  wow,
  sad,
  angry,
  all; // For filtering

  String get emoji {
    switch (this) {
      case ReactionType.like:
        return '👍';
      case ReactionType.love:
        return '❤️';
      case ReactionType.haha:
        return '😆';
      case ReactionType.wow:
        return '😮';
      case ReactionType.sad:
        return '😢';
      case ReactionType.angry:
        return '😠';
      case ReactionType.all:
        return '';
    }
  }

  String get label {
    switch (this) {
      case ReactionType.like:
        return 'ถูกใจ';
      case ReactionType.love:
        return 'รัก';
      case ReactionType.haha:
        return 'ฮา';
      case ReactionType.wow:
        return 'ว้าว';
      case ReactionType.sad:
        return 'เศร้า';
      case ReactionType.angry:
        return 'โกรธ';
      case ReactionType.all:
        return 'ทั้งหมด';
    }
  }

  Color get color {
    switch (this) {
      case ReactionType.like:
        return const Color(0xFF2078F4);
      case ReactionType.love:
        return const Color(0xFFF33E58);
      case ReactionType.haha:
        return const Color(0xFFF7B125);
      case ReactionType.wow:
        return const Color(0xFFF7B125);
      case ReactionType.sad:
        return const Color(0xFFF7B125);
      case ReactionType.angry:
        return const Color(0xFFE9710F);
      case ReactionType.all:
        return Colors.grey;
    }
  }

  String get name {
    return toString().split('.').last;
  }
}

/// Helper function to handle reactions
Future<void> handlePostReaction({
  required String postId,
  required String userId,
  required ReactionType type,
  required Map<String, dynamic> currentReactions,
}) async {
  final batch = FirebaseFirestore.instance.batch();
  final postRef =
      FirebaseFirestore.instance.collection('forum_posts').doc(postId);

  // Remove user from all reaction types
  final updatedReactions = Map<String, dynamic>.from(currentReactions);
  for (var reactionType in ReactionType.values) {
    if (reactionType == ReactionType.all) continue;
    final users = List<String>.from(updatedReactions[reactionType.name] ?? []);
    users.remove(userId);
    updatedReactions[reactionType.name] = users;
  }

  // Add to new reaction type (toggle off if same)
  final currentTypeUsers = List<String>.from(currentReactions[type.name] ?? []);
  if (!currentTypeUsers.contains(userId)) {
    final users = List<String>.from(updatedReactions[type.name] ?? []);
    users.add(userId);
    updatedReactions[type.name] = users;
  }

  // Update post
  batch.update(postRef, {'reactions': updatedReactions});

  await batch.commit();
}
