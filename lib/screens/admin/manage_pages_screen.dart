// lib/screens/admin/manage_pages_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/static_page.dart';
import 'package:green_market/screens/admin/edit_page_screen.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/app_utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ManagePagesScreen extends StatefulWidget {
  const ManagePagesScreen({super.key});

  @override
  State<ManagePagesScreen> createState() => _ManagePagesScreenState();
}

class _ManagePagesScreenState extends State<ManagePagesScreen> {
  // Method to handle page deletion with confirmation
  Future<void> _deletePage(
      BuildContext context, String pageId, String pageTitle) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('ยืนยันการลบ'),
          content: Text(
              'คุณแน่ใจหรือไม่ว่าต้องการลบเพจ "$pageTitle"? การกระทำนี้ไม่สามารถย้อนกลับได้'),
          actions: <Widget>[
            TextButton(
              child: const Text('ยกเลิก'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('ลบ'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true && mounted) {
      try {
        final firebaseService =
            Provider.of<FirebaseService>(context, listen: false);
        await firebaseService.deleteStaticPage(pageId);
        if (mounted) {
          showAppSnackBar(context, 'ลบเพจ "$pageTitle" สำเร็จ',
              isSuccess: true);
        }
      } catch (e) {
        if (mounted) {
          showAppSnackBar(context, 'เกิดข้อผิดพลาดในการลบเพจ: $e',
              isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('จัดการหน้าเพจ',
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.primary)),
      ),
      body: StreamBuilder<List<StaticPage>>(
        stream: firebaseService.getStaticPages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ยังไม่มีหน้าเพจในระบบ'));
          }

          final pages = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: pages.length,
            itemBuilder: (context, index) {
              final page = pages[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: const Icon(Icons.article_outlined),
                  title: Text(page.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      'Last Updated: ${DateFormat('dd MMM yyyy, HH:mm').format(page.updatedAt.toDate())}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.edit_outlined, color: Colors.blue),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => EditPageScreen(page: page),
                          ));
                        },
                      ),
                      // Implemented delete functionality
                      IconButton(
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          _deletePage(context, page.id, page.title);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const EditPageScreen(),
          ));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
