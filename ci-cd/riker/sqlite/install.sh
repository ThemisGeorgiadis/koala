#!/bin/bash

TOP=$(git rev-parse --show-toplevel)
OS=$("$TOP/.tools/detect-os.sh")

case "$OS" in
    fedora)
        PKG_MANAGER="dnf"
        PACKAGES=(
            git
            gcc
            tcl
            libtool
            readline-devel
            tcl-devel
        )
        sudo dnf makecache
        ;;
    *)
        PKG_MANAGER="apt-get"
        PACKAGES=(
            git
            gcc
            tcl8.6
            libtool
            libreadline-dev
            tcl8.6-dev
        )
        sudo apt-get update
        ;;
esac

for pkg in "${PACKAGES[@]}"; do
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

