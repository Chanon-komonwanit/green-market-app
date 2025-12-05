// lib/widgets/pull_to_refresh.dart
import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Custom Pull to Refresh แบบ Instagram, TikTok
class CustomPullToRefresh extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;

  const CustomPullToRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? AppColors.primaryTeal,
      backgroundColor: AppColors.surfaceWhite,
      strokeWidth: 3.0,
      displacement: 40,
      child: child,
    );
  }
}

/// Sliver Pull to Refresh สำหรับ CustomScrollView
class SliverPullToRefresh extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final List<Widget> slivers;
  final Color? color;

  const SliverPullToRefresh({
    super.key,
    required this.onRefresh,
    required this.slivers,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? AppColors.primaryTeal,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: slivers,
      ),
    );
  }
}
