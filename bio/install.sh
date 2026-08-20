#!/bin/sh

TOP=$(git rev-parse --show-toplevel)
OS=$("$TOP/.tools/detect-os.sh")

VENV_DIR="$TOP/venv"
. "$VENV_DIR/bin/activate"

size=full
for arg in "$@"; do
    case "$arg" in
    --small) size=small ;;
    --min) size=min ;;
    esac
done

case "$OS" in
    debian)
        sudo apt-get update
        pkgs="build-essential libncurses5-dev libncursesw5-dev libbz2-dev liblzma-dev libcurl4-openssl-dev libssl-dev wget zlib1g-dev minimap2 samtools"

        for pkg in $pkgs; do
            if ! dpkg -s "$pkg" >/dev/null 2>&1; then
                sudo apt-get install -y --no-install-recommends "$pkg"
            fi
        done
        ;;
    macos)
        # ncurses/bzip2/xz/zlib headers ship with the Xcode SDK; libcurl ships
        # with the OS. minimap2/samtools have direct brew formulae.
        if ! xcode-select -p >/dev/null 2>&1; then
            echo "Xcode Command Line Tools required: run 'xcode-select --install' first." >&2
            exit 1
        fi
        brew install wget minimap2 samtools
        ;;
    fedora)
        sudo dnf makecache
        pkgs="gcc gcc-c++ make ncurses-devel bzip2-devel xz-devel libcurl-devel openssl-devel wget zlib-ng-compat-devel perl-Digest-SHA"

        for pkg in $pkgs; do
            if ! rpm -q "$pkg" >/dev/null 2>&1; then
                sudo dnf install -y "$pkg"
            fi
        done
        ;;
esac

if [ "$size" = "min" ]; then
    exit 0
fi

# For teraseq
benchmark_dir="${TOP}/bio"

# install.sh: Installs system-wide dependencies for the TERA-Seq pipeline

# 1. Install OS packages
case "$OS" in
    debian)
        pkgs="build-essential git wget curl python3 python3-dev perl cpanminus libdbi-perl zlib1g-dev libbz2-dev libdeflate-dev liblzma-dev libcurl4-openssl-dev openjdk-17-jdk default-jre-headless r-base r-base-dev gradle cmake make gcc g++ gffread gmap parallel"

        for pkg in $pkgs; do
            if ! dpkg -s "$pkg" >/dev/null 2>&1; then
                sudo apt-get install -y --no-install-recommends "$pkg"
            fi
        done

        sudo wget -qO /usr/local/bin/liftOver http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/liftOver
        sudo chmod +x /usr/local/bin/liftOver

        export CFLAGS="-I/usr/include/python3.11 -I/usr/include/python3.11/cpython"
        export CPPFLAGS="$CFLAGS"
        ;;
    macos)
        # libdbi-perl has no brew formula; installed via cpanm in section 6
        # below. seqkit/rna-star are added here (brew formulae exist) so the
        # Linux-binary fallbacks in sections 3 and 4 no-op via their existing
        # `command -v` checks.
        brew install git wget curl python3 perl cpanminus openjdk@17 r gradle cmake \
            gffread parallel seqkit rna-star

        # liftOver: UCSC also publishes macOS binaries, at a different path
        # per architecture than the Linux one the debian branch uses above.
        if [ "$(uname -m)" = "arm64" ]; then
            liftover_url="http://hgdownload.cse.ucsc.edu/admin/exe/macOSX.arm64/liftOver"
        else
            liftover_url="http://hgdownload.cse.ucsc.edu/admin/exe/macOSX.x86_64/liftOver"
        fi
        sudo wget -qO /usr/local/bin/liftOver "$liftover_url"
        sudo chmod +x /usr/local/bin/liftOver

        # gmap/gmap_build: no brew formula, built from source same as the
        # nanopolish fallback in section 5 below.
        if ! command -v gmap >/dev/null 2>&1; then
            gmap_tmp=$(mktemp -d)
            curl -L http://research-pub.gene.com/gmap/src/gmap-gsnap-2025-07-31.v2.tar.gz \
                -o "$gmap_tmp/gmap.tar.gz" \
            && tar -xzf "$gmap_tmp/gmap.tar.gz" -C "$gmap_tmp" \
            && gmap_srcdir=$(find "$gmap_tmp" -maxdepth 1 -type d -name 'gmap-gsnap-*') \
            && cd "$gmap_srcdir" \
            && ./configure \
            && make -j"$(sysctl -n hw.ncpu)" \
            && sudo make install \
            && cd - >/dev/null || exit 1
            rm -rf "$gmap_tmp"
        fi

        # Prebuilt macOS wheels exist for this pipeline's Python packages, so
        # the explicit Python-header CFLAGS the debian branch needs aren't.
        ;;
    fedora)
        pkgs="gcc gcc-c++ make git wget curl python3 python3-devel python3-pip perl perl-App-cpanminus perl-DBI libdeflate-devel zlib-ng-compat-devel bzip2-devel xz-devel libcurl-devel openssl-devel ncurses-devel openjdk-17-devel R R-devel gradle cmake gffread gmap parallel unzip"

        for pkg in $pkgs; do
            if ! rpm -q "$pkg" >/dev/null 2>&1; then
                sudo dnf install -y "$pkg"
            fi
        done

        sudo wget -qO /usr/local/bin/liftOver http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/liftOver
        sudo chmod +x /usr/local/bin/liftOver

        export CFLAGS="-I/usr/include/python3 -I/usr/include/python3/cpython"
        export CPPFLAGS="$CFLAGS"
        ;;
esac

# 2. Install Python packages
# Pin versions to match the working container for reproducible output
pip3 install --no-cache-dir --break-system-packages \
    cutadapt \
    pysam==0.24.0 \
    numpy \
    pandas==3.0.5 \
    matplotlib==3.11.1 \
    seaborn==0.13.2 \
    deeptools==3.5.0 \
    ont-fast5-api==3.3.0 \
    h5py==3.14.0

# 3. Install bioinformatics binaries
# Ensure /usr/local/bin takes precedence over stale distro binaries
export PATH="/usr/local/bin:/usr/local/sbin:$PATH"

# Use exact versions from the working container to match reference hashes
SAMTOOLS_VERSION="${SAMTOOLS_VERSION:-1.16.1}"
MINIMAP2_VERSION="${MINIMAP2_VERSION:-r1122}"
SEQKIT_VERSION="${SEQKIT_VERSION:-v2.1.0}"
STAR_VERSION="${STAR_VERSION:-2.7.11b}"
NPROC=$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)

## samtools - install exact release version with sudo to ensure it replaces distro version
if ! command -v samtools >/dev/null 2>&1 \
    || ! samtools --version 2>&1 | grep -q "$SAMTOOLS_VERSION" \
    || ! samtools --version 2>&1 | grep -q 'libdeflate=yes'; then
    rm -rf "/tmp/samtools-${SAMTOOLS_VERSION}" /tmp/samtools.tar.bz2
    curl -L "https://github.com/samtools/samtools/releases/download/${SAMTOOLS_VERSION}/samtools-${SAMTOOLS_VERSION}.tar.bz2" \
        -o /tmp/samtools.tar.bz2
    tar -xjf /tmp/samtools.tar.bz2 -C /tmp
    cd "/tmp/samtools-${SAMTOOLS_VERSION}" || exit 1
    ./configure --prefix=/usr/local
    make -j"$NPROC"
    sudo make install
    cd / || exit 1
    rm -rf "/tmp/samtools-${SAMTOOLS_VERSION}" /tmp/samtools.tar.bz2
fi

## minimap2 - use exact tag from working container
if ! command -v minimap2 >/dev/null 2>&1 || ! minimap2 --version 2>&1 | grep -q "$MINIMAP2_VERSION"; then
    git clone --depth 1  https://github.com/lh3/minimap2.git /tmp/minimap2 \
    && cd /tmp/minimap2 \
    && make -j"$NPROC" \
    && sudo install -m 0755 minimap2 /usr/local/bin/minimap2 \
    && sudo install -m 0755 ./*.py /usr/local/bin/ 2>/dev/null || true \
    && cd / && rm -rf /tmp/minimap2
fi

## seqkit - use exact version
if ! command -v seqkit >/dev/null 2>&1 || ! seqkit version 2>&1 | grep -q "$SEQKIT_VERSION"; then
  curl -L "https://github.com/shenwei356/seqkit/releases/download/${SEQKIT_VERSION}/seqkit_linux_amd64.tar.gz" \
    -o /tmp/seqkit.tar.gz \
  && tar -xzf /tmp/seqkit.tar.gz -C /tmp seqkit --no-same-owner \
  && sudo install -m 0755 /tmp/seqkit /usr/local/bin/seqkit \
  && rm /tmp/seqkit.tar.gz /tmp/seqkit
fi

## STAR - use exact version
if ! command -v STAR >/dev/null 2>&1 || ! STAR --version 2>&1 | grep -q "$STAR_VERSION"; then
  tmpdir=$(mktemp -d)
  wget -qO "$tmpdir/STAR_${STAR_VERSION}.zip" \
    "https://github.com/alexdobin/STAR/releases/download/${STAR_VERSION}/STAR_${STAR_VERSION}.zip"

  unzip -q "$tmpdir/STAR_${STAR_VERSION}.zip" -d "$tmpdir"

  sudo install -m 0755 \
    "$tmpdir/STAR_${STAR_VERSION}/Linux_x86_64_static/STAR" \
    /usr/local/bin/STAR

  rm -rf "$tmpdir"
fi

# # 4. Install Jvarkit
# if [ ! -f /usr/local/bin/jvarkit.jar ]; then
#     git clone https://github.com/lindenb/jvarkit.git /tmp/jvarkit \
#     && cd /tmp/jvarkit \
#     && git checkout 014d3e9 \
#     && ./gradlew biostar84452 \
#     && cp dist/biostar84452.jar /usr/local/bin/jvarkit.jar \
#     && cd / && rm -rf /tmp/jvarkit;
# fi

# 5. Install Nanopolish
if [ ! -f /usr/local/bin/nanopolish ]; then
    git clone --recursive https://github.com/jts/nanopolish.git /tmp/nanopolish \
    && cd /tmp/nanopolish \
    && git checkout 480fc85 \
    && make -j"$NPROC" \
    && cp nanopolish /usr/local/bin/ \
    && cd / && rm -rf /tmp/nanopolish;
fi

# 6. Install Perl modules (system-wide)
# Using cpanminus (cpanm)
cpanm --notest \
    inc::Module::Install@1.19 \
    autodie@2.29 \
    Modern::Perl@1.20190601 \
    Getopt::Long::Descriptive@0.104 \
    Params::Validate@1.29 \
    Params::Util@1.07 \
    Sub::Install@0.928 \
    Devel::Size@0.83 \
    IO::File@1.39 \
    IO::Interactive@1.022 \
    IO::Uncompress::Gunzip \
    DBI@1.642 \
    MooseX::App::Simple@1.41 \
    MooseX::App::Command \
    MooseX::Getopt::Meta::Attribute::Trait::NoGetopt@0.74

cpanm --notest --force \
    GenOO@1.5.2 \
    CLIPSeqTools@0.1.9

# Manually install GenOOx from TeRA-Seq
tmpdir=$(mktemp -d) || { echo "Failed to create tempdir"; exit 1; }
git clone --depth 1 https://github.com/mourelatos-lab/TERA-Seq_manuscript.git "$tmpdir"
perldir=$(perl -MConfig -e 'print $Config{installsitelib}')
cp -r "$tmpdir"/misc/GenOOx "$perldir"
rm -rf "$tmpdir"

# 7. Install R packages
Rscript -e 'install.packages(c(
    "DBI",
    "RSQLite",
    "dplyr",
    "stringr",
    "optparse",
    "longitudinal",
    "fdrtool",
    "ggplot2",
    "reshape2"
  ), repos="https://cloud.r-project.org")'
Rscript -e 'install.packages("https://cran.r-project.org/src/contrib/Archive/GeneCycle/GeneCycle_1.1.5.tar.gz", repos=NULL, type="source")'

# 8. Install sam_to_sqlite and annotate-sqlite-with-fastq
# Assuming these scripts are in tools/utils
cd "${benchmark_dir}" || exit 1
chmod +x utils/*

# Cleanup
case "$OS" in
    debian)
        apt-get clean && rm -rf /var/lib/apt/lists/ /tmp/*
        ;;
    fedora)
        dnf clean all && rm -rf /var/cache/dnf/ /tmp/*
        ;;
esac