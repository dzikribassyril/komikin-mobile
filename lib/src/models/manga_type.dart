enum MangaType {
  popular('komik-populer', 'Popular'),
  latest('komik-terbaru', 'Latest'),
  colored('komik-berwarna', 'Colored'),
  all('daftar-manga', 'All'),
  manga('manga', 'Manga'),
  manhwa('manhwa', 'Manhwa'),
  manhua('manhua', 'Manhua');

  const MangaType(this.path, this.label);

  final String path;
  final String label;
}
