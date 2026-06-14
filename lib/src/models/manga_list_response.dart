import 'manga_info.dart';
import 'page_info.dart';

class MangaListResponse {
  const MangaListResponse({
    required this.mangaList,
    required this.pageInfo,
  });

  factory MangaListResponse.fromJson(Map<String, dynamic> json) {
    return MangaListResponse(
      mangaList: (json['manga_list'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => MangaInfo.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      pageInfo: PageInfo.fromJson(
        Map<String, dynamic>.from(json['page_info'] as Map? ?? const {}),
      ),
    );
  }

  final List<MangaInfo> mangaList;
  final PageInfo pageInfo;
}
