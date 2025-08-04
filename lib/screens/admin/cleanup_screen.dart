// lib/screens/admin/cleanup_screen.dart
import 'package:flutter/material.dart';
import '../../utils/cleanup_restored_data.dart';

class CleanupScreen extends StatefulWidget {
  const CleanupScreen({super.key});

  @override
  State<CleanupScreen> createState() => _CleanupScreenState();
}

class _CleanupScreenState extends State<CleanupScreen> {
  bool _isCleaningUp = false;
  Map<String, dynamic> _cleanupResults = {};
  String _currentStep = '';
  final List<String> _completedSteps = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ลบข้อมูลที่กู้คืนมา'),
        backgroundColor: Colors.red[600],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Card
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        Text(
                          'ลบข้อมูลที่กู้คืนมา',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[700],
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'ระบบนี้จะลบข้อมูลที่สร้างขึ้นเพื่อการกู้คืนทั้งหมด:\n'
                      '• หมวดหมู่สินค้าตัวอย่าง\n'
                      '• สินค้าตัวอย่าง\n'
                      '• โพสชุมชนตัวอย่าง\n'
                      '• กิจกรรมสิ่งแวดล้อมตัวอย่าง\n'
                      '• การลงทุนตัวอย่าง\n'
                      '• ความท้าทายตัวอย่าง\n'
                      '• รางวัลตัวอย่าง\n'
                      '• ข่าวสารตัวอย่าง\n'
                      '• หน้าเว็บตัวอย่าง\n'
                      '• คำสั่งซื้อตัวอย่าง\n'
                      '• ข้อมูลทดสอบทั้งหมด\n\n'
                      '⚠️ การกระทำนี้ไม่สามารถย้อนกลับได้!',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Current Step
            if (_isCleaningUp) ...[
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _currentStep.isEmpty
                              ? 'กำลังเตรียมการ...'
                              : _currentStep,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Completed Steps
            if (_completedSteps.isNotEmpty) ...[
              Text(
                'ขั้นตอนที่เสร็จสิ้น:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...(_completedSteps.map((step) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(step,
                                style: const TextStyle(fontSize: 14))),
                      ],
                    ),
                  ))),
              const SizedBox(height: 16),
            ],

            // Results
            if (_cleanupResults.isNotEmpty) ...[
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ผลการลบข้อมูล',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            child: _buildResultsWidget(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_sweep, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'พร้อมสำหรับการลบข้อมูล',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'กดปุ่ม "เริ่มลบข้อมูล" เพื่อดำเนินการ',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isCleaningUp ? null : _showConfirmDialog,
        backgroundColor: _isCleaningUp ? Colors.grey : Colors.red,
        icon: _isCleaningUp
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.delete_sweep),
        label: Text(_isCleaningUp ? 'กำลังลบ...' : 'เริ่มลบข้อมูล'),
      ),
    );
  }

  Widget _buildResultsWidget() {
    if (_cleanupResults.isEmpty) return const SizedBox.shrink();

    final status = _cleanupResults['status'] ?? 'UNKNOWN';
    final isSuccess = status == 'SUCCESS';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall Status
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSuccess ? Colors.green[100] : Colors.red[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSuccess ? Colors.green[300]! : Colors.red[300]!,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green[700] : Colors.red[700],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isSuccess ? 'ลบข้อมูลสำเร็จ!' : 'เกิดข้อผิดพลาด',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSuccess ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Detail Results
        if (isSuccess) ...[
          const Text(
            'รายละเอียดการลบข้อมูล:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...(_cleanupResults.entries
              .where((entry) =>
                  entry.key != 'status' &&
                  entry.key != 'message' &&
                  entry.value is int)
              .map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.delete, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Text('${_getCollectionDisplayName(entry.key)}: '),
                        Text(
                          '${entry.value} รายการ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ))),
        ] else ...[
          if (_cleanupResults['error'] != null) ...[
            const Text(
              'ข้อผิดพลาด:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(
                _cleanupResults['error'].toString(),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  String _getCollectionDisplayName(String key) {
    final displayNames = {
      'categories': 'หมวดหมู่สินค้า',
      'products': 'สินค้า',
      'community_posts': 'โพสชุมชน',
      'sustainable_activities': 'กิจกรรมสิ่งแวดล้อม',
      'green_investments': 'การลงทุนเพื่อสิ่งแวดล้อม',
      'eco_challenges': 'ความท้าทาย Eco',
      'eco_rewards': 'รางวัล Eco Coins',
      'news_articles': 'ข่าวสาร',
      'static_pages': 'หน้าเว็บสำคัญ',
      'orders': 'คำสั่งซื้อ',
      'test_data': 'ข้อมูลทดสอบ',
    };
    return displayNames[key] ?? key;
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('ยืนยันการลบข้อมูล'),
          ],
        ),
        content: const Text(
          'คุณแน่ใจหรือไม่ที่จะลบข้อมูลที่กู้คืนมาทั้งหมด?\n\n'
          'การกระทำนี้จะลบ:\n'
          '• ข้อมูลตัวอย่างทั้งหมด\n'
          '• ข้อมูลทดสอบทั้งหมด\n'
          '• ข้อมูลที่สร้างขึ้นเพื่อการกู้คืน\n\n'
          '⚠️ การกระทำนี้ไม่สามารถย้อนกลับได้!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startCleanup();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('ยืนยันลบข้อมูล'),
          ),
        ],
      ),
    );
  }

  Future<void> _startCleanup() async {
    setState(() {
      _isCleaningUp = true;
      _currentStep = 'เริ่มการลบข้อมูล...';
      _completedSteps.clear();
      _cleanupResults.clear();
    });

    try {
      // Simulate step-by-step cleanup
      await _updateStep('กำลังลบหมวดหมู่สินค้า...', 'หมวดหมู่สินค้า');
      await _updateStep('กำลังลบสินค้าตัวอย่าง...', 'สินค้าตัวอย่าง');
      await _updateStep('กำลังลบโพสชุมชน...', 'โพสชุมชนสีเขียว');
      await _updateStep('กำลังลบกิจกรรมสิ่งแวดล้อม...', 'กิจกรรมสิ่งแวดล้อม');
      await _updateStep(
          'กำลังลบการลงทุนเพื่อสิ่งแวดล้อม...', 'การลงทุนเพื่อสิ่งแวดล้อม');
      await _updateStep('กำลังลบความท้าทาย Eco...', 'ความท้าทาย Eco');
      await _updateStep('กำลังลบรางวัล Eco Coins...', 'รางวัล Eco Coins');
      await _updateStep('กำลังลบข่าวสาร...', 'ข่าวสาร');
      await _updateStep('กำลังลบหน้าเว็บสำคัญ...', 'หน้าเว็บสำคัญ');
      await _updateStep('กำลังลบคำสั่งซื้อตัวอย่าง...', 'คำสั่งซื้อตัวอย่าง');
      await _updateStep('กำลังลบข้อมูลทดสอบ...', 'ข้อมูลทดสอบ');

      setState(() {
        _currentStep = 'กำลังดำเนินการลบข้อมูล...';
      });

      final results = await CleanupRestoredData.cleanupAllRestoredData();

      setState(() {
        _cleanupResults = results;
        _currentStep = '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ ลบข้อมูลที่กู้คืนมาทั้งหมดสำเร็จ!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _cleanupResults = {
          'status': 'ERROR',
          'error': e.toString(),
        };
        _currentStep = '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isCleaningUp = false;
      });
    }
  }

  Future<void> _updateStep(String step, String completedStep) async {
    setState(() {
      _currentStep = step;
    });

    // Simulate processing time
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _completedSteps.add(completedStep);
    });
  }
}
