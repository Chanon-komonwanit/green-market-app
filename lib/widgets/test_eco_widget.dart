// lib/widgets/test_eco_widget.dart
import 'package:flutter/material.dart';

class TestEcoWidget extends StatelessWidget {
  const TestEcoWidget({Key? key}) : super(key: key);

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.eco, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          const Text(
            '1250',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 8),
        ],
      ),
    );
  }
}
