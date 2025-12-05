# 🎥 Live Streaming System - Complete Implementation Guide

## 📋 Overview

ระบบ Live Streaming แบบครบวงจร สำหรับแอพ Green Market โดยออกแบบให้คล้ายกับ Facebook Live และ Instagram Live พร้อมระบบจัดการความคุณภาพและการจัดเก็บอัตโนมัติ

---

## 🎯 Features

### ✅ ฟีเจอร์ที่สมบูรณ์แล้ว

1. **Data Models**
   - ✅ LiveStream model with all statuses
   - ✅ Quality levels (SD, HD, Full HD)
   - ✅ Retention policy system
   - ✅ Auto-delete scheduling

2. **Backend Service**
   - ✅ Create/Start/End live streams
   - ✅ Viewer management (join/leave)
   - ✅ Real-time statistics tracking
   - ✅ Comments system
   - ✅ Likes system
   - ✅ Archive functionality
   - ✅ Auto-cleanup logic

3. **Cloud Functions**
   - ✅ cleanupExpiredStreams (Daily 3 AM)
   - ✅ monitorStorageSize (Daily midnight)
   - ⚠️ Video compression (TODO)

4. **UI Screens**
   - ✅ LiveStreamsListScreen (Grid view with tabs)
   - ✅ CreateLiveStreamScreen (Setup form)
   - ✅ LiveStreamViewerScreen (Watch live)
   - ⏳ LiveStreamHostScreen (Broadcast) - TODO

5. **Real-time Features**
   - ✅ Viewer count updates
   - ✅ Live comments stream
   - ✅ Like/unlike functionality
   - ✅ Auto-scroll comments

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter App (Web/Mobile)                  │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ List Screen  │  │Create Screen │  │Viewer Screen │      │
│  │              │  │              │  │              │      │
│  │ - Grid View  │  │ - Form Input │  │ - Video Play │      │
│  │ - 3 Tabs     │  │ - Settings   │  │ - Comments   │      │
│  │ - Live Badge │  │ - Hashtags   │  │ - Likes      │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                  │                  │              │
└─────────┼──────────────────┼──────────────────┼──────────────┘
          │                  │                  │
          ▼                  ▼                  ▼
┌─────────────────────────────────────────────────────────────┐
│              LiveStreamService (Business Logic)              │
├─────────────────────────────────────────────────────────────┤
│ • createLiveStream()      • joinLiveStream()                 │
│ • startLiveStream()       • leaveLiveStream()                │
│ • endLiveStream()         • addComment()                     │
│ • updateViewerCount()     • toggleLike()                     │
│ • archiveLiveStream()     • cleanupExpiredStreams()          │
└──────────────────────┬──────────────────────────────────────┘
                       │
          ┌────────────┴────────────┐
          ▼                         ▼
┌──────────────────┐      ┌──────────────────┐
│    Firestore     │      │ Firebase Storage │
├──────────────────┤      ├──────────────────┤
│ live_streams/    │      │ recordings/      │
│ ├─ {id}          │      │ └─ {id}.mp4      │
│    ├─ comments/  │      └──────────────────┘
│    ├─ viewers/   │
│    └─ likes/     │      ┌──────────────────┐
└──────────────────┘      │ Cloud Functions  │
                          ├──────────────────┤
          ┌───────────────┤ cleanupExpired   │
          │               │ monitorStorage   │
          │               └──────────────────┘
          ▼
┌──────────────────┐
│   Agora SDK      │
│  (WebRTC/RTMP)   │
└──────────────────┘
```

---

## 📊 Database Schema

### Firestore Structure

```
live_streams/
├─ {liveId}/
   ├─ streamerId: string
   ├─ streamerName: string
   ├─ streamerPhoto: string?
   ├─ title: string
   ├─ description: string?
   ├─ thumbnailUrl: string?
   ├─ status: 'scheduled' | 'live' | 'ended' | 'archived' | 'deleted'
   ├─ quality: 'sd' | 'hd' | 'fullHd'
   ├─ agoraChannelName: string?
   ├─ agoraToken: string?
   ├─ recordingId: string?
   ├─ recordedVideoUrl: string?
   ├─ currentViewers: number
   ├─ totalViewers: number
   ├─ peakViewers: number
   ├─ likesCount: number
   ├─ commentsCount: number
   ├─ sharesCount: number
   ├─ scheduledAt: timestamp
   ├─ startedAt: timestamp?
   ├─ endedAt: timestamp?
   ├─ createdAt: timestamp
   ├─ archivedAt: timestamp?
   ├─ deleteAt: timestamp?
   ├─ isRecording: boolean
   ├─ allowComments: boolean
   ├─ isPublic: boolean
   ├─ tags: string[]
   ├─ mentions: string[]
   ├─ retentionDays: number
   └─ autoDeleteEnabled: boolean
   │
   ├─ comments/ (subcollection)
   │  └─ {commentId}/
   │     ├─ userId: string
   │     ├─ userName: string
   │     ├─ userPhoto: string?
   │     ├─ message: string
   │     ├─ createdAt: timestamp
   │     └─ likesCount: number
   │
   ├─ viewers/ (subcollection)
   │  └─ {userId}/
   │     ├─ userId: string
   │     ├─ userName: string
   │     ├─ joinedAt: timestamp
   │     └─ isActive: boolean
   │
   └─ likes/ (subcollection)
      └─ {userId}/
         ├─ userId: string
         └─ createdAt: timestamp
```

---

## 🎬 User Flows

### 1. Create & Start Live Stream

```
User clicks "ไลฟ์สด" FAB
  → Opens CreateLiveStreamScreen (modal)
  → User enters title, description, settings
  → User clicks "เริ่มไลฟ์"
  → Service.createLiveStream() creates document (status: 'scheduled')
  → Service.startLiveStream() updates status to 'live'
  → TODO: Navigate to LiveStreamHostScreen with Agora SDK
```

### 2. Watch Live Stream

```
User opens LiveStreamsListScreen
  → Sees grid of active lives (status: 'live')
  → User clicks on a live card
  → Opens LiveStreamViewerScreen
  → Service.joinLiveStream() increments viewer count
  → StreamBuilder connects to Firestore
  → Real-time updates: comments, likes, viewer count
  → TODO: Agora SDK renders video stream
  → User leaves → Service.leaveLiveStream() decrements count
```

### 3. End Live Stream & Auto-Cleanup

```
Host clicks "จบไลฟ์"
  → Service.endLiveStream()
  → Sets status to 'ended'
  → Sets endedAt timestamp
  → Calculates deleteAt (endedAt + retentionDays)
  → TODO: Trigger video compression (HD → SD)
  → Upload compressed video to Storage
  → Update recordedVideoUrl

After 7 days (default):
  → Cloud Function: cleanupExpiredStreams runs daily at 3 AM
  → Query: status='ended' AND deleteAt <= now
  → Delete video file from Storage
  → Delete subcollections (comments, viewers, likes)
  → Update status to 'deleted'
```

---

## ⚙️ Configuration

### Retention Policy Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `retentionDays` | 7 วัน | จำนวนวันที่เก็บวิดีโอหลังจบไลฟ์ |
| `autoDeleteEnabled` | `true` | เปิด/ปิดการลบอัตโนมัติ |
| `quality` (live) | `hd` (720p) | คุณภาพขณะไลฟ์ |
| `quality` (archived) | `sd` (480p) | คุณภาพหลังบีบอัด |
| `isRecording` | `true` | บันทึกวิดีโอหรือไม่ |
| `allowComments` | `true` | อนุญาตให้แสดงความคิดเห็น |

### Comparison with Major Platforms

| Feature | Facebook Live | Instagram Live | TikTok Live | Green Market |
|---------|--------------|---------------|-------------|--------------|
| Max Duration | Unlimited | 4 hours | Unlimited | Unlimited |
| Retention | 60 days | 30 days | 90 days | **7 days** ⚡ |
| Quality (Live) | 1080p | 720p | 1080p | **720p** ⚡ |
| Quality (Archive) | 1080p | 720p | 1080p | **480p** ⚡ |
| Auto-Delete | ❌ No | ❌ No | ❌ No | **✅ Yes** ⚡ |
| Archive Option | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| Comments | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| Likes | ✅ Yes | ❤️ Hearts | ❤️ Hearts | ✅ Yes |
| Viewer Count | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |

⚡ = Optimized for cost savings

---

## 💾 Storage Calculations

### Cost Estimates (Firebase Storage)

**Assumptions:**
- HD 720p @ 30fps = ~900 MB/hour
- SD 480p @ 30fps = ~450 MB/hour
- Average live duration = 30 minutes

**Daily Usage:**
```
10 lives/day × 30 min × 225 MB = 2.25 GB/day
```

**Weekly Usage (7-day retention):**
```
2.25 GB/day × 7 days = 15.75 GB/week
```

**Monthly Cost (Google Cloud Pricing):**
```
Storage: 15.75 GB × $0.026/GB = $0.41/month
Download: Varies by views
```

### Optimization Tips

1. **Reduce Retention Period:**
   - 7 days → 3 days = 6.75 GB/week (57% savings)

2. **Compress to Lower Bitrate:**
   - 900 MB/hour → 600 MB/hour (33% savings)

3. **Delete Non-Archived Streams:**
   - Only keep important lives in Archive

4. **Limit Live Duration:**
   - Set max duration to 1 hour

---

## 🔧 Integration Guide

### Step 1: Install Packages

```yaml
# pubspec.yaml
dependencies:
  agora_rtc_engine: ^6.3.2  # Already added ✅
  permission_handler: ^11.0.1  # Already added ✅
  wakelock_plus: ^1.2.8  # Already added ✅
```

### Step 2: Agora Setup

1. **Create Agora Account:**
   - Go to https://console.agora.io
   - Create project
   - Get App ID and Certificate

2. **Add to Firebase Environment:**
   ```dart
   // lib/utils/constants.dart
   class AgoraConfig {
     static const String appId = 'YOUR_AGORA_APP_ID';
     static const String certificate = 'YOUR_CERTIFICATE';
   }
   ```

3. **Generate Token (Server-side):**
   - Use Cloud Functions to generate Agora tokens
   - Store token in `agoraToken` field

### Step 3: Request Permissions

```dart
// lib/services/permission_service.dart
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestCameraAndMic() async {
    final camera = await Permission.camera.request();
    final microphone = await Permission.microphone.request();
    return camera.isGranted && microphone.isGranted;
  }
}
```

### Step 4: Implement Host Screen

```dart
// lib/screens/live/live_stream_host_screen.dart (TODO)
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class LiveStreamHostScreen extends StatefulWidget {
  final String streamId;
  final String channelName;
  final String token;
  
  // Implementation details...
}
```

### Step 5: Deploy Cloud Functions

```bash
cd functions
npm install
firebase deploy --only functions
```

---

## 📱 UI Screens Breakdown

### 1. LiveStreamsListScreen

**Purpose:** Browse all live streams

**Features:**
- 3 tabs: Active Lives, Scheduled, Recorded
- Grid view (2 columns)
- Live badge with viewer count
- Real-time updates via StreamBuilder
- FAB button to create new live

**Location:** `lib/screens/live/live_streams_list_screen.dart`

**Status:** ✅ Complete

---

### 2. CreateLiveStreamScreen

**Purpose:** Setup live stream before going live

**Features:**
- Title input (required)
- Description textarea (optional)
- Hashtag suggestions (Instagram style)
- Settings:
  - Allow comments toggle
  - Public/Private toggle
  - Retention days dropdown
- Retention policy info box
- "เริ่มไลฟ์" button

**Location:** `lib/screens/live/create_live_stream_screen.dart`

**Status:** ✅ Complete

---

### 3. LiveStreamViewerScreen

**Purpose:** Watch live stream

**Features:**
- Video player (Agora SDK placeholder)
- Top overlay:
  - Close button
  - Streamer info
  - Live badge + viewer count
- Comments overlay:
  - Real-time comments stream
  - Auto-scroll to latest
  - Comment bubbles with names
- Bottom controls:
  - Comment input field
  - Like button (heart)
  - Share button
  - Toggle comments visibility

**Location:** `lib/screens/live/live_stream_viewer_screen.dart`

**Status:** ✅ Complete (needs Agora integration)

**TODO:**
- Integrate Agora SDK for video playback
- Implement share functionality

---

### 4. LiveStreamHostScreen (TODO)

**Purpose:** Broadcast live stream

**Planned Features:**
- Camera preview
- Switch camera (front/back)
- Mute/unmute microphone
- Toggle flashlight
- End live button
- Real-time stats overlay:
  - Viewer count
  - Duration
  - Comments count
- Comments overlay (same as viewer)

**Location:** `lib/screens/live/live_stream_host_screen.dart`

**Status:** ⏳ Not yet created

**Required Implementation:**
```dart
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class LiveStreamHostScreen extends StatefulWidget {
  final String streamId;
  final LiveStream liveStream;

  @override
  _LiveStreamHostScreenState createState() => _LiveStreamHostScreenState();
}

class _LiveStreamHostScreenState extends State<LiveStreamHostScreen> {
  late RtcEngine _engine;
  bool _isMuted = false;
  bool _isFlashlightOn = false;
  
  @override
  void initState() {
    super.initState();
    _initAgora();
    WakelockPlus.enable(); // Keep screen on
  }
  
  Future<void> _initAgora() async {
    // 1. Create engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(
      appId: AgoraConfig.appId,
    ));
    
    // 2. Enable video
    await _engine.enableVideo();
    
    // 3. Set broadcaster role
    await _engine.setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    
    // 4. Join channel
    await _engine.joinChannel(
      token: widget.liveStream.agoraToken!,
      channelId: widget.liveStream.agoraChannelName!,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }
  
  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    WakelockPlus.disable();
    super.dispose();
  }
  
  // Build UI with camera preview, controls, etc.
}
```

---

## 🚀 API Reference

### LiveStreamService Methods

#### createLiveStream()
```dart
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
  int retentionDays = 7,
})
```

**Returns:** `String` - Stream ID

**Creates:** Live stream document with status 'scheduled'

---

#### startLiveStream()
```dart
Future<void> startLiveStream(String streamId)
```

**Updates:**
- `status` → 'live'
- `startedAt` → now

---

#### endLiveStream()
```dart
Future<void> endLiveStream(String streamId)
```

**Updates:**
- `status` → 'ended'
- `endedAt` → now
- `deleteAt` → now + retentionDays

---

#### joinLiveStream()
```dart
Future<void> joinLiveStream(String streamId, String userId, String userName)
```

**Actions:**
- Increment `currentViewers`
- Add to `viewers` subcollection

---

#### leaveLiveStream()
```dart
Future<void> leaveLiveStream(String streamId, String userId)
```

**Actions:**
- Decrement `currentViewers`
- Update `isActive` to false

---

#### addComment()
```dart
Future<void> addComment({
  required String streamId,
  required String userId,
  required String userName,
  String? userPhoto,
  required String message,
})
```

**Actions:**
- Add to `comments` subcollection
- Increment `commentsCount`

---

#### toggleLike()
```dart
Future<void> toggleLike(String streamId, String userId)
```

**Actions:**
- Add/remove from `likes` subcollection
- Increment/decrement `likesCount`

---

#### archiveLiveStream()
```dart
Future<void> archiveLiveStream(String streamId)
```

**Updates:**
- `status` → 'archived'
- `archivedAt` → now
- `autoDeleteEnabled` → false
- Removes `deleteAt`

---

#### cleanupExpiredStreams()
```dart
Future<void> cleanupExpiredStreams()
```

**Actions:**
- Query expired streams (status='ended' AND deleteAt <= now)
- Delete video files from Storage
- Delete subcollections
- Update status to 'deleted'

---

## ⚠️ Known Issues & TODO

### High Priority

- [ ] **Agora SDK Integration**
  - Need to implement actual video streaming
  - Generate Agora tokens via Cloud Function
  - Handle reconnection logic

- [ ] **Video Compression**
  - Cloud Function to compress HD → SD after live ends
  - Use FFmpeg or similar tool
  - Update `recordedVideoUrl` after compression

- [ ] **LiveStreamHostScreen**
  - Create broadcast UI
  - Implement camera controls
  - Real-time stats overlay

### Medium Priority

- [ ] **Share Functionality**
  - Generate shareable links
  - Deep linking support
  - Social media integration

- [ ] **Notifications**
  - Notify followers when user goes live
  - Push notifications via FCM

- [ ] **Analytics**
  - Track engagement metrics
  - Export reports

### Low Priority

- [ ] **Monetization**
  - Virtual gifts
  - Super chat
  - Subscription tiers

- [ ] **Moderation**
  - Ban/mute users
  - Comment filters
  - Auto-moderation

---

## 🧪 Testing Checklist

### Unit Tests
- [ ] LiveStream model serialization/deserialization
- [ ] LiveStreamService methods
- [ ] Retention policy calculations

### Integration Tests
- [ ] Create → Start → End flow
- [ ] Viewer join/leave flow
- [ ] Comments real-time sync
- [ ] Auto-cleanup execution

### Manual Tests
- [ ] Create live from CreateLiveStreamScreen
- [ ] View live from LiveStreamsListScreen
- [ ] Send comments and see real-time updates
- [ ] Like/unlike functionality
- [ ] Archive live stream
- [ ] Verify auto-delete after retention period

---

## 📚 Resources

### Official Documentation
- **Agora:** https://docs.agora.io/en/video-calling/overview
- **Firebase Storage:** https://firebase.google.com/docs/storage
- **Cloud Functions:** https://firebase.google.com/docs/functions

### Related Files
- `lib/models/live_stream.dart` - Data model
- `lib/services/live_stream_service.dart` - Business logic
- `lib/screens/live/` - UI screens
- `functions/index.js` - Cloud Functions
- `docs/LIVE_STREAMING_SYSTEM.md` - This document

---

## 📝 Changelog

### 2024-01-XX - Initial Implementation
- ✅ Created data models (LiveStream, enums)
- ✅ Implemented LiveStreamService
- ✅ Added Cloud Functions for cleanup
- ✅ Built UI screens (List, Create, Viewer)
- ✅ Integrated real-time features (comments, likes, viewers)
- ⏳ Pending: Agora SDK integration
- ⏳ Pending: Video compression
- ⏳ Pending: Host screen

---

## 🤝 Contributing

เมื่อพัฒนาเพิ่มเติม:

1. Update this document
2. Add tests for new features
3. Update Cloud Functions if needed
4. Test on both Web and Mobile
5. Monitor Storage usage

---

## 📞 Support

For questions or issues:
- Check Firebase Console for errors
- Review Agora Console for streaming logs
- Monitor Cloud Functions logs
- Check Firestore security rules

---

**Status:** 🟡 In Progress (70% Complete)

**Last Updated:** 2024-01-XX
