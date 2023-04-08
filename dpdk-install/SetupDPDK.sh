#!/bin/bash

# Root user

# Install required packages
sudo apt-get install build-essential meson python3-pyelftools libnuma-dev pkgconf -y

# Get latest LTS DPDK release: http://core.dpdk.org/download/
wget https://fast.dpdk.org/rel/dpdk-21.11.2.tar.xz

tar xf dpdk-21.11.2.tar.xz

# Get into Directory
cd dpdk-stable-21.11.2/

# Build libraries, drivers and test applications.
meson -Dexamples=all build

# Ninja Build
ninja -C build

# Get into Build Directory 
cd build

# Install Dpdk related files
ninja install

# Configure
ldconfig

# DONE
