import '../models/chapter_detail.dart';
import '../models/manga_detail.dart';
import '../models/manga_list_response.dart';
import '../models/manga_type.dart';
import 'api_client.dart';

class MangaRepository {
  MangaRepository(this._apiClient);

  final ApiClient _apiClient;

  final Map<String, MangaListResponse> _listCache = {};
  final Map<String, MangaDetail> _detailCache = {};
  final Map<String, ChapterDetail> _chapterCache = {};

  void clearCache() {
    _listCache.clear();
    _detailCache.clear();
    _chapterCache.clear();
  }

  Future<MangaListResponse> fetchMangaList({
    required MangaType type,
    required int page,
    bool refresh = false,
  }) async {
    final key = 'list:${type.path}:$page';
    if (!refresh && _listCache.containsKey(key)) {
      return _listCache[key]!;
    }

    final json = await _apiClient.getJson('/api/manga/${type.path}/$page');
    final response = MangaListResponse.fromJson(json);
    _listCache[key] = response;
    return response;
  }

  Future<MangaListResponse> searchManga({
    required String query,
    required int page,
    bool refresh = false,
  }) async {
    final encoded = Uri.encodeComponent(query.trim());
    final key = 'search:$encoded:$page';
    if (!refresh && _listCache.containsKey(key)) {
      return _listCache[key]!;
    }

    final json = await _apiClient.getJson('/api/manga/search/$encoded/$page');
    final response = MangaListResponse.fromJson(json);
    _listCache[key] = response;
    return response;
  }

  Future<MangaDetail> fetchMangaDetail(
    String slug, {
    bool refresh = false,
  }) async {
    final key = 'detail:$slug';
    if (!refresh && _detailCache.containsKey(key)) {
      return _detailCache[key]!;
    }

    final json = await _apiClient.getJson('/api/manga/detail/$slug');
    final detail = MangaDetail.fromJson(json);
    _detailCache[key] = detail;
    return detail;
  }

  Future<ChapterDetail> fetchChapter(
    String chapterId, {
    bool refresh = false,
  }) async {
    final key = 'chapter:$chapterId';
    if (!refresh && _chapterCache.containsKey(key)) {
      return _chapterCache[key]!;
    }

    final json = await _apiClient.getJson('/api/manga/read/$chapterId');
    final chapter = ChapterDetail.fromJson(json);
    _chapterCache[key] = chapter;
    return chapter;
  }
}
