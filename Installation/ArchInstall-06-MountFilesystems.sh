#!/bin/bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Source existing variables
. $SCRIPT_DIR/vars
################################################################################
echo "Importing zpool"
zpool import -d $ZFSDISKDEV -R /mnt zroot

mkdir -p /etc/zfs
mkdir -p /mnt/etc/zfs
zpool set cachefile=/etc/zfs/zpool.cache zroot
cp /etc/zfs/zpool.cache /mnt/etc/zfs/zpool.cache
#ln -s /mnt/etc/zfs/zpool.cache /etc/zfs/zpool.cache

echo "Mounting /mnt/boot."
mkdir -p /mnt/boot
mount $BOOTDEV /mnt/boot

mkdir -p /mnt/home;  mount -t zfs ${SYS_ROOT}/${SYSTEM_NAME}/home /mnt/home
mkdir -p /mnt/var/lib/systemd/coredump;  mount -t zfs ${SYS_ROOT}/${SYSTEM_NAME}/var/lib/systemd/coredump /mnt/var/lib/systemd/coredump
mkdir -p /mnt/var/log;  mount -t zfs ${SYS_ROOT}/${SYSTEM_NAME}/var/log /mnt/var/log
mkdir -p /mnt/var/log/journal;  mount -t zfs ${SYS_ROOT}/${SYSTEM_NAME}/var/log/journal /mnt/var/log/journal
mkdir -p /mnt/var/lib/lxc;  mount -t zfs ${SYS_ROOT}/${SYSTEM_NAME}/var/lib/lxc /mnt/var/lib/lxc
mkdir -p /mnt/var/lib/machines;  mount -t zfs ${SYS_ROOT}/${SYSTEM_NAME}/var/lib/machines /mnt/var/lib/machines
mkdir -p /mnt/var/lib/libvirt;  mount -t zfs ${SYS_ROOT}/${SYSTEM_NAME}/var/lib/libvirt /mnt/var/lib/libvirt
mkdir -p /mnt/var/cache;  mount -t zfs ${SYS_ROOT}/${SYSTEM_NAME}/var/cache /mnt/var/cache
mkdir -p /mnt/usr/local;  mount -t zfs ${SYS_ROOT}/${SYSTEM_NAME}/usr/local /mnt/usr/local

genfstab -U -p /mnt >> /mnt/etc/fstab
echo "/dev/zvol/zroot/swap none swap discard 0 0" >> /mnt/etc/fstab
