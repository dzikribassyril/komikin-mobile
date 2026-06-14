import 'package:flutter/material.dart';

import '../models/manga_info.dart';
import 'manga_card.dart';

class MangaGrid extends StatelessWidget {
  const MangaGrid({
    super.key,
    required this.items,
    this.padding = const EdgeInsets.all(16),
  });

  final List<MangaInfo> items;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _columnsForWidth(MediaQuery.sizeOf(context).width),
        mainAxisSpacing: 14,
        crossAxisSpacing: 12,
        childAspectRatio: 0.56,
      ),
      itemBuilder: (context, index) => MangaCard(manga: items[index]),
    );
  }
}

int _columnsForWidth(double width) {
  if (width >= 900) return 6;
  if (width >= 620) return 4;
  return 3;
}
