#!/bin/bash

TOP=$(git rev-parse --show-toplevel)

OS=$("$TOP/.tools/detect-os.sh")

COMMON_PACKAGES=(
    gpg
    wget
    git
    unzip
    zip
    zstd
    nodejs
    ffmpeg
    unrtf
    tcpdump
    cmake
    gcc
    make
    libtool
    npm
)

if [[ "$OS" == "fedora" ]]; then
    PKG_MANAGER="dnf"
    PACKAGES=(
        "${COMMON_PACKAGES[@]}"
        ncurses-devel
        xz-devel
        bzip2-devel
        libarchive
        ImageMagick
        gcc-c++
        openssl-devel
        qt-creator
        qt5-qtbase-devel
        libtirpc-devel
        libSM-devel
        libICE-devel
        libXt-devel
        libX11-devel
        libXdmcp-devel
        libselinux-devel
        readline-devel
        java-latest-openjdk-devel
    )
else
    PKG_MANAGER="apt-get"
    PACKAGES=(
        "${COMMON_PACKAGES[@]}"
        libncurses5-dev
        libncursesw5-dev
        liblzma-dev
        libbz2-dev
        libarchive-tools
        imagemagick
        build-essential
        libssl-dev
        qtcreator
        qtbase5-dev
        qt5-qmake
        libtirpc-dev
        libncurses-dev
        libsm-dev
        libice-dev
        libxt-dev
        libx11-dev
        libxdmcp-dev
        libselinux-dev
        libtool-bin
        libreadline-dev
        default-jdk
    )
fi

sudo "$PKG_MANAGER" update

for pkg in "${PACKAGES[@]}"; do
    if [[ "$OS" == "fedora" ]]; then
        if ! rpm -q "$pkg" >/dev/null 2>&1; then
            sudo dnf install -y "$pkg"
        fi
    else
        if ! dpkg -l | grep -q "^ii\s\+$pkg\s"; then
            sudo apt-get install -y --no-install-recommends "$pkg"
        fi
    fi
done

if [[ "$OS" != "fedora" ]]; then
    wget -qO - 'https://proget.makedeb.org/debian-feeds/makedeb.pub' | gpg --dearmor | sudo tee /usr/share/keyrings/makedeb-archive-keyring.gpg > /dev/null
    echo 'deb [signed-by=/usr/share/keyrings/makedeb-archive-keyring.gpg arch=all] https://proget.makedeb.org/ makedeb main' | sudo tee /etc/apt/sources.list.d/makedeb.list > /dev/null

    sudo apt-get update
    sudo apt-get install -y --no-install-recommends makedeb
fi

TOP=$(git rev-parse --show-toplevel)
URL="https://atlas.cs.brown.edu/data"
installdir="$TOP/pkg/inputs"

mkdir -p "$installdir"
cd "$installdir" || exit 1

# Install mir-sa
if [ ! -d mir-sa ]; then
    wget "$URL/prog-inf/mir-sa.tar.gz" -O mir-sa.tar.gz
    tar xf mir-sa.tar.gz --no-same-owner
    rm mir-sa.tar.gz
fi

cd mir-sa/@andromeda/mir-sa || exit 1
if [ ! -d node_modules ]; then
    npm install
fi

# Install Node.js (18.x) and npm via NodeSource
if ! command -v node >/dev/null 2>&1; then
    if [[ "$OS" == "fedora" ]]; then
        sudo dnf install -y nodejs
    else
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y --no-install-recommends nodejs
    fi
fi

if [[ "$OS" == "fedora" ]]; then
    if ! rpm -q java-latest-openjdk-devel >/dev/null 2>&1; then
        sudo dnf install -y java-latest-openjdk-devel
    fi
else
    if ! dpkg -l | grep -q "^ii\s\+default-jdk\s"; then
        sudo apt-get install -y --no-install-recommends default-jdk
    fi
fi