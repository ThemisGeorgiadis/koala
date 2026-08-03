#!/usr/bin/env bash

TOP=$(git rev-parse --show-toplevel)

OS=$("$TOP/.tools/detect-os.sh")

if [[ "$OS" == "fedora" ]]; then
    PKG_MANAGER="dnf"
    PACKAGES=(
        p7zip curl wget unzip npm
    )
    sudo dnf makecache
else
    PKG_MANAGER="apt-get"
    PACKAGES=(
        p7zip-full curl wget unzip npm
    )
    sudo apt-get update
fi


for pkg in "${PACKAGES[@]}"; do
    if [[ "$OS" == "fedora" ]]; then
        if ! rpm -q "$pkg" >/dev/null 2>&1; then
            sudo dnf install -y "$pkg"
        fi
    else
        if ! dpkg -s "$pkg" >/dev/null 2>&1; then
            sudo apt-get install -y --no-install-recommends "$pkg"
        fi
    fi
done

# Install pandoc if not installed
if [[ "$OS" == "fedora" ]]; then
    if ! command -v pandoc >/dev/null 2>&1; then
        sudo dnf install -y pandoc
    fi
else
    if ! dpkg -s pandoc >/dev/null 2>&1 ; then
        # since pandoc v.2.2.1 does not support arm64, we use v.3.5
        arch=$(dpkg --print-architecture)
        wget https://github.com/jgm/pandoc/releases/download/3.5/pandoc-3.5-1-"${arch}".deb
        sudo dpkg -i pandoc-3.5-1-"${arch}".deb || sudo apt-get install -f -y --no-install-recommends
        rm pandoc-3.5-1-"${arch}".deb
    fi
fi

# Install Node.js (18.x) and npm via NodeSource
if ! command -v node > /dev/null 2>&1 ; then
    if [[ "$ID" == "fedora" ]]; then
        curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
        sudo dnf install -y nodejs
    else
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y --no-install-recommends nodejs
    fi
fi

# Verify node installation
if ! command -v node > /dev/null 2>&1 ; then
    echo "Node.js installation failed."
    exit 1
fi

if [[ "$OS" == "fedora" ]]; then
    if ! rpm -q nodejs >/dev/null 2>&1 ; then
        sudo dnf install -y nodejs
    fi
else
    if ! dpkg -s nodejs >/dev/null 2>&1 ; then
        # node version 18+ does not need external npm
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y --no-install-recommends nodejs
    fi
fi

cd "$(dirname "$0")/scripts" || exit 1
if [ ! -d node_modules ]; then
    npm install html-to-text jsdom natural
fi

cd - || exit 1