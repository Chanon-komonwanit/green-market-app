// lib/screens/live/live_streams_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/live_stream.dart';
import '../../services/live_stream_service.dart';
import '../../providers/user_provider.dart';
import '../../utils/constants.dart';
import 'create_live_stream_screen.dart';
import 'live_stream_viewer_screen.dart';

/// หน้ารายการ Live Streams (เหมือน Facebook/Instagram Live)
class LiveStreamsListScreen extends StatefulWidget {
  const LiveStreamsListScreen({super.key});

  @override
  State<LiveStreamsListScreen> createState() => _LiveStreamsListScreenState();
}

class _LiveStreamsListScreenState extends State<LiveStreamsListScreen>
    with SingleTickerProviderStateMixin {
  final LiveStreamService _liveService = LiveStreamService();
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
    final userProvider = context.watch<UserProvider>();
    final currentUser = userProvider.currentUser;

    return Scaffold(
      backgroundColor: AppColors.surfaceGray,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.red, Colors.pink],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.circle, color: Colors.white, size: 8),
                  SizedBox(width: 6),
                  Text('LIVE',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text('ไลฟ์สด', style: AppTextStyles.headline),
          ],
        ),
        backgroundColor: AppColors.white,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryTeal,
          labelColor: AppColors.primaryTeal,
          unselectedLabelColor: AppColors.graySecondary,
          tabs: const [
            Tab(text: '🔴 กำลังไลฟ์'),
            Tab(text: '📅 กำหนดเวลา'),
            Tab(text: '📺 บันทึก'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveLives(),
          _buildScheduledLives(),
          _buildRecordedLives(),
        ],
      ),
      floatingActionButton: currentUser != null
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateLiveDialog(context),
              backgroundColor: Colors.red,
              icon: const Icon(Icons.videocam, color: Colors.white),
              label: const Text(
                'ไลฟ์สด',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  /// รายการไลฟ์ที่กำลังดำเนินการ
  Widget _buildActiveLives() {
    return StreamBuilder<List<LiveStream>>(
      stream: _liveService.getActiveLiveStreams(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingGrid();
        }

        if (snapshot.hasError) {
          return _buildErrorState('เกิดข้อผิดพลาด: ${snapshot.error}');
        }

        final lives = snapshot.data ?? [];

        if (lives.isEmpty) {
          return _buildEmptyState(
            icon: Icons.videocam_off,
            title: 'ยังไม่มีไลฟ์สด',
            subtitle: 'เป็นคนแรกที่เริ่มไลฟ์สด!',
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.7,
          ),
          itemCount: lives.length,
          itemBuilder: (context, index) => _buildLiveCard(lives[index]),
        );
      },
    );
  }

  /// รายการไลฟ์ที่กำหนดเวลาไว้
  Widget _buildScheduledLives() {
    // TODO: Query scheduled streams
    return _buildEmptyState(
      icon: Icons.schedule,
      title: 'ยังไม่มีไลฟ์ที่กำหนดเวลา',
      subtitle: 'จัดตารางไลฟ์สดของคุณล่วงหน้า',
    );
  }

  /// รายการไลฟ์ที่บันทึกไว้
  Widget _buildRecordedLives() {
    // TODO: Query recorded streams
    return _buildEmptyState(
      icon: Icons.video_library,
      title: 'ยังไม่มีไลฟ์บันทึก',
      subtitle: 'ไลฟ์สดที่ผ่านมาจะถูกบันทึกไว้ที่นี่',
    );
  }

  /// Card สำหรับแต่ละ Live Stream
  Widget _buildLiveCard(LiveStream live) {
    return GestureDetector(
      onTap: () => _openLiveStream(live),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Thumbnail/Background
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: live.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: live.thumbnailUrl!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey[800],
                      child: const Center(
                        child: Icon(
                          Icons.videocam,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
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

            // LIVE Badge
            Positioned(
              top: 8,
              left: 8,
              child: _buildLiveBadge(live.currentViewers),
            ),

            // Stream Info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      live.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Streamer info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundImage: live.streamerPhoto != null
                              ? CachedNetworkImageProvider(live.streamerPhoto!)
                              : null,
                          backgroundColor: Colors.grey,
                          child: live.streamerPhoto == null
                              ? const Icon(Icons.person,
                                  size: 14, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            live.streamerName,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Live Badge แบบ Facebook/Instagram
  Widget _buildLiveBadge(int viewers) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.red, Colors.pink],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, color: Colors.white, size: 8),
          const SizedBox(width: 4),
          const Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _formatViewers(viewers),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _formatViewers(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: AppColors.grayBorder,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: AppColors.graySecondary),
          const SizedBox(height: 16),
          Text(
            title,
            style:
                AppTextStyles.subtitle.copyWith(color: AppColors.grayPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.body.copyWith(color: AppColors.graySecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: AppColors.errorRed),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.body.copyWith(color: AppColors.errorRed),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showCreateLiveDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateLiveStreamScreen(),
    );
  }

  void _openLiveStream(LiveStream live) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveStreamViewerScreen(streamId: live.id),
      ),
    );
  }
}
