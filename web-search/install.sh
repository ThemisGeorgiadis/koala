#!/bin/sh

TOP=$(git rev-parse --show-toplevel)

OS=$("$TOP/.tools/detect-os.sh")

case "$OS" in
    fedora)
        PKG_MANAGER="dnf"
        PACKAGES="
            p7zip curl wget unzip npm
        "
        sudo dnf makecache
        ;;
    *)
        PKG_MANAGER="apt-get"
        PACKAGES="
            p7zip-full curl wget unzip npm
        "
        sudo apt-get update
        ;;
esac


for pkg in $PACKAGES; do
    case "$OS" in
        fedora)
            if ! rpm -q "$pkg" >/dev/null 2>&1; then
                sudo dnf install -y "$pkg"
            fi
            ;;
        *)
            if ! dpkg -s "$pkg" >/dev/null 2>&1; then
                sudo apt-get install -y --no-install-recommends "$pkg"
            fi
            ;;
    esac
done

# Install pandoc if not installed
case "$OS" in
    fedora)
        if ! command -v pandoc >/dev/null 2>&1; then
            sudo dnf install -y pandoc
        fi
        ;;
    *)
        if ! dpkg -s pandoc >/dev/null 2>&1 ; then
            # since pandoc v.2.2.1 does not support arm64, we use v.3.5
            arch=$(dpkg --print-architecture)
            wget https://github.com/jgm/pandoc/releases/download/3.5/pandoc-3.5-1-"${arch}".deb
            sudo dpkg -i pandoc-3.5-1-"${arch}".deb || sudo apt-get install -f -y --no-install-recommends
            rm pandoc-3.5-1-"${arch}".deb
        fi
        ;;
esac

# Install Node.js (18.x) and npm via NodeSource
if ! command -v node > /dev/null 2>&1 ; then
    case "$OS" in
        fedora)
            curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
            sudo dnf install -y nodejs
            ;;
        *)
            curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
            sudo apt-get install -y --no-install-recommends nodejs
            ;;
    esac
fi

# Verify node installation
if ! command -v node > /dev/null 2>&1 ; then
    echo "Node.js installation failed."
    exit 1
fi

case "$OS" in
    fedora)
        if ! rpm -q nodejs >/dev/null 2>&1 ; then
            sudo dnf install -y nodejs
        fi
        ;;
    *)
        if ! dpkg -s nodejs >/dev/null 2>&1 ; then
            # node version 18+ does not need external npm
            curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
            sudo apt-get install -y --no-install-recommends nodejs
        fi
        ;;
esac

cd "$(dirname "$0")/scripts" || exit 1
if [ ! -d node_modules ]; then
    npm install html-to-text jsdom natural
fi

cd - || exit 1