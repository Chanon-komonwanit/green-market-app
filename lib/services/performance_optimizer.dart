// lib/services/performance_optimizer.dart
//
// ⚡ PerformanceOptimizer - ปรับปรุงประสิทธิภาพแอพ
//
// หน้าที่:
// - Image compression & optimization
// - Video quality adjustment
// - Lazy loading & pagination
// - Cache management
// - Memory optimization

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:image/image.dart' as img;

class PerformanceOptimizer {
  final Logger _logger = Logger();

  // Image settings
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1920;
  static const int thumbnailSize = 400;
  static const int imageQuality = 85; // 0-100

  // Video settings
  static const int maxVideoDuration = 60; // seconds
  static const int maxVideoSize = 100 * 1024 * 1024; // 100 MB

  // Cache settings
  static const int maxCacheSize = 200 * 1024 * 1024; // 200 MB
  static const int maxCacheAge = 7; // days

  /// บีบอัดรูปภาพ
  Future<File?> compressImage(File imageFile) async {
    try {
      _logger.d('Compressing image: ${imageFile.path}');

      // อ่านรูปภาพ
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        _logger.e('Failed to decode image');
        return null;
      }

      // Resize ถ้าใหญ่เกินไป
      if (image.width > maxImageWidth || image.height > maxImageHeight) {
        image = img.copyResize(
          image,
          width: image.width > maxImageWidth ? maxImageWidth : null,
          height: image.height > maxImageHeight ? maxImageHeight : null,
        );
        _logger.d('Resized image to ${image.width}x${image.height}');
      }

      // บีบอัดเป็น JPEG
      final compressedBytes = img.encodeJpg(image, quality: imageQuality);

      // สร้างไฟล์ใหม่
      final compressedFile = File(
        '${imageFile.parent.path}/compressed_${imageFile.uri.pathSegments.last}',
      );
      await compressedFile.writeAsBytes(compressedBytes);

      final originalSize = bytes.length;
      final compressedSize = compressedBytes.length;
      final reduction = ((originalSize - compressedSize) / originalSize * 100)
          .toStringAsFixed(1);

      _logger.i(
        'Compressed image: ${originalSize ~/ 1024}KB → ${compressedSize ~/ 1024}KB (-$reduction%)',
      );

      return compressedFile;
    } catch (e) {
      _logger.e('Error compressing image: $e');
      return null;
    }
  }

  /// สร้าง thumbnail
  Future<File?> createThumbnail(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) return null;

      // สร้าง thumbnail
      final thumbnail = img.copyResize(
        image,
        width: thumbnailSize,
        height: thumbnailSize,
        interpolation: img.Interpolation.average,
      );

      final thumbnailBytes = img.encodeJpg(thumbnail, quality: 70);

      final thumbnailFile = File(
        '${imageFile.parent.path}/thumb_${imageFile.uri.pathSegments.last}',
      );
      await thumbnailFile.writeAsBytes(thumbnailBytes);

      _logger.d('Created thumbnail: ${thumbnailBytes.length ~/ 1024}KB');
      return thumbnailFile;
    } catch (e) {
      _logger.e('Error creating thumbnail: $e');
      return null;
    }
  }

  /// บีบอัดรูปภาพหลายไฟล์
  Future<List<File>> compressImages(List<File> images) async {
    final compressed = <File>[];

    for (var image in images) {
      final result = await compressImage(image);
      if (result != null) {
        compressed.add(result);
      }
    }

    return compressed;
  }

  /// ตรวจสอบขนาดวิดีโอ
  bool isVideoSizeValid(File videoFile) {
    final size = videoFile.lengthSync();
    return size <= maxVideoSize;
  }

  /// คำนวณขนาดหน่วยความจำที่ใช้
  Future<int> calculateMemoryUsage() async {
    // ใช้ได้เฉพาะบน mobile
    if (kIsWeb) return 0;

    try {
      // ตัวอย่าง: ใช้ ProcessInfo หรือ memory_info package
      _logger.d('Memory usage calculated');
      return 0;
    } catch (e) {
      _logger.e('Error calculating memory: $e');
      return 0;
    }
  }

  /// Optimize สำหรับ low-end devices
  Map<String, dynamic> getLowEndSettings() {
    return {
      'imageQuality': 70,
      'maxImageWidth': 1280,
      'maxImageHeight': 1280,
      'thumbnailSize': 200,
      'videoBitrate': 'low',
      'preloadImages': false,
      'enableAnimations': false,
    };
  }

  /// Optimize สำหรับ high-end devices
  Map<String, dynamic> getHighEndSettings() {
    return {
      'imageQuality': 95,
      'maxImageWidth': 2560,
      'maxImageHeight': 2560,
      'thumbnailSize': 600,
      'videoBitrate': 'high',
      'preloadImages': true,
      'enableAnimations': true,
    };
  }

  /// ตรวจสอบประสิทธิภาพอุปกรณ์
  Future<DevicePerformance> detectDevicePerformance() async {
    try {
      // ตัวอย่าง: ตรวจสอบ RAM, CPU, GPU
      // ในระบบจริงใช้ device_info_plus

      _logger.d('Detecting device performance...');

      // Default: medium
      return DevicePerformance.medium;
    } catch (e) {
      _logger.e('Error detecting performance: $e');
      return DevicePerformance.low;
    }
  }
}

/// ระดับประสิทธิภาพอุปกรณ์
enum DevicePerformance {
  low,
  medium,
  high,
}

/// Configuration สำหรับประสิทธิภาพ
class PerformanceConfig {
  final int imageQuality;
  final int maxImageWidth;
  final int maxImageHeight;
  final int thumbnailSize;
  final bool preloadImages;
  final bool enableAnimations;
  final String videoBitrate;

  const PerformanceConfig({
    required this.imageQuality,
    required this.maxImageWidth,
    required this.maxImageHeight,
    required this.thumbnailSize,
    required this.preloadImages,
    required this.enableAnimations,
    required this.videoBitrate,
  });

  factory PerformanceConfig.fromPerformance(DevicePerformance performance) {
    switch (performance) {
      case DevicePerformance.low:
        return const PerformanceConfig(
          imageQuality: 70,
          maxImageWidth: 1280,
          maxImageHeight: 1280,
          thumbnailSize: 200,
          preloadImages: false,
          enableAnimations: false,
          videoBitrate: 'low',
        );
      case DevicePerformance.medium:
        return const PerformanceConfig(
          imageQuality: 85,
          maxImageWidth: 1920,
          maxImageHeight: 1920,
          thumbnailSize: 400,
          preloadImages: true,
          enableAnimations: true,
          videoBitrate: 'medium',
        );
      case DevicePerformance.high:
        return const PerformanceConfig(
          imageQuality: 95,
          maxImageWidth: 2560,
          maxImageHeight: 2560,
          thumbnailSize: 600,
          preloadImages: true,
          enableAnimations: true,
          videoBitrate: 'high',
        );
    }
  }
}
