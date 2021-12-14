#!/bin/bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Source existing variables
. $SCRIPT_DIR/vars
################################################################################
echo "##### DONE #####"
#echo "##### IMPORTANT #####"
#echo "remember to 'umount /mnt/boot' and 'zfs umount -a' and 'zpool export zroot' OR"
#echo "cat unmount.txt | xargs unmount; zfs unmount -a; zpool export zroot"



echo "UNMOUNTING AND EXPORING POOL"
umount /mnt/boot
umount /mnt/usr/local
umount /mnt/var/cache
umount /mnt/home
umount /mnt/var/lib/systemd/coredump
umount /mnt/var/log/journal
umount /mnt/var/log
umount /mnt/var/lib/lxc
umount /mnt/var/lib/libvirt 
umount /mnt/var/lib/machines

zfs unmount -a
zpool export zroot

#cryptsetup luksOpen $CRYPTDEV luks_zfs

echo "Done, reboot into the new system! Waiting 5 seconds to reboot . . ."
sleep 5
echo "Rebooting now!!!"
sleep 1
reboot now
