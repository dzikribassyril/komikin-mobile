import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/manga_info.dart';
import 'manga_badge.dart';

class MangaCard extends StatelessWidget {
  const MangaCard({
    super.key,
    required this.manga,
  });

  final MangaInfo manga;

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (manga.color) ...[
                          const MangaBadge(
                            label: 'Color',
                            color: Color(0xFFD44242),
                            icon: Icons.palette,
                          ),
                          const SizedBox(height: 4),
                        ],
                        MangaBadge(
                          label: manga.mangaType,
                          color: _typeColor(manga.mangaType),
                        ),
                      ],
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
          const SizedBox(height: 3),
          Row(
            children: [
              if (manga.rating != null && manga.rating!.isNotEmpty) ...[
                const Icon(Icons.star, size: 14, color: Color(0xFFF3A712)),
                const SizedBox(width: 3),
                Text(
                  manga.rating!,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
              const Spacer(),
              if (manga.latestChapter != null &&
                  manga.latestChapter!.isNotEmpty)
                Flexible(
                  child: Text(
                    manga.latestChapter!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _typeColor(String type) {
    return switch (type.toLowerCase()) {
      'manga' => const Color(0xFF228B5A),
      'manhwa' => const Color(0xFFC28A10),
      'manhua' => const Color(0xFF2B72B8),
      _ => const Color(0xFF667085),
    };
  }
}
