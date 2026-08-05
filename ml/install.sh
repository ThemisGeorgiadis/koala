#!/bin/sh

TOP=$(git rev-parse --show-toplevel)

OS=$("$TOP/.tools/detect-os.sh")

COMMON_PACKAGES="
    wget
    unzip
    git
    zstd
    ffmpeg
    python3
    python3-pip
"

case "$OS" in
    fedora)
        PKG_MANAGER="dnf"
        PACKAGES="
            $COMMON_PACKAGES
            python3-virtualenv
            python3-devel
            gcc
            gcc-c++
            mesa-libGL
            glib2
            libjpeg-turbo-devel
            ImageMagick
            parallel
        "
        sudo dnf makecache
        ;;
    *)
        PKG_MANAGER="apt-get"
        PACKAGES="
            $COMMON_PACKAGES
            python3-venv
            libgl1
            libglib2.0-0
            libjpeg-dev
            imagemagick
            parallel
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

pip install --break-system-packages --upgrade pip

pip install --break-system-packages \
    joblib==1.4.2 \
    numpy==1.26.4 \
    scikit-learn==1.5.0 \
    scipy==1.13.1 \
    threadpoolctl==3.5.0 \
    imbalanced-learn==0.13.0