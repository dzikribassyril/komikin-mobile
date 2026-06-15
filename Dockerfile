# syntax=docker/dockerfile:1

FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

ARG KOMIKIN_API_BASE_URL=http://localhost:3000
RUN flutter build web --release --dart-define=KOMIKIN_API_BASE_URL=${KOMIKIN_API_BASE_URL}

FROM nginx:1.27-alpine

ENV KOMIKIN_API_BASE_URL=http://localhost:3000

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY docker/10-komikin-config.sh /docker-entrypoint.d/10-komikin-config.sh
RUN chmod +x /docker-entrypoint.d/10-komikin-config.sh

COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -qO- http://127.0.0.1/ >/dev/null || exit 1
