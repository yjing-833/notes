#!/usr/bin/env bash

shopt -s nullglob

SUPPORTED_EXT=("7z" "zip" "rar" "tar" "gz" "bz2" "xz")
MARK_DIR="/tmp/extract_marks"

mkdir -p "$MARK_DIR"

print_menu() {
    echo "=============================="
    echo "1) Giải nén tất cả file trong thư mục hiện tại"
    echo "2) Giải nén theo pattern"
    echo "3) Thoát"
    echo "=============================="
    read -rp "Chọn: " choice
}

is_supported() {
    local file="$1"
    local ext="${file##*.}"
    for e in "${SUPPORTED_EXT[@]}"; do
        [[ "$ext" == "$e" ]] && return 0
    done
    return 1
}

mark_file() {
    local file="$1"
    local hash
    hash=$(echo -n "$file" | md5sum | awk '{print $1}')
    echo "$MARK_DIR/$hash.done"
}

already_done() {
    local mark
    mark=$(mark_file "$1")
    [[ -f "$mark" ]]
}

set_done() {
    local mark
    mark=$(mark_file "$1")
    touch "$mark"
}

analyze_archive() {
    local file="$1"
    local list
    list=$(7z l -ba "$file" 2>/dev/null | awk '{print $NF}' | sed '/^$/d')

    local roots=()
    local has_root_file=0

    while IFS= read -r entry; do
        entry="${entry#./}"
        local top="${entry%%/*}"
        if [[ "$entry" != */* ]]; then
            has_root_file=1
        fi
        [[ -n "$top" ]] && roots+=("$top")
    done <<< "$list"

    local unique
    unique=$(printf "%s\n" "${roots[@]}" | sort -u | wc -l)

    if [[ "$unique" -eq 1 && "$has_root_file" -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

extract_archive() {
    local file="$1"

    if ! is_supported "$file"; then
        return
    fi

    if already_done "$file"; then
        printf "[Skip] %s\n" "$file"
        return
    fi

    printf "[Extract] %s\n" "$file"

    if analyze_archive "$file"; then
        if 7z x -y "$file" >/dev/null 2>&1; then
            set_done "$file"
            printf "[Done] %s\n" "$file"
        else
            printf "[Fail] %s\n" "$file"
        fi
    else
        local base="${file%.*}"
        mkdir -p "$base"
        if 7z x -y "$file" -o"$base" >/dev/null 2>&1; then
            set_done "$file"
            printf "[Done] %s\n" "$file"
        else
            printf "[Fail] %s\n" "$file"
        fi
    fi
}

extract_all() {
    local files=(*)
    for f in "${files[@]}"; do
        [[ -f "$f" ]] && extract_archive "$f"
    done
}

extract_pattern() {
    read -rp "Nhập pattern: " pattern
    local files=($pattern*)
    for f in "${files[@]}"; do
        [[ -f "$f" ]] && extract_archive "$f"
    done
}

main() {
    while true; do
        print_menu
        case "$choice" in
            1) extract_all ;;
            2) extract_pattern ;;
            3) exit 0 ;;
            *) echo "Lựa chọn không hợp lệ" ;;
        esac
    done
}

main
