#!/bin/bash

TOP=$(git rev-parse --show-toplevel)

OS=$("$TOP/.tools/detect-os.sh")

COMMON_PACKAGES=(
    dc
    coreutils
    gawk
    pkg-config
)

if [[ "$OS" == "fedora" ]]; then
    PKG_MANAGER="dnf"
    PACKAGES=(
        "${COMMON_PACKAGES[@]}"
        fuse3-devel
        fuse3
    )
else
    PKG_MANAGER="apt-get"
    PACKAGES=(
        "${COMMON_PACKAGES[@]}"
        libfuse3-dev
        fuse3
    )
fi

sudo "$PKG_MANAGER" update

for pkg in "${PACKAGES[@]}"; do
    if [[ "$OS" == "fedora" ]]; then
        if ! rpm -q "$pkg" >/dev/null 2>&1; then
            sudo dnf install -y "$pkg"
        fi
    else
        if ! dpkg -l | grep -q "^ii\s\+$pkg\s"; then
            sudo apt-get install -y --no-install-recommends "$pkg"
        fi
    fi
done

cd /tmp || exit 1

if [ ! -d unionfs-fuse ]; then
    git clone https://github.com/rpodgorny/unionfs-fuse.git
fi

cd /tmp/unionfs-fuse || exit 1

make -j"$(nproc)"
sudo make install