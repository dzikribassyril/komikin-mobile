import 'package:flutter/foundation.dart';

import '../models/chapter_detail.dart';
import '../models/manga_detail.dart';
import '../models/reading_progress.dart';
import '../services/local_storage_service.dart';

class ReadingProgressController extends ChangeNotifier {
  ReadingProgressController(this._storage);

  final LocalStorageService _storage;
  final List<ReadingProgress> _items = [];

  List<ReadingProgress> get items => List.unmodifiable(_items);

  ReadingProgress? progressFor(String mangaSlug) {
    for (final item in _items) {
      if (item.mangaSlug == mangaSlug) return item;
    }
    return null;
  }

  Future<void> load() async {
    _items
      ..clear()
      ..addAll(await _storage.getReadingProgress());
    _sort();
    notifyListeners();
  }

  Future<void> primeFromDetail(MangaDetail manga) async {
    if (manga.chapters.isEmpty || progressFor(manga.slug) != null) return;
    _upsert(ReadingProgress.fromMangaDetail(manga));
    await _persist();
  }

  Future<void> updateFromChapter(
    ChapterDetail chapter, {
    required int pageIndex,
    MangaDetail? detail,
  }) async {
    final existing = progressFor(chapter.mangaSlug);
    final safeTotal =
        chapter.totalPages <= 0 ? chapter.pages.length : chapter.totalPages;
    final page =
        safeTotal <= 0 ? 0 : (pageIndex + 1).clamp(1, safeTotal).toInt();

    _upsert(
      ReadingProgress(
        mangaSlug: chapter.mangaSlug,
        mangaTitle: detail?.title ?? existing?.mangaTitle ?? chapter.title,
        cover: detail?.cover ?? existing?.cover ?? '',
        chapterId: chapter.chapterId,
        chapterTitle: chapter.title,
        page: page,
        totalPages: safeTotal,
        updatedAt: DateTime.now(),
      ),
    );
    await _persist();
  }

  Future<void> remove(String mangaSlug) async {
    _items.removeWhere((item) => item.mangaSlug == mangaSlug);
    await _persist();
  }

  Future<void> clear() async {
    _items.clear();
    notifyListeners();
    await _persist();
  }

  void _upsert(ReadingProgress progress) {
    _items.removeWhere((item) => item.mangaSlug == progress.mangaSlug);
    _items.insert(0, progress);
    _sort();
    notifyListeners();
  }

  void _sort() {
    _items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> _persist() async {
    if (_items.length > 30) {
      _items.removeRange(30, _items.length);
    }
    await _storage.saveReadingProgress(_items);
  }
}
