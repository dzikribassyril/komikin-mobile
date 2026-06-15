import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/result_state.dart';
import '../models/manga_list_response.dart';
import '../models/manga_type.dart';
import '../models/reading_progress.dart';
import '../services/manga_repository.dart';
import '../state/reading_progress_controller.dart';
import '../widgets/app_error.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_grid.dart';
import '../widgets/manga_card.dart';
import '../widgets/paging_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MangaType _type = MangaType.popular;
  int _page = 1;
  ResultState<MangaListResponse> _state = const ResultState.loading();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() => _state = ResultState.loading(_state.data));

    try {
      final data = await context.read<MangaRepository>().fetchMangaList(
            type: _type,
            page: _page,
            refresh: refresh,
          );
      if (!mounted) return;
      setState(() => _state = ResultState.success(data));
    } catch (error) {
      if (!mounted) return;
      setState(() => _state = ResultState.failure(error.toString()));
    }
  }

  void _changeType(MangaType type) {
    if (_type == type) return;
    setState(() {
      _type = type;
      _page = 1;
    });
    _load();
  }

  void _changePage(int page) {
    setState(() => _page = page);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final data = _state.data;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/komikin_logo.png',
                width: 34,
                height: 34,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Text('KomikIN'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _state.isLoading ? null : () => _load(refresh: true),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final type = MangaType.values[index];
                return ChoiceChip(
                  selected: _type == type,
                  label: Text(type.label),
                  onSelected: (_) => _changeType(type),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemCount: MangaType.values.length,
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
      bottomNavigationBar: data == null
          ? null
          : PagingBar(
              pageInfo: data.pageInfo,
              isLoading: _state.isLoading,
              onPageChanged: _changePage,
            ),
    );
  }

  Widget _buildContent() {
    final data = _state.data;

    if (_state.isLoading && data == null) {
      return const LoadingGrid();
    }

    if (_state.error != null && data == null) {
      return AppError(message: _state.error!, onRetry: () => _load());
    }

    if (data == null || data.mangaList.isEmpty) {
      return EmptyState(
        icon: Icons.menu_book_outlined,
        title: 'Belum ada manga',
        message: 'Coba kategori lain atau refresh halaman ini.',
        action: FilledButton.icon(
          onPressed: () => _load(refresh: true),
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(refresh: true),
      child: Stack(
        children: [
          CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const _ContinueReadingSection(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _type.label,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                      Text(
                        'Page $_page',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                sliver: SliverGrid.builder(
                  itemCount: data.mangaList.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        _columnsForWidth(MediaQuery.sizeOf(context).width),
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.56,
                  ),
                  itemBuilder: (context, index) {
                    return MangaCard(manga: data.mangaList[index]);
                  },
                ),
              ),
            ],
          ),
          if (_state.isLoading)
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

class _ContinueReadingSection extends StatelessWidget {
  const _ContinueReadingSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<ReadingProgressController>(
      builder: (context, progress, _) {
        final items = progress.items.take(10).toList();
        if (items.isEmpty) return const SliverToBoxAdapter();

        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Continue Reading',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                      Text(
                        '${items.length}',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 154,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      return _ContinueReadingCard(progress: items[index]);
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 10),
                    itemCount: items.length,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({required this.progress});

  final ReadingProgress progress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: 252,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push('/read/${progress.chapterId}'),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 76,
                    height: 112,
                    child: CachedNetworkImage(
                      imageUrl: progress.cover,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => ColoredBox(
                        color: colors.surfaceContainerHighest,
                      ),
                      errorWidget: (context, url, error) => ColoredBox(
                        color: colors.surfaceContainerHighest,
                        child: const Icon(Icons.menu_book_outlined),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        progress.mangaTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        progress.chapterTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                      const Spacer(),
                      LinearProgressIndicator(
                        value:
                            progress.fraction == 0 ? null : progress.fraction,
                        minHeight: 5,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        progress.pageLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

int _columnsForWidth(double width) {
  if (width >= 900) return 6;
  if (width >= 620) return 4;
  return 3;
}
