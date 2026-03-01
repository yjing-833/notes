#!/bin/bash

shopt -s nullglob

MARK_DIR="/tmp/7z_marks"
mkdir -p "$MARK_DIR"

EXT=("7z" "zip" "rar" "tar" "gz" "bz2" "xz")

echo "Password (Enter if none):"
read -s PASSWORD
echo

need_folder() {
    local file="$1"

    entries=$(7z l -ba "$file" 2>/dev/null | awk '{print $NF}' | grep -v '^$')

    root_files=$(echo "$entries" | grep -v '/')
    top_dirs=$(echo "$entries" | awk -F/ '{print $1}' | sort -u | wc -l)

    if [[ -z "$root_files" && "$top_dirs" -eq 1 ]]; then
        return 1
    else
        return 0
    fi
}

extract_one() {
    local file="$1"
    [[ -f "$file" ]] || return

    mark="$MARK_DIR/$(basename "$file").done"

    if [[ -f "$mark" ]]; then
        echo "Skip: $file"
        return
    fi

    echo "Extract: $file"

    base="${file%.*}"

    if need_folder "$file"; then
        mkdir -p "$base"
        7z x "$file" -o"$base" -p"$PASSWORD" -y
        result=$?
    else
        7z x "$file" -p"$PASSWORD" -y
        result=$?
    fi

    if [[ $result -eq 0 ]]; then
        touch "$mark"
        echo "Done: $file"
    else
        echo "Fail: $file"
    fi
}

extract_all() {
    for e in "${EXT[@]}"; do
        for f in *."$e"; do
            extract_one "$f"
        done
    done
}

extract_pattern() {
    read -p "Pattern (e.g. abc* or *2024*): " pattern
    found=0

    for e in "${EXT[@]}"; do
        for f in $pattern."$e"; do
            if [[ -f "$f" ]]; then
                extract_one "$f"
                found=1
            fi
        done
    done

    [[ $found -eq 0 ]] && echo "No match."
}

while true; do
    echo "====== MENU ======"
    echo "1. Extract all"
    echo "2. Extract by pattern"
    echo "0. Exit"
    echo "=================="
    read -p "Select: " c

    case "$c" in
        1) extract_all ;;
        2) extract_pattern ;;
        0) exit 0 ;;
        *) echo "Invalid." ;;
    esac
done
