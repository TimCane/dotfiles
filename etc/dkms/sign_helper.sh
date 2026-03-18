#!/bin/sh
# DKMS module signing helper for Secure Boot
# Signs kernel modules with the enrolled MOK key so they load under Secure Boot
KBUILD_DIR="/usr/lib/linux-kbuild-$(uname -r | cut -d. -f1-2)"
if [ ! -x "$KBUILD_DIR/scripts/sign-file" ]; then
    KBUILD_DIR="/usr/lib/linux-kbuild-$(uname -r | cut -d. -f1)"
fi
"$KBUILD_DIR/scripts/sign-file" sha256 \
    /var/lib/shim-signed/mok/MOK.priv \
    /var/lib/shim-signed/mok/MOK.der \
    "$2"
