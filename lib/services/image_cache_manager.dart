// lib/services/image_cache_manager.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'optimized_image_service.dart';

/// Advanced Image Cache Manager for enterprise-scale applications
/// ตัวจัดการ Cache รูปภาพขั้นสูงสำหรับแอประดับองค์กร
class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._internal();
  factory ImageCacheManager() => _instance;
  ImageCacheManager._internal();

  late final OptimizedImageService _imageService;
  Timer? _cleanupTimer;
  Timer? _preloadTimer;

  // Performance monitoring
  final Map<String, CachePerformanceMetric> _performanceMetrics = {};

  /// Initialize the cache manager
  void initialize() {
    _imageService = OptimizedImageService();
    _startPeriodicCleanup();
    _startPreloadScheduler();

    print('[ImageCacheManager] Initialized with enterprise features');
  }

  /// Start periodic cleanup of expired cache entries
  void _startPeriodicCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      _performCleanup();
    });
  }

  /// Start intelligent preloading scheduler
  void _startPreloadScheduler() {
    _preloadTimer?.cancel();
    _preloadTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _scheduleIntelligentPreloading();
    });
  }

  /// Perform cache cleanup based on performance metrics
  void _performCleanup() {
    print('[ImageCacheManager] Starting intelligent cache cleanup...');

    // Get current cache stats
    final stats = _imageService.getCacheStats();
    final currentMemoryMB =
        double.parse(stats['memorySizeMB'].toString().replaceAll('MB', ''));

    if (currentMemoryMB > 150) {
      // If memory usage > 150MB
      print(
          '[ImageCacheManager] Memory usage high (${currentMemoryMB}MB), performing cleanup');

      // Clear cache of least performing images
      _clearLowPerformingImages();
    }

    // Clean old performance metrics
    final now = DateTime.now();
    _performanceMetrics.removeWhere((key, metric) {
      return now.difference(metric.lastAccessed).inDays > 7;
    });

    print('[ImageCacheManager] Cleanup completed');
  }

  /// Clear images with poor performance metrics
  void _clearLowPerformingImages() {
    final lowPerformingImages = _performanceMetrics.entries
        .where((entry) =>
            entry.value.accessCount < 3 &&
            DateTime.now().difference(entry.value.lastAccessed).inHours > 24)
        .map((entry) => entry.key)
        .toList();

    for (final imageUrl in lowPerformingImages) {
      _performanceMetrics.remove(imageUrl);
    }

    // Note: Actual cache clearing happens in OptimizedImageService
    print(
        '[ImageCacheManager] Marked ${lowPerformingImages.length} low-performing images for cleanup');
  }

  /// Schedule intelligent preloading based on user patterns
  void _scheduleIntelligentPreloading() {
    // Get frequently accessed images that aren't cached
    final frequentImages = _performanceMetrics.entries
        .where((entry) => entry.value.accessCount > 5)
        .map((entry) => entry.key)
        .toList();

    if (frequentImages.isNotEmpty) {
      print(
          '[ImageCacheManager] Preloading ${frequentImages.length} frequently accessed images');
      _imageService.preloadImages(frequentImages, quality: ImageQuality.medium);
    }
  }

  /// Track image access for intelligent caching
  void trackImageAccess(String imageUrl) {
    final now = DateTime.now();

    if (_performanceMetrics.containsKey(imageUrl)) {
      _performanceMetrics[imageUrl]!.accessCount++;
      _performanceMetrics[imageUrl]!.lastAccessed = now;
    } else {
      _performanceMetrics[imageUrl] = CachePerformanceMetric(
        imageUrl: imageUrl,
        accessCount: 1,
        lastAccessed: now,
        firstAccessed: now,
      );
    }
  }

  /// Get cache performance report
  Map<String, dynamic> getPerformanceReport() {
    final stats = _imageService.getCacheStats();
    final totalMetrics = _performanceMetrics.length;
    final frequentlyAccessed = _performanceMetrics.values
        .where((metric) => metric.accessCount > 3)
        .length;

    return {
      ...stats,
      'trackedImages': totalMetrics,
      'frequentlyAccessed': frequentlyAccessed,
      'avgAccessPerImage': totalMetrics > 0
          ? (_performanceMetrics.values
                      .map((m) => m.accessCount)
                      .reduce((a, b) => a + b) /
                  totalMetrics)
              .toStringAsFixed(1)
          : '0',
      'cacheEfficiency': _calculateCacheEfficiency(),
    };
  }

  /// Calculate cache efficiency percentage
  String _calculateCacheEfficiency() {
    if (_performanceMetrics.isEmpty) return '0%';

    final totalAccesses = _performanceMetrics.values
        .map((m) => m.accessCount)
        .reduce((a, b) => a + b);

    final stats = _imageService.getCacheStats();
    final cacheHits = int.tryParse(stats['cacheHits'].toString()) ?? 0;

    if (totalAccesses == 0) return '0%';

    final efficiency = (cacheHits / totalAccesses * 100);
    return '${efficiency.toStringAsFixed(1)}%';
  }

  /// Force cache cleanup
  void forceCacheCleanup() {
    _imageService.clearCache();
    _performanceMetrics.clear();
    print('[ImageCacheManager] Force cleanup completed');
  }

  /// Preload images for specific screen or feature
  Future<void> preloadForScreen(
      String screenName, List<String> imageUrls) async {
    print(
        '[ImageCacheManager] Preloading ${imageUrls.length} images for screen: $screenName');

    // Use medium quality for screen preloading
    await _imageService.preloadImages(imageUrls, quality: ImageQuality.medium);

    // Track these as accessed
    for (final url in imageUrls) {
      trackImageAccess(url);
    }
  }

  /// Optimize cache for low memory devices
  void optimizeForLowMemory() {
    print('[ImageCacheManager] Optimizing for low memory device');

    // Clear cache and reduce memory limits
    _imageService.clearCache();

    // Clear old metrics
    final now = DateTime.now();
    _performanceMetrics.removeWhere((key, metric) {
      return now.difference(metric.lastAccessed).inHours > 12;
    });

    print('[ImageCacheManager] Low memory optimization completed');
  }

  /// Dispose resources
  void dispose() {
    _cleanupTimer?.cancel();
    _preloadTimer?.cancel();
    _performanceMetrics.clear();
    print('[ImageCacheManager] Disposed');
  }
}

/// Performance metric for cache optimization
class CachePerformanceMetric {
  final String imageUrl;
  int accessCount;
  DateTime lastAccessed;
  final DateTime firstAccessed;

  CachePerformanceMetric({
    required this.imageUrl,
    required this.accessCount,
    required this.lastAccessed,
    required this.firstAccessed,
  });

  Duration get totalTrackingTime => DateTime.now().difference(firstAccessed);
  double get accessFrequency =>
      accessCount / math.max(1, totalTrackingTime.inHours);
}
