// lib/widgets/optimized_image_widget.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/optimized_image_service.dart';

/// Enterprise-grade Image Widget with intelligent loading and caching
/// Widget รูปภาพระดับองค์กรพร้อม loading อัจฉริยะและ caching
class OptimizedImageWidget extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final ImageQuality quality;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool enableHeroAnimation;
  final String? heroTag;
  final bool preloadOnHover;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const OptimizedImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.quality = ImageQuality.high,
    this.placeholder,
    this.errorWidget,
    this.enableHeroAnimation = false,
    this.heroTag,
    this.preloadOnHover = false,
    this.onTap,
    this.borderRadius,
  });

  @override
  State<OptimizedImageWidget> createState() => _OptimizedImageWidgetState();
}

class _OptimizedImageWidgetState extends State<OptimizedImageWidget>
    with SingleTickerProviderStateMixin {
  late final OptimizedImageService _imageService;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  Uint8List? _imageData;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _imageService = OptimizedImageService();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _loadImage();
  }

  @override
  void didUpdateWidget(OptimizedImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.quality != widget.quality) {
      _loadImage();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    if (widget.imageUrl.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      print('[OptimizedImage] Loading: ${widget.imageUrl}');

      final imageData = await _imageService.loadImage(
        widget.imageUrl,
        quality: widget.quality,
        useCache: true,
      );

      if (mounted) {
        setState(() {
          _imageData = imageData;
          _isLoading = false;
          _hasError = false;
        });

        _fadeController.forward();
        print('[OptimizedImage] Loaded successfully: ${widget.imageUrl}');
      }
    } catch (e) {
      print('[OptimizedImage] Error loading ${widget.imageUrl}: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _retry() {
    _fadeController.reset();
    _loadImage();
  }

  Widget _buildImage() {
    if (_imageData == null) return const SizedBox.shrink();

    Widget imageWidget = Image.memory(
      _imageData!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        print('[OptimizedImage] Memory image error: $error');
        return _buildErrorWidget();
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;

        return FadeTransition(
          opacity: _fadeAnimation,
          child: child,
        );
      },
    );

    // Apply border radius if specified
    if (widget.borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: imageWidget,
      );
    }

    // Add hero animation if enabled
    if (widget.enableHeroAnimation && widget.heroTag != null) {
      imageWidget = Hero(
        tag: widget.heroTag!,
        child: imageWidget,
      );
    }

    // Add tap gesture if specified
    if (widget.onTap != null) {
      imageWidget = GestureDetector(
        onTap: widget.onTap,
        child: imageWidget,
      );
    }

    // Add hover preloading for web
    if (widget.preloadOnHover && kIsWeb) {
      imageWidget = MouseRegion(
        onEnter: (_) => _preloadHigherQuality(),
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildLoadingWidget() {
    return widget.placeholder ??
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: widget.borderRadius,
          ),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
        );
  }

  Widget _buildErrorWidget() {
    return widget.errorWidget ??
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: widget.borderRadius,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image,
                  size: (widget.width != null && widget.width! < 100) ? 20 : 40,
                  color: Colors.grey[400]),
              const SizedBox(height: 4),
              Text(
                'ไม่สามารถโหลดรูปได้',
                style: TextStyle(
                  fontSize:
                      (widget.width != null && widget.width! < 100) ? 8 : 10,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.width == null || widget.width! >= 100) ...[
                const SizedBox(height: 4),
                TextButton(
                  onPressed: _retry,
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'ลองใหม่',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ],
          ),
        );
  }

  void _preloadHigherQuality() {
    if (widget.quality != ImageQuality.original) {
      final higherQuality = _getHigherQuality(widget.quality);
      if (higherQuality != null) {
        _imageService
            .loadImage(
          widget.imageUrl,
          quality: higherQuality,
          useCache: true,
        )
            .catchError((e) {
          // Ignore preload errors
          print('[OptimizedImage] Preload failed: $e');
          return Uint8List(0);
        });
      }
    }
  }

  ImageQuality? _getHigherQuality(ImageQuality current) {
    switch (current) {
      case ImageQuality.thumbnail:
        return ImageQuality.medium;
      case ImageQuality.medium:
        return ImageQuality.high;
      case ImageQuality.high:
        return ImageQuality.original;
      case ImageQuality.original:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle empty URL
    if (widget.imageUrl.isEmpty) {
      return _buildErrorWidget();
    }

    return Container(
      width: widget.width,
      height: widget.height,
      clipBehavior: widget.borderRadius != null ? Clip.antiAlias : Clip.none,
      decoration: widget.borderRadius != null
          ? BoxDecoration(
              borderRadius: widget.borderRadius,
            )
          : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Loading state
          if (_isLoading) _buildLoadingWidget(),

          // Error state
          if (_hasError && !_isLoading) _buildErrorWidget(),

          // Image content
          if (!_isLoading && !_hasError && _imageData != null) _buildImage(),
        ],
      ),
    );
  }
}

/// Smart Image Grid for efficient rendering of multiple images
/// Grid รูปภาพอัจฉริยะสำหรับการแสดงผลรูปหลายๆ รูปอย่างมีประสิทธิภาพ
class OptimizedImageGrid extends StatefulWidget {
  final List<String> imageUrls;
  final double itemWidth;
  final double itemHeight;
  final int crossAxisCount;
  final double spacing;
  final ImageQuality quality;
  final bool enableLazyLoading;
  final Widget Function(String imageUrl, int index)? itemBuilder;

  const OptimizedImageGrid({
    super.key,
    required this.imageUrls,
    this.itemWidth = 150,
    this.itemHeight = 150,
    this.crossAxisCount = 2,
    this.spacing = 8,
    this.quality = ImageQuality.medium,
    this.enableLazyLoading = true,
    this.itemBuilder,
  });

  @override
  State<OptimizedImageGrid> createState() => _OptimizedImageGridState();
}

class _OptimizedImageGridState extends State<OptimizedImageGrid> {
  late final ScrollController _scrollController;
  final Set<int> _loadedIndices = {};
  late final OptimizedImageService _imageService;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _imageService = OptimizedImageService();

    if (widget.enableLazyLoading) {
      _scrollController.addListener(_onScroll);
      // Load initial visible items
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadVisibleItems());
    } else {
      // Preload all images
      _preloadAllImages();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    _loadVisibleItems();
  }

  void _loadVisibleItems() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final viewportHeight = renderBox.size.height;
    final scrollOffset = _scrollController.offset;

    final itemsPerRow = widget.crossAxisCount;
    final itemHeight = widget.itemHeight + widget.spacing;

    final visibleStartRow = (scrollOffset / itemHeight).floor();
    final visibleEndRow = ((scrollOffset + viewportHeight) / itemHeight).ceil();

    final bufferRows = 2; // Preload 2 rows ahead and behind
    final startRow = math.max(0, visibleStartRow - bufferRows);
    final endRow = math.min(
      (widget.imageUrls.length / itemsPerRow).ceil() - 1,
      visibleEndRow + bufferRows,
    );

    for (int row = startRow; row <= endRow; row++) {
      for (int col = 0; col < itemsPerRow; col++) {
        final index = row * itemsPerRow + col;
        if (index < widget.imageUrls.length &&
            !_loadedIndices.contains(index)) {
          _loadedIndices.add(index);
          _preloadImage(widget.imageUrls[index]);
        }
      }
    }
  }

  void _preloadImage(String imageUrl) {
    _imageService
        .loadImage(
      imageUrl,
      quality: widget.quality,
      useCache: true,
    )
        .catchError((e) {
      print('[ImageGrid] Preload failed for $imageUrl: $e');
      return Uint8List(0);
    });
  }

  void _preloadAllImages() {
    _imageService.preloadImages(widget.imageUrls, quality: widget.quality);
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: _scrollController,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: widget.spacing,
        mainAxisSpacing: widget.spacing,
        childAspectRatio: widget.itemWidth / widget.itemHeight,
      ),
      itemCount: widget.imageUrls.length,
      itemBuilder: (context, index) {
        final imageUrl = widget.imageUrls[index];

        if (widget.itemBuilder != null) {
          return widget.itemBuilder!(imageUrl, index);
        }

        return OptimizedImageWidget(
          imageUrl: imageUrl,
          width: widget.itemWidth,
          height: widget.itemHeight,
          quality: widget.quality,
          borderRadius: BorderRadius.circular(8),
        );
      },
    );
  }
}
