# KomikIN Mobile

Flutter comic reader app for Android and Web. The app consumes an external manga scraper API and supports browsing, search, manga detail, reader, bookmarks, reading progress, and configurable API base URL.

## Features

- Explore manga by category: Popular, Latest, Colored, All, Manga, Manhwa, and Manhua.
- Search manga with pagination.
- Manga detail with cover, synopsis, genres, information, chapters, and read actions.
- Reader with vertical and horizontal modes.
- Continue Reading with saved chapter and page progress.
- Bookmarks and read chapter history using `shared_preferences`.
- Dark, light, and system theme modes.
- Runtime API Base URL setting from the Settings page.
- KomikIN branding, web icons, and Android launcher icons.

## API Contract

The app expects these API endpoints:

```text
GET /api/manga/{type}/{page}
GET /api/manga/search/{query}/{page}
GET /api/manga/detail/{slug}
GET /api/manga/read/{chapterId}
```

Default API base URL is:

```text
http://localhost:3000
```

You can change it inside the app:

```text
Settings > API Base URL
```

## Local Development

Install dependencies:

```powershell
flutter pub get
```

Run on Chrome:

```powershell
flutter run -d chrome --dart-define=KOMIKIN_API_BASE_URL=http://localhost:3000
```

Run on Android emulator:

```powershell
flutter run -d android --dart-define=KOMIKIN_API_BASE_URL=http://10.0.2.2:3000
```

Run on physical Android device:

```powershell
flutter run -d DEVICE_ID --dart-define=KOMIKIN_API_BASE_URL=http://YOUR_LAPTOP_IP:3000
```

## Docker Compose / Portainer

This repository includes a Docker setup for Flutter Web served by Nginx.

### Compose

```yaml
services:
  komikin-web:
    build:
      context: .
      dockerfile: Dockerfile
      args:
        KOMIKIN_API_BASE_URL: ${KOMIKIN_API_BASE_URL:-http://localhost:3000}
    image: komikin-mobile-web:latest
    container_name: komikin-mobile-web
    restart: unless-stopped
    ports:
      - "${KOMIKIN_WEB_PORT:-8080}:80"
    environment:
      KOMIKIN_API_BASE_URL: ${KOMIKIN_API_BASE_URL:-http://localhost:3000}
```

### Portainer Stack Variables

Set these environment variables in Portainer:

```text
KOMIKIN_WEB_PORT=8080
KOMIKIN_API_BASE_URL=https://your-api-domain.com
```

Then deploy the stack. The app will be available at:

```text
http://YOUR_SERVER_IP:8080
```

`KOMIKIN_API_BASE_URL` is written to `/config.json` when the container starts, so you can change it from Portainer by updating the environment variable and recreating the container. Users can still override it from the app Settings page.

## Build And Verify

Analyze:

```powershell
flutter analyze
```

Run tests:

```powershell
flutter test
```

Build web:

```powershell
flutter build web
```

Build APK debug:

```powershell
flutter build apk --debug
```
