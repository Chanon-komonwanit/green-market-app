// lib/widgets/post_action_bar.dart
import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Instagram-style Post Action Bar
/// สร้างแถบ Action ด้านล่างโพสต์แบบ Instagram/Facebook
class PostActionBar extends StatefulWidget {
  final bool isLiked;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback? onReaction;
  final VoidCallback? onBookmark;
  final bool isBookmarked;

  const PostActionBar({
    super.key,
    required this.isLiked,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    this.onReaction,
    this.onBookmark,
    this.isBookmarked = false,
  });

  @override
  State<PostActionBar> createState() => _PostActionBarState();
}

class _PostActionBarState extends State<PostActionBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeController;
  late Animation<double> _likeAnimation;

  @override
  void initState() {
    super.initState();
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _likeAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _likeController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  void _handleLike() {
    if (widget.isLiked) {
      _likeController.reverse();
    } else {
      _likeController.forward().then((_) => _likeController.reverse());
    }
    widget.onLike();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Main Actions Row
          Row(
            children: [
              // Like Button (แบบ Instagram)
              _buildActionButton(
                icon: widget.isLiked ? Icons.favorite : Icons.favorite_border,
                color: widget.isLiked ? Colors.red : AppColors.graySecondary,
                onTap: _handleLike,
                scale: _likeAnimation,
              ),
              const SizedBox(width: 16),

              // Comment Button
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                color: AppColors.graySecondary,
                onTap: widget.onComment,
              ),
              const SizedBox(width: 16),

              // Share Button
              _buildActionButton(
                icon: Icons.send_outlined,
                color: AppColors.graySecondary,
                onTap: widget.onShare,
              ),

              const Spacer(),

              // Bookmark Button (แบบ Instagram)
              if (widget.onBookmark != null)
                _buildActionButton(
                  icon: widget.isBookmarked
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  color: widget.isBookmarked
                      ? AppColors.accentGreen
                      : AppColors.graySecondary,
                  onTap: widget.onBookmark!,
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Counts Row (แบบ Facebook)
          Row(
            children: [
              if (widget.likesCount > 0) ...[
                Icon(
                  Icons.favorite,
                  size: 14,
                  color: Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatCount(widget.likesCount),
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.grayPrimary,
                  ),
                ),
              ],
              const Spacer(),
              if (widget.commentsCount > 0)
                Text(
                  '${_formatCount(widget.commentsCount)} ความคิดเห็น',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.graySecondary,
                  ),
                ),
              if (widget.commentsCount > 0 && widget.sharesCount > 0)
                Text(
                  ' • ',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.graySecondary,
                  ),
                ),
              if (widget.sharesCount > 0)
                Text(
                  '${_formatCount(widget.sharesCount)} แชร์',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.graySecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    Animation<double>? scale,
  }) {
    Widget button = IconButton(
      icon: Icon(icon, size: 28),
      color: color,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: onTap,
    );

    if (scale != null) {
      return ScaleTransition(
        scale: scale,
        child: button,
      );
    }

    return button;
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}

/// Quick Reaction Bar (แบบ Facebook)
/// แสดง Reaction แบบ Facebook ที่มี 7 แบบ
class QuickReactionBar extends StatelessWidget {
  final Function(String reaction) onReaction;
  final String? currentReaction;

  const QuickReactionBar({
    super.key,
    required this.onReaction,
    this.currentReaction,
  });

  static const reactions = [
    {'emoji': '👍', 'name': 'like', 'color': Colors.blue},
    {'emoji': '❤️', 'name': 'love', 'color': Colors.red},
    {'emoji': '😂', 'name': 'haha', 'color': Colors.orange},
    {'emoji': '😮', 'name': 'wow', 'color': Colors.amber},
    {'emoji': '😢', 'name': 'sad', 'color': Colors.blue},
    {'emoji': '😡', 'name': 'angry', 'color': Colors.deepOrange},
    {'emoji': '🌱', 'name': 'eco', 'color': Colors.green},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactions.map((reaction) {
          final isSelected = currentReaction == reaction['name'];
          return _buildReactionButton(
            emoji: reaction['emoji'] as String,
            name: reaction['name'] as String,
            color: reaction['color'] as Color,
            isSelected: isSelected,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReactionButton({
    required String emoji,
    required String name,
    required Color color,
    required bool isSelected,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(
          milliseconds: 200 +
              (reactions
                      .indexOf({'emoji': emoji, 'name': name, 'color': color}) *
                  50)),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: GestureDetector(
            onTap: () => onReaction(name),
            child: Container(
              width: 45,
              height: 45,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: TextStyle(
                    fontSize: isSelected ? 28 : 24,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
