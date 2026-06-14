import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/result_state.dart';
import '../models/manga_list_response.dart';
import '../models/manga_type.dart';
import '../services/manga_repository.dart';
import '../widgets/app_error.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_grid.dart';
import '../widgets/manga_grid.dart';
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
        title: const Text('Komikin'),
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
          MangaGrid(items: data.mangaList),
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
