// lib/widgets/community_quick_actions.dart
import 'package:flutter/material.dart';
import 'package:green_market/utils/constants.dart';

/// Community Quick Actions - แบบ Facebook/Instagram
/// ปุ่มลัดสำหรับ Features สำคัญในชุมชน
class CommunityQuickActions extends StatelessWidget {
  const CommunityQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                context,
                icon: Icons.camera_alt,
                label: 'Story',
                color: Colors.purple,
                gradient: LinearGradient(
                  colors: [Colors.purple, Colors.deepPurple],
                ),
                onTap: () => Navigator.pushNamed(context, '/create_story'),
              ),
              _buildActionButton(
                context,
                icon: Icons.emoji_events,
                label: 'Challenges',
                color: Colors.amber,
                gradient: LinearGradient(
                  colors: [Colors.amber, Colors.orange],
                ),
                onTap: () => Navigator.pushNamed(context, '/eco_challenges'),
              ),
              _buildActionButton(
                context,
                icon: Icons.trending_up,
                label: 'Trending',
                color: Colors.red,
                gradient: LinearGradient(
                  colors: [Colors.red, Colors.pink],
                ),
                onTap: () => Navigator.pushNamed(context, '/trending_topics'),
              ),
              _buildActionButton(
                context,
                icon: Icons.group,
                label: 'Groups',
                color: Colors.blue,
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.lightBlue],
                ),
                onTap: () => Navigator.pushNamed(context, '/community_groups'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }
}
