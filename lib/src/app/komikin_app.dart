import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../state/app_theme_controller.dart';
import 'router.dart';

class KomikinApp extends StatelessWidget {
  const KomikinApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<AppThemeController>().themeMode;

    return MaterialApp.router(
      title: 'Komikin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
