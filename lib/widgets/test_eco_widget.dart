// lib/widgets/test_eco_widget.dart
import 'package:flutter/material.dart';

class TestEcoWidget extends StatelessWidget {
  const TestEcoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32, // ลดขนาดให้เล็กลง
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco, color: Colors.white, size: 12),
          SizedBox(width: 4),
          Text(
            '1250',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 2),
          Icon(Icons.arrow_forward_ios, color: Colors.white, size: 8),
        ],
      ),
    );
  }
}

