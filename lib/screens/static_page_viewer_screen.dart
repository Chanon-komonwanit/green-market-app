// lib/screens/static_page_viewer_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:green_market/models/static_page.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class StaticPageViewerScreen extends StatelessWidget {
  final String pageId;

  const StaticPageViewerScreen({super.key, required this.pageId});

  @override
  Widget build(BuildContext context) {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<StaticPage?>(
          future: firebaseService.getStaticPage(pageId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Loading...');
            }
            return Text(snapshot.data?.title ?? 'Page Not Found',
                style: theme.textTheme.titleLarge
                    ?.copyWith(color: theme.colorScheme.primary));
          },
        ),
      ),
      body: FutureBuilder<StaticPage?>(
        future: firebaseService.getStaticPage(pageId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('ไม่สามารถโหลดเนื้อหาได้'));
          }
          final page = snapshot.data!;
          return Markdown(
            data: page.content,
            padding: const EdgeInsets.all(16.0),
            onTapLink: (text, href, title) {
              if (href != null) {
                launchUrl(Uri.parse(href));
              }
            },
            styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
              p: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
              h1: theme.textTheme.headlineMedium,
              h2: theme.textTheme.headlineSmall,
              h3: theme.textTheme.titleLarge,
            ),
          );
        },
      ),
    );
  }
}
