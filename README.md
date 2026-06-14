# Komikin Mobile

Flutter manga reader app migrated from the existing Next.js Komikin project.

This folder intentionally contains the Flutter source app only. I did not run or build the app. The Flutter CLI wrapper in this WSL environment did not scaffold reliably, so generate native platform folders later from your normal Flutter terminal with:

```bash
flutter create . --platforms=android,ios,web
flutter pub get
```

If Flutter asks about overwriting files, keep the existing `lib/`, `pubspec.yaml`, and `README.md` from this folder.

Run with your Next.js API URL:

```bash
flutter run --dart-define=KOMIKIN_API_BASE_URL=http://10.0.2.2:3000
```

For a physical device, replace `10.0.2.2` with your computer LAN IP, for example:

```bash
flutter run --dart-define=KOMIKIN_API_BASE_URL=http://192.168.1.10:3000
```

## Features

- Home manga list with category filters and pagination.
- Search manga with paginated results.
- Manga detail page with cover, synopsis, genres, information, chapters, first/latest shortcuts.
- Bookmark storage using `shared_preferences`.
- Read chapter history per manga.
- Reader screen with vertical and horizontal modes.
- Reader page width setting, persisted locally.
- Dark/light/system theme setting.
- Cached network images for covers and pages.

## API Contract

The app consumes the existing Next.js endpoints:

- `GET /api/manga/{type}/{page}`
- `GET /api/manga/search/{query}/{page}`
- `GET /api/manga/detail/{slug}`
- `GET /api/manga/read/{chapterId}`

Default API base URL is `http://localhost:3000`, but Android emulator should usually use `http://10.0.2.2:3000`.

For Flutter Web on a different domain, the Next.js API must allow CORS or be proxied under the same domain.
