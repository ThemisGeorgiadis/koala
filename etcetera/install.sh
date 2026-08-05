#!/bin/sh

TOP=$(git rev-parse --show-toplevel)

OS=$("$TOP/.tools/detect-os.sh")

COMMON_PACKAGES="
    dc
    coreutils
    gawk
    pkg-config
"

case "$OS" in
    fedora)
        PKG_MANAGER="dnf"
        PACKAGES="
            $COMMON_PACKAGES
            fuse3-devel
            fuse3
        "
        sudo dnf makecache
        ;;
    *)
        PKG_MANAGER="apt-get"
        PACKAGES="
            $COMMON_PACKAGES
            libfuse3-dev
            fuse3
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

cd /tmp || exit 1

if [ ! -d unionfs-fuse ]; then
    git clone https://github.com/rpodgorny/unionfs-fuse.git
fi

cd /tmp/unionfs-fuse || exit 1

make -j"$(nproc)"
sudo make install