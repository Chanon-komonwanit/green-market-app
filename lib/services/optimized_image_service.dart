// lib/services/optimized_image_service.dart
import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Enterprise-level Image Service with intelligent caching, memory management, and performance optimization
/// ระบบจัดการรูปภาพระดับองค์กรพร้อม cache อัจฉริยะ และการจัดการ memory
class OptimizedImageService {
  static final OptimizedImageService _instance =
      OptimizedImageService._internal();
  factory OptimizedImageService() => _instance;
  OptimizedImageService._internal();

  // Memory Cache - LRU with size limit
  final Map<String, _CacheEntry> _memoryCache = {};
  final Queue<String> _accessOrder = Queue<String>();
  static const int _maxMemoryItems = 500; // จำกัดจำนวนรูปใน memory
  static const int _maxMemorySizeMB = 200; // จำกัดขนาด memory 200MB
  int _currentMemorySize = 0;

  // Network Request Management
  final Map<String, Completer<Uint8List>> _activeRequests = {};
  static const int _maxConcurrentRequests = 10;
  int _activeRequestCount = 0;
  final Queue<_PendingRequest> _requestQueue = Queue<_PendingRequest>();

  // Performance Metrics
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _totalRequests = 0;

  /// Load image with intelligent caching and memory management
  /// โหลดรูปภาพพร้อมระบบ cache อัจฉริยะและการจัดการ memory
  Future<Uint8List> loadImage(
    String imageUrl, {
    ImageQuality quality = ImageQuality.high,
    bool useCache = true,
    Duration timeout = const Duration(seconds: 30),
    int maxRetries = 3,
  }) async {
    _totalRequests++;

    // Check memory cache first
    if (useCache && _memoryCache.containsKey(imageUrl)) {
      final entry = _memoryCache[imageUrl]!;
      if (!entry.isExpired) {
        _cacheHits++;
        _updateAccessOrder(imageUrl);
        print('[ImageService] Cache hit: $imageUrl');
        return entry.data;
      } else {
        _removeFromCache(imageUrl);
      }
    }

    _cacheMisses++;

    // Check if already loading
    if (_activeRequests.containsKey(imageUrl)) {
      print('[ImageService] Already loading, waiting: $imageUrl');
      return await _activeRequests[imageUrl]!.future;
    }

    // Create completer for this request
    final completer = Completer<Uint8List>();
    _activeRequests[imageUrl] = completer;

    try {
      final imageData =
          await _fetchWithQueue(imageUrl, quality, timeout, maxRetries);

      // Store in cache if enabled
      if (useCache) {
        await _storeInCache(imageUrl, imageData, quality);
      }

      completer.complete(imageData);
      return imageData;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _activeRequests.remove(imageUrl);
    }
  }

  /// Fetch image with request queue management
  Future<Uint8List> _fetchWithQueue(String imageUrl, ImageQuality quality,
      Duration timeout, int maxRetries) async {
    if (_activeRequestCount >= _maxConcurrentRequests) {
      // Add to queue
      final completer = Completer<Uint8List>();
      _requestQueue.add(
          _PendingRequest(imageUrl, quality, timeout, maxRetries, completer));
      print(
          '[ImageService] Queued request: $imageUrl (queue size: ${_requestQueue.length})');
      return await completer.future;
    }

    return await _performRequest(imageUrl, quality, timeout, maxRetries);
  }

  /// Perform actual HTTP request with optimization
  Future<Uint8List> _performRequest(String imageUrl, ImageQuality quality,
      Duration timeout, int maxRetries) async {
    _activeRequestCount++;

    try {
      print('[ImageService] Fetching: $imageUrl (quality: $quality)');

      int retryCount = 0;
      late Exception lastException;

      while (retryCount <= maxRetries) {
        try {
          final headers = {
            'Cache-Control': 'max-age=3600', // Cache for 1 hour
            'Accept': 'image/webp,image/png,image/jpeg,*/*',
            'User-Agent': 'GreenMarket/1.0 (Flutter)',
          };

          // Add quality parameters for supported services
          String optimizedUrl = imageUrl;
          if (imageUrl.contains('firebasestorage.googleapis.com')) {
            optimizedUrl = _addFirebaseOptimization(imageUrl, quality);
          }

          final response = await http
              .get(
                Uri.parse(optimizedUrl),
                headers: headers,
              )
              .timeout(timeout);

          if (response.statusCode == 200) {
            Uint8List imageData = response.bodyBytes;

            // Optimize image if needed
            if (quality != ImageQuality.original &&
                imageData.length > 1024 * 1024) {
              // > 1MB
              imageData = await _optimizeImage(imageData, quality);
            }

            print(
                '[ImageService] Success: $imageUrl (${imageData.length} bytes)');
            return imageData;
          } else {
            throw HttpException(
                'HTTP ${response.statusCode}: ${response.reasonPhrase}');
          }
        } catch (e) {
          lastException = e is Exception ? e : Exception(e.toString());

          if (retryCount < maxRetries) {
            retryCount++;
            final delay =
                Duration(milliseconds: 500 * retryCount); // Exponential backoff
            print(
                '[ImageService] Retry $retryCount/$maxRetries after ${delay.inMilliseconds}ms: $imageUrl');
            await Future.delayed(delay);
          }
        }
      }

      throw lastException;
    } finally {
      _activeRequestCount--;
      _processQueue();
    }
  }

  /// Process queued requests
  void _processQueue() {
    while (_requestQueue.isNotEmpty &&
        _activeRequestCount < _maxConcurrentRequests) {
      final request = _requestQueue.removeFirst();
      _performRequest(request.imageUrl, request.quality, request.timeout,
              request.maxRetries)
          .then(request.completer.complete)
          .catchError(request.completer.completeError);
    }
  }

  /// Add Firebase Storage optimization parameters
  String _addFirebaseOptimization(String url, ImageQuality quality) {
    final uri = Uri.parse(url);
    final params = Map<String, String>.from(uri.queryParameters);

    switch (quality) {
      case ImageQuality.thumbnail:
        params['w'] = '150';
        params['h'] = '150';
        break;
      case ImageQuality.medium:
        params['w'] = '400';
        params['h'] = '400';
        break;
      case ImageQuality.high:
        params['w'] = '800';
        params['h'] = '800';
        break;
      case ImageQuality.original:
        // No modification
        break;
    }

    return uri.replace(queryParameters: params).toString();
  }

  /// Optimize image using Flutter's image codec
  Future<Uint8List> _optimizeImage(
      Uint8List originalData, ImageQuality quality) async {
    try {
      final codec = await ui.instantiateImageCodec(originalData);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      int targetWidth = image.width;
      int targetHeight = image.height;

      switch (quality) {
        case ImageQuality.thumbnail:
          final scale = 150 / math.max(image.width, image.height);
          targetWidth = (image.width * scale).round();
          targetHeight = (image.height * scale).round();
          break;
        case ImageQuality.medium:
          final scale = 400 / math.max(image.width, image.height);
          if (scale < 1.0) {
            targetWidth = (image.width * scale).round();
            targetHeight = (image.height * scale).round();
          }
          break;
        case ImageQuality.high:
          final scale = 800 / math.max(image.width, image.height);
          if (scale < 1.0) {
            targetWidth = (image.width * scale).round();
            targetHeight = (image.height * scale).round();
          }
          break;
        case ImageQuality.original:
          // No resizing
          break;
      }

      if (targetWidth != image.width || targetHeight != image.height) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.scale(targetWidth / image.width, targetHeight / image.height);
        canvas.drawImage(image, Offset.zero, Paint());

        final picture = recorder.endRecording();
        final resizedImage = await picture.toImage(targetWidth, targetHeight);
        final byteData =
            await resizedImage.toByteData(format: ui.ImageByteFormat.png);

        image.dispose();
        resizedImage.dispose();
        picture.dispose();

        return byteData!.buffer.asUint8List();
      }

      image.dispose();
      return originalData;
    } catch (e) {
      print('[ImageService] Image optimization failed: $e');
      return originalData;
    }
  }

  /// Store image in memory cache with size management
  Future<void> _storeInCache(
      String imageUrl, Uint8List data, ImageQuality quality) async {
    final sizeInBytes = data.length;

    // Check if image is too large for cache
    if (sizeInBytes > 10 * 1024 * 1024) {
      // 10MB
      print(
          '[ImageService] Image too large for cache: $imageUrl (${sizeInBytes / 1024 / 1024}MB)');
      return;
    }

    // Make room in cache if needed
    while (
        (_currentMemorySize + sizeInBytes) > (_maxMemorySizeMB * 1024 * 1024) ||
            _memoryCache.length >= _maxMemoryItems) {
      if (_accessOrder.isEmpty) break;

      final oldestKey = _accessOrder.removeFirst();
      _removeFromCache(oldestKey);
    }

    // Store in cache
    _memoryCache[imageUrl] = _CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      sizeInBytes: sizeInBytes,
      quality: quality,
    );
    _accessOrder.add(imageUrl);
    _currentMemorySize += sizeInBytes;

    print(
        '[ImageService] Cached: $imageUrl (${sizeInBytes / 1024}KB) - Cache: ${_memoryCache.length} items, ${_currentMemorySize / 1024 / 1024}MB');
  }

  /// Remove item from cache
  void _removeFromCache(String imageUrl) {
    final entry = _memoryCache.remove(imageUrl);
    if (entry != null) {
      _currentMemorySize -= entry.sizeInBytes;
      _accessOrder.remove(imageUrl);
    }
  }

  /// Update access order for LRU
  void _updateAccessOrder(String imageUrl) {
    _accessOrder.remove(imageUrl);
    _accessOrder.add(imageUrl);
  }

  /// Clear all cache
  void clearCache() {
    _memoryCache.clear();
    _accessOrder.clear();
    _currentMemorySize = 0;
    print('[ImageService] Cache cleared');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final hitRate =
        _totalRequests > 0 ? (_cacheHits / _totalRequests * 100) : 0;

    return {
      'totalRequests': _totalRequests,
      'cacheHits': _cacheHits,
      'cacheMisses': _cacheMisses,
      'hitRate': '${hitRate.toStringAsFixed(1)}%',
      'cachedItems': _memoryCache.length,
      'memorySizeMB': (_currentMemorySize / 1024 / 1024).toStringAsFixed(1),
      'activeRequests': _activeRequestCount,
      'queuedRequests': _requestQueue.length,
    };
  }

  /// Preload images for better UX
  Future<void> preloadImages(List<String> imageUrls,
      {ImageQuality quality = ImageQuality.medium}) async {
    print('[ImageService] Preloading ${imageUrls.length} images');

    final futures = imageUrls.map((url) => loadImage(
          url,
          quality: quality,
          useCache: true,
        ).catchError((e) {
          print('[ImageService] Preload failed for $url: $e');
          return Uint8List(0);
        }));

    await Future.wait(futures);
    print('[ImageService] Preloading completed');
  }
}

/// Cache entry with metadata
class _CacheEntry {
  final Uint8List data;
  final DateTime timestamp;
  final int sizeInBytes;
  final ImageQuality quality;

  _CacheEntry({
    required this.data,
    required this.timestamp,
    required this.sizeInBytes,
    required this.quality,
  });

  bool get isExpired => DateTime.now().difference(timestamp).inHours > 24;
}

/// Pending request in queue
class _PendingRequest {
  final String imageUrl;
  final ImageQuality quality;
  final Duration timeout;
  final int maxRetries;
  final Completer<Uint8List> completer;

  _PendingRequest(this.imageUrl, this.quality, this.timeout, this.maxRetries,
      this.completer);
}

/// Image quality levels for optimization
enum ImageQuality {
  thumbnail, // 150x150 max
  medium, // 400x400 max
  high, // 800x800 max
  original // No modification
}

/// HTTP Exception for better error handling
class HttpException implements Exception {
  final String message;
  HttpException(this.message);

  @override
  String toString() => 'HttpException: $message';
}
