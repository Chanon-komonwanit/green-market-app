// lib/widgets/shimmer_loading.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/constants.dart';

/// Shimmer loading widget แบบ Facebook, Instagram
class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.grayBorder.withOpacity(0.3),
      highlightColor: AppColors.surfaceWhite.withOpacity(0.8),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Post Card Shimmer แบบ Instagram
class PostCardShimmer extends StatelessWidget {
  const PostCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.padding, vertical: AppTheme.smallPadding),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const ShimmerLoading(width: 40, height: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerLoading(
                        width: MediaQuery.of(context).size.width * 0.4,
                        height: 14,
                      ),
                      const SizedBox(height: 6),
                      ShimmerLoading(
                        width: MediaQuery.of(context).size.width * 0.2,
                        height: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Content
            ShimmerLoading(
              width: double.infinity,
              height: 16,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 6),
            ShimmerLoading(
              width: MediaQuery.of(context).size.width * 0.7,
              height: 16,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            // Image
            ShimmerLoading(
              width: double.infinity,
              height: 200,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(height: 12),
            // Actions
            Row(
              children: [
                const ShimmerLoading(width: 60, height: 32),
                const SizedBox(width: 16),
                const ShimmerLoading(width: 60, height: 32),
                const SizedBox(width: 16),
                const ShimmerLoading(width: 60, height: 32),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Story Circle Shimmer แบบ Instagram
class StoryShimmer extends StatelessWidget {
  const StoryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          ShimmerLoading(
            width: 70,
            height: 70,
            borderRadius: BorderRadius.circular(35),
          ),
          const SizedBox(height: 4),
          const ShimmerLoading(width: 60, height: 12),
        ],
      ),
    );
  }
}
