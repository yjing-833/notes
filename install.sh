#!/bin/bash

set -e

BEDROCK_VERSION="${BEDROCK_VERSION:-latest}"
INSTALL_DIR="/app/data"
cd "$INSTALL_DIR"

if [ -f bedrock_server ]; then
  echo "$BEDROCK_VERSION"
  echo "✅ Skipping installation."
else
  echo "$BEDROCK_VERSION"
  echo "📦 Installing Bedrock server..."

  apt update -qq > /dev/null
  apt install -y -qq zip unzip wget curl > /dev/null

  RANDVERSION=$(echo $((1 + $RANDOM % 4000)))

  if [ "${BEDROCK_VERSION}" == "latest" ]; then
    echo "⬇️  Downloading latest Bedrock server..."
    curl -sL -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.${RANDVERSION}.212 Safari/537.36" \
      -H "Accept-Language: en" -H "Accept-Encoding: gzip, deflate" \
      -o versions.html.gz https://net-secondary.web.minecraft-services.net/api/v1.0/download/links

    DOWNLOAD_URL=$(zgrep -o 'https://www.minecraft.net/bedrockdedicatedserver/bin-linux/[^"]*' versions.html.gz)
  else
    echo "⬇️  Downloading Bedrock server version: ${BEDROCK_VERSION}..."
    DOWNLOAD_URL="https://www.minecraft.net/bedrockdedicatedserver/bin-linux/bedrock-server-${BEDROCK_VERSION}.zip"
  fi

  DOWNLOAD_FILE=$(basename "${DOWNLOAD_URL}")

  # Backup file cấu hình (nếu có)
  cp server.properties server.properties.bak 2>/dev/null || true
  cp permissions.json permissions.json.bak 2>/dev/null || true
  cp allowlist.json allowlist.json.bak 2>/dev/null || true

  curl -sL -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.${RANDVERSION}.212 Safari/537.36" \
    -H "Accept-Language: en" -o "${DOWNLOAD_FILE}" "${DOWNLOAD_URL}" > /dev/null

  unzip -oq "${DOWNLOAD_FILE}" > /dev/null
  rm -f "${DOWNLOAD_FILE}" versions.html.gz *.bak

  # Khôi phục file cấu hình
  cp -f server.properties.bak server.properties 2>/dev/null || true
  cp -f permissions.json.bak permissions.json 2>/dev/null || true
  cp -f allowlist.json.bak allowlist.json 2>/dev/null || true

  chmod +x bedrock_server

  echo "✅ Install Completed"
fi

echo "🚀 Starting Bedrock server..."
exec ./bedrock_server
