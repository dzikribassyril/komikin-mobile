import 'manga_detail.dart';

class ReadingProgress {
  const ReadingProgress({
    required this.mangaSlug,
    required this.mangaTitle,
    required this.cover,
    required this.chapterId,
    required this.chapterTitle,
    required this.page,
    required this.totalPages,
    required this.updatedAt,
  });

  factory ReadingProgress.fromJson(Map<String, dynamic> json) {
    final totalPages = json['totalPages'] as int? ?? 0;
    final page = json['page'] as int? ?? 0;

    return ReadingProgress(
      mangaSlug: json['mangaSlug'] as String? ?? '',
      mangaTitle: json['mangaTitle'] as String? ?? '',
      cover: json['cover'] as String? ?? '',
      chapterId: json['chapterId'] as String? ?? '',
      chapterTitle: json['chapterTitle'] as String? ?? '',
      page: page.clamp(0, totalPages).toInt(),
      totalPages: totalPages,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory ReadingProgress.fromMangaDetail(MangaDetail manga) {
    final chapter = manga.chapters.isEmpty ? null : manga.chapters.first;

    return ReadingProgress(
      mangaSlug: manga.slug,
      mangaTitle: manga.title,
      cover: manga.cover,
      chapterId: chapter?.chapterId ?? '',
      chapterTitle: chapter?.title ?? '',
      page: 0,
      totalPages: 0,
      updatedAt: DateTime.now(),
    );
  }

  final String mangaSlug;
  final String mangaTitle;
  final String cover;
  final String chapterId;
  final String chapterTitle;
  final int page;
  final int totalPages;
  final DateTime updatedAt;

  bool get canResume => mangaSlug.isNotEmpty && chapterId.isNotEmpty;

  double get fraction {
    if (totalPages <= 0) return 0;
    return (page / totalPages).clamp(0, 1);
  }

  String get pageLabel {
    if (totalPages <= 0) return 'Belum dibaca';
    return 'Page ${page.clamp(1, totalPages).toInt()} / $totalPages';
  }

  Map<String, dynamic> toJson() {
    return {
      'mangaSlug': mangaSlug,
      'mangaTitle': mangaTitle,
      'cover': cover,
      'chapterId': chapterId,
      'chapterTitle': chapterTitle,
      'page': page,
      'totalPages': totalPages,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ReadingProgress copyWith({
    String? mangaSlug,
    String? mangaTitle,
    String? cover,
    String? chapterId,
    String? chapterTitle,
    int? page,
    int? totalPages,
    DateTime? updatedAt,
  }) {
    return ReadingProgress(
      mangaSlug: mangaSlug ?? this.mangaSlug,
      mangaTitle: mangaTitle ?? this.mangaTitle,
      cover: cover ?? this.cover,
      chapterId: chapterId ?? this.chapterId,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
