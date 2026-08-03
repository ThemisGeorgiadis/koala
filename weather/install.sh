#!/bin/bash

source /etc/os-release

if [[ "$ID" == "fedora" ]]; then
    PKG_MANAGER="dnf"
    PACKAGES=(
        curl wget unzip coreutils gzip gawk sed findutils
            git python3 python3-pip # python3-venv is included with python3 on Fedora
    )
else
    PKG_MANAGER="apt-get"
    PACKAGES=(
        curl wget unzip coreutils gzip gawk sed findutils
            git python3 python3-pip python3-venv
    )
fi

sudo "$PKG_MANAGER" update 

for pkg in "${PACKAGES[@]}"; do
    if [[ "$ID" == "fedora" ]]; then
        if ! rpm -q "$pkg" >/dev/null 2>&1; then
            sudo dnf install -y "$pkg"
        fi
    else
        if ! dpkg -l | grep -q "$pkg"; then
            sudo apt-get install -y --no-install-recommends "$pkg"
        fi
    fi
done

pip install --break-system-packages --upgrade pip

pip install --break-system-packages \
    numpy \
    matplotlib