#!/bin/bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Source existing variables
. $SCRIPT_DIR/vars
################################################################################
# if BOOT_DISK
#if [ "$BOOT_DISK" == "$USER_DISK" ]; then
#    echo "Strings are equal"
#else
#    echo "Strings are not equal"
#fi


echo "Destroying existing partitions"

sgdisk --zap-all ${BOOT_DISK}
partprobe ${BOOT_DISK}
sgdisk -p ${BOOT_DISK}

sgdisk --zap-all ${USER_DISK}
partprobe ${USER_DISK}
sgdisk -p ${USER_DISK}
################################################################################
echo "Creating the following partition scheme"

sgdisk --new=1:1M:1G ${BOOT_DISK}
sgdisk --typecode=1:EF00 ${BOOT_DISK}
sgdisk --change-name=1:efi ${BOOT_DISK}
sgdisk --new=2::-0 ${BOOT_DISK}
sgdisk --typecode=2:0700 ${BOOT_DISK}
sgdisk --change-name=2:data ${BOOT_DISK}
sgdisk -p ${BOOT_DISK}
echo "Partitions created, reloading table on ${BOOT_DISK}"
partprobe ${BOOT_DISK}

sgdisk --new=1:1M:-0 ${USER_DISK}
sgdisk --typecode=1:BF00 ${USER_DISK}
sgdisk --change-name=1:sys ${USER_DISK}
sgdisk -p ${USER_DISK}
echo "Partitions created, reloading table on ${USER_DISK}"
partprobe ${USER_DISK}
################################################################################
BOOT="${BOOT_DISK}-part1"
DATA="${BOOT_DISK}-part2"
BOOTDEV=$BOOT
DATADEV=$DATA
CRYPT="${USER_DISK}-part1"
CRYPTDEV=$CRYPT
BOOTUUID=$(blkid -o export $BOOTDEV | grep -E 'UUID' | cut -d'=' -f2)

echo "" >> $SCRIPT_DIR/vars
echo "CRYPTDEV=$CRYPTDEV" >> $SCRIPT_DIR/vars
echo "" >> $SCRIPT_DIR/vars
echo "BOOTDEV=$BOOTDEV" >> $SCRIPT_DIR/vars
echo "" >> $SCRIPT_DIR/vars

echo "Creating FAT32 FS on ${BOOTDEV}"
ls -l "${BOOTDEV}"
mkfs.vfat -F32 ${BOOTDEV}

echo "Creating FAT32 FS on ${DATADEV}"
ls -l "${DATADEV}"
mkfs.vfat -F32 ${DATADEV}
