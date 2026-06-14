import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/result_state.dart';
import '../models/chapter_detail.dart';
import '../models/reader_settings.dart';
import '../services/manga_repository.dart';
import '../state/read_history_controller.dart';
import '../state/reader_settings_controller.dart';
import '../widgets/app_error.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    super.key,
    required this.chapterId,
  });

  final String chapterId;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final _pageController = PageController();

  ResultState<ChapterDetail> _state = const ResultState.loading();
  bool _showControls = true;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chapterId != widget.chapterId) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      _load();
    }
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() => _state = ResultState.loading(_state.data));

    try {
      final chapter = await context.read<MangaRepository>().fetchChapter(
            widget.chapterId,
            refresh: refresh,
          );
      await context
          .read<ReadHistoryController>()
          .markAsRead(chapter.mangaSlug, chapter.chapterId);
      if (!mounted) return;
      setState(() {
        _currentPage = 0;
        _state = ResultState.success(chapter);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _state = ResultState.failure(error.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final chapter = _state.data;

    if (_state.isLoading && chapter == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_state.error != null && chapter == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reader')),
        body: AppError(message: _state.error!, onRetry: () => _load()),
      );
    }

    if (chapter == null) {
      return const Scaffold(
        body: AppError(message: 'Chapter tidak ditemukan'),
      );
    }

    final settings = context.watch<ReaderSettingsController>().settings;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _showControls
          ? AppBar(
              backgroundColor: Colors.black.withOpacity(0.92),
              foregroundColor: Colors.white,
              title: Text(
                chapter.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                IconButton(
                  onPressed: () => _load(refresh: true),
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
                IconButton(
                  onPressed: () => _showReaderSettings(context),
                  icon: const Icon(Icons.tune),
                  tooltip: 'Reader settings',
                ),
              ],
            )
          : null,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _showControls = !_showControls),
        child: settings.readingMode == ReadingMode.vertical
            ? _VerticalReader(
                chapter: chapter,
                pageWidth: settings.pageWidth,
              )
            : _HorizontalReader(
                chapter: chapter,
                pageWidth: settings.pageWidth,
                pageController: _pageController,
                currentPage: _currentPage,
                onPageChanged: (page) => setState(() => _currentPage = page),
              ),
      ),
      bottomNavigationBar: _showControls
          ? _ReaderBottomBar(
              chapter: chapter,
              currentPage: _currentPage,
              readingMode: settings.readingMode,
            )
          : null,
    );
  }

  Future<void> _showReaderSettings(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Consumer<ReaderSettingsController>(
          builder: (context, controller, _) {
            final settings = controller.settings;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reader',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<ReadingMode>(
                      segments: const [
                        ButtonSegment(
                          value: ReadingMode.vertical,
                          icon: Icon(Icons.vertical_align_bottom),
                          label: Text('Vertical'),
                        ),
                        ButtonSegment(
                          value: ReadingMode.horizontal,
                          icon: Icon(Icons.view_carousel),
                          label: Text('Horizontal'),
                        ),
                      ],
                      selected: {settings.readingMode},
                      onSelectionChanged: (value) {
                        controller.setReadingMode(value.first);
                      },
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<PageWidth>(
                      segments: const [
                        ButtonSegment(
                          value: PageWidth.fit,
                          icon: Icon(Icons.fit_screen),
                          label: Text('Fit'),
                        ),
                        ButtonSegment(
                          value: PageWidth.full,
                          icon: Icon(Icons.fullscreen),
                          label: Text('Full'),
                        ),
                      ],
                      selected: {settings.pageWidth},
                      onSelectionChanged: (value) {
                        controller.setPageWidth(value.first);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _VerticalReader extends StatelessWidget {
  const _VerticalReader({
    required this.chapter,
    required this.pageWidth,
  });

  final ChapterDetail chapter;
  final PageWidth pageWidth;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: chapter.pages.length,
      itemBuilder: (context, index) {
        return _ReaderImage(
          imageUrl: chapter.pages[index],
          pageNumber: index + 1,
          pageWidth: pageWidth,
        );
      },
    );
  }
}

class _HorizontalReader extends StatelessWidget {
  const _HorizontalReader({
    required this.chapter,
    required this.pageWidth,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
  });

  final ChapterDetail chapter;
  final PageWidth pageWidth;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: pageController,
          itemCount: chapter.pages.length,
          onPageChanged: onPageChanged,
          itemBuilder: (context, index) {
            return Center(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 3,
                child: _ReaderImage(
                  imageUrl: chapter.pages[index],
                  pageNumber: index + 1,
                  pageWidth: pageWidth,
                ),
              ),
            );
          },
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withOpacity(0.18),
                    Colors.transparent,
                    Colors.black.withOpacity(0.18),
                  ],
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: _PageArrow(
            icon: Icons.chevron_left,
            isVisible: currentPage > 0,
            onPressed: () => pageController.previousPage(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: _PageArrow(
            icon: Icons.chevron_right,
            isVisible: currentPage < chapter.pages.length - 1,
            onPressed: () => pageController.nextPage(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReaderImage extends StatelessWidget {
  const _ReaderImage({
    required this.imageUrl,
    required this.pageNumber,
    required this.pageWidth,
  });

  final String imageUrl;
  final int pageNumber;
  final PageWidth pageWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final imageWidth = pageWidth == PageWidth.fit
              ? viewportWidth.clamp(0, 720).toDouble()
              : viewportWidth;

          return SizedBox(
            width: imageWidth,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.fitWidth,
              placeholder: (context, url) => AspectRatio(
                aspectRatio: 0.72,
                child: ColoredBox(
                  color: const Color(0xFF1F1F1F),
                  child: Center(
                    child: Text(
                      'Page $pageNumber',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => AspectRatio(
                aspectRatio: 0.72,
                child: ColoredBox(
                  color: const Color(0xFF1F1F1F),
                  child: Center(
                    child: Text(
                      'Gagal memuat page $pageNumber',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PageArrow extends StatelessWidget {
  const _PageArrow({
    required this.icon,
    required this.isVisible,
    required this.onPressed,
  });

  final IconData icon;
  final bool isVisible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isVisible ? 1 : 0,
      duration: const Duration(milliseconds: 150),
      child: IgnorePointer(
        ignoring: !isVisible,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withOpacity(0.56),
              foregroundColor: Colors.white,
            ),
            onPressed: onPressed,
            icon: Icon(icon),
          ),
        ),
      ),
    );
  }
}

class _ReaderBottomBar extends StatelessWidget {
  const _ReaderBottomBar({
    required this.chapter,
    required this.currentPage,
    required this.readingMode,
  });

  final ChapterDetail chapter;
  final int currentPage;
  final ReadingMode readingMode;

  @override
  Widget build(BuildContext context) {
    final pageText = readingMode == ReadingMode.horizontal
        ? '${currentPage + 1} / ${chapter.totalPages}'
        : '${chapter.totalPages} pages';

    return SafeArea(
      top: false,
      child: ColoredBox(
        color: Colors.black.withOpacity(0.92),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Row(
            children: [
              IconButton(
                onPressed: chapter.prevChapter == null
                    ? null
                    : () => context.pushReplacement(
                          '/read/${chapter.prevChapter}',
                        ),
                color: Colors.white,
                disabledColor: Colors.white30,
                icon: const Icon(Icons.skip_previous),
                tooltip: 'Chapter sebelumnya',
              ),
              Expanded(
                child: Text(
                  pageText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: chapter.nextChapter == null
                    ? null
                    : () => context.pushReplacement(
                          '/read/${chapter.nextChapter}',
                        ),
                color: Colors.white,
                disabledColor: Colors.white30,
                icon: const Icon(Icons.skip_next),
                tooltip: 'Chapter berikutnya',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
