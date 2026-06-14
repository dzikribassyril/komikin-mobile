import 'package:flutter/foundation.dart';

import '../services/local_storage_service.dart';

class ReadHistoryController extends ChangeNotifier {
  ReadHistoryController(this._storage);

  final LocalStorageService _storage;

  final Map<String, Set<String>> _readByManga = {};

  bool isChapterRead(String mangaSlug, String chapterId) {
    return _readByManga[mangaSlug]?.contains(chapterId) ?? false;
  }

  Future<void> loadManga(String mangaSlug) async {
    if (mangaSlug.isEmpty || _readByManga.containsKey(mangaSlug)) return;
    final chapters = await _storage.getReadChapters(mangaSlug);
    _readByManga[mangaSlug] = chapters.toSet();
    notifyListeners();
  }

  Future<void> markAsRead(String mangaSlug, String chapterId) async {
    if (mangaSlug.isEmpty || chapterId.isEmpty) return;
    final chapters = _readByManga.putIfAbsent(mangaSlug, () => <String>{});
    if (chapters.add(chapterId)) {
      notifyListeners();
      await _storage.markChapterRead(mangaSlug, chapterId);
    }
  }
}
