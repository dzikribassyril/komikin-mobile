import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/reader_settings.dart';

class LocalStorageService {
  static const _bookmarkKey = 'bookmarks';
  static const _readerSettingsKey = 'manga-reader-settings';
  static const _themeModeKey = 'theme-mode';

  Future<List<String>> getBookmarkSlugs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_bookmarkKey) ?? const [];
  }

  Future<void> saveBookmarkSlugs(List<String> slugs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_bookmarkKey, slugs);
  }

  Future<ReaderSettings> getReaderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_readerSettingsKey);
    if (raw == null) return const ReaderSettings();

    try {
      return ReaderSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const ReaderSettings();
    }
  }

  Future<void> saveReaderSettings(ReaderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_readerSettingsKey, jsonEncode(settings.toJson()));
  }

  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeModeKey);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<List<String>> getReadChapters(String mangaSlug) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_readKey(mangaSlug)) ?? const [];
  }

  Future<void> markChapterRead(String mangaSlug, String chapterId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _readKey(mangaSlug);
    final chapters = prefs.getStringList(key) ?? <String>[];
    if (!chapters.contains(chapterId)) {
      chapters.add(chapterId);
      await prefs.setStringList(key, chapters);
    }
  }

  String _readKey(String mangaSlug) => 'read_$mangaSlug';
}
