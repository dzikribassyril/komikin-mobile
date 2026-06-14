class ChapterLink {
  const ChapterLink({
    required this.title,
    required this.url,
    required this.chapter,
    required this.chapterId,
    this.date,
  });

  factory ChapterLink.fromJson(Map<String, dynamic> json) {
    return ChapterLink(
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      chapter: json['chapter'] as String? ?? '',
      chapterId: json['chapterId'] as String? ?? '',
      date: json['date'] as String?,
    );
  }

  final String title;
  final String url;
  final String chapter;
  final String chapterId;
  final String? date;
}
