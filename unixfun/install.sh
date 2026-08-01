#!/bin/bash

source /etc/os-release

if [[ "$ID" == "fedora" ]]; then
    sudo dnf update
	sudo dnf install perl-Digest-SHA -y 
fi