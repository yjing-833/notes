#!/usr/bin/env bash
# l.sh
# Yêu cầu: bash 4+ (để dùng associative arrays)
# Lưu ý: dùng LF line endings. Nếu file bị CRLF, chạy: dos2unix l.sh

set -euo pipefail

# Cấu hình (có thể sửa)
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WHITELIST="${DIR}/whitelist.txt"   # danh sách process được phép (mỗi dòng 1 entry, exact match)
SEEN_DB="${DIR}/seen.db"           # file lưu danh sách đã ghi (persistent)
LOG_FILE="${DIR}/log.txt"          # file log (chỉ dành cho log)
SLEEP_INTERVAL=5                   # giây giữa các lần kiểm tra

# Create files if missing (seen.db riêng, log.txt chỉ append)
: > "${LOG_FILE}" 2>/dev/null || true  # ensure log exists (do not truncate if already exist)
touch "${SEEN_DB}" "${WHITELIST}" >/dev/null 2>&1 || true

# Load whitelist into an associative array for fast lookup
declare -A WHITELIST_MAP
if [[ -s "${WHITELIST}" ]]; then
  # read lines, strip CR, ignore empty lines and lines starting with #
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%$'\r'}"   # remove possible CR
    [[ -z "${line}" ]] && continue
    [[ "${line}" =~ ^[[:space:]]*# ]] && continue
    WHITELIST_MAP["$line"]=1
  done < "${WHITELIST}"
fi

# Load seen DB (persistent) into associative array
declare -A SEEN_MAP
if [[ -s "${SEEN_DB}" ]]; then
  while IFS= read -r sline || [[ -n "$sline" ]]; do
    sline="${sline%%$'\r'}"
    [[ -z "${sline}" ]] && continue
    SEEN_MAP["$sline"]=1
  done < "${SEEN_DB}"
fi

# Ensure we append to seen.db in a safe manner (use a temp file if needed)
append_to_seen_db() {
  local entry="$1"
  # Use printf to preserve content exactly and avoid extra newlines
  printf '%s\n' "$entry" >> "${SEEN_DB}"
}

# Trap signals to exit cleanly
cleanup() {
  echo "Exiting l.sh" >&2
  exit 0
}
trap cleanup INT TERM

# Main loop
while true; do
  # Use ps -eo cmd without headers; ensure each line is a command line
  # We read via process substitution to avoid using log.txt for filtering
  while IFS= read -r proc || [[ -n "$proc" ]]; do
    # strip possible CR that might appear in ps output (rare)
    proc="${proc%%$'\r'}"
    # skip empty lines
    [[ -z "${proc}" ]] && continue

    # If in whitelist, skip
    if [[ -n "${WHITELIST_MAP["$proc"]+_}" ]]; then
      continue
    fi

    # If already seen (persistent), skip
    if [[ -n "${SEEN_MAP["$proc"]+_}" ]]; then
      continue
    fi

    # Not whitelisted and not seen -> log it
    timestamp="$(date --utc +'%Y-%m-%dT%H:%M:%SZ')"
    # Append to log.txt (only used for logs)
    printf '%s %s\n' "$timestamp" "$proc" >> "${LOG_FILE}"
    # Record as seen in both in-memory map and persistent DB
    SEEN_MAP["$proc"]=1
    append_to_seen_db "$proc"
  done < <(ps -eo cmd)

  sleep "${SLEEP_INTERVAL}"
done
