#!/bin/bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Source existing variables
. $SCRIPT_DIR/vars
################################################################################
echo "############# LUKS Setup ##############"

echo "Using $CRYPTDEV as LUKS partition"

modprobe dm-crypt
modprobe dm-mod

truncate -s 128M /mnt/boot/cryptheader.img
echo -e -n "${CRYPT_PASS}" | cryptsetup luksFormat -q -v --cipher aes-xts-plain64 -s 512 -h sha512 --iter-time 3000 --use-random --header /mnt/boot/cryptheader.img $CRYPTDEV # -q prevents confirmation prompt.

echo "Mounting $CRYPTDEV... you will need to enter the passphrase again"
echo -e -n "${CRYPT_PASS}" | cryptsetup luksOpen $CRYPTDEV --header /mnt/boot/cryptheader.img luks_zfs

echo "ZFSDISK=${ZFSDISK=$(ls /dev/disk/by-id | grep CRYPT)}" >> vars # Gets the open LUKS-encrypted drive.
echo "ZFSDISKDEV=${ZFSDISKDEV=/dev/disk/by-id/$ZFSDISK}" >> vars # Sets the full-path to the LUKS-encrypted drive.

