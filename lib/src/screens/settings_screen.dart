import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/reader_settings.dart';
import '../services/api_client.dart';
import '../services/local_storage_service.dart';
import '../services/manga_repository.dart';
import '../state/app_theme_controller.dart';
import '../state/reading_progress_controller.dart';
import '../state/reader_settings_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiController = TextEditingController();
  bool _apiInitialized = false;
  bool _isSavingApi = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_apiInitialized) return;
    _apiController.text = context.read<ApiClient>().baseUrl;
    _apiInitialized = true;
  }

  @override
  void dispose() {
    _apiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppThemeController>();
    final reader = context.watch<ReaderSettingsController>();
    final progress = context.watch<ReadingProgressController>();
    final apiClient = context.watch<ApiClient>();

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
          _ApiBaseUrlEditor(
            controller: _apiController,
            activeBaseUrl: apiClient.baseUrl,
            isSaving: _isSavingApi,
            onSave: _saveApiBaseUrl,
            onReset: _resetApiBaseUrl,
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

  Future<void> _saveApiBaseUrl() async {
    final raw = _apiController.text.trim();
    final normalized = raw.replaceFirst(RegExp(r'/$'), '');
    final uri = Uri.tryParse(normalized);

    if (uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        !{'http', 'https'}.contains(uri.scheme)) {
      _showMessage('Base URL harus diawali http:// atau https://');
      return;
    }

    setState(() => _isSavingApi = true);
    final storage = context.read<LocalStorageService>();
    final apiClient = context.read<ApiClient>();
    final repository = context.read<MangaRepository>();
    try {
      await storage.saveApiBaseUrl(normalized);
      apiClient.setBaseUrl(normalized);
      repository.clearCache();
      _apiController.text = normalized;
      _showMessage('API base URL disimpan');
    } finally {
      if (mounted) {
        setState(() => _isSavingApi = false);
      }
    }
  }

  Future<void> _resetApiBaseUrl() async {
    _apiController.text = context.read<ApiClient>().defaultBaseUrl;
    await _saveApiBaseUrl();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _ApiBaseUrlEditor extends StatelessWidget {
  const _ApiBaseUrlEditor({
    required this.controller,
    required this.activeBaseUrl,
    required this.isSaving,
    required this.onSave,
    required this.onReset,
  });

  final TextEditingController controller;
  final String activeBaseUrl;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onReset;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.dns_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'API Base URL',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              decoration: const InputDecoration(
                hintText: 'http://192.168.1.10:3000',
                prefixIcon: Icon(Icons.link),
              ),
              onSubmitted: (_) => onSave(),
            ),
            const SizedBox(height: 10),
            Text(
              'Aktif: $activeBaseUrl',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isSaving ? null : onReset,
                    icon: const Icon(Icons.restore),
                    label: const Text('Default'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isSaving ? null : onSave,
                    icon: isSaving
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
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
