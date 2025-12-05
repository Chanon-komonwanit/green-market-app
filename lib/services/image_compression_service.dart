// lib/services/image_compression_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;

/// Image Compression Service
/// บีบอัดรูปภาพก่อนอัปโหลดเพื่อประหยัด storage และเร็วขึ้น
class ImageCompressionService {
  static final ImageCompressionService _instance =
      ImageCompressionService._internal();
  factory ImageCompressionService() => _instance;
  ImageCompressionService._internal();

  /// บีบอัดรูปภาพสำหรับโพสต์ (คุณภาพ 80%)
  /// รูปที่ใหญ่กว่า 1920x1920 จะถูกลดขนาดลง
  Future<File> compressImageForPost(File imageFile) async {
    try {
      final filePath = imageFile.absolute.path;
      final lastIndex = filePath.lastIndexOf(RegExp(r'.jp'));
      final splitted = filePath.substring(0, (lastIndex));
      final outPath = "${splitted}_compressed${path.extension(filePath)}";

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        filePath,
        outPath,
        quality: 80,
        minWidth: 1920,
        minHeight: 1920,
      );

      if (compressedFile == null) {
        debugPrint('Compression failed, returning original file');
        return imageFile;
      }

      final originalSize = await imageFile.length();
      final compressedSize = await compressedFile.length();
      final savedPercentage =
          ((originalSize - compressedSize) / originalSize * 100)
              .toStringAsFixed(1);

      debugPrint('Image compressed successfully!');
      debugPrint('Original size: ${_formatBytes(originalSize)}');
      debugPrint('Compressed size: ${_formatBytes(compressedSize)}');
      debugPrint('Saved: $savedPercentage%');

      return File(compressedFile.path);
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return imageFile;
    }
  }

  /// บีบอัดรูปโปรไฟล์ (คุณภาพ 85%, ขนาด 512x512)
  Future<File> compressProfileImage(File imageFile) async {
    try {
      final filePath = imageFile.absolute.path;
      final lastIndex = filePath.lastIndexOf(RegExp(r'.jp'));
      final splitted = filePath.substring(0, (lastIndex));
      final outPath = "${splitted}_profile${path.extension(filePath)}";

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        filePath,
        outPath,
        quality: 85,
        minWidth: 512,
        minHeight: 512,
      );

      if (compressedFile == null) {
        return imageFile;
      }

      debugPrint('Profile image compressed successfully!');
      return File(compressedFile.path);
    } catch (e) {
      debugPrint('Error compressing profile image: $e');
      return imageFile;
    }
  }

  /// บีบอัดรูปสตอรี่ (คุณภาพ 75%, ขนาด 1080x1920)
  Future<File> compressStoryImage(File imageFile) async {
    try {
      final filePath = imageFile.absolute.path;
      final lastIndex = filePath.lastIndexOf(RegExp(r'.jp'));
      final splitted = filePath.substring(0, (lastIndex));
      final outPath = "${splitted}_story${path.extension(filePath)}";

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        filePath,
        outPath,
        quality: 75,
        minWidth: 1080,
        minHeight: 1920,
      );

      if (compressedFile == null) {
        return imageFile;
      }

      debugPrint('Story image compressed successfully!');
      return File(compressedFile.path);
    } catch (e) {
      debugPrint('Error compressing story image: $e');
      return imageFile;
    }
  }

  /// บีบอัดรูปสำหรับแชท (คุณภาพ 70%, ขนาด 1280x1280)
  Future<File> compressImageForChat(File imageFile) async {
    try {
      final filePath = imageFile.absolute.path;
      final lastIndex = filePath.lastIndexOf(RegExp(r'.jp'));
      final splitted = filePath.substring(0, (lastIndex));
      final outPath = "${splitted}_chat${path.extension(filePath)}";

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        filePath,
        outPath,
        quality: 70,
        minWidth: 1280,
        minHeight: 1280,
      );

      if (compressedFile == null) {
        return imageFile;
      }

      debugPrint('Chat image compressed successfully!');
      return File(compressedFile.path);
    } catch (e) {
      debugPrint('Error compressing chat image: $e');
      return imageFile;
    }
  }

  /// บีบอัดรูปเป็น thumbnail (ขนาดเล็ก 300x300, คุณภาพ 60%)
  Future<Uint8List?> compressToThumbnail(File imageFile) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        quality: 60,
        minWidth: 300,
        minHeight: 300,
      );

      if (result != null) {
        debugPrint('Thumbnail created successfully!');
      }

      return result;
    } catch (e) {
      debugPrint('Error creating thumbnail: $e');
      return null;
    }
  }

  /// บีบอัดหลายรูปพร้อมกัน (Batch compression)
  Future<List<File>> compressMultipleImages(
    List<File> imageFiles, {
    String type = 'post', // post, profile, story, chat
  }) async {
    final List<File> compressedFiles = [];

    for (final imageFile in imageFiles) {
      File compressedFile;

      switch (type) {
        case 'profile':
          compressedFile = await compressProfileImage(imageFile);
          break;
        case 'story':
          compressedFile = await compressStoryImage(imageFile);
          break;
        case 'chat':
          compressedFile = await compressImageForChat(imageFile);
          break;
        default:
          compressedFile = await compressImageForPost(imageFile);
      }

      compressedFiles.add(compressedFile);
    }

    return compressedFiles;
  }

  /// ตรวจสอบว่ารูปต้องบีบอัดหรือไม่
  /// (ถ้าไฟล์ใหญ่กว่า 2MB หรือความกว้างเกิน 2048px)
  Future<bool> needsCompression(File imageFile) async {
    try {
      final fileSize = await imageFile.length();

      // Check file size (2MB = 2 * 1024 * 1024 bytes)
      if (fileSize > 2 * 1024 * 1024) {
        return true;
      }

      // Check image dimensions using image package
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image != null) {
        if (image.width > 2048 || image.height > 2048) {
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error checking compression need: $e');
      return false;
    }
  }

  /// แปลงขนาดไฟล์เป็นข้อความที่อ่านง่าย
  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  /// ลบไฟล์ชั่วคราวที่ใช้ในการบีบอัด
  Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();

      for (final file in files) {
        if (file is File && file.path.contains('_compressed')) {
          await file.delete();
          debugPrint('Deleted temp file: ${file.path}');
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up temp files: $e');
    }
  }
}
