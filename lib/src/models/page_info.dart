class PageInfo {
  const PageInfo({
    required this.currentPage,
    required this.totalPages,
  });

  factory PageInfo.fromJson(Map<String, dynamic> json) {
    return PageInfo(
      currentPage: _asInt(json['current_page'], fallback: 1),
      totalPages: _asInt(json['total_pages'], fallback: 1),
    );
  }

  final int currentPage;
  final int totalPages;

  bool get canGoBack => currentPage > 1;

  bool get canGoNext => currentPage < totalPages;
}

int _asInt(Object? value, {required int fallback}) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}
