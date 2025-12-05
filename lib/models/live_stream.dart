// lib/models/live_stream.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum LiveStreamStatus {
  scheduled, // กำหนดเวลาไว้แล้ว
  live, // กำลังไลฟ์อยู่
  ended, // จบแล้ว
  archived, // เก็บเป็น archive (SD)
  deleted, // ลบแล้ว
}

enum LiveStreamQuality {
  sd, // 480p - สำหรับ archive
  hd, // 720p - ขณะ live
  fullHd, // 1080p - ไม่แนะนำสำหรับแอพเล็ก
}

class LiveStream {
  final String id;
  final String streamerId; // Host ID
  final String streamerName;
  final String? streamerPhoto;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final LiveStreamStatus status;
  final LiveStreamQuality quality;

  // Stream details
  final String? agoraChannelName; // Agora channel
  final String? agoraToken; // Agora token
  final String? recordingId; // Recording ID
  final String? recordedVideoUrl; // URL หลังจบ live

  // Stats
  final int currentViewers;
  final int totalViewers;
  final int peakViewers;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;

  // Timestamps
  final Timestamp scheduledAt;
  final Timestamp? startedAt;
  final Timestamp? endedAt;
  final Timestamp createdAt;
  final Timestamp? archivedAt;
  final Timestamp? deleteAt; // วันที่จะลบ (auto-delete)

  // Settings
  final bool isRecording; // บันทึกหรือไม่
  final bool allowComments;
  final bool isPublic;
  final List<String> tags;
  final List<String> mentions;

  // Retention policy
  final int retentionDays; // จำนวนวันที่เก็บไว้
  final bool autoDeleteEnabled; // ลบอัตโนมัติหรือไม่

  // Getter for channel name (alias for agoraChannelName)
  String? get channelName => agoraChannelName;

  const LiveStream({
    required this.id,
    required this.streamerId,
    required this.streamerName,
    this.streamerPhoto,
    required this.title,
    this.description,
    this.thumbnailUrl,
    required this.status,
    this.quality = LiveStreamQuality.hd,
    this.agoraChannelName,
    this.agoraToken,
    this.recordingId,
    this.recordedVideoUrl,
    this.currentViewers = 0,
    this.totalViewers = 0,
    this.peakViewers = 0,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    required this.scheduledAt,
    this.startedAt,
    this.endedAt,
    required this.createdAt,
    this.archivedAt,
    this.deleteAt,
    this.isRecording = true,
    this.allowComments = true,
    this.isPublic = true,
    this.tags = const [],
    this.mentions = const [],
    this.retentionDays = 7, // เก็บไว้ 7 วัน (น้อยกว่า Facebook)
    this.autoDeleteEnabled = true,
  });

  // Duration
  Duration? get duration {
    if (startedAt == null) return null;
    final end = endedAt ?? Timestamp.now();
    return end.toDate().difference(startedAt!.toDate());
  }

  // Is live now
  bool get isLive => status == LiveStreamStatus.live;

  // Is scheduled
  bool get isScheduled => status == LiveStreamStatus.scheduled;

  // Is ended but still available
  bool get isAvailable =>
      status == LiveStreamStatus.ended || status == LiveStreamStatus.archived;

  // Should auto-delete
  bool get shouldAutoDelete {
    if (!autoDeleteEnabled || deleteAt == null) return false;
    return DateTime.now().isAfter(deleteAt!.toDate());
  }

  factory LiveStream.fromMap(Map<String, dynamic> map, String docId) {
    return LiveStream(
      id: docId,
      streamerId: map['streamerId'] ?? '',
      streamerName: map['streamerName'] ?? '',
      streamerPhoto: map['streamerPhoto'],
      title: map['title'] ?? '',
      description: map['description'],
      thumbnailUrl: map['thumbnailUrl'],
      status: _parseStatus(map['status']),
      quality: _parseQuality(map['quality']),
      agoraChannelName: map['agoraChannelName'],
      agoraToken: map['agoraToken'],
      recordingId: map['recordingId'],
      recordedVideoUrl: map['recordedVideoUrl'],
      currentViewers: map['currentViewers'] ?? 0,
      totalViewers: map['totalViewers'] ?? 0,
      peakViewers: map['peakViewers'] ?? 0,
      likesCount: map['likesCount'] ?? 0,
      commentsCount: map['commentsCount'] ?? 0,
      sharesCount: map['sharesCount'] ?? 0,
      scheduledAt: map['scheduledAt'] ?? Timestamp.now(),
      startedAt: map['startedAt'],
      endedAt: map['endedAt'],
      createdAt: map['createdAt'] ?? Timestamp.now(),
      archivedAt: map['archivedAt'],
      deleteAt: map['deleteAt'],
      isRecording: map['isRecording'] ?? true,
      allowComments: map['allowComments'] ?? true,
      isPublic: map['isPublic'] ?? true,
      tags: List<String>.from(map['tags'] ?? []),
      mentions: List<String>.from(map['mentions'] ?? []),
      retentionDays: map['retentionDays'] ?? 7,
      autoDeleteEnabled: map['autoDeleteEnabled'] ?? true,
    );
  }

  factory LiveStream.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LiveStream.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'streamerId': streamerId,
      'streamerName': streamerName,
      'streamerPhoto': streamerPhoto,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'status': status.toString().split('.').last,
      'quality': quality.toString().split('.').last,
      'agoraChannelName': agoraChannelName,
      'agoraToken': agoraToken,
      'recordingId': recordingId,
      'recordedVideoUrl': recordedVideoUrl,
      'currentViewers': currentViewers,
      'totalViewers': totalViewers,
      'peakViewers': peakViewers,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'scheduledAt': scheduledAt,
      'startedAt': startedAt,
      'endedAt': endedAt,
      'createdAt': createdAt,
      'archivedAt': archivedAt,
      'deleteAt': deleteAt,
      'isRecording': isRecording,
      'allowComments': allowComments,
      'isPublic': isPublic,
      'tags': tags,
      'mentions': mentions,
      'retentionDays': retentionDays,
      'autoDeleteEnabled': autoDeleteEnabled,
    };
  }

  static LiveStreamStatus _parseStatus(dynamic status) {
    if (status == null) return LiveStreamStatus.scheduled;
    final str = status.toString().toLowerCase();
    switch (str) {
      case 'live':
        return LiveStreamStatus.live;
      case 'ended':
        return LiveStreamStatus.ended;
      case 'archived':
        return LiveStreamStatus.archived;
      case 'deleted':
        return LiveStreamStatus.deleted;
      default:
        return LiveStreamStatus.scheduled;
    }
  }

  static LiveStreamQuality _parseQuality(dynamic quality) {
    if (quality == null) return LiveStreamQuality.hd;
    final str = quality.toString().toLowerCase();
    switch (str) {
      case 'sd':
        return LiveStreamQuality.sd;
      case 'fullhd':
        return LiveStreamQuality.fullHd;
      default:
        return LiveStreamQuality.hd;
    }
  }

  LiveStream copyWith({
    LiveStreamStatus? status,
    int? currentViewers,
    int? totalViewers,
    int? peakViewers,
    int? likesCount,
    int? commentsCount,
    Timestamp? startedAt,
    Timestamp? endedAt,
    Timestamp? archivedAt,
    Timestamp? deleteAt,
    String? recordedVideoUrl,
    LiveStreamQuality? quality,
  }) {
    return LiveStream(
      id: id,
      streamerId: streamerId,
      streamerName: streamerName,
      streamerPhoto: streamerPhoto,
      title: title,
      description: description,
      thumbnailUrl: thumbnailUrl,
      status: status ?? this.status,
      quality: quality ?? this.quality,
      agoraChannelName: agoraChannelName,
      agoraToken: agoraToken,
      recordingId: recordingId,
      recordedVideoUrl: recordedVideoUrl ?? this.recordedVideoUrl,
      currentViewers: currentViewers ?? this.currentViewers,
      totalViewers: totalViewers ?? this.totalViewers,
      peakViewers: peakViewers ?? this.peakViewers,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount,
      scheduledAt: scheduledAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      createdAt: createdAt,
      archivedAt: archivedAt ?? this.archivedAt,
      deleteAt: deleteAt ?? this.deleteAt,
      isRecording: isRecording,
      allowComments: allowComments,
      isPublic: isPublic,
      tags: tags,
      mentions: mentions,
      retentionDays: retentionDays,
      autoDeleteEnabled: autoDeleteEnabled,
    );
  }
}
