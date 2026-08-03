#!/bin/bash

TOP=$(git rev-parse --show-toplevel)

OS=$("$TOP/.tools/detect-os.sh")

if [[ "$OS" == "fedora" ]]; then
    PKG_MANAGER="dnf"
    PACKAGES=(
        bash curl grep gawk iptables procps-ng net-tools fail2ban iproute git patch time
        # ufw is not available by default on Fedora
    )
    sudo dnf makecache
else
    PKG_MANAGER="apt-get"
    PACKAGES=(
        bash curl grep gawk iptables ufw procps net-tools fail2ban iproute2 git patch time
    )
    sudo apt-get update
fi


for pkg in "${PACKAGES[@]}"; do
    if [[ "$OS" == "fedora" ]]; then
        if ! rpm -q "$pkg" >/dev/null 2>&1; then
            sudo dnf install -y "$pkg"
        fi
    else
        if ! dpkg -l | grep -q "^ii  $pkg "; then
            sudo apt-get install -y --no-install-recommends "$pkg"
        fi
    fi
done
