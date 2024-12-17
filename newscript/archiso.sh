#DISK1=/dev/disk/by-id/scsi-3600224802c58be3dd6d17e59deb06d6d
#DISK2=/dev/disk/by-id/scsi-360022480ce395636dfe850cadad70682

i=1
while read -r byid; do
    size=$(lsblk -dn -o SIZE "$(readlink -f "$byid")" | tr -d ' ')
    if [ "$size" = "8G" ]; then
        declare "DISK$i=$byid"
        ((i++))
    fi
done < <(find /dev/disk/by-id -name 'scsi*')

# Print the results to verify
for ((j=1; j<i; j++)); do
    eval "echo DISK$j=\$DISK$j"
done

echo DISK1 is $DISK1
echo DISK2 is $DISK2

echo "Reset any mounts"
umount /mnt/boot
umount /mnt

echo "Remove any running RAID devices"
mdadm --stop --scan

echo "Destroying existing partitions"

#wipefs -a ${DISK1}
sgdisk --zap-all ${DISK1}
partprobe ${DISK1}
sgdisk -p ${DISK1}

#wipefs -a ${DISK2}
sgdisk --zap-all ${DISK2}
partprobe ${DISK2}
sgdisk -p ${DISK2}
################################################################################
echo "Creating the following partition scheme"

sgdisk --new=1:1M:1G ${DISK1}
sgdisk --typecode=1:EF00 ${DISK1}
sgdisk --change-name=1:efi ${DISK1}
sgdisk --new=2::2G ${DISK1}
sgdisk --typecode=2:0700 ${DISK1}
sgdisk --change-name=2:recovery ${DISK1}
sgdisk --new=3::-0 ${DISK1}
sgdisk --typecode=3:0700 ${DISK1}
sgdisk --change-name=3:data ${DISK1}
sgdisk -p ${DISK1}
echo "Partitions created, reloading table on ${DISK1}"
partprobe ${DISK1}

echo "Copy the partition table from ${DISK1} to ${DISK2}"
sgdisk --backup=table ${DISK1}
sgdisk --load-backup=table ${DISK2}
sgdisk -p ${DISK2}
echo "Partitions created, reloading table on ${DISK2}"
partprobe ${DISK2}

################################################################################
################################################################################
################################################################################

#BOOT="${BOOT_DISK}-part1"
#DATA="${BOOT_DISK}-part2"
#BOOTDEV=$BOOT
#DATADEV=$DATA
#CRYPT="${USER_DISK}-part1"
#CRYPTDEV=$CRYPT
#BOOTUUID=$(blkid -o export $BOOTDEV | grep -E 'UUID' | cut -d'=' -f2)
#
#echo "" >> $SCRIPT_DIR/vars
#echo "CRYPTDEV=$CRYPTDEV" >> $SCRIPT_DIR/vars
#echo "" >> $SCRIPT_DIR/vars
#echo "BOOTDEV=$BOOTDEV" >> $SCRIPT_DIR/vars
#echo "" >> $SCRIPT_DIR/vars
#
#echo "Creating FAT32 FS on ${BOOTDEV}"
#ls -l "${BOOTDEV}"
#mkfs.vfat -F32 ${BOOTDEV}
#
#echo "Creating FAT32 FS on ${DATADEV}"
#ls -l "${DATADEV}"
#mkfs.vfat -F32 ${DATADEV}


# Setup RAID1 (mirror) across EFI partitions


# Create EFI RAID1 device
# The EFI boot partition must be created using an older version of the mdadm metadata.
mdadm --create --run --name=boot --metadata 1.0 --raid-devices=2 --level=1 /dev/md/boot ${DISK1}-part1 ${DISK2}-part1

#mdadm --create --run --name=boot --metadata 0.9 --raid-devices=2 --level=1 /dev/md/boot ${DISK1}-part1 ${DISK2}-part1

# Create Recovery RAID1 device
mdadm --create --run --name=recovery --raid-devices=2 --level=1 /dev/md/recovery ${DISK1}-part2 ${DISK2}-part2

# Create Data RAID0 device
mdadm --create --run --name=data --raid-devices=2 --level=0 /dev/md/data ${DISK1}-part3 ${DISK2}-part3

cat /proc/mdstat

  


mkfs.fat -F32 /dev/md/boot
mkfs.fat -F32 /dev/md/recovery
mkfs.ext4 /dev/md/data

  

mount /dev/md/data /mnt
mkdir /mnt/boot
mount /dev/md/boot /mnt/boot


## Install base packages

pacman -Sy
pacstrap /mnt base base-devel efibootmgr mkinitcpio intel-ucode git efitools wget openssh dhcpcd ntp sudo linux mdadm



mdadm --detail --scan >> /mnt/etc/mdadm.conf
genfstab -U -p /mnt >> /mnt/etc/fstab


## Install systemd-boot


# bootctl --path=/mnt/boot install # Fails due to RAID-device, Instead, install by hand

mkdir -p /mnt/boot/EFI/systemd
mkdir -p /mnt/boot/EFI/Boot

cp /mnt/usr/lib/systemd/boot/efi/systemd-bootx64.efi /mnt/boot/EFI/systemd/
cp /mnt/usr/lib/systemd/boot/efi/systemd-bootx64.efi /mnt/boot/EFI/Boot/bootx64.efi

efibootmgr -c -d ${DISK1} -p 1 -L "Arch Linux 1" -l '\EFI\systemd\systemd-bootx64.efi'
efibootmgr -c -d ${DISK2} -p 1 -L "Arch Linux 2" -l '\EFI\systemd\systemd-bootx64.efi'

echo "Set EFI boot-order"
BOOT_ORDER=$(efibootmgr -v | grep "Arch Linux" | sort -k2 | cut -c5-8 | tr '\n' ',' | sed 's/,$//')
echo $BOOT_ORDER
efibootmgr -o $BOOT_ORDER



## Configure bootloader - option RAID
MDDATA=$(blkid -s UUID -o value /dev/md/data)

mkdir -p /mnt/boot/loader/entries
cat <<EOF > /mnt/boot/loader/entries/arch.conf
title     Arch Linux
linux     /vmlinuz-linux
initrd    /initramfs-linux.img
options   root=UUID=${MDDATA} rw
EOF

cat /mnt/boot/loader/entries/arch.conf


# Configure mkinitcpio


#HOOKS="base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt sd-zfs usr mdadm_udev filesystems shutdown"
HOOKS="base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt usr mdadm_udev filesystems shutdown"
MODULES="vfat"

#sed -i 's/^HOOKS=.*$/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block mdadm_udev filesystems fsck)/' /mnt/etc/mkinitcpio.conf

echo "/etc/mkinitcpio.conf HOOKS config..."
sed -i -e "s/^HOOKS=(.*$/HOOKS=(${HOOKS})/" /mnt/etc/mkinitcpio.conf
grep -E '^HOOKS=' /mnt/etc/mkinitcpio.conf

echo "/etc/mkinitcpio.conf MODULES config..."
sed -i -e "s/^MODULES=(.*$/MODULES=(${MODULES})/" /mnt/etc/mkinitcpio.conf
grep -E '^MODULES=' /mnt/etc/mkinitcpio.conf


# Set Keymap


echo "KEYMAP=us" > /mnt/etc/vconsole.conf


# Set wheel group in sudoers


echo '%wheel ALL=(ALL) ALL' > /mnt/etc/sudoers.d/wheel


# chroot


arch-chroot /mnt /bin/bash
