import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/result_state.dart';
import '../models/chapter_link.dart';
import '../models/manga_detail.dart';
import '../services/manga_repository.dart';
import '../state/bookmark_controller.dart';
import '../state/read_history_controller.dart';
import '../state/reading_progress_controller.dart';
import '../widgets/app_error.dart';

class MangaDetailScreen extends StatefulWidget {
  const MangaDetailScreen({
    super.key,
    required this.slug,
  });

  final String slug;

  @override
  State<MangaDetailScreen> createState() => _MangaDetailScreenState();
}

class _MangaDetailScreenState extends State<MangaDetailScreen> {
  ResultState<MangaDetail> _state = const ResultState.loading();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() => _state = ResultState.loading(_state.data));

    try {
      final repository = context.read<MangaRepository>();
      final readHistory = context.read<ReadHistoryController>();
      final readingProgress = context.read<ReadingProgressController>();
      final manga = await repository.fetchMangaDetail(
        widget.slug,
        refresh: refresh,
      );
      await readHistory.loadManga(manga.slug);
      await readingProgress.primeFromDetail(manga);
      if (!mounted) return;
      setState(() => _state = ResultState.success(manga));
    } catch (error) {
      if (!mounted) return;
      setState(() => _state = ResultState.failure(error.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final manga = _state.data;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Komik'),
        actions: [
          if (manga != null)
            Consumer<BookmarkController>(
              builder: (context, bookmarks, _) {
                final bookmarked = bookmarks.isBookmarked(manga.slug);
                return IconButton(
                  onPressed: () => bookmarks.toggleBookmark(
                    manga.slug,
                    detail: manga,
                  ),
                  icon: Icon(
                    bookmarked ? Icons.bookmark : Icons.bookmark_border,
                  ),
                  tooltip: bookmarked ? 'Hapus bookmark' : 'Simpan bookmark',
                );
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final manga = _state.data;

    if (_state.isLoading && manga == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_state.error != null && manga == null) {
      return AppError(message: _state.error!, onRetry: () => _load());
    }

    if (manga == null) {
      return const AppError(message: 'Manga tidak ditemukan');
    }

    return RefreshIndicator(
      onRefresh: () => _load(refresh: true),
      child: CustomScrollView(
        slivers: [
          if (_state.isLoading)
            const SliverToBoxAdapter(child: LinearProgressIndicator()),
          SliverToBoxAdapter(child: _PageBand(child: _Header(manga: manga))),
          SliverToBoxAdapter(
            child: _PageBand(
              child: _ChapterShortcuts(manga: manga),
            ),
          ),
          SliverToBoxAdapter(child: _PageBand(child: _Synopsis(manga: manga))),
          SliverToBoxAdapter(child: _PageBand(child: _GenreList(manga: manga))),
          SliverToBoxAdapter(child: _PageBand(child: _InfoList(manga: manga))),
          _ChapterList(manga: manga),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

String _cleanText(String value) {
  return value.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _displayTitle(MangaDetail manga) {
  return _cleanText(manga.title)
      .replaceFirst(RegExp(r'^Komik\s+', caseSensitive: false), '')
      .trim();
}

String _infoValue(MangaDetail manga, String key) {
  return _cleanText(manga.info[key] ?? '');
}

String _synopsisText(MangaDetail manga) {
  final synopsis = _cleanText(manga.synopsis);
  final type = _infoValue(manga, 'Jenis Komik');
  if (type.isNotEmpty &&
      synopsis.toLowerCase().startsWith(type.toLowerCase())) {
    return synopsis.substring(type.length).trimLeft();
  }
  return synopsis;
}

String _chapterLabel(ChapterLink chapter) {
  final value = _cleanText(chapter.chapter);
  return value.isEmpty ? _cleanText(chapter.title) : 'Chapter $value';
}

class _PageBand extends StatelessWidget {
  const _PageBand({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: child,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.manga});

  final MangaDetail manga;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final title = _displayTitle(manga);
    final type = _infoValue(manga, 'Jenis Komik');
    final status = _infoValue(manga, 'Status');
    final author = _infoValue(manga, 'Pengarang');
    final altTitle = _cleanText(manga.alternativeTitle ?? '');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CoverImage(url: manga.cover),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? 'Tanpa judul' : title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.08,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (type.isNotEmpty)
                      _MetaPill(icon: Icons.style_outlined, label: type),
                    if (status.isNotEmpty)
                      _MetaPill(icon: Icons.flag_outlined, label: status),
                    _MetaPill(
                      icon: Icons.menu_book_outlined,
                      label: '${manga.chapters.length} chapter',
                    ),
                  ],
                ),
                if (author.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
                if (altTitle.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    altTitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.35,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 124,
          height: 178,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (context, url) => ColoredBox(
              color: colors.surfaceContainerHighest,
            ),
            errorWidget: (context, url, error) => ColoredBox(
              color: colors.surfaceContainerHighest,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: colors.primary),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
    );
  }
}

class _Synopsis extends StatelessWidget {
  const _Synopsis({required this.manga});

  final MangaDetail manga;

  @override
  Widget build(BuildContext context) {
    final synopsis = _synopsisText(manga);
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Synopsis'),
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                synopsis.isEmpty ? 'Tidak ada synopsis.' : synopsis,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: colors.onSurface,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenreList extends StatelessWidget {
  const _GenreList({required this.manga});

  final MangaDetail manga;

  @override
  Widget build(BuildContext context) {
    if (manga.genres.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Genres'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final genre in manga.genres)
                Chip(
                  label: Text(genre),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoList extends StatelessWidget {
  const _InfoList({required this.manga});

  final MangaDetail manga;

  @override
  Widget build(BuildContext context) {
    final entries = manga.info.entries
        .where(
          (entry) => !{'Judul Alternatif', 'Informasi'}.contains(entry.key),
        )
        .map((entry) => MapEntry(entry.key, _cleanText(entry.value)))
        .where((entry) => entry.value.isNotEmpty)
        .toList();

    if (entries.isEmpty) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Information'),
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Column(
                children: [
                  for (var index = 0; index < entries.length; index++) ...[
                    _InfoRow(entry: entries[index]),
                    if (index != entries.length - 1)
                      Divider(height: 1, color: colors.outlineVariant),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.entry});

  final MapEntry<String, String> entry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              entry.key,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              entry.value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterShortcuts extends StatelessWidget {
  const _ChapterShortcuts({required this.manga});

  final MangaDetail manga;

  @override
  Widget build(BuildContext context) {
    if (manga.chapters.isEmpty) return const SizedBox.shrink();

    final latest = manga.chapters.first;
    final first = manga.chapters.last;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Consumer<ReadingProgressController>(
        builder: (context, progressController, _) {
          final progress = progressController.progressFor(manga.slug);
          final resumeChapter = progress?.canResume == true
              ? progress!.chapterId
              : latest.chapterId;
          final primaryLabel =
              progress?.canResume == true ? 'Continue reading' : 'Read now';

          return Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _openChapterId(context, resumeChapter),
                  icon: Icon(
                    progress?.canResume == true
                        ? Icons.play_arrow
                        : Icons.auto_stories,
                  ),
                  label: Text(primaryLabel),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: () => _openChapter(context, first),
                icon: const Icon(Icons.first_page),
                tooltip: 'First chapter',
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openChapterId(BuildContext context, String chapterId) async {
    await context
        .read<ReadHistoryController>()
        .markAsRead(manga.slug, chapterId);
    if (context.mounted) {
      context.push('/read/$chapterId');
    }
  }

  Future<void> _openChapter(BuildContext context, ChapterLink chapter) async {
    await context
        .read<ReadHistoryController>()
        .markAsRead(manga.slug, chapter.chapterId);
    if (context.mounted) {
      context.push('/read/${chapter.chapterId}');
    }
  }
}

class _ChapterList extends StatelessWidget {
  const _ChapterList({required this.manga});

  final MangaDetail manga;

  @override
  Widget build(BuildContext context) {
    if (manga.chapters.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Belum ada chapter.'),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: _PageBand(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(child: _SectionTitle('Chapters')),
                  Text(
                    '${manga.chapters.length}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  children: [
                    for (var index = 0; index < manga.chapters.length; index++)
                      _ChapterTile(
                        manga: manga,
                        chapter: manga.chapters[index],
                        showDivider: index != manga.chapters.length - 1,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({
    required this.manga,
    required this.chapter,
    required this.showDivider,
  });

  final MangaDetail manga;
  final ChapterLink chapter;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Consumer<ReadHistoryController>(
      builder: (context, history, _) {
        final read = history.isChapterRead(manga.slug, chapter.chapterId);

        return InkWell(
          onTap: () async {
            await history.markAsRead(manga.slug, chapter.chapterId);
            if (context.mounted) {
              context.push('/read/${chapter.chapterId}');
            }
          },
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      read ? Icons.check_circle : Icons.menu_book_outlined,
                      color: read ? colors.primary : colors.onSurfaceVariant,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _chapterLabel(chapter),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (chapter.date != null &&
                              chapter.date!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              chapter.date!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              if (showDivider)
                Divider(
                  height: 1,
                  indent: 48,
                  color: colors.outlineVariant,
                ),
            ],
          ),
        );
      },
    );
  }
}
