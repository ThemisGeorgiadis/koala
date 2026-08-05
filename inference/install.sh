#!/bin/sh

TOP=$(git rev-parse --show-toplevel)

OS=$("$TOP/.tools/detect-os.sh")

COMMON_PACKAGES="
    python3
    python3-pip
    zstd
    ffmpeg
    coreutils
    findutils
    wget
    sed
    unzip
    curl
    jq
"

case "$OS" in
    fedora)
        PKG_MANAGER="dnf"
        PACKAGES="
            $COMMON_PACKAGES
            procps-ng
            python3-virtualenv
            mesa-libGL
            glib2
            libjpeg-turbo-devel
            ImageMagick
            perl-Digest-SHA
        "
        sudo dnf makecache
        ;;
    *)
        PKG_MANAGER="apt-get"
        PACKAGES="
            $COMMON_PACKAGES
            procps
            python3-venv
            libgl1
            libglib2.0-0
            libjpeg-dev
            imagemagick
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
pip install --break-system-packages llm
pip install --break-system-packages llm-interpolate
pip install --break-system-packages llm-clap
pip install --break-system-packages llm-ollama

pip install --break-system-packages numpy \
    torch \
    torchvision \
    Pillow \
    segment-anything \
    tensorflow \
    opencv-python

# check if ollama is installed
if ! command -v ollama >/dev/null 2>&1
then
    echo "Ollama could not be found, installing..."
    curl -fsSL https://ollama.com/install.sh | sh
else
    echo "Ollama is already installed."
fi

ollama serve > /dev/null 2>&1 &
sleep 5
ollama pull moondream:latest

ollama_pid=$(pgrep ollama)
sudo kill "$ollama_pid"