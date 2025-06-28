// lib/widgets/eco_level_indicator.dart
import 'package:flutter/material.dart';
import 'package:green_market/utils/constants.dart'; // Corrected: Already correct

class EcoLevelIndicator extends StatelessWidget {
  final int ecoScore;
  final double size;
  final bool showText;

  const EcoLevelIndicator({
    super.key,
    required this.ecoScore,
    this.size = 24.0,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    final ecoLevel = EcoLevelExtension.fromScore(ecoScore);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          ecoLevel.icon,
          color: ecoLevel.color,
          size: size,
        ),
        if (showText) const SizedBox(width: 4),
        if (showText)
          Text(ecoLevel.name,
              style: TextStyle(color: ecoLevel.color, fontSize: size * 0.7)),
      ],
    );
  }
}
