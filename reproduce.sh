#!/usr/bin/env bash

rm -f system.raw
rm -rf ./sysroot
mkdir -p sysroot
touch sysroot/hardlink-1
ln sysroot/hardlink-1 sysroot/hardlink-2
stat sysroot/hardlink-*

sudo SYSTEMD_LOG_LEVEL=debug systemd-repart --empty=allow  --empty=create --size=auto --dry-run=no --offline=yes \
    --definitions repart.d \
    --root sysroot \
    system.raw
sudo systemd-dissect --mtree system.raw
