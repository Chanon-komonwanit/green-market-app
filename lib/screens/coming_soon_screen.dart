// lib/screens/coming_soon_screen.dart
import 'package:flutter/material.dart';

class ComingSoonScreen extends StatelessWidget {
  final String featureName;
  final IconData featureIcon;

  const ComingSoonScreen({
    super.key,
    required this.featureName,
    required this.featureIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(featureName),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                featureIcon,
                size: 100,
                color: theme.colorScheme.primary.withAlpha(150),
              ),
              const SizedBox(height: 24),
              Text(
                'Coming Soon!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'ฟีเจอร์ "$featureName" กำลังอยู่ในระหว่างการพัฒนา\nและจะพร้อมให้คุณใช้งานเร็วๆ นี้',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('กลับไปหน้าหลัก'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
