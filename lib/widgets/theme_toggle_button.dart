// lib/widgets/theme_toggle_button.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:green_market/providers/theme_provider.dart';

class ThemeToggleButton extends StatelessWidget {
  final bool showLabel;
  final double iconSize;
  final EdgeInsets? padding;

  const ThemeToggleButton({
    super.key,
    this.showLabel = true,
    this.iconSize = 24.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          padding:
              padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  size: iconSize,
                ),
                onPressed: () {
                  themeProvider.toggleDarkMode();
                },
                tooltip: themeProvider.isDarkMode
                    ? 'เปลี่ยนเป็นโหมดกลางวัน'
                    : 'เปลี่ยนเป็นโหมดกลางคืน',
              ),
              if (showLabel)
                Text(
                  themeProvider.isDarkMode ? 'กลางวัน' : 'กลางคืน',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ),
        );
      },
    );
  }
}

class ThemeToggleSwitch extends StatelessWidget {
  final bool showLabels;
  final double? width;

  const ThemeToggleSwitch({
    super.key,
    this.showLabels = true,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.light_mode,
                size: 20,
                color: !themeProvider.isDarkMode
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              if (showLabels)
                Text(
                  'กลางวัน',
                  style: TextStyle(
                    color: !themeProvider.isDarkMode
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                    fontWeight: !themeProvider.isDarkMode
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              const SizedBox(width: 8),
              Switch(
                value: themeProvider.isDarkMode,
                onChanged: (bool value) {
                  themeProvider.setDarkMode(value);
                },
                activeColor: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              if (showLabels)
                Text(
                  'กลางคืน',
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                    fontWeight: themeProvider.isDarkMode
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                Icons.dark_mode,
                size: 20,
                color: themeProvider.isDarkMode
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ThemeToggleListTile extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? leading;

  const ThemeToggleListTile({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return ListTile(
          leading: leading ??
              Icon(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              ),
          title: Text(title ?? 'โหมดการแสดงผล'),
          subtitle: subtitle != null
              ? Text(subtitle!)
              : Text(
                  themeProvider.isDarkMode
                      ? 'กลางคืน - พื้นหลังเข้ม ข้อความสีสว่าง'
                      : 'กลางวัน - พื้นหลังสว่าง ข้อความสีเข้ม',
                ),
          trailing: Switch(
            value: themeProvider.isDarkMode,
            onChanged: (bool value) {
              themeProvider.setDarkMode(value);
            },
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }
}
