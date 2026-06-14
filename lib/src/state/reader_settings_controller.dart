import 'package:flutter/foundation.dart';

import '../models/reader_settings.dart';
import '../services/local_storage_service.dart';

class ReaderSettingsController extends ChangeNotifier {
  ReaderSettingsController(this._storage);

  final LocalStorageService _storage;

  ReaderSettings _settings = const ReaderSettings();

  ReaderSettings get settings => _settings;

  Future<void> load() async {
    _settings = await _storage.getReaderSettings();
  }

  Future<void> update(ReaderSettings settings) async {
    _settings = settings;
    notifyListeners();
    await _storage.saveReaderSettings(settings);
  }

  Future<void> setReadingMode(ReadingMode mode) async {
    await update(_settings.copyWith(readingMode: mode));
  }

  Future<void> setPageWidth(PageWidth width) async {
    await update(_settings.copyWith(pageWidth: width));
  }
}
