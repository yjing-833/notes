#!/usr/bin/env bash

set -euo pipefail

OUTPUT="whitelist.txt"

ps -eo cmd \
  | sed 's/\r$//' \
  | sort -u \
  > "$OUTPUT"

echo "Whitelist đã được lưu vào $OUTPUT ($(wc -l < "$OUTPUT") dòng)."
