class MangaInfo {
  const MangaInfo({
    required this.title,
    required this.url,
    required this.cover,
    required this.slug,
    this.latestChapter,
    this.rating,
    this.color = false,
    required this.mangaType,
  });

  factory MangaInfo.fromJson(Map<String, dynamic> json) {
    return MangaInfo(
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      cover: json['cover'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      latestChapter: json['latestChapter'] as String?,
      rating: json['rating'] as String?,
      color: json['color'] as bool? ?? false,
      mangaType: json['mangaType'] as String? ?? 'Unknown',
    );
  }

  final String title;
  final String url;
  final String cover;
  final String slug;
  final String? latestChapter;
  final String? rating;
  final bool color;
  final String mangaType;
}
