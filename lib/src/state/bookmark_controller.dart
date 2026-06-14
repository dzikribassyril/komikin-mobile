import 'package:flutter/foundation.dart';

import '../models/manga_detail.dart';
import '../services/local_storage_service.dart';
import '../services/manga_repository.dart';

class BookmarkController extends ChangeNotifier {
  BookmarkController(this._storage, this._repository);

  final LocalStorageService _storage;
  final MangaRepository _repository;

  final List<String> _slugs = [];
  final List<MangaDetail> _bookmarkedManga = [];

  bool _isLoadingDetails = false;
  String? _error;

  List<String> get slugs => List.unmodifiable(_slugs);

  List<MangaDetail> get bookmarkedManga => List.unmodifiable(_bookmarkedManga);

  bool get isLoadingDetails => _isLoadingDetails;

  String? get error => _error;

  Future<void> load() async {
    _slugs
      ..clear()
      ..addAll(await _storage.getBookmarkSlugs());
  }

  bool isBookmarked(String slug) => _slugs.contains(slug);

  Future<void> toggleBookmark(String slug, {MangaDetail? detail}) async {
    if (isBookmarked(slug)) {
      await removeBookmark(slug);
      return;
    }

    _slugs.add(slug);
    if (detail != null) {
      _bookmarkedManga.removeWhere((manga) => manga.slug == slug);
      _bookmarkedManga.insert(0, detail);
    }
    notifyListeners();
    await _storage.saveBookmarkSlugs(_slugs);
  }

  Future<void> removeBookmark(String slug) async {
    _slugs.remove(slug);
    _bookmarkedManga.removeWhere((manga) => manga.slug == slug);
    notifyListeners();
    await _storage.saveBookmarkSlugs(_slugs);
  }

  Future<void> loadDetails({bool refresh = false}) async {
    if (_isLoadingDetails) return;
    if (!refresh && _bookmarkedManga.length == _slugs.length) return;

    _isLoadingDetails = true;
    _error = null;
    notifyListeners();

    try {
      final details = await Future.wait(
        _slugs.map((slug) => _repository.fetchMangaDetail(slug)),
      );
      _bookmarkedManga
        ..clear()
        ..addAll(details.where((manga) => manga.slug.isNotEmpty));
    } catch (error) {
      _error = 'Gagal memuat bookmark';
    } finally {
      _isLoadingDetails = false;
      notifyListeners();
    }
  }
}
