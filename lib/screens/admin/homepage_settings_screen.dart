// lib/screens/admin/homepage_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/app_settings.dart';
import 'package:green_market/models/homepage_settings.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:green_market/utils/constants.dart';
import 'package:green_market/utils/ui_helpers.dart'; // Import the new helper
import 'package:cloud_firestore/cloud_firestore.dart';

class HomepageSettingsScreen extends StatefulWidget {
  const HomepageSettingsScreen({super.key});

  @override
  State<HomepageSettingsScreen> createState() => _HomepageSettingsScreenState();
}

class _HomepageSettingsScreenState extends State<HomepageSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _heroTitleController = TextEditingController();
  final TextEditingController _heroSubtitleController = TextEditingController();
  final TextEditingController _heroImageUrlController = TextEditingController();

  bool _isLoading = true;
  AppSettings? _appSettings;

  @override
  void initState() {
    super.initState();
    _loadHomepageData();
    _heroImageUrlController.addListener(_updateImagePreview);
  }

  Future<void> _loadHomepageData() async {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    try {
      final appSettingsData = await firebaseService.getAppSettingsDocument();
      if (mounted && appSettingsData != null) {
        _appSettings = AppSettings.fromMap(appSettingsData);
        _heroTitleController.text = _appSettings!.homepageSettings.heroTitle;
        _heroSubtitleController.text =
            _appSettings!.homepageSettings.heroSubtitle;
        _heroImageUrlController.text =
            _appSettings!.homepageSettings.heroImageUrl;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูลหน้าแรก: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveHomepageData() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    final updatedHomepageSettings = HomepageSettings(
      heroTitle: _heroTitleController.text.trim(),
      heroSubtitle: _heroSubtitleController.text.trim(),
      heroImageUrl: _heroImageUrlController.text.trim(),
    );

    final appSettingsToSave = AppSettings(
      id: _appSettings?.id ?? 'app_settings',
      appName: _appSettings?.appName ?? 'Green Market',
      contactEmail: _appSettings?.contactEmail ?? 'support@greenmarket.com',
      homepageSettings: updatedHomepageSettings,
      createdAt: _appSettings?.createdAt ?? Timestamp.now(),
      updatedAt: Timestamp.now(),
    );

    try {
      await firebaseService
          .updateAppSettingsDocument(appSettingsToSave.toMap());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('บันทึกการตั้งค่าหน้าแรกสำเร็จ!'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกการตั้งค่า: $e')),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _updateImagePreview() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _heroTitleController.dispose();
    _heroSubtitleController.dispose();
    _heroImageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'การตั้งค่าส่วน Hero บนหน้าแรก',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _heroTitleController,
                    decoration: buildInputDecoration(context, 'หัวข้อ Hero'),
                    style: theme.textTheme.bodyLarge,
                    validator: (v) => v!.isEmpty ? 'กรุณากรอกหัวข้อ' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _heroSubtitleController,
                    decoration: buildInputDecoration(context, 'คำบรรยาย Hero'),
                    style: theme.textTheme.bodyLarge,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _heroImageUrlController,
                    decoration:
                        buildInputDecoration(context, 'URL รูปภาพ Hero'),
                    style: theme.textTheme.bodyLarge,
                    keyboardType: TextInputType.url,
                    validator: (v) => (v != null &&
                            v.isNotEmpty &&
                            !(Uri.tryParse(v)?.isAbsolute ?? false))
                        ? 'รูปแบบ URL ไม่ถูกต้อง'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildImagePreview(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveHomepageData,
                        child: const Text('บันทึกการตั้งค่า')),
                  ),
                ],
              ),
            ),
          );
  }

  Widget _buildImagePreview() {
    final imageUrl = _heroImageUrlController.text.trim();
    if (imageUrl.isEmpty) {
      return const SizedBox.shrink(); // Don't show anything if URL is empty
    }

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'ไม่สามารถแสดงรูปภาพได้\nกรุณาตรวจสอบ URL',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
