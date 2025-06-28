// lib/widgets/eco_level_overview_card.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../screens/eco_level_products_screen.dart';

class EcoLevelOverviewCard extends StatelessWidget {
  final EcoLevel ecoLevel;
  final int productCount;

  const EcoLevelOverviewCard({
    super.key,
    required this.ecoLevel,
    required this.productCount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EcoLevelProductsScreen(ecoLevel: ecoLevel),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        width: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ecoLevel.backgroundColor,
              ecoLevel.color.withOpacity(0.1),
            ],
          ),
          border: Border.all(
            color: ecoLevel.color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ecoLevel.color.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ecoLevel.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      ecoLevel.icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ecoLevel.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ecoLevel.scoreRange,
                      style: TextStyle(
                        color: ecoLevel.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Level name
              Text(
                ecoLevel.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ecoLevel.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Description
              Text(
                ecoLevel.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              // Product count and arrow
              Row(
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 16,
                    color: ecoLevel.color.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$productCount สินค้า',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ecoLevel.color,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: ecoLevel.color.withOpacity(0.7),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget for horizontal scrollable eco level overview
class EcoLevelOverviewSection extends StatelessWidget {
  final List<Map<String, dynamic>> levelCounts;

  const EcoLevelOverviewSection({
    super.key,
    required this.levelCounts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'สินค้าตามระดับสิ่งแวดล้อม',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to all eco levels page
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ดูทั้งหมด',
                        style: TextStyle(
                          color: AppColors.primaryTeal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppColors.primaryTeal,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: levelCounts.length,
              itemBuilder: (context, index) {
                final data = levelCounts[index];
                final level = data['level'] as EcoLevel;
                final count = data['count'] as int;

                return EcoLevelOverviewCard(
                  ecoLevel: level,
                  productCount: count,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
