#!/bin/bash

TOP=$(git rev-parse --show-toplevel)

OS=$("$TOP/.tools/detect-os.sh")

COMMON_PACKAGES=(
    coreutils
    git
    curl
    wget
    bzip2
    gpg
    tar
    sed
    gawk
    autoconf
    automake
    python3
    python3-pip
    ca-certificates
    zsh
)

if [[ "$OS" == "fedora" ]]; then
    PKG_MANAGER="dnf"
    PACKAGES=(
        "${COMMON_PACKAGES[@]}"
        gcc
        gcc-c++
        make
        python3-virtualenv
        ncurses
    )
else
    PKG_MANAGER="apt-get"
    PACKAGES=(
        "${COMMON_PACKAGES[@]}"
        build-essential
        python3-venv
        ncurses-bin
    )
fi

sudo "$PKG_MANAGER" update -y

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