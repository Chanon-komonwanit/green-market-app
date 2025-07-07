// lib/widgets/debug_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:green_market/services/firebase_data_seeder.dart';

class DebugPanel extends StatelessWidget {
  const DebugPanel({super.key});

  @override
  Widget build(BuildContext context) {
    // Show only in debug mode
    if (kReleaseMode) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bug_report, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Debug Panel (Development Only)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _seedSampleData(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Seed Sample Data'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _clearSampleData(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Clear Sample Data'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _seedSampleData(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กำลังสร้างข้อมูลทดสอบ...'),
          backgroundColor: Colors.blue,
        ),
      );

      await FirebaseDataSeeder.seedSampleData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('สร้างข้อมูลทดสอบสำเร็จ!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearSampleData(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบข้อมูลทดสอบ'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบข้อมูลทดสอบทั้งหมด?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('กำลังลบข้อมูลทดสอบ...'),
            backgroundColor: Colors.blue,
          ),
        );

        await FirebaseDataSeeder.clearSampleData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ลบข้อมูลทดสอบสำเร็จ!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
