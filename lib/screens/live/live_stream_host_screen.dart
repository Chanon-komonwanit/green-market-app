// lib/screens/live/live_stream_host_screen.dart
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';
import '../../models/live_stream.dart';
import '../../services/agora_service.dart';
import '../../services/live_stream_service.dart';
import '../../providers/user_provider.dart';
import '../../utils/constants.dart';

/// หน้าสำหรับ Host ถ่ายทอดสด (Facebook/Instagram Live Host)
class LiveStreamHostScreen extends StatefulWidget {
  final String streamId;
  final LiveStream liveStream;

  const LiveStreamHostScreen({
    super.key,
    required this.streamId,
    required this.liveStream,
  });

  @override
  State<LiveStreamHostScreen> createState() => _LiveStreamHostScreenState();
}

class _LiveStreamHostScreenState extends State<LiveStreamHostScreen> {
  final AgoraService _agoraService = AgoraService();
  final LiveStreamService _liveService = LiveStreamService();

  bool _isInitialized = false;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isFrontCamera = true;
  bool _showComments = true;

  Timer? _durationTimer;
  Duration _liveDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeAgora();
    WakelockPlus.enable(); // Keep screen on
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  Future<void> _initializeAgora() async {
    try {
      // Initialize Agora
      await _agoraService.initialize();

      // Setup event handlers
      _agoraService.engine?.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            print('Host joined channel: ${connection.channelId}');
            setState(() => _isInitialized = true);
            _startDurationTimer();
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            print('Viewer joined: $remoteUid');
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            print('Viewer left: $remoteUid');
          },
          onError: (ErrorCodeType err, String msg) {
            print('Agora Error: $err - $msg');
          },
        ),
      );

      // Join as broadcaster
      await _agoraService.joinChannelAsBroadcaster(
        channelName: widget.liveStream.agoraChannelName!,
        token: widget.liveStream.agoraToken ?? '',
        uid: 0, // Agora will assign UID automatically
      );
    } catch (e) {
      print('Agora initialization error: $e');
      _showError('ไม่สามารถเริ่มไลฟ์สดได้: $e');
    }
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _liveDuration = Duration(seconds: _liveDuration.inSeconds + 1);
      });
    });
  }

  Future<void> _cleanup() async {
    _durationTimer?.cancel();
    await _agoraService.leaveChannel();
    await WakelockPlus.disable();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          _buildCameraPreview(),

          // Top Overlay
          _buildTopOverlay(),

          // Comments Overlay
          if (_showComments) _buildCommentsOverlay(),

          // Bottom Controls
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      children: [
        // Local preview (broadcaster view)
        AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: _agoraService.engine!,
            canvas: const VideoCanvas(uid: 0),
          ),
        ),

        // Placeholder if Agora App ID not configured
        if (AgoraConfig.appId == 'YOUR_AGORA_APP_ID')
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.yellow, width: 2),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber, color: Colors.yellow, size: 48),
                  SizedBox(height: 16),
                  Text(
                    '⚠️ Agora App ID ยังไม่ได้ตั้งค่า',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'กรุณาใส่ Agora App ID ใน\nlib/services/agora_service.dart',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTopOverlay() {
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
            // Live badge with duration
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
                    _formatDuration(_liveDuration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Stats
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('live_streams')
                  .doc(widget.streamId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();

                final data = snapshot.data!.data() as Map<String, dynamic>?;
                final viewers = data?['currentViewers'] ?? 0;
                final likes = data?['likesCount'] ?? 0;
                final comments = data?['commentsCount'] ?? 0;

                return Row(
                  children: [
                    _buildStatBadge(Icons.visibility, viewers.toString()),
                    const SizedBox(width: 8),
                    _buildStatBadge(Icons.favorite, likes.toString()),
                    const SizedBox(width: 8),
                    _buildStatBadge(Icons.comment, comments.toString()),
                  ],
                );
              },
            ),

            const SizedBox(width: 12),

            // Close button
            IconButton(
              onPressed: _showEndLiveDialog,
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsOverlay() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 100,
      child: Container(
        height: 200,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('live_streams')
              .doc(widget.streamId)
              .collection('comments')
              .orderBy('timestamp', descending: false)
              .limit(20)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();

            final comments = snapshot.data!.docs;

            return ListView.builder(
              reverse: false,
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index].data() as Map<String, dynamic>;
                return _buildCommentBubble(
                  comment['userName'] ?? 'ผู้ใช้',
                  comment['message'] ?? '',
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

  Widget _buildBottomControls() {
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
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Switch Camera
            _buildControlButton(
              icon: Icons.switch_camera,
              label: 'กลับกล้อง',
              onPressed: _switchCamera,
            ),

            // Mute/Unmute Audio
            _buildControlButton(
              icon: _isMuted ? Icons.mic_off : Icons.mic,
              label: _isMuted ? 'เปิดเสียง' : 'ปิดเสียง',
              onPressed: _toggleMute,
              isActive: !_isMuted,
            ),

            // Camera On/Off
            _buildControlButton(
              icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
              label: _isCameraOff ? 'เปิดกล้อง' : 'ปิดกล้อง',
              onPressed: _toggleCamera,
              isActive: !_isCameraOff,
            ),

            // Toggle Comments
            _buildControlButton(
              icon: _showComments ? Icons.chat : Icons.chat_bubble_outline,
              label: 'ความคิดเห็น',
              onPressed: () {
                setState(() => _showComments = !_showComments);
              },
            ),

            // End Live
            _buildControlButton(
              icon: Icons.call_end,
              label: 'จบไลฟ์',
              onPressed: _showEndLiveDialog,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = true,
    Color? color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: (color ?? Colors.white).withOpacity(isActive ? 0.3 : 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: color ?? Colors.white,
              width: 2,
            ),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: color ?? Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Future<void> _switchCamera() async {
    try {
      await _agoraService.switchCamera();
      setState(() => _isFrontCamera = !_isFrontCamera);
    } catch (e) {
      print('Switch camera error: $e');
    }
  }

  Future<void> _toggleMute() async {
    try {
      await _agoraService.muteLocalAudio(!_isMuted);
      setState(() => _isMuted = !_isMuted);
    } catch (e) {
      print('Toggle mute error: $e');
    }
  }

  Future<void> _toggleCamera() async {
    try {
      await _agoraService.muteLocalVideo(!_isCameraOff);
      setState(() => _isCameraOff = !_isCameraOff);
    } catch (e) {
      print('Toggle camera error: $e');
    }
  }

  void _showEndLiveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('จบการถ่ายทอดสด?'),
        content: const Text('คุณต้องการจบการถ่ายทอดสดใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _endLiveStream();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('จบไลฟ์'),
          ),
        ],
      ),
    );
  }

  Future<void> _endLiveStream() async {
    try {
      // End live stream
      await _liveService.endLiveStream(widget.streamId);

      // Cleanup
      await _cleanup();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('จบการถ่ายทอดสดแล้ว'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      _showError('ไม่สามารถจบไลฟ์สดได้: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
