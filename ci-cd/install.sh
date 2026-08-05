#!/bin/sh

TOP=$(git rev-parse --show-toplevel)

OS=$("$TOP/.tools/detect-os.sh")

COMMON_PACKAGES="
    binutils
    git
    build-essential
    coreutils
    wget
    unzip
    make
    pbzip2
    bzip2
    zstd
    gnupg
"

case "$OS" in
    fedora)
        PKG_MANAGER="dnf"
        PACKAGES="
            $COMMON_PACKAGES
        "
        sudo dnf makecache
        ;;
    *)
        PKG_MANAGER="apt-get"
        PACKAGES="
            $COMMON_PACKAGES
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

eval_dir="${TOP}/ci-cd/riker"

min_benchmark="
    xz-clang
"

run_min=false

for arg in "$@"; do
    if [ "$arg" = "--min" ]; then
        run_min=true
        break
    fi
done

if [ "$run_min" = true ]; then
    for bench in $min_benchmark; do
        script_path="$eval_dir/$bench/install.sh"
        if [ -x "$script_path" ]; then
            "$script_path" "$@"
        else
            echo "Error: $script_path not found or not executable."
            exit 1
        fi
    done
    exit 0
fi

for bench in "$eval_dir"/*; do
    "$bench/install.sh" "$@"
done