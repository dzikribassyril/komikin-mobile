enum ReadingMode {
  vertical('vertical'),
  horizontal('horizontal');

  const ReadingMode(this.value);

  factory ReadingMode.fromValue(String? value) {
    return ReadingMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => ReadingMode.vertical,
    );
  }

  final String value;
}

enum PageWidth {
  fit('fit'),
  full('full');

  const PageWidth(this.value);

  factory PageWidth.fromValue(String? value) {
    return PageWidth.values.firstWhere(
      (width) => width.value == value,
      orElse: () => PageWidth.fit,
    );
  }

  final String value;
}

class ReaderSettings {
  const ReaderSettings({
    this.readingMode = ReadingMode.vertical,
    this.pageWidth = PageWidth.fit,
  });

  factory ReaderSettings.fromJson(Map<String, dynamic> json) {
    return ReaderSettings(
      readingMode: ReadingMode.fromValue(json['readingMode'] as String?),
      pageWidth: PageWidth.fromValue(json['pageWidth'] as String?),
    );
  }

  final ReadingMode readingMode;
  final PageWidth pageWidth;

  Map<String, dynamic> toJson() {
    return {
      'readingMode': readingMode.value,
      'pageWidth': pageWidth.value,
    };
  }

  ReaderSettings copyWith({
    ReadingMode? readingMode,
    PageWidth? pageWidth,
  }) {
    return ReaderSettings(
      readingMode: readingMode ?? this.readingMode,
      pageWidth: pageWidth ?? this.pageWidth,
    );
  }
}
