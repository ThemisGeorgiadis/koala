#!/bin/sh

set -eu

TOP=$(git rev-parse --show-toplevel)
OS=$("$TOP/.tools/detect-os.sh")

install_ffmpeg_5_1_9_fedora() {
    echo "Installing FFmpeg 5.1.9 from source for Fedora"

    src_dir="/tmp/ffmpeg-5.1.9"
    tarball="/tmp/ffmpeg-5.1.9.tar.gz"
    prefix="/usr/local/ffmpeg-5.1.9"
    ffmpeg_bin="$prefix/bin/ffmpeg"

    if [ -x "$ffmpeg_bin" ]; then
        actual="$("$ffmpeg_bin" -version 2>&1 | head -n 1 || true)"
        if printf '%s\n' "$actual" | grep -Fq "ffmpeg version 5.1.9" &&
           "$ffmpeg_bin" -hide_banner -encoders 2>/dev/null | grep -q 'libmp3lame'; then
            echo "FFmpeg 5.1.9 with MP3 support already installed; skipping rebuild"
            return 0
        fi
        echo "FFmpeg 5.1.9 is present but MP3 support is missing; rebuilding"
    fi

    if ! rpm -q lame-devel >/dev/null 2>&1; then
        sudo dnf install -y lame-devel
    fi

    sudo dnf install -y \
        gcc gcc-c++ make nasm yasm pkgconf-pkg-config \
        wget curl tar xz git perl bzip2 gzip

    rm -rf "$src_dir"
    curl -L --fail \
        "https://www.ffmpeg.org/releases/ffmpeg-5.1.9.tar.gz" \
        -o "$tarball"
    tar -xzf "$tarball" -C /tmp

    cd "$src_dir"
    ./configure \
        --prefix="$prefix" \
        --disable-doc \
        --disable-debug \
        --enable-gpl \
        --enable-version3 \
        --enable-shared \
        --enable-libmp3lame \
        --extra-ldflags="-Wl,-rpath,$prefix/lib"

    make -j"$(nproc)"
    sudo make install

    sudo install -m 0755 "$ffmpeg_bin" /usr/local/bin/ffmpeg
    sudo install -m 0755 "$prefix/bin/ffprobe" /usr/local/bin/ffprobe

    sudo sh -c "echo '$prefix/lib' > /etc/ld.so.conf.d/ffmpeg-5.1.9.conf"
    sudo ldconfig

    actual="$("$ffmpeg_bin" -version 2>&1 | head -n 1)"
    echo "FFmpeg installed: $actual"

    if ! printf '%s\n' "$actual" | grep -Fq "ffmpeg version 5.1.9"; then
        echo "FFmpeg installation failed: expected 5.1.9 but got '$actual'" >&2
        exit 1
    fi
}

install_libjpeg_2_1_5_fedora() {
    echo "Installing libjpeg-turbo 2.1.5"

    src_dir="/tmp/libjpeg-turbo-2.1.5"
    tarball="/tmp/libjpeg-turbo-2.1.5.tar.gz"
    prefix="/usr/local/libjpeg-2.1.5"
    libdir="$prefix/lib64"

    if [ -x "$prefix/bin/cjpeg" ]; then
        actual="$("$prefix/bin/cjpeg" -version 2>&1 | head -n 1 || true)"
        if printf '%s\n' "$actual" | grep -Fq '2.1.5'; then
            echo "libjpeg-turbo 2.1.5 already installed; skipping rebuild"
            return 0
        fi
    fi

    sudo dnf install -y gcc make cmake curl tar xz gzip

    rm -rf "$src_dir" "$tarball"
    curl -L --fail \
        "https://downloads.sourceforge.net/libjpeg-turbo/2.1.5/libjpeg-turbo-2.1.5.tar.gz" \
        -o "$tarball"
    tar -xzf "$tarball" -C /tmp

    cmake -S "$src_dir" -B "$src_dir/build" \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -DCMAKE_INSTALL_PREFIX="$prefix" \
        -DENABLE_SHARED=ON \
        -DENABLE_STATIC=OFF \
        -DWITH_JPEG8=1 \
        -DWITH_TURBOJPEG=OFF

    cmake --build "$src_dir/build" -j"$(nproc)"
    sudo cmake --install "$src_dir/build"

    sudo ln -sfn "$libdir" "$prefix/lib"
    sudo sh -c "echo '$libdir' > /etc/ld.so.conf.d/libjpeg-2.1.5.conf"
    sudo ldconfig
}

install_libpng_1_6_39_fedora() {
    echo "Installing libpng 1.6.39"

    src_dir="/tmp/libpng-1.6.39"
    tarball="/tmp/libpng-1.6.39.tar.gz"
    prefix="/usr/local/libpng-1.6.39"

    if [ -x "$prefix/bin/pngfix" ]; then
        actual="$("$prefix/bin/pngfix" -V 2>&1 | head -n 1 || true)"
        if printf '%s\n' "$actual" | grep -Fq '1.6.39'; then
            echo "libpng 1.6.39 already installed; skipping rebuild"
            return 0
        fi
    fi

    sudo dnf install -y gcc make curl tar xz gzip zlib-devel

    rm -rf "$src_dir" "$tarball"
    curl -L --fail \
        "https://download.sourceforge.net/libpng/libpng-1.6.39.tar.gz" \
        -o "$tarball"
    tar -xzf "$tarball" -C /tmp

    cd "$src_dir"
    ./configure \
        --prefix="$prefix" \
        --enable-shared \
        --disable-static

    make -j"$(nproc)"
    sudo make install

    sudo sh -c "echo '$prefix/lib' > /etc/ld.so.conf.d/libpng-1.6.39.conf"
    sudo ldconfig
}

install_imagemagick_6_9_11_60_fedora() {
    echo "Installing ImageMagick 6.9.11-60 from source for Fedora"

    install_libjpeg_2_1_5_fedora
    install_libpng_1_6_39_fedora

    src_dir="/tmp/ImageMagick-6.9.11-60"
    tarball="/tmp/ImageMagick-6.9.11-60.tar.xz"
    prefix="/usr/local/imagemagick-6.9.11-60"
    convert_bin="$prefix/bin/convert"

    if [ -x "$convert_bin" ]; then
        actual="$("$convert_bin" -version 2>&1 | head -n 1 || true)"
        if printf '%s\n' "$actual" | grep -Fq "Version: ImageMagick 6.9.11-60"; then
            echo "ImageMagick 6.9.11-60 already installed; skipping rebuild"
            return 0
        fi
    fi

    sudo dnf install -y \
        gcc gcc-c++ make pkgconf-pkg-config \
        curl tar xz git perl bzip2 gzip \
        autoconf automake libtool libtool-ltdl-devel \
        libtiff-devel libwebp-devel libxml2-devel \
        freetype-devel fontconfig-devel \
        ghostscript-devel librsvg2-devel

    rm -rf "$src_dir"
    curl -L --fail \
        "https://download.imagemagick.org/archive/releases/ImageMagick-6.9.11-60.tar.xz" \
        -o "$tarball"
    tar -xJf "$tarball" -C /tmp

    cd "$src_dir"

    PKG_CONFIG_PATH="/usr/local/libjpeg-2.1.5/lib64/pkgconfig:/usr/local/libpng-1.6.39/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}" \
    CPPFLAGS="-I/usr/local/libjpeg-2.1.5/include -I/usr/local/libpng-1.6.39/include" \
    LDFLAGS="-L/usr/local/libjpeg-2.1.5/lib64 -L/usr/local/libpng-1.6.39/lib \
        -Wl,-rpath,/usr/local/libjpeg-2.1.5/lib64 \
        -Wl,-rpath,/usr/local/libpng-1.6.39/lib \
        -Wl,-rpath,$prefix/lib" \
    ./configure \
        --prefix="$prefix" \
        --disable-dependency-tracking \
        --with-modules \
        --without-perl \
        --without-magick-plus-plus

    make -j"$(nproc)"
    sudo make install

    sudo install -m 0755 "$convert_bin" /usr/local/bin/convert
    sudo install -m 0755 "$prefix/bin/mogrify" /usr/local/bin/mogrify
    sudo install -m 0755 "$prefix/bin/identify" /usr/local/bin/identify

    sudo sh -c "echo '$prefix/lib' > /etc/ld.so.conf.d/imagemagick-6.9.11-60.conf"
    sudo ldconfig

    actual="$("$convert_bin" -version 2>&1 | head -n 1)"
    echo "ImageMagick installed: $actual"

    if ! printf '%s\n' "$actual" | grep -Fq "Version: ImageMagick 6.9.11-60"; then
        echo "ImageMagick installation failed: expected 6.9.11-60 but got '$actual'" >&2
        exit 1
    fi

    if ! ldd "$convert_bin" | grep -Fq '/usr/local/libjpeg-2.1.5/'; then
        echo "ImageMagick is not linked against libjpeg-turbo 2.1.5" >&2
        exit 1
    fi

    if ! ldd "$convert_bin" | grep -Fq '/usr/local/libpng-1.6.39/'; then
        echo "ImageMagick is not linked against libpng 1.6.39" >&2
        exit 1
    fi
}

case "$OS" in
    debian)
        sudo apt-get update
        sudo apt-get install -y \
            sudo coreutils wget unzip gzip gawk sed git openssl curl \
            ffmpeg unrtf imagemagick zstd xz-utils
        ;;
    macos)
        # coreutils/gawk/sed come from the PATH shim (main.sh)
        brew install wget unzip gzip git openssl curl ffmpeg unrtf \
            imagemagick zstd xz
        ;;
    fedora)
        sudo dnf makecache
        sudo dnf install -y \
            sudo coreutils wget unzip gzip gawk sed git openssl curl \
            unrtf zstd xz

        install_imagemagick_6_9_11_60_fedora
        install_ffmpeg_5_1_9_fedora
        ;;
esac