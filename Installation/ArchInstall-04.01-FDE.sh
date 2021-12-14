#!/bin/bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Source existing variables
. $SCRIPT_DIR/vars
################################################################################
echo "Mounting /boot to store LUKS headers for encryption"
mkdir -p /mnt/boot
mount $BOOTDEV /mnt/boot
