// lib/screens/admin/ai_settings_screen.dart
// 🎛️ AI System Settings Management Screen for Admin
// แอดมินสามารถเปิด/ปิด AI และจัดการการตั้งค่าต่างๆ

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/ai_eco_analysis_service.dart';
import '../../models/ai_settings.dart';
import '../../providers/auth_provider.dart';

class AISettingsScreen extends StatefulWidget {
  const AISettingsScreen({super.key});

  @override
  State<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen> {
  final _aiService = AIEcoAnalysisService();
  final _apiKeyController = TextEditingController();
  final _dailyLimitController = TextEditingController();
  final _minConfidenceController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  AISettings? _currentSettings;
  Map<String, dynamic>? _usageStats;
  Map<String, dynamic>? _accuracyStats;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _dailyLimitController.dispose();
    _minConfidenceController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _aiService.getAISettings();
      final usage = await _aiService.getTodayUsageStats();
      final accuracy = await _aiService.getAIAccuracyStats();

      setState(() {
        _currentSettings = settings;
        _usageStats = usage;
        _accuracyStats = accuracy;
        _apiKeyController.text = settings.apiKey;
        _dailyLimitController.text = settings.dailyLimit.toString();
        _minConfidenceController.text = settings.minConfidenceScore.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  Future<void> _toggleAI(bool enabled) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final adminId = authProvider.currentUser?.uid ?? '';

    try {
      await _aiService.toggleAI(enabled, adminId);
      await _loadSettings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enabled ? '✅ เปิดใช้งาน AI สำเร็จ' : '⛔ ปิดใช้งาน AI สำเร็จ'),
            backgroundColor: enabled ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    if (_currentSettings == null) return;

    setState(() => _isSaving = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final adminId = authProvider.currentUser?.uid ?? '';

      final updatedSettings = _currentSettings!.copyWith(
        apiKey: _apiKeyController.text.trim(),
        dailyLimit: int.tryParse(_dailyLimitController.text) ?? 1500,
        minConfidenceScore: int.tryParse(_minConfidenceController.text) ?? 80,
        updatedAt: DateTime.now(),
        updatedBy: adminId,
      );

      await _aiService.updateAISettings(updatedSettings);
      await _loadSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ บันทึกการตั้งค่าสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('⚙️ AI System Settings'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final settings = _currentSettings!;
    final usage = _usageStats!;
    final accuracy = _accuracyStats!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ AI System Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSettings,
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========== AI STATUS CARD ==========
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          settings.aiEnabled ? Icons.check_circle : Icons.cancel,
                          color: settings.aiEnabled ? Colors.green : Colors.red,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'สถานะ AI System',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                settings.aiEnabled ? 'เปิดใช้งาน' : 'ปิดใช้งาน',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: settings.aiEnabled ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: settings.aiEnabled,
                          onChanged: _toggleAI,
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    
                    // Usage Stats
                    Text(
                      'การใช้งานวันนี้',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    LinearProgressIndicator(
                      value: usage['usagePercentage'] / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        usage['usagePercentage'] > 80 ? Colors.red : Colors.green,
                      ),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 8),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${usage['currentUsage']} / ${usage['dailyLimit']} requests',
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          '${usage['usagePercentage'].toStringAsFixed(1)}%',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: usage['usagePercentage'] > 80 ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'เหลือ ${usage['remainingUsage']} requests',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ========== ACCURACY STATS CARD ==========
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.analytics, color: Colors.blue, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'ความแม่นยำของ AI',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          icon: Icons.assessment,
                          label: 'ความแม่นยำ',
                          value: '${accuracy['accuracy']?.toStringAsFixed(1) ?? '0.0'}%',
                          color: Colors.blue,
                        ),
                        _buildStatItem(
                          icon: Icons.bar_chart,
                          label: 'วิเคราะห์ทั้งหมด',
                          value: '${accuracy['totalAnalysis'] ?? 0}',
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ========== API SETTINGS CARD ==========
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔑 API Configuration',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: _apiKeyController,
                      decoration: const InputDecoration(
                        labelText: 'Gemini API Key',
                        hintText: 'กรอก API Key จาก Google AI Studio',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.vpn_key),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'รับ API Key ฟรีที่: https://makersuite.google.com/app/apikey',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.blue,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    TextField(
                      controller: _dailyLimitController,
                      decoration: const InputDecoration(
                        labelText: 'Daily Limit',
                        hintText: 'จำนวนครั้งสูงสุดต่อวัน',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.speed),
                        suffixText: 'requests/day',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'แนะนำ: 1,500 (Free tier ของ Gemini)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    TextField(
                      controller: _minConfidenceController,
                      decoration: const InputDecoration(
                        labelText: 'Min Confidence Score',
                        hintText: 'คะแนนความมั่นใจขั้นต่ำ',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.thumb_up),
                        suffixText: '%',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    SwitchListTile(
                      title: const Text('Auto-approve High Confidence'),
                      subtitle: const Text('อนุมัติอัตโนมัติเมื่อ AI มั่นใจสูง'),
                      value: settings.autoApproveHighConfidence,
                      onChanged: (value) {
                        setState(() {
                          _currentSettings = settings.copyWith(
                            autoApproveHighConfidence: value,
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ========== SAVE BUTTON ==========
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveSettings,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึกการตั้งค่า'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ========== INFO CARD ==========
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'ข้อมูลเพิ่มเติม',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• ปิด AI System เมื่อต้องการประหยัด API usage\n'
                      '• Daily limit จะ reset อัตโนมัติทุกวันเวลา 00:00\n'
                      '• API Key จะถูกเข้ารหัสเก็บใน Firestore\n'
                      '• ระบบจะใช้ fallback analysis เมื่อ AI ถูกปิดหรือเกิน limit',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
