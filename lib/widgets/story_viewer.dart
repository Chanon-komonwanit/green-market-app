// lib/widgets/story_viewer.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:video_player/video_player.dart'; // TODO: Add this package later
import 'dart:async';
import '../models/story.dart';
import '../utils/constants.dart';

class StoryViewer extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;
  final Function(String storyId) onStoryViewed;
  final VoidCallback onComplete;

  const StoryViewer({
    super.key,
    required this.stories,
    this.initialIndex = 0,
    required this.onStoryViewed,
    required this.onComplete,
  });

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _progressController;
  // VideoPlayerController? _videoController; // TODO: Enable video support later
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _progressController = AnimationController(vsync: this);
    _loadStory();
  }

  @override
  void dispose() {
    _progressController.dispose();
    // _videoController?.dispose(); // TODO: Enable video support later
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadStory() async {
    final story = widget.stories[_currentIndex];
    widget.onStoryViewed(story.id);

    // TODO: Add video support later
    // if (story.mediaType == 'video') {
    //   _videoController?.dispose();
    //   _videoController = VideoPlayerController.network(story.mediaUrl)
    //     ..initialize().then((_) {
    //       setState(() {});
    //       _videoController!.play();
    //       _startProgress(_videoController!.value.duration.inSeconds);
    //     });
    // } else {
    _startProgress(story.duration);
    // }
  }

  void _startProgress(int seconds) {
    _progressController.duration = Duration(seconds: seconds);
    _progressController.forward(from: 0).then((_) {
      _nextStory();
    });
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _loadStory();
    } else {
      widget.onComplete();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _loadStory();
    }
  }

  void _pauseStory() {
    _progressController.stop();
    // _videoController?.pause(); // TODO: Enable video support later
  }

  void _resumeStory() {
    _progressController.forward();
    // _videoController?.play(); // TODO: Enable video support later
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 3) {
            _previousStory();
          } else if (details.globalPosition.dx > 2 * screenWidth / 3) {
            _nextStory();
          }
        },
        onLongPressStart: (_) => _pauseStory(),
        onLongPressEnd: (_) => _resumeStory(),
        child: Stack(
          children: [
            // Story Content
            Center(
              child: story.mediaType == 'video'
                  ? Container(
                      color: Colors.black,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_circle_outline,
                                size: 64, color: Colors.white),
                            SizedBox(height: 16),
                            Text(
                              'Video support coming soon!',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Image.network(
                      story.mediaUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const CircularProgressIndicator();
                      },
                    ),
            ),

            // Progress Indicators
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 8,
              child: Row(
                children: List.generate(
                  widget.stories.length,
                  (index) => Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: index == _currentIndex
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
                          : index < _currentIndex
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                )
                              : const SizedBox(),
                    ),
                  ),
                ),
              ),
            ),

            // User Info Header
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: story.userPhotoUrl != null
                        ? NetworkImage(story.userPhotoUrl!)
                        : null,
                    child: story.userPhotoUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatTimestamp(story.createdAt),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onComplete,
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Caption
            if (story.caption != null && story.caption!.isNotEmpty)
              Positioned(
                bottom: 100,
                left: 16,
                right: 16,
                child: Text(
                  story.caption!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      final DateTime dateTime = timestamp is DateTime
          ? timestamp
          : (timestamp is Timestamp ? timestamp.toDate() : DateTime.now());
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'เมื่อสักครู่';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes} นาที';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} ชั่วโมง';
      } else {
        return '${difference.inDays} วัน';
      }
    } catch (e) {
      return '';
    }
  }
}
