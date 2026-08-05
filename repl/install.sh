#!/bin/sh

TOP=$(git rev-parse --show-toplevel)

OS=$("$TOP/.tools/detect-os.sh")

case "$OS" in
    fedora)
        PKG_MANAGER="dnf"
        PACKAGES="
            bash curl grep gawk iptables procps-ng net-tools fail2ban iproute git patch time
        "
        sudo dnf makecache
        ;;
    *)
        PKG_MANAGER="apt-get"
        PACKAGES="
            bash curl grep gawk iptables ufw procps net-tools fail2ban iproute2 git patch time
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
            if ! dpkg -l | grep -q "^ii  $pkg "; then
                sudo apt-get install -y --no-install-recommends "$pkg"
            fi
            ;;
    esac
done