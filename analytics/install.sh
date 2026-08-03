#!/bin/bash

set -e

TOP=$(git rev-parse --show-toplevel)

OS=$("$TOP/.tools/detect-os.sh")

COMMON_PACKAGES=(
    tcpdump
    curl
    wget
    coreutils
    diffutils
    gzip
    gawk
    unzip
    git
    jq
    cmake
    tar
    python3
    grep
    sed
)

if [[ "$OS" == "fedora" ]]; then
    PKG_MANAGER="dnf"
    PACKAGES=(
        "${COMMON_PACKAGES[@]}"
        bc
        bcftools
        gcc
        gcc-c++
        jansson-devel
        libpcap-devel
        q-text-as-data
    )
else
    PKG_MANAGER="apt-get"
    PACKAGES=(
        "${COMMON_PACKAGES[@]}"
        bc
        bcftools
        build-essential
        libjansson-dev
        libpcap-dev
        q-text-as-data
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

# Set GO_VERSION before using it
GO_VERSION=1.24.2
echo "Installing Go $GO_VERSION"

TOP=$(git rev-parse --show-toplevel)
eval_dir="$TOP/analytics"
go_install_dir="${eval_dir}/go_install"

mkdir -p "$go_install_dir"

curl -LO "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
tar -C "$go_install_dir" -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
rm -f "go${GO_VERSION}.linux-amd64.tar.gz"

export GOROOT="$go_install_dir/go"
export GOPATH="$HOME/go"
export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"

go version || { echo "Go installation failed"; exit 1; }

go install github.com/zmap/zannotate/cmd/zannotate@latest

command -v zannotate || { echo "zannotate not found on PATH after go install"; exit 1; }