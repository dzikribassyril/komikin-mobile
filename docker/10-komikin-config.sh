#!/bin/sh
set -eu

: "${KOMIKIN_API_BASE_URL:=http://localhost:3000}"

escaped_api_url="$(printf '%s' "$KOMIKIN_API_BASE_URL" | sed 's/\\/\\\\/g; s/"/\\"/g')"

cat > /usr/share/nginx/html/config.json <<EOF
{"apiBaseUrl":"$escaped_api_url"}
EOF
