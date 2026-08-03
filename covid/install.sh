#!/bin/bash

TOP=$(git rev-parse --show-toplevel)

OS=$("$TOP/.tools/detect-os.sh")

COMMON_PACKAGES=(
    coreutils
    curl
    gzip
    gawk
    sed
    git
)

if [[ "$OS" == "fedora" ]]; then
    PKG_MANAGER="dnf"
    PACKAGES=(
        "${COMMON_PACKAGES[@]}"
    )
else
    PKG_MANAGER="apt-get"
    PACKAGES=(
        "${COMMON_PACKAGES[@]}"
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
            sudo apt-get install --no-install-recommends -y "$pkg"
        fi
    fi
done