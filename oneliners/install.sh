#!/bin/sh

TOP=$(git rev-parse --show-toplevel)

OS=$("$TOP/.tools/detect-os.sh")

case "$OS" in
    fedora)
        PKG_MANAGER="dnf"
        PACKAGES="
            wget
            util-linux
            file
            dos2unix
            grep
            findutils
            mawk
        "
        sudo dnf makecache
        ;;
    *)
        PKG_MANAGER="apt-get"
        PACKAGES="
            wget
            bsdmainutils
            file
            dos2unix
            grep
            findutils
            mawk
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