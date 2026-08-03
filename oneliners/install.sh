#!/bin/bash

TOP=$(git rev-parse --show-toplevel)

OS=$("$TOP/.tools/detect-os.sh")

if [[ "$OS" == "fedora" ]]; then
    PKG_MANAGER="dnf"
    PACKAGES=(
        wget
        util-linux
        file
        dos2unix
        grep
        findutils
        gawk
    )
else
    PKG_MANAGER="apt-get"
    PACKAGES=(
        wget
        bsdmainutils
        file
        dos2unix
        grep
        findutils
        mawk
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
