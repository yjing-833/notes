#!/usr/bin/env bash

set -o pipefail
shopt -s nullglob nocaseglob

EXTS=("7z" "zip" "rar" "tar" "gz" "bz2" "xz")
MARK_DIR="/tmp/extract_done"

init() {
    mkdir -p "$MARK_DIR" || { echo "Init fail"; exit 1; }
    command -v 7z >/dev/null 2>&1 || { echo "7z not found"; exit 1; }
}

is_supported() {
    local f="$1"
    local ext="${f##*.}"
    for e in "${EXTS[@]}"; do
        [[ "$ext" == "$e" ]] && return 0
    done
    return 1
}

mark_path() {
    local f="$1"
    local h
    h=$(printf "%s" "$f" | md5sum | awk '{print $1}')
    echo "$MARK_DIR/$h.done"
}

is_done() {
    local f="$1"
    [[ -f "$(mark_path "$f")" ]]
}

set_done() {
    touch "$(mark_path "$1")"
}

extract_one() {
    local f="$1"

    is_supported "$f" || return

    if is_done "$f"; then
        printf "Skip  : %s\n" "$f"
        return
    fi

    printf "Extract: %s\n" "$f"

    if 7z x -y "$f" >/dev/null 2>&1; then
        set_done "$f"
        printf "Done  : %s\n" "$f"
    else
        printf "Fail  : %s\n" "$f"
    fi
}

extract_all() {
    for f in *; do
        [[ -f "$f" ]] && extract_one "$f"
    done
}

extract_pattern() {
    read -rp "Pattern: " p
    [[ -z "$p" ]] && return
    for f in $p; do
        [[ -f "$f" ]] && extract_one "$f"
    done
}

menu() {
    while true; do
        echo "1) Extract all"
        echo "2) Extract by pattern"
        echo "3) Exit"
        read -rp "Choice: " c
        case "$c" in
            1) extract_all ;;
            2) extract_pattern ;;
            3) exit 0 ;;
            *) echo "Invalid" ;;
        esac
    done
}

main() {
    init
    menu
}

main
