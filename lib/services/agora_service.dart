// lib/services/agora_service.dart
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/constants.dart';

/// Service สำหรับจัดการ Agora RTC Engine
class AgoraService {
  RtcEngine? _engine;
  bool _isInitialized = false;

  // Singleton pattern
  static final AgoraService _instance = AgoraService._internal();
  factory AgoraService() => _instance;
  AgoraService._internal();

  /// Initialize Agora Engine
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permissions
      await requestPermissions();

      // Create engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: AgoraConfig.appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      // Enable video
      await _engine!.enableVideo();
      await _engine!.enableAudio();

      _isInitialized = true;
    } catch (e) {
      print('Agora initialization error: $e');
      rethrow;
    }
  }

  /// Request camera and microphone permissions
  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    return statuses[Permission.camera]!.isGranted &&
        statuses[Permission.microphone]!.isGranted;
  }

  /// Join channel as broadcaster (for host)
  Future<void> joinChannelAsBroadcaster({
    required String channelName,
    required String token,
    required int uid,
  }) async {
    if (!_isInitialized || _engine == null) {
      throw Exception('Agora engine not initialized');
    }

    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine!.joinChannel(
      token: token,
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );
  }

  /// Join channel as audience (for viewer)
  Future<void> joinChannelAsAudience({
    required String channelName,
    required String token,
    required int uid,
  }) async {
    if (!_isInitialized || _engine == null) {
      throw Exception('Agora engine not initialized');
    }

    await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);
    await _engine!.joinChannel(
      token: token,
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleAudience,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );
  }

  /// Leave channel
  Future<void> leaveChannel() async {
    if (_engine != null) {
      await _engine!.leaveChannel();
    }
  }

  /// Switch camera (front/back)
  Future<void> switchCamera() async {
    if (_engine != null) {
      await _engine!.switchCamera();
    }
  }

  /// Mute/Unmute local audio
  Future<void> muteLocalAudio(bool muted) async {
    if (_engine != null) {
      await _engine!.muteLocalAudioStream(muted);
    }
  }

  /// Mute/Unmute local video
  Future<void> muteLocalVideo(bool muted) async {
    if (_engine != null) {
      await _engine!.muteLocalVideoStream(muted);
    }
  }

  /// Get RTC Engine instance
  RtcEngine? get engine => _engine;

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  /// Dispose engine
  Future<void> dispose() async {
    if (_engine != null) {
      await _engine!.leaveChannel();
      await _engine!.release();
      _engine = null;
      _isInitialized = false;
    }
  }
}

/// Agora Configuration (ควรเก็บใน environment variables)
class AgoraConfig {
  // TODO: Replace with your Agora App ID
  static const String appId = 'YOUR_AGORA_APP_ID';

  // TODO: Implement token generation via Cloud Function
  // For testing, you can use temp token from Agora Console
  static String generateTempToken(String channelName) {
    // In production, call Cloud Function to generate token
    return ''; // Empty for testing without token
  }
}
