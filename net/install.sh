#!/bin/bash

TOP=$(git rev-parse --show-toplevel)

OS=$("$TOP/.tools/detect-os.sh")

COMMON_PACKAGES=(
    git
    curl
    wget
    gpg
    tar
    bison
    python3
    python3-pip
)

case "$OS" in
    fedora)
        PKG_MANAGER="dnf"
        PACKAGES=(
            "${COMMON_PACKAGES[@]}"
            gcc
            gcc-c++
            make
            automake
            flex
            postgresql-devel
            pcre-devel
            openssl-devel
            libpcap-devel
            libtool-ltdl-devel
            python3-virtualenv
            net-tools
            libxslt
            bind-utils
            nc
            nmap
            lolcat
            masscan
            bind
            geoip
            hwinfo
            autoconf
            iproute
            iptables
            ipset
            postgresql-server
            postgresql-contrib
            check
            iputils
        )
        sudo dnf makecache
        ;;
    *)
        PKG_MANAGER="apt-get"
        PACKAGES=(
            "${COMMON_PACKAGES[@]}"
            build-essential
            automake
            flex
            libpq-dev
            libpcre3-dev
            libssl-dev
            libpcap-dev
            libltdl-dev
            python3-venv
            net-tools
            xsltproc
            bind9-dnsutils
            netcat-traditional
            nmap
            lolcat
            masscan
            bind9-host
            geoip-bin
            hwinfo
            autoconf
            iproute2
            iptables
            ipset
            postgresql
            postgresql-contrib
            check
            iputils-ping
        )
        sudo apt-get update
        ;;
esac

if [[ "$OS" != "fedora" ]]; then
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --yes --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
fi

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