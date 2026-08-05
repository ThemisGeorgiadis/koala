#!/bin/sh

TOP=$(git rev-parse --show-toplevel)

OS=$("$TOP/.tools/detect-os.sh")

if [ "$OS" = "fedora" ]; then
    sudo dnf makecache
    sudo dnf install perl-Digest-SHA -y
fi