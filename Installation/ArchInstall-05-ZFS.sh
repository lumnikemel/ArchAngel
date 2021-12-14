#!/bin/bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Source existing variables
. $SCRIPT_DIR/vars
################################################################################
### Load ZFS Module ###
curl -s https://eoli3n.github.io/archzfs/init | bash # Uses archzfs repo.
modprobe zfs

echo "Creating zroot pool"
zpool create -f zroot \
  -o ashift=13 \
  -o altroot=/mnt \
  -O compression=lz4 \
  -O xattr=sa \
  -O atime=off \
  -O acltype=posix \
  -O dedup=off \
  -O checksum=on \
  -O recordsize=128K \
  -m none $ZFSDISKDEV

echo >> $SCRIPT_DIR/vars
echo "SYS_ROOT=${SYS_ROOT=zroot/sys}" >> $SCRIPT_DIR/vars
echo >> $SCRIPT_DIR/vars

zfs create -o mountpoint=none -p ${SYS_ROOT}/${SYSTEM_NAME}
zfs create -o mountpoint=none    ${SYS_ROOT}/${SYSTEM_NAME}/ROOT
zfs create -o mountpoint=/       ${SYS_ROOT}/${SYSTEM_NAME}/ROOT/default
zpool set bootfs=${SYS_ROOT}/${SYSTEM_NAME}/ROOT/default zroot
zfs create -o mountpoint=legacy  ${SYS_ROOT}/${SYSTEM_NAME}/home

zfs create -V ${SWAPSIZE}G -b $(getconf PAGESIZE) -o logbias=throughput -o sync=always -o primarycache=metadata -o com.sun:auto-snapshot=false zroot/swap
mkswap -f /dev/zvol/zroot/swap

zfs create -o canmount=off -o mountpoint=/var -o xattr=sa ${SYS_ROOT}/${SYSTEM_NAME}/var
zfs create -o canmount=off -o mountpoint=/var/lib ${SYS_ROOT}/${SYSTEM_NAME}/var/lib
zfs create -o canmount=off -o mountpoint=/var/lib/systemd ${SYS_ROOT}/${SYSTEM_NAME}/var/lib/systemd
zfs create -o canmount=off -o mountpoint=/usr ${SYS_ROOT}/${SYSTEM_NAME}/usr

zfs create -o mountpoint=legacy ${SYS_ROOT}/${SYSTEM_NAME}/var/lib/systemd/coredump
zfs create -o mountpoint=legacy ${SYS_ROOT}/${SYSTEM_NAME}/var/log
zfs create -o mountpoint=legacy ${SYS_ROOT}/${SYSTEM_NAME}/var/lib/lxc
zfs create -o mountpoint=legacy ${SYS_ROOT}/${SYSTEM_NAME}/var/lib/lxd
zfs create -o mountpoint=legacy ${SYS_ROOT}/${SYSTEM_NAME}/var/lib/machines
zfs create -o mountpoint=legacy ${SYS_ROOT}/${SYSTEM_NAME}/var/lib/libvirt
zfs create -o mountpoint=legacy ${SYS_ROOT}/${SYSTEM_NAME}/var/cache
zfs create -o mountpoint=legacy ${SYS_ROOT}/${SYSTEM_NAME}/usr/local

zfs create -o mountpoint=legacy -o acltype=posixacl ${SYS_ROOT}/${SYSTEM_NAME}/var/log/journal

echo "Unmounting /mnt/boot to prevent mount corruption from unmounting zpool."
umount -l /mnt/boot

echo "All datasets created.... unmounting for installation"
zfs umount -a
zpool export zroot
