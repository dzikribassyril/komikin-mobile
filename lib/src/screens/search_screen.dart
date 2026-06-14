import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/result_state.dart';
import '../models/manga_list_response.dart';
import '../services/manga_repository.dart';
import '../widgets/app_error.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_grid.dart';
import '../widgets/manga_grid.dart';
import '../widgets/paging_bar.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  Timer? _debounce;
  String _query = '';
  int _page = 1;
  ResultState<MangaListResponse> _state = const ResultState.idle();

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      final nextQuery = value.trim();
      if (nextQuery == _query) return;
      setState(() {
        _query = nextQuery;
        _page = 1;
      });
      if (_query.isEmpty) {
        setState(() => _state = const ResultState.idle());
      } else {
        _search();
      }
    });
  }

  Future<void> _search({bool refresh = false}) async {
    if (_query.isEmpty) return;
    setState(() => _state = ResultState.loading(_state.data));

    try {
      final data = await context.read<MangaRepository>().searchManga(
            query: _query,
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

  void _changePage(int page) {
    setState(() => _page = page);
    _search();
  }

  @override
  Widget build(BuildContext context) {
    final data = _state.data;

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onChanged: _onQueryChanged,
              onSubmitted: (value) {
                _debounce?.cancel();
                setState(() {
                  _query = value.trim();
                  _page = 1;
                });
                _search(refresh: true);
              },
              decoration: InputDecoration(
                hintText: 'Cari manga, manhwa, manhua...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _controller.clear();
                          _onQueryChanged('');
                        },
                        icon: const Icon(Icons.close),
                        tooltip: 'Bersihkan',
                      ),
              ),
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

    if (_query.isEmpty) {
      return const EmptyState(
        icon: Icons.search,
        title: 'Cari komik favoritmu',
        message: 'Ketik judul manga untuk melihat hasil pencarian.',
      );
    }

    if (_state.isLoading && data == null) {
      return const LoadingGrid();
    }

    if (_state.error != null && data == null) {
      return AppError(message: _state.error!, onRetry: () => _search());
    }

    if (data == null || data.mangaList.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off,
        title: 'Tidak ditemukan',
        message: 'Coba kata kunci yang lebih pendek atau berbeda.',
      );
    }

    return Stack(
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
    );
  }
}
