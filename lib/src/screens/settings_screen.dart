import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_config.dart';
import '../models/reader_settings.dart';
import '../state/app_theme_controller.dart';
import '../state/reading_progress_controller.dart';
import '../state/reader_settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppThemeController>();
    final reader = context.watch<ReaderSettingsController>();
    final progress = context.watch<ReadingProgressController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const _AppIdentity(),
          const SizedBox(height: 24),
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
          const SizedBox(height: 24),
          Text('Data', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history),
            title: const Text('Reading progress'),
            subtitle: Text('${progress.items.length} manga tersimpan'),
            trailing: TextButton(
              onPressed: progress.items.isEmpty ? null : progress.clear,
              child: const Text('Clear'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppIdentity extends StatelessWidget {
  const _AppIdentity();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/komikin_logo.png',
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KomikIN',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Comic reading app',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
