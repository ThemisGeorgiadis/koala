#!/bin/sh

TOP=$(git rev-parse --show-toplevel)

OS=$("$TOP/.tools/detect-os.sh")

COMMON_PACKAGES="
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
"

case "$OS" in
    fedora)
        PKG_MANAGER="dnf"
        PACKAGES="
            $COMMON_PACKAGES
            gcc
            gcc-c++
            make
            python3-virtualenv
            ncurses
        "
        sudo dnf makecache
        ;;
    *)
        PKG_MANAGER="apt-get"
        PACKAGES="
            $COMMON_PACKAGES
            build-essential
            python3-venv
            ncurses-bin
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
            if ! dpkg -l | grep -q "^ii\s\+$pkg\s"; then
                sudo apt-get install -y --no-install-recommends "$pkg"
            fi
            ;;
    esac
done