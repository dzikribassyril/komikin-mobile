import 'chapter_link.dart';

class MangaDetail {
  const MangaDetail({
    required this.title,
    required this.url,
    required this.cover,
    required this.slug,
    this.alternativeTitle,
    required this.synopsis,
    required this.info,
    required this.genres,
    required this.chapters,
  });

  factory MangaDetail.fromJson(Map<String, dynamic> json) {
    return MangaDetail(
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      cover: json['cover'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      alternativeTitle: json['alternativeTitle'] as String?,
      synopsis: json['synopsis'] as String? ?? '',
      info: Map<String, String>.from(json['info'] as Map? ?? const {}),
      genres: (json['genres'] as List? ?? const [])
          .map((genre) => genre.toString())
          .toList(),
      chapters: (json['chapters'] as List? ?? const [])
          .whereType<Map>()
          .map((chapter) => ChapterLink.fromJson(
                Map<String, dynamic>.from(chapter),
              ))
          .toList(),
    );
  }

  final String title;
  final String url;
  final String cover;
  final String slug;
  final String? alternativeTitle;
  final String synopsis;
  final Map<String, String> info;
  final List<String> genres;
  final List<ChapterLink> chapters;
}
