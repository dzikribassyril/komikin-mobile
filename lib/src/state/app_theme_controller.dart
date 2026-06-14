import 'package:flutter/material.dart';

import '../services/local_storage_service.dart';

class AppThemeController extends ChangeNotifier {
  AppThemeController(this._storage);

  final LocalStorageService _storage;

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    _themeMode = await _storage.getThemeMode();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _storage.saveThemeMode(mode);
  }
}
