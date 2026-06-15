import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/app/komikin_app.dart';
import 'src/core/app_config.dart';
import 'src/services/api_client.dart';
import 'src/services/local_storage_service.dart';
import 'src/services/manga_repository.dart';
import 'src/state/app_theme_controller.dart';
import 'src/state/bookmark_controller.dart';
import 'src/state/read_history_controller.dart';
import 'src/state/reading_progress_controller.dart';
import 'src/state/reader_settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = LocalStorageService();
  final apiBaseUrl = await storage.getApiBaseUrl(AppConfig.apiBaseUrl);
  final apiClient = ApiClient(baseUrl: apiBaseUrl);
  final repository = MangaRepository(apiClient);

  final themeController = AppThemeController(storage);
  final readerSettings = ReaderSettingsController(storage);
  final bookmarks = BookmarkController(storage, repository);
  final readHistory = ReadHistoryController(storage);
  final readingProgress = ReadingProgressController(storage);

  await Future.wait([
    themeController.load(),
    readerSettings.load(),
    bookmarks.load(),
    readingProgress.load(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: storage),
        Provider.value(value: apiClient),
        Provider.value(value: repository),
        ChangeNotifierProvider.value(value: themeController),
        ChangeNotifierProvider.value(value: readerSettings),
        ChangeNotifierProvider.value(value: bookmarks),
        ChangeNotifierProvider.value(value: readHistory),
        ChangeNotifierProvider.value(value: readingProgress),
      ],
      child: const KomikinApp(),
    ),
  );
}
