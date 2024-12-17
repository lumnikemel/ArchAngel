#!/bin/bash

curl -s https://raw.githubusercontent.com/lumnikemel/ArchAngel/refs/heads/main/newscript/archiso.sh | bash
curl -s https://raw.githubusercontent.com/lumnikemel/ArchAngel/refs/heads/main/newscript/chroot.sh > /mnt/tmp/chroot.sh && arch-chroot /mnt /bin/bash /tmp/chroot.sh

# Reboot
umount /mnt/boot
umount /mnt

#reboot now

