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
      final manga = await context.read<MangaRepository>().fetchMangaDetail(
            widget.slug,
            refresh: refresh,
          );
      await context.read<ReadHistoryController>().loadManga(manga.slug);
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
        title: Text(manga?.title ?? 'Detail Manga'),
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
          SliverToBoxAdapter(child: _Header(manga: manga)),
          SliverToBoxAdapter(child: _Synopsis(manga: manga)),
          SliverToBoxAdapter(child: _GenreList(manga: manga)),
          SliverToBoxAdapter(child: _InfoList(manga: manga)),
          SliverToBoxAdapter(child: _ChapterShortcuts(manga: manga)),
          _ChapterList(manga: manga),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 132,
              height: 188,
              child: CachedNetworkImage(
                imageUrl: manga.cover,
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  manga.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                if (manga.alternativeTitle != null &&
                    manga.alternativeTitle!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    manga.alternativeTitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  '${manga.chapters.length} chapter',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.primary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Synopsis extends StatelessWidget {
  const _Synopsis({required this.manga});

  final MangaDetail manga;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Synopsis', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            manga.synopsis.isEmpty ? 'Tidak ada synopsis.' : manga.synopsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.45,
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
          Text('Genres', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final genre in manga.genres)
                Chip(
                  label: Text(genre),
                  visualDensity: VisualDensity.compact,
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
            (entry) => !{'Judul Alternatif', 'Informasi'}.contains(entry.key))
        .toList();

    if (entries.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Information', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              children: [
                for (final entry in entries)
                  ListTile(
                    dense: true,
                    title: Text(entry.key),
                    subtitle: Text(entry.value),
                  ),
              ],
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: () => _openChapter(context, first),
              icon: const Icon(Icons.skip_previous),
              label: const Text('First'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _openChapter(context, latest),
              icon: const Icon(Icons.skip_next),
              label: const Text('Latest'),
            ),
          ),
        ],
      ),
    );
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

    return SliverList.builder(
      itemCount: manga.chapters.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Chapters',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          );
        }

        final chapter = manga.chapters[index - 1];
        return Consumer<ReadHistoryController>(
          builder: (context, history, _) {
            final read = history.isChapterRead(manga.slug, chapter.chapterId);

            return ListTile(
              leading: Icon(
                read ? Icons.check_circle : Icons.menu_book_outlined,
                color: read ? Theme.of(context).colorScheme.primary : null,
              ),
              title: Text('Chapter ${chapter.chapter}'),
              subtitle: chapter.date == null || chapter.date!.isEmpty
                  ? null
                  : Text(chapter.date!),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await history.markAsRead(manga.slug, chapter.chapterId);
                if (context.mounted) {
                  context.push('/read/${chapter.chapterId}');
                }
              },
            );
          },
        );
      },
    );
  }
}
