#!/bin/sh

set -e

ROOTFS_DIR="$(pwd)"
export PATH="$PATH:$HOME/.local/usr/bin"

MAX_RETRIES=50
TIMEOUT=1
INSTALLED_FLAG="$ROOTFS_DIR/.installed"

ARCH="$(uname -m)"

case "$ARCH" in
    x86_64)
        ARCH_ALT="amd64"
        ;;
    aarch64)
        ARCH_ALT="arm64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

download() {
    wget \
        --tries="$MAX_RETRIES" \
        --timeout="$TIMEOUT" \
        --no-hsts \
        -O "$2" \
        "$1"
}

if [ ! -f "$INSTALLED_FLAG" ]; then

    ROOTFS_URL="http://cdimage.ubuntu.com/ubuntu-base/releases/20.04/release/ubuntu-base-20.04.4-base-${ARCH_ALT}.tar.gz"

    echo "Downloading Ubuntu rootfs..."
    download "$ROOTFS_URL" /tmp/rootfs.tar.gz

    echo "Extracting rootfs..."
    tar -xzf /tmp/rootfs.tar.gz -C "$ROOTFS_DIR"

    mkdir -p "$ROOTFS_DIR/usr/local/bin"

    PROOT_PATH="$ROOTFS_DIR/usr/local/bin/proot"
    PROOT_URL="https://raw.githubusercontent.com/9xcongit/freeroot/main/proot-${ARCH}"

    echo "Downloading proot..."

    until download "$PROOT_URL" "$PROOT_PATH" && [ -s "$PROOT_PATH" ]; do
        rm -f "$PROOT_PATH"
        sleep 1
    done

    chmod 755 "$PROOT_PATH"

    cat > "$ROOTFS_DIR/etc/resolv.conf" << EOF
nameserver 1.1.1.1
nameserver 1.0.0.1
EOF

    rm -f /tmp/rootfs.tar.gz
    rm -rf /tmp/sbin

    touch "$INSTALLED_FLAG"
fi

clear

exec "$ROOTFS_DIR/usr/local/bin/proot" \
    --rootfs="$ROOTFS_DIR" \
    -0 \
    -w /root \
    -v HOME=/root \
    -b /dev \
    -b /sys \
    -b /proc \
    -b /etc/resolv.conf \
    --kill-on-exit \
    /bin/bash --login
