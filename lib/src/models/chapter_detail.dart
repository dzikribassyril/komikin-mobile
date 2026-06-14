class ChapterDetail {
  const ChapterDetail({
    required this.title,
    required this.mangaSlug,
    required this.chapterId,
    required this.chapterNumber,
    required this.pages,
    this.prevChapter,
    this.nextChapter,
    required this.totalPages,
  });

  factory ChapterDetail.fromJson(Map<String, dynamic> json) {
    final pages = (json['pages'] as List? ?? const [])
        .map((page) => page.toString())
        .where((page) => page.isNotEmpty)
        .toList();

    return ChapterDetail(
      title: json['title'] as String? ?? '',
      mangaSlug: json['mangaSlug'] as String? ?? '',
      chapterId: json['chapterId'] as String? ?? '',
      chapterNumber: json['chapterNumber'] as String? ?? '',
      pages: pages,
      prevChapter: json['prevChapter'] as String?,
      nextChapter: json['nextChapter'] as String?,
      totalPages: json['totalPages'] as int? ?? pages.length,
    );
  }

  final String title;
  final String mangaSlug;
  final String chapterId;
  final String chapterNumber;
  final List<String> pages;
  final String? prevChapter;
  final String? nextChapter;
  final int totalPages;
}
