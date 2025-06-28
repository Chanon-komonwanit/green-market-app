// lib/screens/admin/edit_page_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/models/static_page.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/app_utils.dart';
import 'package:green_market/utils/ui_helpers.dart';
import 'package:provider/provider.dart';

class EditPageScreen extends StatefulWidget {
  final StaticPage? page;

  const EditPageScreen({super.key, this.page});

  @override
  State<EditPageScreen> createState() => _EditPageScreenState();
}

class _EditPageScreenState extends State<EditPageScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _idController;
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.page?.id ?? '');
    _titleController = TextEditingController(text: widget.page?.title ?? '');
    _contentController =
        TextEditingController(text: widget.page?.content ?? '');
  }

  @override
  void dispose() {
    _idController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _savePage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    try {
      final pageToSave = StaticPage(
        id: widget.page?.id ?? _idController.text.trim(),
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        createdAt: widget.page?.createdAt ?? Timestamp.now(),
        updatedAt: Timestamp.now(),
      );
      await firebaseService.saveStaticPage(pageToSave);

      if (mounted) {
        showAppSnackBar(context, 'บันทึกหน้าสำเร็จ', isSuccess: true);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'เกิดข้อผิดพลาด: ${e.toString()}',
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.page == null ? 'สร้างหน้าใหม่' : 'แก้ไขหน้า'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _idController,
                decoration:
                    buildInputDecoration(context, 'Page ID (e.g., about-us)'),
                enabled: widget.page ==
                    null, // Disable editing ID for existing pages
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอก Page ID';
                  }
                  if (value.contains(' ')) {
                    return 'Page ID ห้ามมีช่องว่าง';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: buildInputDecoration(context, 'หัวข้อหน้า'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกหัวข้อ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration:
                    buildInputDecoration(context, 'เนื้อหา (รองรับ Markdown)'),
                maxLines: 15,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกเนื้อหา';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _savePage,
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Text('บันทึก'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
