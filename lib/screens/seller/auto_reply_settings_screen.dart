// lib/screens/seller/auto_reply_settings_screen.dart
// Auto Reply Settings Screen - ตั้งค่าระบบตอบกลับอัตโนมัติ

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:green_market/models/auto_reply.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/theme/app_colors.dart';
import 'package:logger/logger.dart';

class AutoReplySettingsScreen extends StatefulWidget {
  const AutoReplySettingsScreen({super.key});

  @override
  State<AutoReplySettingsScreen> createState() =>
      _AutoReplySettingsScreenState();
}

class _AutoReplySettingsScreenState extends State<AutoReplySettingsScreen>
    with SingleTickerProviderStateMixin {
  final _firebaseService = FirebaseService();
  final _logger = Logger();

  late TabController _tabController;
  bool _isLoading = true;
  bool _isSaving = false;

  // Settings
  AutoReplySettings? _settings;
  final _welcomeMessageController = TextEditingController();
  final _outOfOfficeMessageController = TextEditingController();

  // Quick Replies
  List<QuickReply> _quickReplies = [];

  // Auto Reply Templates
  List<AutoReplyTemplate> _templates = [];

  String? _sellerId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _sellerId = FirebaseAuth.instance.currentUser?.uid;
    if (_sellerId != null) {
      _loadData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _welcomeMessageController.dispose();
    _outOfOfficeMessageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load settings
      final settingsData =
          await _firebaseService.getAutoReplySettings(_sellerId!);
      _settings = settingsData != null
          ? AutoReplySettings.fromMap(settingsData)
          : AutoReplySettings(sellerId: _sellerId!);

      _welcomeMessageController.text = _settings!.welcomeMessage;
      _outOfOfficeMessageController.text = _settings!.outOfOfficeMessage;

      // Load quick replies
      final quickRepliesData =
          await _firebaseService.getQuickReplies(_sellerId!);
      _quickReplies =
          quickRepliesData.map((data) => QuickReply.fromMap(data)).toList();

      // If no quick replies, create defaults
      if (_quickReplies.isEmpty) {
        await _createDefaultQuickReplies();
      }

      // Load auto reply templates
      final templatesData =
          await _firebaseService.getAutoReplyTemplates(_sellerId!);
      _templates =
          templatesData.map((data) => AutoReplyTemplate.fromMap(data)).toList();
    } catch (e) {
      _logger.e('Error loading auto reply data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('โหลดข้อมูลไม่สำเร็จ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createDefaultQuickReplies() async {
    try {
      for (var template in DefaultQuickReplies.templates) {
        final quickReply = QuickReply(
          id: '',
          sellerId: _sellerId!,
          label: template['label']!,
          message: template['message']!,
          emoji: template['emoji'],
        );
        final id = await _firebaseService.addQuickReply(quickReply.toMap());
        _quickReplies.add(quickReply.copyWith(id: id));
      }
    } catch (e) {
      _logger.e('Error creating default quick replies: $e');
    }
  }

  Future<void> _saveSettings() async {
    if (_settings == null) return;

    setState(() => _isSaving = true);
    try {
      _settings = _settings!.copyWith(
        welcomeMessage: _welcomeMessageController.text.trim(),
        outOfOfficeMessage: _outOfOfficeMessageController.text.trim(),
      );

      await _firebaseService.saveAutoReplySettings(
          _sellerId!, _settings!.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกการตั้งค่าสำเร็จ')),
        );
      }
    } catch (e) {
      _logger.e('Error saving settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ระบบตอบกลับอัตโนมัติ'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.settings), text: 'ตั้งค่า'),
            Tab(icon: Icon(Icons.flash_on), text: 'ตอบด่วน'),
            Tab(icon: Icon(Icons.auto_awesome), text: 'คำหลัก'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSettingsTab(),
                _buildQuickRepliesTab(),
                _buildTemplatesTab(),
              ],
            ),
    );
  }

  Widget _buildSettingsTab() {
    if (_settings == null) return const Center(child: Text('ไม่พบข้อมูล'));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Enable/Disable Auto Reply
        Card(
          child: SwitchListTile(
            title: const Text('เปิดใช้ระบบตอบกลับอัตโนมัติ',
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('ตอบข้อความอัตโนมัติเมื่อลูกค้าส่งข้อความมา'),
            value: _settings!.isEnabled,
            activeColor: AppColors.primary,
            onChanged: (value) {
              setState(() {
                _settings = _settings!.copyWith(isEnabled: value);
              });
              _saveSettings();
            },
          ),
        ),
        const SizedBox(height: 16),

        // Welcome Message
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.waving_hand, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text('ข้อความต้อนรับ',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('ส่งข้อความต้อนรับอัตโนมัติ'),
                  value: _settings!.sendWelcomeMessage,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() {
                      _settings =
                          _settings!.copyWith(sendWelcomeMessage: value);
                    });
                    _saveSettings();
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _welcomeMessageController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'ข้อความต้อนรับ',
                    hintText: 'สวัสดีค่ะ! ยินดีให้บริการค่ะ 😊',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Out of Office
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule, color: AppColors.warning),
                    const SizedBox(width: 8),
                    const Text('นอกเวลาทำการ',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('เปิดใช้โหมดนอกเวลาทำการ'),
                  value: _settings!.enableOutOfOffice,
                  activeColor: AppColors.warning,
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings!.copyWith(enableOutOfOffice: value);
                    });
                    _saveSettings();
                  },
                ),
                if (_settings!.enableOutOfOffice) ...[
                  const SizedBox(height: 12),
                  const Text('วันทำการ:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildWorkingDaysSelector(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeField(
                            'เวลาเปิด', _settings!.workingHoursStart, (value) {
                          setState(() {
                            _settings =
                                _settings!.copyWith(workingHoursStart: value);
                          });
                          _saveSettings();
                        }),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimeField(
                            'เวลาปิด', _settings!.workingHoursEnd, (value) {
                          setState(() {
                            _settings =
                                _settings!.copyWith(workingHoursEnd: value);
                          });
                          _saveSettings();
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _outOfOfficeMessageController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'ข้อความนอกเวลาทำการ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Save Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text('บันทึกการตั้งค่า',
                    style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkingDaysSelector() {
    const days = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];

    return Wrap(
      spacing: 8,
      children: List.generate(7, (index) {
        final isSelected = _settings!.workingDays.contains(index);
        return FilterChip(
          label: Text(days[index]),
          selected: isSelected,
          selectedColor: AppColors.primary,
          onSelected: (selected) {
            setState(() {
              final workingDays = List<int>.from(_settings!.workingDays);
              if (selected) {
                workingDays.add(index);
              } else {
                workingDays.remove(index);
              }
              workingDays.sort();
              _settings = _settings!.copyWith(workingDays: workingDays);
            });
            _saveSettings();
          },
        );
      }),
    );
  }

  Widget _buildTimeField(
      String label, String value, Function(String) onChanged) {
    return InkWell(
      onTap: () async {
        final parts = value.split(':');
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          ),
        );
        if (time != null) {
          onChanged(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(value),
      ),
    );
  }

  Widget _buildQuickRepliesTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.primary.withOpacity(0.1),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ข้อความตอบกลับด่วน ใช้สำหรับตอบคำถามที่ถามบ่อย กดที่ข้อความเพื่อใช้งาน',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _quickReplies.length + 1,
            itemBuilder: (context, index) {
              if (index == _quickReplies.length) {
                return _buildAddQuickReplyButton();
              }
              return _buildQuickReplyCard(_quickReplies[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddQuickReplyButton() {
    return Card(
      child: InkWell(
        onTap: _showAddQuickReplyDialog,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: const [
              Icon(Icons.add_circle_outline, color: AppColors.primary),
              SizedBox(width: 12),
              Text('เพิ่มข้อความตอบด่วน',
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickReplyCard(QuickReply reply) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: reply.emoji != null
            ? Text(reply.emoji!, style: const TextStyle(fontSize: 28))
            : const Icon(Icons.chat_bubble_outline),
        title: Text(reply.label,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle:
            Text(reply.message, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (reply.usageCount > 0)
              Chip(
                label: Text('${reply.usageCount}',
                    style: const TextStyle(fontSize: 10)),
                padding: EdgeInsets.zero,
              ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showEditQuickReplyDialog(reply),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _deleteQuickReply(reply),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddQuickReplyDialog() {
    final labelController = TextEditingController();
    final messageController = TextEditingController();
    final emojiController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เพิ่มข้อความตอบด่วน'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อ',
                  hintText: 'เช่น ยินดีต้อนรับ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emojiController,
                decoration: const InputDecoration(
                  labelText: 'Emoji (ไม่บังคับ)',
                  hintText: '😊',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'ข้อความ',
                  hintText: 'ข้อความที่ต้องการส่ง',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (labelController.text.isEmpty ||
                  messageController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบ')),
                );
                return;
              }

              try {
                final quickReply = QuickReply(
                  id: '',
                  sellerId: _sellerId!,
                  label: labelController.text.trim(),
                  message: messageController.text.trim(),
                  emoji: emojiController.text.trim().isNotEmpty
                      ? emojiController.text.trim()
                      : null,
                );

                final id =
                    await _firebaseService.addQuickReply(quickReply.toMap());
                setState(() {
                  _quickReplies.add(quickReply.copyWith(id: id));
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('เพิ่มสำเร็จ')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                );
              }
            },
            child: const Text('เพิ่ม'),
          ),
        ],
      ),
    );
  }

  void _showEditQuickReplyDialog(QuickReply reply) {
    final labelController = TextEditingController(text: reply.label);
    final messageController = TextEditingController(text: reply.message);
    final emojiController = TextEditingController(text: reply.emoji ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('แก้ไขข้อความตอบด่วน'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emojiController,
                decoration: const InputDecoration(
                  labelText: 'Emoji',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'ข้อความ',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firebaseService.updateQuickReply(reply.id, {
                  'label': labelController.text.trim(),
                  'message': messageController.text.trim(),
                  'emoji': emojiController.text.trim().isNotEmpty
                      ? emojiController.text.trim()
                      : null,
                });

                final index = _quickReplies.indexWhere((q) => q.id == reply.id);
                setState(() {
                  _quickReplies[index] = reply.copyWith(
                    label: labelController.text.trim(),
                    message: messageController.text.trim(),
                    emoji: emojiController.text.trim().isNotEmpty
                        ? emojiController.text.trim()
                        : null,
                  );
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('บันทึกสำเร็จ')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                );
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteQuickReply(QuickReply reply) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบข้อความตอบด่วน'),
        content: Text('ต้องการลบ "${reply.label}" หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firebaseService.deleteQuickReply(reply.id);
      setState(() {
        _quickReplies.removeWhere((q) => q.id == reply.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบสำเร็จ')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  Widget _buildTemplatesTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.warning.withOpacity(0.1),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.warning),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ตั้งค่าคำหลักและข้อความตอบกลับอัตโนมัติ เมื่อลูกค้าพิมพ์คำหลัก ระบบจะตอบกลับอัตโนมัติ',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _templates.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('ยังไม่มีเทมเพลตคำหลัก'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showAddTemplateDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('เพิ่มเทมเพลต'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _templates.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _templates.length) {
                      return Card(
                        child: InkWell(
                          onTap: _showAddTemplateDialog,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: const [
                                Icon(Icons.add_circle_outline,
                                    color: AppColors.primary),
                                SizedBox(width: 12),
                                Text('เพิ่มเทมเพลตใหม่',
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    return _buildTemplateCard(_templates[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTemplateCard(AutoReplyTemplate template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(
          template.isActive ? Icons.check_circle : Icons.cancel,
          color: template.isActive ? Colors.green : Colors.grey,
        ),
        title: Text('คำหลัก: "${template.trigger}"',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(template.response,
            maxLines: 2, overflow: TextOverflow.ellipsis),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('คำตอบ:',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(template.response),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showEditTemplateDialog(template),
                        icon: const Icon(Icons.edit),
                        label: const Text('แก้ไข'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteTemplate(template),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red),
                        icon: const Icon(Icons.delete),
                        label: const Text('ลบ'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTemplateDialog() {
    final triggerController = TextEditingController();
    final responseController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เพิ่มเทมเพลตคำหลัก'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: triggerController,
                decoration: const InputDecoration(
                  labelText: 'คำหลัก',
                  hintText: 'เช่น ราคา, ส่งไว, สต็อก',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: responseController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'ข้อความตอบกลับ',
                  hintText: 'ข้อความที่จะตอบอัตโนมัติเมื่อมีคำหลัก',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (triggerController.text.isEmpty ||
                  responseController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบ')),
                );
                return;
              }

              try {
                final template = AutoReplyTemplate(
                  id: '',
                  sellerId: _sellerId!,
                  trigger: triggerController.text.trim(),
                  response: responseController.text.trim(),
                  priority: _templates.length,
                );

                final id = await _firebaseService
                    .addAutoReplyTemplate(template.toMap());
                setState(() {
                  _templates.add(template.copyWith(id: id));
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('เพิ่มสำเร็จ')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                );
              }
            },
            child: const Text('เพิ่ม'),
          ),
        ],
      ),
    );
  }

  void _showEditTemplateDialog(AutoReplyTemplate template) {
    final triggerController = TextEditingController(text: template.trigger);
    final responseController = TextEditingController(text: template.response);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('แก้ไขเทมเพลต'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: triggerController,
                decoration: const InputDecoration(
                  labelText: 'คำหลัก',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: responseController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'ข้อความตอบกลับ',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firebaseService.updateAutoReplyTemplate(template.id, {
                  'trigger': triggerController.text.trim(),
                  'response': responseController.text.trim(),
                });

                final index = _templates.indexWhere((t) => t.id == template.id);
                setState(() {
                  _templates[index] = template.copyWith(
                    trigger: triggerController.text.trim(),
                    response: responseController.text.trim(),
                  );
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('บันทึกสำเร็จ')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                );
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTemplate(AutoReplyTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบเทมเพลต'),
        content: Text('ต้องการลบคำหลัก "${template.trigger}" หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firebaseService.deleteAutoReplyTemplate(template.id);
      setState(() {
        _templates.removeWhere((t) => t.id == template.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบสำเร็จ')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  AutoReplyTemplate copyWith({String? id}) {
    // Helper method placeholder
    return AutoReplyTemplate(
      id: id ?? '',
      sellerId: _sellerId!,
      trigger: '',
      response: '',
    );
  }
}
