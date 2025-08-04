// lib/utils/backup_recovery_system.dart
// ระบบสำรองและกู้คืนข้อมูลสำหรับ Green Market App

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ประเภทการสำรองข้อมูล
enum BackupType {
  userProfile,
  shopSettings,
  products,
  orders,
  preferences,
  cache,
  complete,
}

/// สถานะการสำรองข้อมูล
enum BackupStatus {
  pending,
  inProgress,
  completed,
  failed,
  cancelled,
}

/// ข้อมูลการสำรอง
class BackupInfo {
  final String id;
  final BackupType type;
  final BackupStatus status;
  final DateTime timestamp;
  final int dataSize;
  final String? filePath;
  final String? error;
  final Map<String, dynamic>? metadata;

  BackupInfo({
    required this.id,
    required this.type,
    required this.status,
    required this.timestamp,
    required this.dataSize,
    this.filePath,
    this.error,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'data_size': dataSize,
      'file_path': filePath,
      'error': error,
      'metadata': metadata,
    };
  }

  factory BackupInfo.fromJson(Map<String, dynamic> json) {
    return BackupInfo(
      id: json['id'],
      type: BackupType.values.firstWhere((e) => e.name == json['type']),
      status: BackupStatus.values.firstWhere((e) => e.name == json['status']),
      timestamp: DateTime.parse(json['timestamp']),
      dataSize: json['data_size'],
      filePath: json['file_path'],
      error: json['error'],
      metadata: json['metadata'],
    );
  }
}

/// ระบบสำรองและกู้คืนข้อมูล
class BackupRecoverySystem {
  static final BackupRecoverySystem _instance =
      BackupRecoverySystem._internal();
  factory BackupRecoverySystem() => _instance;
  BackupRecoverySystem._internal();

  // Services
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State
  final List<BackupInfo> _backupHistory = [];
  final Map<String, StreamController<double>> _progressControllers = {};

  // Configuration
  static const int MAX_BACKUP_HISTORY = 50;
  static const Duration AUTO_BACKUP_INTERVAL = Duration(days: 1);
  static const int MAX_BACKUP_SIZE = 50 * 1024 * 1024; // 50MB

  Timer? _autoBackupTimer;
  bool _isInitialized = false;

  /// เริ่มต้นระบบสำรองข้อมูล
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadBackupHistory();
    _startAutoBackup();
    _isInitialized = true;

    _logInfo('Backup Recovery System initialized');
  }

  /// เริ่มการสำรองข้อมูลอัตโนมัติ
  void _startAutoBackup() {
    _autoBackupTimer = Timer.periodic(AUTO_BACKUP_INTERVAL, (_) async {
      try {
        await performBackup(BackupType.preferences, automated: true);
      } catch (e) {
        _logError('Auto backup failed: $e');
      }
    });
  }

  /// สำรองข้อมูลหลัก
  Future<BackupInfo> performBackup(
    BackupType type, {
    bool automated = false,
    Map<String, dynamic>? options,
  }) async {
    final backupId = _generateBackupId();
    final progressController = StreamController<double>.broadcast();
    _progressControllers[backupId] = progressController;

    final backupInfo = BackupInfo(
      id: backupId,
      type: type,
      status: BackupStatus.inProgress,
      timestamp: DateTime.now(),
      dataSize: 0,
      metadata: {
        'automated': automated,
        'options': options,
      },
    );

    _addBackupInfo(backupInfo);
    progressController.add(0.0);

    try {
      Map<String, dynamic> data;

      switch (type) {
        case BackupType.userProfile:
          data = await _backupUserProfile();
          break;
        case BackupType.shopSettings:
          data = await _backupShopSettings();
          break;
        case BackupType.products:
          data = await _backupProducts();
          break;
        case BackupType.orders:
          data = await _backupOrders();
          break;
        case BackupType.preferences:
          data = await _backupPreferences();
          break;
        case BackupType.cache:
          data = await _backupCache();
          break;
        case BackupType.complete:
          data = await _backupComplete();
          break;
      }

      progressController.add(0.5);

      // บันทึกข้อมูลลง local storage
      final filePath = await _saveBackupToLocal(backupId, data);
      progressController.add(0.8);

      // อัปโหลดไปยัง cloud (ถ้าต้องการ)
      if (!automated || type == BackupType.complete) {
        await _uploadBackupToCloud(backupId, data);
      }

      progressController.add(1.0);

      final completedBackup = BackupInfo(
        id: backupId,
        type: type,
        status: BackupStatus.completed,
        timestamp: backupInfo.timestamp,
        dataSize: jsonEncode(data).length,
        filePath: filePath,
        metadata: backupInfo.metadata,
      );

      _updateBackupInfo(completedBackup);
      _logInfo(
          'Backup completed: ${type.name} (${completedBackup.dataSize} bytes)');

      return completedBackup;
    } catch (e) {
      final failedBackup = BackupInfo(
        id: backupId,
        type: type,
        status: BackupStatus.failed,
        timestamp: backupInfo.timestamp,
        dataSize: 0,
        error: e.toString(),
        metadata: backupInfo.metadata,
      );

      _updateBackupInfo(failedBackup);
      _logError('Backup failed: ${type.name} - $e');
      rethrow;
    } finally {
      _progressControllers.remove(backupId);
      progressController.close();
    }
  }

  /// สำรองข้อมูลโปรไฟล์ผู้ใช้
  Future<Map<String, dynamic>> _backupUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final sellerDoc =
        await _firestore.collection('sellers').doc(user.uid).get();

    return {
      'user_data': userDoc.exists ? userDoc.data() : null,
      'seller_data': sellerDoc.exists ? sellerDoc.data() : null,
      'auth_info': {
        'uid': user.uid,
        'email': user.email,
        'display_name': user.displayName,
        'photo_url': user.photoURL,
        'email_verified': user.emailVerified,
        'creation_time': user.metadata.creationTime?.toIso8601String(),
        'last_sign_in': user.metadata.lastSignInTime?.toIso8601String(),
      },
    };
  }

  /// สำรองข้อมูลการตั้งค่าร้าน
  Future<Map<String, dynamic>> _backupShopSettings() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final customizationDoc =
        await _firestore.collection('shop_customizations').doc(user.uid).get();

    return {
      'shop_customization':
          customizationDoc.exists ? customizationDoc.data() : null,
      'backup_timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// สำรองข้อมูลสินค้า
  Future<Map<String, dynamic>> _backupProducts() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final productsQuery = await _firestore
        .collection('products')
        .where('sellerId', isEqualTo: user.uid)
        .get();

    final products = productsQuery.docs
        .map((doc) => {
              'id': doc.id,
              'data': doc.data(),
            })
        .toList();

    return {
      'products': products,
      'total_count': products.length,
      'backup_timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// สำรองข้อมูลคำสั่งซื้อ
  Future<Map<String, dynamic>> _backupOrders() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // ดึงคำสั่งซื้อที่เป็นผู้ซื้อ
    final buyerOrdersQuery = await _firestore
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .get();

    // ดึงคำสั่งซื้อที่เป็นผู้ขาย
    final sellerOrdersQuery = await _firestore
        .collection('orders')
        .where('sellerId', isEqualTo: user.uid)
        .get();

    final buyerOrders = buyerOrdersQuery.docs
        .map((doc) => {
              'id': doc.id,
              'data': doc.data(),
              'type': 'buyer',
            })
        .toList();

    final sellerOrders = sellerOrdersQuery.docs
        .map((doc) => {
              'id': doc.id,
              'data': doc.data(),
              'type': 'seller',
            })
        .toList();

    return {
      'buyer_orders': buyerOrders,
      'seller_orders': sellerOrders,
      'total_buyer_orders': buyerOrders.length,
      'total_seller_orders': sellerOrders.length,
      'backup_timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// สำรองข้อมูลการตั้งค่า
  Future<Map<String, dynamic>> _backupPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    final preferences = <String, dynamic>{};
    for (final key in keys) {
      final value = prefs.get(key);
      if (value != null) {
        preferences[key] = value;
      }
    }

    return {
      'preferences': preferences,
      'backup_timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// สำรองข้อมูล cache
  Future<Map<String, dynamic>> _backupCache() async {
    // สำรองข้อมูล cache ที่สำคัญ
    return {
      'cache_info': {
        'backup_timestamp': DateTime.now().toIso8601String(),
        'note': 'Cache backup is not implemented for security reasons',
      },
    };
  }

  /// สำรองข้อมูลทั้งหมด
  Future<Map<String, dynamic>> _backupComplete() async {
    final data = <String, dynamic>{};

    try {
      data['user_profile'] = await _backupUserProfile();
    } catch (e) {
      data['user_profile_error'] = e.toString();
    }

    try {
      data['shop_settings'] = await _backupShopSettings();
    } catch (e) {
      data['shop_settings_error'] = e.toString();
    }

    try {
      data['products'] = await _backupProducts();
    } catch (e) {
      data['products_error'] = e.toString();
    }

    try {
      data['orders'] = await _backupOrders();
    } catch (e) {
      data['orders_error'] = e.toString();
    }

    try {
      data['preferences'] = await _backupPreferences();
    } catch (e) {
      data['preferences_error'] = e.toString();
    }

    data['backup_timestamp'] = DateTime.now().toIso8601String();
    data['backup_type'] = 'complete';

    return data;
  }

  /// บันทึกการสำรองข้อมูลไปยัง local storage
  Future<String> _saveBackupToLocal(
      String backupId, Map<String, dynamic> data) async {
    final jsonString = jsonEncode(data);

    // ตรวจสอบขนาดไฟล์
    if (jsonString.length > MAX_BACKUP_SIZE) {
      throw Exception('Backup file too large: ${jsonString.length} bytes');
    }

    final prefs = await SharedPreferences.getInstance();
    final key = 'backup_$backupId';
    await prefs.setString(key, jsonString);

    _logInfo(
        'Backup saved to local storage: $key (${jsonString.length} bytes)');
    return key;
  }

  /// อัปโหลดการสำรองข้อมูลไปยัง cloud
  Future<void> _uploadBackupToCloud(
      String backupId, Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString);

    final ref =
        _storage.ref().child('backups').child(user.uid).child('$backupId.json');

    await ref.putData(bytes);
    _logInfo('Backup uploaded to cloud: ${ref.fullPath}');
  }

  /// กู้คืนข้อมูลจาก backup
  Future<bool> restoreFromBackup(String backupId,
      {bool fromCloud = false}) async {
    try {
      Map<String, dynamic> data;

      if (fromCloud) {
        data = await _downloadBackupFromCloud(backupId);
      } else {
        data = await _loadBackupFromLocal(backupId);
      }

      await _performRestore(data);

      _logInfo('Data restored successfully from backup: $backupId');
      return true;
    } catch (e) {
      _logError('Failed to restore from backup: $e');
      return false;
    }
  }

  /// ดาวน์โหลดการสำรองข้อมูลจาก cloud
  Future<Map<String, dynamic>> _downloadBackupFromCloud(String backupId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final ref =
        _storage.ref().child('backups').child(user.uid).child('$backupId.json');

    final bytes = await ref.getData();
    final jsonString = utf8.decode(bytes!);
    return jsonDecode(jsonString);
  }

  /// โหลดการสำรองข้อมูลจาก local storage
  Future<Map<String, dynamic>> _loadBackupFromLocal(String backupId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = backupId.startsWith('backup_') ? backupId : 'backup_$backupId';
    final jsonString = prefs.getString(key);

    if (jsonString == null) {
      throw Exception('Backup not found: $key');
    }

    return jsonDecode(jsonString);
  }

  /// ดำเนินการกู้คืนข้อมูล
  Future<void> _performRestore(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // กู้คืนข้อมูลผู้ใช้
    if (data['user_profile'] != null) {
      await _restoreUserProfile(data['user_profile']);
    }

    // กู้คืนข้อมูลการตั้งค่าร้าน
    if (data['shop_settings'] != null) {
      await _restoreShopSettings(data['shop_settings']);
    }

    // กู้คืนข้อมูลการตั้งค่า
    if (data['preferences'] != null) {
      await _restorePreferences(data['preferences']);
    }

    // หมายเหตุ: สินค้าและคำสั่งซื้อไม่ควรกู้คืนอัตโนมัติเพื่อป้องกันข้อมูลซ้ำ
  }

  /// กู้คืนข้อมูลผู้ใช้
  Future<void> _restoreUserProfile(Map<String, dynamic> profileData) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (profileData['user_data'] != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(profileData['user_data'], SetOptions(merge: true));
    }

    if (profileData['seller_data'] != null) {
      await _firestore
          .collection('sellers')
          .doc(user.uid)
          .set(profileData['seller_data'], SetOptions(merge: true));
    }
  }

  /// กู้คืนข้อมูลการตั้งค่าร้าน
  Future<void> _restoreShopSettings(Map<String, dynamic> shopData) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (shopData['shop_customization'] != null) {
      await _firestore
          .collection('shop_customizations')
          .doc(user.uid)
          .set(shopData['shop_customization'], SetOptions(merge: true));
    }
  }

  /// กู้คืนข้อมูลการตั้งค่า
  Future<void> _restorePreferences(Map<String, dynamic> prefData) async {
    final prefs = await SharedPreferences.getInstance();
    final preferences = prefData['preferences'] as Map<String, dynamic>?;

    if (preferences != null) {
      for (final entry in preferences.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value is String) {
          await prefs.setString(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is List<String>) {
          await prefs.setStringList(key, value);
        }
      }
    }
  }

  /// ลบการสำรองข้อมูล
  Future<bool> deleteBackup(String backupId, {bool fromCloud = false}) async {
    try {
      if (fromCloud) {
        await _deleteBackupFromCloud(backupId);
      } else {
        await _deleteBackupFromLocal(backupId);
      }

      // ลบจากประวัติ
      _backupHistory.removeWhere((backup) => backup.id == backupId);
      await _saveBackupHistory();

      _logInfo('Backup deleted: $backupId');
      return true;
    } catch (e) {
      _logError('Failed to delete backup: $e');
      return false;
    }
  }

  /// ลบการสำรองข้อมูลจาก cloud
  Future<void> _deleteBackupFromCloud(String backupId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final ref =
        _storage.ref().child('backups').child(user.uid).child('$backupId.json');

    await ref.delete();
  }

  /// ลบการสำรองข้อมูลจาก local storage
  Future<void> _deleteBackupFromLocal(String backupId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = backupId.startsWith('backup_') ? backupId : 'backup_$backupId';
    await prefs.remove(key);
  }

  /// โหลดประวัติการสำรองข้อมูล
  Future<void> _loadBackupHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('backup_history');

      if (historyJson != null) {
        final historyList = jsonDecode(historyJson) as List;
        _backupHistory.clear();
        _backupHistory.addAll(
          historyList.map((item) => BackupInfo.fromJson(item)),
        );
      }
    } catch (e) {
      _logError('Failed to load backup history: $e');
    }
  }

  /// บันทึกประวัติการสำรองข้อมูล
  Future<void> _saveBackupHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = jsonEncode(
        _backupHistory.map((backup) => backup.toJson()).toList(),
      );
      await prefs.setString('backup_history', historyJson);
    } catch (e) {
      _logError('Failed to save backup history: $e');
    }
  }

  /// เพิ่มข้อมูลการสำรอง
  void _addBackupInfo(BackupInfo backup) {
    _backupHistory.add(backup);

    // จำกัดขนาดประวัติ
    while (_backupHistory.length > MAX_BACKUP_HISTORY) {
      _backupHistory.removeAt(0);
    }

    _saveBackupHistory();
  }

  /// อัปเดตข้อมูลการสำรอง
  void _updateBackupInfo(BackupInfo updatedBackup) {
    final index = _backupHistory.indexWhere((b) => b.id == updatedBackup.id);
    if (index != -1) {
      _backupHistory[index] = updatedBackup;
      _saveBackupHistory();
    }
  }

  /// สร้าง ID การสำรองข้อมูล
  String _generateBackupId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random =
        (DateTime.now().microsecond % 10000).toString().padLeft(4, '0');
    return 'backup_${timestamp}_$random';
  }

  /// ได้รับ stream ของ progress
  Stream<double>? getBackupProgress(String backupId) {
    return _progressControllers[backupId]?.stream;
  }

  /// ได้รับประวัติการสำรองข้อมูล
  List<BackupInfo> get backupHistory => List.unmodifiable(_backupHistory);

  /// ได้รับการสำรองข้อมูลล่าสุด
  BackupInfo? get latestBackup {
    if (_backupHistory.isEmpty) return null;

    final sortedBackups = List<BackupInfo>.from(_backupHistory);
    sortedBackups.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sortedBackups.first;
  }

  /// ได้รับรายงานการสำรองข้อมูล
  Map<String, dynamic> getBackupReport() {
    final completedBackups = _backupHistory
        .where((b) => b.status == BackupStatus.completed)
        .toList();
    final failedBackups =
        _backupHistory.where((b) => b.status == BackupStatus.failed).toList();

    final totalSize =
        completedBackups.fold<int>(0, (sum, backup) => sum + backup.dataSize);

    return {
      'total_backups': _backupHistory.length,
      'completed_backups': completedBackups.length,
      'failed_backups': failedBackups.length,
      'total_data_size': totalSize,
      'latest_backup': latestBackup?.toJson(),
      'auto_backup_enabled': _autoBackupTimer?.isActive ?? false,
    };
  }

  /// ปิดระบบสำรองข้อมูล
  void dispose() {
    _autoBackupTimer?.cancel();
    for (final controller in _progressControllers.values) {
      controller.close();
    }
    _progressControllers.clear();
    _logInfo('Backup Recovery System disposed');
  }

  // Logging methods
  void _logInfo(String message) {
    if (kDebugMode) {
      print('🟢 [BackupRecovery] $message');
    }
  }

  void _logError(String message) {
    if (kDebugMode) {
      print('🔴 [BackupRecovery] ERROR: $message');
    }
  }
}
