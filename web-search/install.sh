#!/bin/sh

TOP=$(git rev-parse --show-toplevel)
OS=$("$TOP/.tools/detect-os.sh")

case "$OS" in
    debian)
        pkgs="p7zip-full curl wget unzip"

        sudo apt-get update
        for pkg in $pkgs; do
          if ! dpkg -s "$pkg" > /dev/null 2>&1 ; then
            sudo apt-get install -y --no-install-recommends "$pkg"
          fi
        done

        # Install pandoc if not installed
        if ! dpkg -s pandoc > /dev/null 2>&1 ; then
          # since pandoc v.2.2.1 does not support arm64, we use v.3.5
          arch=$(dpkg --print-architecture)
          wget https://github.com/jgm/pandoc/releases/download/3.5/pandoc-3.5-1-"${arch}".deb
          sudo dpkg -i pandoc-3.5-1-"${arch}".deb || sudo apt-get install -f -y --no-install-recommends
          rm pandoc-3.5-1-"${arch}".deb
        fi

        # Install Node.js (18.x) and npm via NodeSource
        NODE_MAJOR=18

        node_major=""
        if command -v node > /dev/null 2>&1 ; then
          node_major=$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || true)
        fi

        if [ "$node_major" != "$NODE_MAJOR" ]; then
          curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

          # Remove an existing Node.js installation if it is not Node.js 18.x
          if dpkg -s nodejs > /dev/null 2>&1 ; then
            sudo apt-get remove -y nodejs
          fi

          sudo apt-get install -y --no-install-recommends nodejs
        fi

        # Verify node and npm installation
        if ! command -v node > /dev/null 2>&1 ; then
          echo "Node.js installation failed."
          exit 1
        fi

        node_major=$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || true)

        if [ "$node_major" != "$NODE_MAJOR" ]; then
          echo "Node.js 18.x installation failed."
          echo "Found: $(node --version)"
          exit 1
        fi
        ;;
    macos)
        # brew's node formula bundles npm; pandoc and p7zip are direct formulae,
        # no arch-specific download dance needed the way the .deb release requires.
        brew install p7zip curl wget unzip node pandoc

        if ! command -v node > /dev/null 2>&1 ; then
          echo "Node.js installation failed."
          exit 1
        fi
        ;;
    fedora)
        pkgs="p7zip curl wget unzip"

        sudo dnf makecache
        for pkg in $pkgs; do
          if ! rpm -q "$pkg" > /dev/null 2>&1 ; then
            sudo dnf install -y "$pkg"
          fi
        done

        # Install pandoc if not installed
        if ! command -v pandoc > /dev/null 2>&1 ; then
          sudo dnf install -y pandoc
        fi

        # Install Node.js (18.x) and npm via NodeSource
        NODE_MAJOR=18

        node_major=""
        if command -v node > /dev/null 2>&1 ; then
          node_major=$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || true)
        fi

        if [ "$node_major" != "$NODE_MAJOR" ]; then
          curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -

          # Fedora may split Node.js into packages such as
          # nodejs24-bin and nodejs24-npm-bin.
          # Remove existing Node.js packages before installing NodeSource 18.
          sudo dnf remove -y 'nodejs*' 2>/dev/null || true

          sudo dnf install -y nodejs
        fi

        # Verify node and npm installation
        if ! command -v node > /dev/null 2>&1 ; then
          echo "Node.js installation failed."
          exit 1
        fi

        node_major=$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || true)

        if [ "$node_major" != "$NODE_MAJOR" ]; then
          echo "Node.js 18.x installation failed."
          echo "Found: $(node --version)"
          exit 1
        fi

        if ! command -v npm > /dev/null 2>&1 ; then
          echo "npm installation failed."
          exit 1
        fi
        ;;
esac

cd "$(dirname "$0")/scripts" || exit 1

rm -rf node_modules package-lock.json

npm install --save-exact \
  html-to-text@9.0.5 \
  jsdom@15.2.1 \
  natural@5.2.0 \
  afinn-165@1.0.2

cd - || exit 1