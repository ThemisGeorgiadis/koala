#!/bin/bash
set -e

source /etc/os-release

if [[ "$ID" == "fedora" ]]; then
    INSTALLER="dnf"
    PACKAGES=(
        git procps-ng autoconf automake libtool
        gcc gcc-c++ make
        cloc time gawk jq strace lsof
        python3 python3-pip
    )
else
    INSTALLER="apt-get"
    PACKAGES=(
        git procps autoconf automake libtool
        build-essential
        cloc time gawk jq strace lsof
        python3 python3-pip python3-venv
    )
fi

cd "$(realpath "$(dirname "$0")")" || exit 1

TOP=$(git rev-parse --show-toplevel)
sudo "$INSTALLER" update
sudo "$INSTALLER" install -y "${PACKAGES[@]}"
VENV_DIR="$TOP/venv"
rm -rf "$VENV_DIR"
python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"

pip install --upgrade pip
pip install --break-system-packages -r "$TOP/.tools/requirements.txt"
