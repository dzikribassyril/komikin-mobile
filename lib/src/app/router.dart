import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/bookmarks_screen.dart';
import '../screens/home_screen.dart';
import '../screens/manga_detail_screen.dart';
import '../screens/reader_screen.dart';
import '../screens/search_screen.dart';
import '../screens/settings_screen.dart';
import 'shell.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: HomeScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: SearchScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/bookmarks',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: BookmarksScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: SettingsScreen(),
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/manga/:slug',
      builder: (context, state) {
        return MangaDetailScreen(slug: state.pathParameters['slug'] ?? '');
      },
    ),
    GoRoute(
      path: '/read/:chapterId',
      builder: (context, state) {
        return ReaderScreen(chapterId: state.pathParameters['chapterId'] ?? '');
      },
    ),
  ],
  errorBuilder: (context, state) {
    return Scaffold(
      appBar: AppBar(title: const Text('Halaman tidak ditemukan')),
      body: Center(
        child: Text(state.error?.toString() ?? 'Route tidak valid'),
      ),
    );
  },
);
