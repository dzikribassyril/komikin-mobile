import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_config.dart';
import '../models/reader_settings.dart';
import '../state/app_theme_controller.dart';
import '../state/reader_settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppThemeController>();
    final reader = context.watch<ReaderSettingsController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text('Theme', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.phone_android),
                label: Text('System'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode),
                label: Text('Light'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode),
                label: Text('Dark'),
              ),
            ],
            selected: {theme.themeMode},
            onSelectionChanged: (value) => theme.setThemeMode(value.first),
          ),
          const SizedBox(height: 24),
          Text('Reader', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<ReadingMode>(
            segments: const [
              ButtonSegment(
                value: ReadingMode.vertical,
                icon: Icon(Icons.vertical_align_bottom),
                label: Text('Vertical'),
              ),
              ButtonSegment(
                value: ReadingMode.horizontal,
                icon: Icon(Icons.view_carousel),
                label: Text('Horizontal'),
              ),
            ],
            selected: {reader.settings.readingMode},
            onSelectionChanged: (value) => reader.setReadingMode(value.first),
          ),
          const SizedBox(height: 12),
          SegmentedButton<PageWidth>(
            segments: const [
              ButtonSegment(
                value: PageWidth.fit,
                icon: Icon(Icons.fit_screen),
                label: Text('Fit'),
              ),
              ButtonSegment(
                value: PageWidth.full,
                icon: Icon(Icons.fullscreen),
                label: Text('Full'),
              ),
            ],
            selected: {reader.settings.pageWidth},
            onSelectionChanged: (value) => reader.setPageWidth(value.first),
          ),
          const SizedBox(height: 24),
          Text('API', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.dns_outlined),
            title: const Text('Base URL'),
            subtitle: const Text(AppConfig.apiBaseUrl),
          ),
        ],
      ),
    );
  }
}
