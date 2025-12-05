// lib/screens/story_viewer_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import '../models/story.dart';
import '../services/story_service.dart';
import '../utils/constants.dart';
import '../widgets/modern_animations.dart';

/// Story Viewer Screen - แบบ Instagram
/// ดูสตอรี่แบบเต็มหน้าจอพร้อม swipe, progress bar, และ reply
class StoryViewerScreen extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;
  final String currentUserId;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
    required this.currentUserId,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentStoryIndex;
  late AnimationController _progressController;
  Timer? _storyTimer;
  VideoPlayerController? _videoController;
  final TextEditingController _replyController = TextEditingController();
  bool _isShowingReply = false;

  @override
  void initState() {
    super.initState();
    _currentStoryIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentStoryIndex);
    _progressController = AnimationController(vsync: this);
    _markAsViewed(_currentStoryIndex);
    _startStory();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _storyTimer?.cancel();
    _videoController?.dispose();
    _replyController.dispose();
    super.dispose();
  }

  void _startStory() {
    _progressController.reset();
    _storyTimer?.cancel();

    final currentStory = widget.stories[_currentStoryIndex];

    if (currentStory.mediaType == 'video') {
      _initializeVideo(currentStory.mediaUrl);
    } else {
      // Image story - use default duration
      final duration = Duration(seconds: currentStory.duration);
      _progressController.duration = duration;
      _progressController.forward();

      _storyTimer = Timer(duration, _nextStory);
    }
  }

  Future<void> _initializeVideo(String videoUrl) async {
    _videoController?.dispose();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

    try {
      await _videoController!.initialize();
      setState(() {});

      final videoDuration = _videoController!.value.duration;
      _progressController.duration = videoDuration;
      _progressController.forward();

      _videoController!.play();
      _videoController!.addListener(() {
        if (_videoController!.value.position >= videoDuration) {
          _nextStory();
        }
      });
    } catch (e) {
      debugPrint('Error loading video: $e');
      _nextStory();
    }
  }

  void _markAsViewed(int index) {
    final story = widget.stories[index];
    if (!story.viewedBy.contains(widget.currentUserId)) {
      FirebaseFirestore.instance.collection('stories').doc(story.id).update({
        'viewedBy': FieldValue.arrayUnion([widget.currentUserId])
      });
    }
  }

  void _nextStory() {
    if (_currentStoryIndex < widget.stories.length - 1) {
      _currentStoryIndex++;
      _pageController.animateToPage(
        _currentStoryIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _markAsViewed(_currentStoryIndex);
      _startStory();
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      _currentStoryIndex--;
      _pageController.animateToPage(
        _currentStoryIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startStory();
    }
  }

  void _pauseStory() {
    _progressController.stop();
    _storyTimer?.cancel();
    _videoController?.pause();
  }

  void _resumeStory() {
    _progressController.forward();
    _videoController?.play();
  }

  Future<void> _sendReply() async {
    final reply = _replyController.text.trim();
    if (reply.isEmpty) return;

    final currentStory = widget.stories[_currentStoryIndex];

    try {
      // Create chat message with story reply
      await FirebaseFirestore.instance
          .collection('community_chats')
          .doc(_getChatId(widget.currentUserId, currentStory.userId))
          .collection('messages')
          .add({
        'senderId': widget.currentUserId,
        'receiverId': currentStory.userId,
        'message': 'ตอบกลับสตอรี่: $reply',
        'type': 'story_reply',
        'storyId': currentStory.id,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update chat room
      await FirebaseFirestore.instance
          .collection('community_chats')
          .doc(_getChatId(widget.currentUserId, currentStory.userId))
          .set({
        'participants': [widget.currentUserId, currentStory.userId],
        'lastMessage': 'ตอบกลับสตอรี่',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': widget.currentUserId,
      }, SetOptions(merge: true));

      _replyController.clear();
      setState(() => _isShowingReply = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ส่งข้อความแล้ว'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending reply: $e');
    }
  }

  String _getChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onLongPressStart: (_) => _pauseStory(),
        onLongPressEnd: (_) => _resumeStory(),
        onTapDown: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 3) {
            _previousStory();
          } else if (details.globalPosition.dx > width * 2 / 3) {
            _nextStory();
          }
        },
        child: Stack(
          children: [
            // Story Content
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.stories.length,
              itemBuilder: (context, index) {
                final story = widget.stories[index];
                return _buildStoryContent(story);
              },
            ),

            // Top gradient overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Progress bars
            _buildProgressBars(),

            // Header
            _buildHeader(),

            // Reply section
            if (_isShowingReply) _buildReplySection(),

            // Bottom reply button
            if (!_isShowingReply) _buildReplyButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryContent(Story story) {
    if (story.mediaType == 'video' && _videoController != null) {
      return Center(
        child: _videoController!.value.isInitialized
            ? AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              )
            : const CircularProgressIndicator(color: Colors.white),
      );
    } else {
      return Image.network(
        story.mediaUrl,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!
                  : null,
              color: Colors.white,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.error, color: Colors.white, size: 64),
          );
        },
      );
    }
  }

  Widget _buildProgressBars() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 8,
      right: 8,
      child: Row(
        children: List.generate(
          widget.stories.length,
          (index) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: index == _currentStoryIndex
                    ? AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) {
                          return FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _progressController.value,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        },
                      )
                    : index < _currentStoryIndex
                        ? Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          )
                        : const SizedBox(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final story = widget.stories[_currentStoryIndex];
    final isOwnStory = story.userId == widget.currentUserId;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 8,
      right: 8,
      child: Row(
        children: [
          // Profile picture
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryTeal,
            backgroundImage: story.userPhotoUrl != null
                ? NetworkImage(story.userPhotoUrl!)
                : null,
            child: story.userPhotoUrl == null
                ? Text(
                    story.userName[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  )
                : null,
          ),
          const SizedBox(width: 8),

          // Username & time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getTimeAgo(story.createdAt.toDate()),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Close button
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),

          // More options (for own story)
          if (isOwnStory)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              color: Colors.grey[900],
              onSelected: (value) async {
                if (value == 'delete') {
                  await _deleteStory(story);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('ลบสตอรี่', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildReplyButton() {
    final story = widget.stories[_currentStoryIndex];
    final isOwnStory = story.userId == widget.currentUserId;

    if (isOwnStory) {
      return Positioned(
        bottom: MediaQuery.of(context).padding.bottom + 16,
        left: 16,
        right: 16,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.visibility, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                '${story.viewCount} คนดูแล้ว',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 16,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: () {
          setState(() => _isShowingReply = true);
          _pauseStory();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.send, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                'ส่งข้อความ',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplySection() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // Cancel button
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() => _isShowingReply = false);
                _resumeStory();
              },
            ),

            // Text field
            Expanded(
              child: TextField(
                controller: _replyController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'ส่งข้อความ...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send button
            IconButton(
              icon: const Icon(Icons.send, color: AppColors.primaryTeal),
              onPressed: _sendReply,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteStory(Story story) async {
    try {
      await FirebaseFirestore.instance
          .collection('stories')
          .doc(story.id)
          .delete();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบสตอรี่แล้ว')),
        );
      }
    } catch (e) {
      debugPrint('Error deleting story: $e');
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 1) return 'เมื่อสักครู่';
    if (difference.inMinutes < 60) return '${difference.inMinutes} นาทีที่แล้ว';
    if (difference.inHours < 24) return '${difference.inHours} ชั่วโมงที่แล้ว';
    return '${difference.inDays} วันที่แล้ว';
  }
}
