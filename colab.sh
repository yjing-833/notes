#!/bin/bash

shopt -s nullglob

MARK_DIR="/tmp/7z_marks"
mkdir -p "$MARK_DIR"

EXT=("7z" "zip" "rar" "tar" "gz" "bz2" "xz")

read_password() {
    echo "Enter password (leave empty if none):"
    read -s PASSWORD
    echo
}

read_password

need_folder() {
    local file="$1"
    local entries root_files top_dirs

    entries=$(7z l -ba "$file" 2>/dev/null | awk '{print $NF}' | grep -v '^$')

    root_files=$(echo "$entries" | grep -v '/')
    top_dirs=$(echo "$entries" | awk -F/ '{print $1}' | sort -u | wc -l)

    if [[ -z "$root_files" && "$top_dirs" -eq 1 ]]; then
        return 1
    else
        return 0
    fi
}

run_extract() {
    local file="$1"
    local outdir="$2"
    local log result

    log=$(mktemp)

    if [[ -n "$PASSWORD" ]]; then
        7z x "$file" -o"$outdir" -p"$PASSWORD" -y | tee "$log"
    else
        7z x "$file" -o"$outdir" -y | tee "$log"
    fi

    result=${PIPESTATUS[0]}

    if grep -qi "Wrong password" "$log"; then
        rm -f "$log"
        return 2
    fi

    rm -f "$log"
    return $result
}

extract_one() {
    local file="$1"
    local mark base result

    [[ -f "$file" ]] || return

    mark="$MARK_DIR/$(basename "$file").done"

    if [[ -f "$mark" ]]; then
        echo "Skip: $file"
        return
    fi

    echo "======================================"
    echo "Extracting: $file"
    echo "======================================"

    base="${file%.*}"
    local outdir="."

    if need_folder "$file"; then
        mkdir -p "$base"
        outdir="$base"
    fi

    while true; do
        run_extract "$file" "$outdir"
        result=$?

        if [[ $result -eq 0 ]]; then
            touch "$mark"
            echo "✔ Done: $file"
            break
        elif [[ $result -eq 2 ]]; then
            echo "✘ Wrong password!"
            read_password
        else
            echo "✘ Extraction failed!"
            break
        fi
    done
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
    local found=0

    for e in "${EXT[@]}"; do
        for f in $pattern."$e"; do
            [[ -f "$f" ]] || continue
            extract_one "$f"
            found=1
        done
    done

    [[ $found -eq 0 ]] && echo "No match."
}

while true; do
    echo
    echo "========== MENU =========="
    echo "1. Extract all"
    echo "2. Extract by pattern"
    echo "0. Exit"
    echo "=========================="
    read -p "Select: " c

    case "$c" in
        1) extract_all ;;
        2) extract_pattern ;;
        0) exit 0 ;;
        *) echo "Invalid." ;;
    esac
done
