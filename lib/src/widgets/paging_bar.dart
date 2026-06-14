import 'package:flutter/material.dart';

import '../models/page_info.dart';

class PagingBar extends StatelessWidget {
  const PagingBar({
    super.key,
    required this.pageInfo,
    required this.isLoading,
    required this.onPageChanged,
  });

  final PageInfo pageInfo;
  final bool isLoading;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            IconButton.filledTonal(
              onPressed: !isLoading && pageInfo.canGoBack
                  ? () => onPageChanged(pageInfo.currentPage - 1)
                  : null,
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Halaman sebelumnya',
            ),
            Expanded(
              child: Text(
                '${pageInfo.currentPage} / ${pageInfo.totalPages}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            IconButton.filledTonal(
              onPressed: !isLoading && pageInfo.canGoNext
                  ? () => onPageChanged(pageInfo.currentPage + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Halaman berikutnya',
            ),
          ],
        ),
      ),
    );
  }
}
