import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/manga_detail.dart';
import '../state/bookmark_controller.dart';
import '../widgets/app_error.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_grid.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookmarkController>().loadDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookmarkController>(
      builder: (context, bookmarks, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Bookmark'),
            actions: [
              IconButton(
                onPressed: bookmarks.slugs.isEmpty || bookmarks.isLoadingDetails
                    ? null
                    : () => bookmarks.loadDetails(refresh: true),
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: _buildBody(context, bookmarks),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, BookmarkController bookmarks) {
    if (bookmarks.slugs.isEmpty) {
      return EmptyState(
        icon: Icons.bookmark_border,
        title: 'Belum ada bookmark',
        message:
            'Simpan manga dari halaman detail untuk membacanya lagi nanti.',
        action: FilledButton.icon(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.explore),
          label: const Text('Explore'),
        ),
      );
    }

    if (bookmarks.isLoadingDetails && bookmarks.bookmarkedManga.isEmpty) {
      return const LoadingGrid();
    }

    if (bookmarks.error != null && bookmarks.bookmarkedManga.isEmpty) {
      return AppError(
        message: bookmarks.error!,
        onRetry: () => bookmarks.loadDetails(refresh: true),
      );
    }

    return RefreshIndicator(
      onRefresh: () => bookmarks.loadDetails(refresh: true),
      child: Stack(
        children: [
          GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookmarks.bookmarkedManga.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  _columnsForWidth(MediaQuery.sizeOf(context).width),
              mainAxisSpacing: 14,
              crossAxisSpacing: 12,
              childAspectRatio: 0.56,
            ),
            itemBuilder: (context, index) {
              final manga = bookmarks.bookmarkedManga[index];
              return _BookmarkCard(manga: manga);
            },
          ),
          if (bookmarks.isLoadingDetails)
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  const _BookmarkCard({required this.manga});

  final MangaDetail manga;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.push('/manga/${manga.slug}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
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
                  Positioned(
                    top: 6,
                    right: 6,
                    child: IconButton.filled(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _confirmRemove(context),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      tooltip: 'Hapus bookmark',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            manga.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus bookmark?'),
        content: Text(manga.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (shouldRemove == true && context.mounted) {
      await context.read<BookmarkController>().removeBookmark(manga.slug);
    }
  }
}

int _columnsForWidth(double width) {
  if (width >= 900) return 6;
  if (width >= 620) return 4;
  return 3;
}
