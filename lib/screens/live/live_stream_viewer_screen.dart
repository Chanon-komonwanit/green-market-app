// lib/screens/live/live_stream_viewer_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/live_stream.dart';
import '../../services/live_stream_service.dart';
import '../../providers/user_provider.dart';
import '../../utils/constants.dart';
import 'dart:async';

/// หน้าดู Live Stream (เหมือน Facebook/Instagram Live Viewer)
class LiveStreamViewerScreen extends StatefulWidget {
  final String streamId;

  const LiveStreamViewerScreen({
    super.key,
    required this.streamId,
  });

  @override
  State<LiveStreamViewerScreen> createState() => _LiveStreamViewerScreenState();
}

class _LiveStreamViewerScreenState extends State<LiveStreamViewerScreen> {
  final LiveStreamService _liveService = LiveStreamService();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _commentScrollController = ScrollController();

  bool _isLiked = false;
  bool _showComments = true;
  StreamSubscription? _viewerSubscription;

  @override
  void initState() {
    super.initState();
    _joinStream();
  }

  @override
  void dispose() {
    _leaveStream();
    _commentController.dispose();
    _commentScrollController.dispose();
    _viewerSubscription?.cancel();
    super.dispose();
  }

  Future<void> _joinStream() async {
    try {
      final userProvider = context.read<UserProvider>();
      final currentUser = userProvider.currentUser;

      if (currentUser != null) {
        await _liveService.joinLiveStream(
          widget.streamId,
          currentUser.id,
          currentUser.displayName ?? 'ผู้ใช้',
        );
      }
    } catch (e) {
      print('Error joining stream: $e');
    }
  }

  Future<void> _leaveStream() async {
    try {
      final userProvider = context.read<UserProvider>();
      final currentUser = userProvider.currentUser;

      if (currentUser != null) {
        await _liveService.leaveLiveStream(widget.streamId, currentUser.id);
      }
    } catch (e) {
      print('Error leaving stream: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('live_streams')
            .doc(widget.streamId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildErrorState('ไม่พบไลฟ์สดนี้');
          }

          final liveStream = LiveStream.fromFirestore(snapshot.data!);

          if (liveStream.status == LiveStreamStatus.ended) {
            return _buildErrorState('ไลฟ์สดนี้จบแล้ว');
          }

          return Stack(
            children: [
              // Video Player (placeholder for now - will integrate Agora)
              _buildVideoPlayer(liveStream),

              // Top Overlay
              _buildTopOverlay(liveStream),

              // Comments Overlay
              if (_showComments) _buildCommentsOverlay(liveStream),

              // Bottom Controls
              _buildBottomControls(liveStream),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVideoPlayer(LiveStream liveStream) {
    // TODO: Integrate Agora SDK here
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: Colors.white, size: 12),
                  SizedBox(width: 8),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Video Stream',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Channel: ${liveStream.channelName}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              '⚠️ Agora SDK Integration Required',
              style: TextStyle(color: Colors.yellow, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopOverlay(LiveStream liveStream) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 16,
        ),
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
        child: Row(
          children: [
            // Close button
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
            const SizedBox(width: 12),

            // Streamer info
            CircleAvatar(
              backgroundImage: liveStream.streamerPhoto != null
                  ? NetworkImage(liveStream.streamerPhoto!)
                  : null,
              child: liveStream.streamerPhoto == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    liveStream.streamerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    liveStream.title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Live badge with viewer count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.circle, color: Colors.white, size: 8),
                  const SizedBox(width: 6),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatViewerCount(liveStream.currentViewers),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsOverlay(LiveStream liveStream) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 100,
      child: Container(
        height: 300,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('live_streams')
              .doc(widget.streamId)
              .collection('comments')
              .orderBy('timestamp', descending: false)
              .limit(50)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final comments = snapshot.data!.docs;

            // Auto scroll to bottom when new comment arrives
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_commentScrollController.hasClients) {
                _commentScrollController.animateTo(
                  _commentScrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });

            return ListView.builder(
              controller: _commentScrollController,
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index].data() as Map<String, dynamic>;
                return _buildCommentBubble(
                  comment['userName'] ?? 'ผู้ใช้',
                  comment['text'] ?? '',
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCommentBubble(String userName, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$userName: ',
                style: const TextStyle(
                  color: AppColors.primaryTeal,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              TextSpan(
                text: text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(LiveStream liveStream) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          top: 16,
        ),
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
        child: Row(
          children: [
            // Comment input
            Expanded(
              child: TextField(
                controller: _commentController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'แสดงความคิดเห็น...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendComment(),
              ),
            ),
            const SizedBox(width: 12),

            // Like button
            IconButton(
              onPressed: _toggleLike,
              icon: Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                color: _isLiked ? Colors.red : Colors.white,
                size: 28,
              ),
            ),

            // Share button
            IconButton(
              onPressed: _shareStream,
              icon: const Icon(
                Icons.share,
                color: Colors.white,
                size: 28,
              ),
            ),

            // Toggle comments
            IconButton(
              onPressed: () {
                setState(() => _showComments = !_showComments);
              },
              icon: Icon(
                _showComments ? Icons.visibility : Icons.visibility_off,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ย้อนกลับ'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    try {
      final userProvider = context.read<UserProvider>();
      final currentUser = userProvider.currentUser;

      if (currentUser != null) {
        await _liveService.addComment(
          streamId: widget.streamId,
          userId: currentUser.id,
          userName: currentUser.displayName ?? 'ผู้ใช้',
          userPhoto: currentUser.photoUrl,
          message: text,
        );
        _commentController.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ส่งความคิดเห็นไม่สำเร็จ: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  Future<void> _toggleLike() async {
    try {
      final userProvider = context.read<UserProvider>();
      final currentUser = userProvider.currentUser;

      if (currentUser != null) {
        await _liveService.toggleLike(widget.streamId, currentUser.id);
        setState(() => _isLiked = !_isLiked);
      }
    } catch (e) {
      print('Error toggling like: $e');
    }
  }

  Future<void> _shareStream() async {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ฟังก์ชันแชร์กำลังพัฒนา'),
      ),
    );
  }

  String _formatViewerCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
