// lib/services/live_stream_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:math';
import '../models/live_stream.dart';

class LiveStreamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ==================== CREATE & SCHEDULE ====================

  /// สร้าง Live Stream ใหม่
  Future<String> createLiveStream({
    required String streamerId,
    required String streamerName,
    String? streamerPhoto,
    required String title,
    String? description,
    DateTime? scheduledTime,
    List<String> tags = const [],
    bool allowComments = true,
    bool isPublic = true,
    int retentionDays = 7, // เก็บไว้ 7 วัน (ประหยัดกว่า Facebook)
  }) async {
    final now = Timestamp.now();
    final scheduled =
        scheduledTime != null ? Timestamp.fromDate(scheduledTime) : now;

    // สร้าง Agora channel name (unique)
    final channelName =
        'live_${streamerId}_${DateTime.now().millisecondsSinceEpoch}';

    final liveStream = LiveStream(
      id: '',
      streamerId: streamerId,
      streamerName: streamerName,
      streamerPhoto: streamerPhoto,
      title: title,
      description: description,
      status: scheduledTime != null
          ? LiveStreamStatus.scheduled
          : LiveStreamStatus.live,
      quality: LiveStreamQuality.hd,
      agoraChannelName: channelName,
      scheduledAt: scheduled,
      createdAt: now,
      allowComments: allowComments,
      isPublic: isPublic,
      tags: tags,
      retentionDays: retentionDays,
      autoDeleteEnabled: true,
    );

    final docRef =
        await _firestore.collection('live_streams').add(liveStream.toMap());
    return docRef.id;
  }

  // ==================== START & END ====================

  /// เริ่ม Live Stream
  Future<void> startLiveStream(String streamId) async {
    final now = Timestamp.now();
    await _firestore.collection('live_streams').doc(streamId).update({
      'status': 'live',
      'startedAt': now,
      'currentViewers': 0,
      'totalViewers': 0,
      'peakViewers': 0,
    });

    // Log activity
    await _logStreamActivity(streamId, 'started');
  }

  /// จบ Live Stream
  Future<void> endLiveStream(String streamId) async {
    final now = Timestamp.now();
    final liveDoc =
        await _firestore.collection('live_streams').doc(streamId).get();
    final liveData = liveDoc.data();

    if (liveData == null) return;

    // คำนวณวันที่จะลบ (หลังจบ live + retention days)
    final retentionDays = liveData['retentionDays'] ?? 7;
    final deleteAt = Timestamp.fromDate(
      now.toDate().add(Duration(days: retentionDays)),
    );

    await _firestore.collection('live_streams').doc(streamId).update({
      'status': 'ended',
      'endedAt': now,
      'currentViewers': 0,
      'deleteAt': deleteAt, // กำหนดเวลาลบอัตโนมัติ
    });

    // เริ่มกระบวนการบันทึก & compress
    await _processRecordedVideo(streamId);

    // Log activity
    await _logStreamActivity(streamId, 'ended');
  }

  // ==================== VIEWER MANAGEMENT ====================

  /// อัพเดทจำนวนผู้ชม Real-time
  Future<void> updateViewerCount(String streamId, int viewerChange) async {
    final docRef = _firestore.collection('live_streams').doc(streamId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final currentViewers = (data['currentViewers'] ?? 0) + viewerChange;
      final totalViewers = data['totalViewers'] ?? 0;
      final peakViewers = data['peakViewers'] ?? 0;

      final newTotal = viewerChange > 0 ? totalViewers + 1 : totalViewers;
      final newPeak =
          currentViewers > peakViewers ? currentViewers : peakViewers;

      transaction.update(docRef, {
        'currentViewers': currentViewers >= 0 ? currentViewers : 0,
        'totalViewers': newTotal,
        'peakViewers': newPeak,
      });
    });
  }

  /// ผู้ใช้เข้าชม
  Future<void> joinLiveStream(
      String streamId, String userId, String userName) async {
    await updateViewerCount(streamId, 1);

    // บันทึกประวัติการเข้าชม
    await _firestore
        .collection('live_streams')
        .doc(streamId)
        .collection('viewers')
        .doc(userId)
        .set({
      'userId': userId,
      'userName': userName,
      'joinedAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });
  }

  /// ผู้ใช้ออกจากการชม
  Future<void> leaveLiveStream(String streamId, String userId) async {
    await updateViewerCount(streamId, -1);

    await _firestore
        .collection('live_streams')
        .doc(streamId)
        .collection('viewers')
        .doc(userId)
        .update({
      'isActive': false,
      'leftAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================== INTERACTIONS ====================

  /// กดไลค์
  Future<void> toggleLike(String streamId, String userId) async {
    final likeRef = _firestore
        .collection('live_streams')
        .doc(streamId)
        .collection('likes')
        .doc(userId);

    final likeDoc = await likeRef.get();
    final streamRef = _firestore.collection('live_streams').doc(streamId);

    if (likeDoc.exists) {
      // Unlike
      await likeRef.delete();
      await streamRef.update({
        'likesCount': FieldValue.increment(-1),
      });
    } else {
      // Like
      await likeRef.set({
        'userId': userId,
        'likedAt': FieldValue.serverTimestamp(),
      });
      await streamRef.update({
        'likesCount': FieldValue.increment(1),
      });
    }
  }

  /// ส่งความคิดเห็น
  Future<void> addComment({
    required String streamId,
    required String userId,
    required String userName,
    String? userPhoto,
    required String message,
  }) async {
    await _firestore
        .collection('live_streams')
        .doc(streamId)
        .collection('comments')
        .add({
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
      'likesCount': 0,
    });

    // อัพเดทจำนวนคอมเมนต์
    await _firestore.collection('live_streams').doc(streamId).update({
      'commentsCount': FieldValue.increment(1),
    });
  }

  // ==================== RECORDING & COMPRESSION ====================

  /// ประมวลผลวิดีโอหลังจบ live
  Future<void> _processRecordedVideo(String streamId) async {
    try {
      // 1. ดึงข้อมูล recording จาก Agora Cloud Recording
      // 2. Download ไฟล์ชั่วคราว
      // 3. Compress เป็น SD (480p) เพื่อประหยัดพื้นที่
      // 4. Upload ไปยัง Firebase Storage
      // 5. ลบไฟล์ต้นฉบับ HD

      // TODO: Implement Agora Cloud Recording integration
      // สำหรับตอนนี้ แค่อัพเดทสถานะ

      await _firestore.collection('live_streams').doc(streamId).update({
        'status': 'ended',
        'quality': 'hd', // จะเปลี่ยนเป็น sd หลัง compress
      });

      // Schedule compression job (ใช้ Cloud Functions)
      await _scheduleVideoCompression(streamId);
    } catch (e) {
      print('Error processing recorded video: $e');
    }
  }

  /// กำหนดเวลา compress วิดีโอ
  Future<void> _scheduleVideoCompression(String streamId) async {
    await _firestore.collection('compression_jobs').add({
      'streamId': streamId,
      'status': 'pending',
      'targetQuality': 'sd', // 480p
      'targetBitrate': 1000, // 1 Mbps
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Archive วิดีโอเป็น SD เพื่อเก็บไว้นานขึ้น
  Future<void> archiveLiveStream(String streamId) async {
    final now = Timestamp.now();

    await _firestore.collection('live_streams').doc(streamId).update({
      'status': 'archived',
      'quality': 'sd', // เปลี่ยนเป็น SD
      'archivedAt': now,
      'autoDeleteEnabled': false, // ปิด auto-delete สำหรับ archive
    });

    // ลบ comments เก่าเพื่อประหยัดพื้นที่
    await _cleanupOldComments(streamId);
  }

  // ==================== AUTO-DELETE SYSTEM ====================

  /// ตรวจสอบและลบ Live Streams ที่หมดอายุ
  Future<void> cleanupExpiredStreams() async {
    final now = Timestamp.now();

    // หา streams ที่หมดอายุแล้ว
    final expiredStreams = await _firestore
        .collection('live_streams')
        .where('autoDeleteEnabled', isEqualTo: true)
        .where('status', whereIn: ['ended', 'archived']).get();

    // Filter deleteAt on client side
    final toDelete = expiredStreams.docs.where((doc) {
      final deleteAt = doc.data()['deleteAt'] as Timestamp?;
      return deleteAt != null && deleteAt.compareTo(now) <= 0;
    }).toList();

    for (final doc in toDelete) {
      await deleteLiveStream(doc.id);
    }

    print('✅ Cleaned up ${toDelete.length} expired streams');
  }

  /// ลบ Live Stream
  Future<void> deleteLiveStream(String streamId) async {
    try {
      final streamDoc =
          await _firestore.collection('live_streams').doc(streamId).get();
      final streamData = streamDoc.data();

      if (streamData == null) return;

      // ลบวิดีโอจาก Storage
      final recordedVideoUrl = streamData['recordedVideoUrl'] as String?;
      if (recordedVideoUrl != null) {
        await _deleteVideoFile(recordedVideoUrl);
      }

      // ลบ subcollections
      await _deleteSubcollections(streamId);

      // ลบเอกสารหลัก
      await _firestore.collection('live_streams').doc(streamId).update({
        'status': 'deleted',
        'recordedVideoUrl': null, // ลบ URL
      });

      print('✅ Deleted stream: $streamId');
    } catch (e) {
      print('❌ Error deleting stream $streamId: $e');
    }
  }

  /// ลบไฟล์วิดีโอจาก Storage
  Future<void> _deleteVideoFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      print('Error deleting video file: $e');
    }
  }

  /// ลบ subcollections
  Future<void> _deleteSubcollections(String streamId) async {
    final collections = ['comments', 'viewers', 'likes'];

    for (final collection in collections) {
      final snapshot = await _firestore
          .collection('live_streams')
          .doc(streamId)
          .collection(collection)
          .limit(500)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  /// ลบ comments เก่า (เก็บแค่ 100 comments ล่าสุด)
  Future<void> _cleanupOldComments(String streamId) async {
    final allComments = await _firestore
        .collection('live_streams')
        .doc(streamId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .get();

    if (allComments.docs.length <= 100) return;

    // ลบ comments เก่าที่เกิน 100
    final batch = _firestore.batch();
    for (var i = 100; i < allComments.docs.length; i++) {
      batch.delete(allComments.docs[i].reference);
    }
    await batch.commit();

    print('✅ Cleaned up ${allComments.docs.length - 100} old comments');
  }

  // ==================== QUERIES ====================

  /// ดึง Live Streams ที่กำลังไลฟ์
  Stream<List<LiveStream>> getActiveLiveStreams() {
    return _firestore
        .collection('live_streams')
        .where('status', isEqualTo: 'live')
        .where('isPublic', isEqualTo: true)
        .orderBy('currentViewers', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LiveStream.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// ดึง Live Stream โดย ID
  Stream<LiveStream?> getLiveStream(String streamId) {
    return _firestore.collection('live_streams').doc(streamId).snapshots().map(
        (doc) => doc.exists ? LiveStream.fromMap(doc.data()!, doc.id) : null);
  }

  /// ดึง comments แบบ real-time
  Stream<List<Map<String, dynamic>>> getComments(String streamId) {
    return _firestore
        .collection('live_streams')
        .doc(streamId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .limit(100) // จำกัด 100 comments ล่าสุด
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  /// Log activity
  Future<void> _logStreamActivity(String streamId, String action) async {
    await _firestore.collection('stream_activities').add({
      'streamId': streamId,
      'action': action,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ==================== ADMIN FUNCTIONS ====================

  /// ดึงสถิติ Live Streams (สำหรับ Admin)
  Future<Map<String, dynamic>> getStreamingStats() async {
    final now = DateTime.now();
    final last30Days =
        Timestamp.fromDate(now.subtract(const Duration(days: 30)));

    final allStreams = await _firestore
        .collection('live_streams')
        .where('createdAt', isGreaterThan: last30Days)
        .get();

    int totalStreams = allStreams.docs.length;
    int liveNow = 0;
    int totalViewers = 0;
    int totalDuration = 0;

    for (final doc in allStreams.docs) {
      final data = doc.data();
      if (data['status'] == 'live') liveNow++;
      totalViewers += (data['totalViewers'] ?? 0) as int;

      if (data['startedAt'] != null && data['endedAt'] != null) {
        final start = (data['startedAt'] as Timestamp).toDate();
        final end = (data['endedAt'] as Timestamp).toDate();
        totalDuration += end.difference(start).inMinutes;
      }
    }

    return {
      'totalStreams': totalStreams,
      'liveNow': liveNow,
      'totalViewers': totalViewers,
      'averageViewers': totalStreams > 0 ? totalViewers / totalStreams : 0,
      'totalDurationMinutes': totalDuration,
      'averageDurationMinutes':
          totalStreams > 0 ? totalDuration / totalStreams : 0,
    };
  }
}
