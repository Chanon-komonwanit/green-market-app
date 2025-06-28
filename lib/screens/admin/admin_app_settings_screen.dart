// lib/screens/admin/admin_app_settings_screen.dart
// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/models/app_settings.dart';
import 'package:green_market/models/homepage_settings.dart';
import 'package:green_market/models/theme_settings.dart'; // Import ThemeSettings
import 'package:green_market/providers/theme_provider.dart'; // Import ThemeProvider for currentSettings
import 'package:green_market/providers/user_provider.dart'; // Import UserProvider to check admin status
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/app_utils.dart';
import 'package:green_market/utils/ui_helpers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class AdminAppSettingsScreen extends StatefulWidget {
  const AdminAppSettingsScreen({super.key});

  @override
  State<AdminAppSettingsScreen> createState() => _AdminAppSettingsScreenState();
}

class _AdminAppSettingsScreenState extends State<AdminAppSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _heroTitleController = TextEditingController();
  final TextEditingController _heroSubtitleController = TextEditingController();
  XFile? _pickedHeroImageFile;
  String? _currentHeroImageUrl;
  Color _primaryColor = Colors.green; // Default
  Color _secondaryColor = Colors.orange; // Default
  bool _isLoading = true;
  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadSettings(); // This will now load both homepage and theme settings
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final firebaseService = Provider.of<FirebaseService>(
      context,
      listen: false,
    );
    try {
      // Load AppSettings (which contains HomepageSettings) and handle null
      final Map<String, dynamic>? appSettingsData =
          await firebaseService.getAppSettingsDocument();
      final AppSettings? appSettings =
          appSettingsData != null ? AppSettings.fromMap(appSettingsData) : null;
      if (mounted && appSettings != null) {
        _heroTitleController.text = appSettings
            .homepageSettings.heroTitle; // Corrected: Use safe access
        _heroSubtitleController.text =
            appSettings.homepageSettings.heroSubtitle; // Safe access
        _currentHeroImageUrl =
            appSettings.homepageSettings.heroImageUrl; // Safe access
      } else {
        // If no app settings document or homepage settings, load defaults
        final defaultHomepage = HomepageSettings.defaultSettings();
        _heroTitleController.text = defaultHomepage.heroTitle;
        _heroSubtitleController.text = defaultHomepage.heroSubtitle;
        _currentHeroImageUrl = defaultHomepage.heroImageUrl;
      }

      // Load Theme Settings
      final Map<String, dynamic>? themeData = await firebaseService
          .streamThemeSettingsDocument()
          .first; // Use .first to get the first emission from the stream
      if (mounted && themeData != null) {
        final themeSettings = ThemeSettings.fromMap(themeData);
        _primaryColor = Color(themeSettings.primaryColor);
        _secondaryColor = Color(themeSettings.secondaryColor);
      } else {
        // If no theme settings, load defaults
        final defaultTheme = ThemeSettings.defaultSettings();
        _primaryColor = Color(defaultTheme.primaryColor);
        _secondaryColor = Color(defaultTheme.secondaryColor);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          'ไม่สามารถโหลดการตั้งค่าได้: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickHeroImage() async {
    final XFile? selectedImage = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (selectedImage != null) {
      if (mounted) {
        setState(() {
          _pickedHeroImageFile = selectedImage;
          _currentHeroImageUrl = null; // Clear current URL if new image picked
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    final firebaseService = Provider.of<FirebaseService>(
      context,
      listen: false,
    );
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Load current app settings for merging fields
    final Map<String, dynamic>? appSettingsData =
        await firebaseService.getAppSettingsDocument();
    final AppSettings? appSettings =
        appSettingsData != null ? AppSettings.fromMap(appSettingsData) : null;

    // Check if user is admin before proceeding
    if (userProvider.currentUser == null || !userProvider.isAdmin) {
      // Corrected: Use isAdmin getter
      showAppSnackBar(
        context,
        'คุณไม่มีสิทธิ์ในการบันทึกการตั้งค่านี้',
        isError: true,
      );
      setState(() => _isSaving = false); // Stop saving state
      return;
    }

    String? newHeroImageUrl = _currentHeroImageUrl;

    try {
      // --- Save Homepage Settings ---
      if (_pickedHeroImageFile != null) {
        const uuid = Uuid();
        final extension = _pickedHeroImageFile!.name.split('.').last;
        final fileName = '${uuid.v4()}.$extension';
        const storagePath = 'app_settings';

        firebaseService.logger.i(
          'Attempting to upload image: $fileName to $storagePath',
        );

        if (kIsWeb) {
          final bytes = await _pickedHeroImageFile!.readAsBytes();
          newHeroImageUrl = await firebaseService.uploadWebImage(
            bytes,
            storagePath,
          );
        } else {
          newHeroImageUrl = await firebaseService.uploadImageFile(
            File(_pickedHeroImageFile!.path),
            storagePath,
          );
        }
        firebaseService.logger.i(
          'Image uploaded successfully: $newHeroImageUrl',
        );
      } else if (_currentHeroImageUrl != null &&
          _currentHeroImageUrl!.isEmpty) {
        // If user cleared the URL and didn't pick a new image, set to null
        newHeroImageUrl = null;
        firebaseService.logger.i('Hero image URL explicitly cleared.');
      } else {
        // If no new image picked and not explicitly cleared, keep existing URL
        newHeroImageUrl = _currentHeroImageUrl;
        firebaseService.logger.i(
          'No new image picked, retaining existing URL: $newHeroImageUrl',
        );
      }

      final updatedHomepageSettings = HomepageSettings(
        heroTitle: _heroTitleController.text.trim(),
        heroSubtitle: _heroSubtitleController.text.trim(),
        heroImageUrl: newHeroImageUrl ?? '',
      );

      // Assuming AppSettings only contains homepageSettings for now.
      // If it's more complex, this needs adjustment.
      final finalAppSettings = AppSettings(
        id: appSettings?.id ?? 'app_settings', // Use existing ID or default
        appName: appSettings?.appName ??
            'Green Market', // Preserve existing or default
        contactEmail: appSettings?.contactEmail ??
            'support@greenmarket.com', // Preserve existing or default
        createdAt: appSettings?.createdAt ?? Timestamp.now(),
        updatedAt: Timestamp.now(), // Always update
        homepageSettings: updatedHomepageSettings,
      );

      firebaseService.logger.i(
        'Updating app_settings document with: ${finalAppSettings.toMap()}',
      );
      await firebaseService.updateAppSettingsDocument(finalAppSettings.toMap());
      firebaseService.logger.i('App settings updated in Firestore.');

      // --- Save Theme Settings ---
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final updatedThemeSettings = ThemeSettings(
        primaryColor: _primaryColor.value,
        secondaryColor: _secondaryColor.value,
        tertiaryColor: themeProvider.currentSettings.tertiaryColor,
        useDarkTheme: themeProvider.currentSettings.useDarkTheme,
      );

      firebaseService.logger.i(
        'Updating app_theme_settings with: ${updatedThemeSettings.toMap()}',
      );
      await firebaseService.updateThemeSettingsDocument(
        updatedThemeSettings.toMap(),
      );
      firebaseService.logger.i('Theme settings updated in Firestore.');

      if (mounted) {
        showAppSnackBar(context, 'บันทึกการตั้งค่าสำเร็จ', isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          'เกิดข้อผิดพลาดในการบันทึก: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _heroTitleController.dispose();
    _heroSubtitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ตั้งค่าแอปพลิเคชัน',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ), // Use primary from theme
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'การตั้งค่าหน้าหลัก (Hero Banner)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _heroTitleController,
                      decoration: buildInputDecoration(
                        context,
                        'หัวข้อ Hero Banner',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'กรุณากรอกหัวข้อ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _heroSubtitleController,
                      decoration: buildInputDecoration(
                        context,
                        'คำบรรยาย Hero Banner',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'รูปภาพ Hero Banner',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Center(
                      // Image preview section
                      child: _buildHeroImagePreview(context),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _pickHeroImage,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('เลือกรูปภาพ'),
                      ),
                    ),
                    if (_currentHeroImageUrl != null ||
                        _pickedHeroImageFile != null)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _clearHeroImage,
                          icon: const Icon(Icons.delete_forever_outlined),
                          label: const Text('ลบรูปภาพ'),
                        ),
                      ),
                    const SizedBox(height: 32),
                    Text(
                      'การตั้งค่าธีม (สีหลักและสีรอง)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(
                        'Primary Color',
                        style: theme.textTheme.bodyLarge,
                      ),
                      trailing: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                      ),
                      onTap: () => _pickColor(true),
                    ),
                    ListTile(
                      title: Text(
                        'Secondary Color',
                        style: theme.textTheme.bodyLarge,
                      ),
                      trailing: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _secondaryColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                      ),
                      onTap: () => _pickColor(false),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveSettings,
                        child: _isSaving
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text('บันทึกการตั้งค่า'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _pickColor(bool isPrimary) {
    Color currentColor = isPrimary ? _primaryColor : _secondaryColor;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isPrimary ? 'เลือก Primary Color' : 'เลือก Secondary Color',
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,
              onColorChanged: (color) {
                currentColor = color;
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('เลือก'),
              onPressed: () {
                setState(() {
                  if (isPrimary) {
                    _primaryColor = currentColor;
                  } else {
                    _secondaryColor = currentColor;
                  }
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildImageErrorPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 150,
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.image_outlined,
        size: 50,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  void _clearHeroImage() {
    setState(() {
      _pickedHeroImageFile = null;
      _currentHeroImageUrl = null;
    });
  }

  Widget _buildHeroImagePreview(BuildContext context) {
    if (_pickedHeroImageFile != null) {
      if (kIsWeb) {
        return FutureBuilder<Uint8List>(
          future: _pickedHeroImageFile!.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Image.memory(
                snapshot.data!,
                height: 150,
                fit: BoxFit.cover,
              );
            }
            if (snapshot.hasError) {
              return _buildImageErrorPlaceholder(context);
            }
            return const CircularProgressIndicator();
          },
        );
      } else {
        return Image.file(
          File(_pickedHeroImageFile!.path),
          height: 150,
          fit: BoxFit.cover,
        );
      }
    } else if (_currentHeroImageUrl != null &&
        _currentHeroImageUrl!.isNotEmpty) {
      return Image.network(
        _currentHeroImageUrl!,
        height: 150,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildImageErrorPlaceholder(context),
      );
    } else {
      return _buildImageErrorPlaceholder(context);
    }
  }
}
