#!/bin/sh

TOP=$(git rev-parse --show-toplevel)

OS=$("$TOP/.tools/detect-os.sh")

case "$OS" in
    fedora)
        PKG_MANAGER="dnf"
        PACKAGES="
            curl wget unzip coreutils gzip gawk sed findutils
            git python3 python3-pip # python3-venv is included with python3 on Fedora
        "
        sudo dnf makecache
        ;;
    *)
        PKG_MANAGER="apt-get"
        PACKAGES="
            curl wget unzip coreutils gzip gawk sed findutils
            git python3 python3-pip python3-venv
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
            if ! dpkg -l | grep -q "$pkg"; then
                sudo apt-get install -y --no-install-recommends "$pkg"
            fi
            ;;
    esac
done

pip install --break-system-packages --upgrade pip

pip install --break-system-packages \
    numpy \
    matplotlib