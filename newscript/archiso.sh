#!/bin/bash

# These are example disk IDs that can be uncommented if you want to specify disks manually
#DISK1=/dev/disk/by-id/scsi-3600224802c58be3dd6d17e59deb06d6d
#DISK2=/dev/disk/by-id/scsi-360022480ce395636dfe850cadad70682

# SECTION 1: DISK DETECTION
# This section automatically finds two 8GB disks and assigns them to DISK1 and DISK2
i=1
while read -r byid; do
    # Get the size of each disk found
    size=$(lsblk -dn -o SIZE "$(readlink -f "$byid")" | tr -d ' ')
    # If the disk is 8GB, assign it to DISK1 or DISK2
    if [ "$size" = "8G" ]; then
        declare "DISK$i=$byid"
        ((i++))
    fi
done < <(find /dev/disk/by-id -name 'scsi*')

# Print the detected disk assignments for verification
for ((j=1; j<i; j++)); do
    eval "echo DISK$j=\$DISK$j"
done

echo "DISK1 is $DISK1"
echo "DISK2 is $DISK2"

# SECTION 2: CLEANUP
echo "Reset any mounts"
# Unmount any existing mounts to ensure clean slate
umount /mnt/boot
umount /mnt

echo "Remove any running RAID devices"
# Stop any existing RAID arrays
mdadm --stop --scan

echo "Destroying existing partitions"
# Clean both disks completely
#wipefs -a ${DISK1}  # Commented out for safety
sgdisk --zap-all ${DISK1}  # Remove all partitions and signatures
partprobe ${DISK1}         # Reload partition table
sgdisk -p ${DISK1}        # Print partition table to verify

#wipefs -a ${DISK2}
sgdisk --zap-all ${DISK2}
partprobe ${DISK2}
sgdisk -p ${DISK2}

# SECTION 3: PARTITION CREATION
echo "Creating the following partition scheme"
# Create partitions on DISK1:
# 1. EFI partition (1MB to 1GB)
sgdisk --new=1:1M:1G ${DISK1}
sgdisk --typecode=1:EF00 ${DISK1}  # Set type to EFI
sgdisk --change-name=1:efi ${DISK1}

# 2. Recovery partition (1GB to 2GB)
sgdisk --new=2::2G ${DISK1}
sgdisk --typecode=2:0700 ${DISK1}  # Set type to Microsoft basic data
sgdisk --change-name=2:recovery ${DISK1}

# 3. Data partition (remaining space)
sgdisk --new=3::-0 ${DISK1}
sgdisk --typecode=3:0700 ${DISK1}  # Set type to Microsoft basic data
sgdisk --change-name=3:data ${DISK1}

# Verify and reload partition table
sgdisk -p ${DISK1}
echo "Partitions created, reloading table on ${DISK1}"
partprobe ${DISK1}

# Copy partition scheme to DISK2
echo "Copy the partition table from ${DISK1} to ${DISK2}"
sgdisk --backup=table ${DISK1}
sgdisk --load-backup=table ${DISK2}
sgdisk -p ${DISK2}
echo "Partitions created, reloading table on ${DISK2}"
partprobe ${DISK2}

# SECTION 4: RAID CONFIGURATION
# Create RAID1 (mirror) for EFI partition
# Note: EFI partition uses metadata 1.0 for compatibility
mdadm --create --run --name=boot --metadata 1.0 --raid-devices=2 --level=1 /dev/md/boot ${DISK1}-part1 ${DISK2}-part1

# Create RAID1 for recovery partition
mdadm --create --run --name=recovery --raid-devices=2 --level=1 /dev/md/recovery ${DISK1}-part2 ${DISK2}-part2

# Create RAID0 (stripe) for data partition
mdadm --create --run --name=data --raid-devices=2 --level=0 /dev/md/data ${DISK1}-part3 ${DISK2}-part3

# Show RAID status
cat /proc/mdstat

# SECTION 5: FILESYSTEM CREATION
# Create filesystems on RAID arrays
mkfs.fat -F32 /dev/md/boot     # EFI partition needs FAT32
mkfs.fat -F32 /dev/md/recovery # Recovery partition as FAT32
mkfs.ext4 /dev/md/data         # Data partition as ext4

# Mount filesystems
mount /dev/md/data /mnt
mkdir /mnt/boot
mount /dev/md/boot /mnt/boot

# SECTION 6: SYSTEM INSTALLATION
# Install base system and essential packages
pacman -Sy
pacstrap /mnt base base-devel efibootmgr mkinitcpio intel-ucode git efitools wget openssh dhcpcd ntp sudo linux mdadm

# Save RAID configuration
mdadm --detail --scan >> /mnt/etc/mdadm.conf
# Generate fstab
genfstab -U -p /mnt >> /mnt/etc/fstab

# SECTION 7: BOOTLOADER INSTALLATION
# Manual systemd-boot installation (because automatic fails with RAID)
mkdir -p /mnt/boot/EFI/systemd
mkdir -p /mnt/boot/EFI/Boot

# Copy bootloader files
cp /mnt/usr/lib/systemd/boot/efi/systemd-bootx64.efi /mnt/boot/EFI/systemd/
cp /mnt/usr/lib/systemd/boot/efi/systemd-bootx64.efi /mnt/boot/EFI/Boot/bootx64.efi

# Create EFI boot entries for both disks
efibootmgr -c -d ${DISK1} -p 1 -L "Arch Linux 1" -l '\EFI\systemd\systemd-bootx64.efi'
efibootmgr -c -d ${DISK2} -p 1 -L "Arch Linux 2" -l '\EFI\systemd\systemd-bootx64.efi'

# Set boot order
echo "Set EFI boot-order"
BOOT_ORDER=$(efibootmgr -v | grep "Arch Linux" | sort -k2 | cut -c5-8 | tr '\n' ',' | sed 's/,$//')
echo $BOOT_ORDER
efibootmgr -o $BOOT_ORDER

# SECTION 8: BOOTLOADER CONFIGURATION
# Get UUID of RAID data partition for boot configuration
MDDATA=$(blkid -s UUID -o value /dev/md/data)

# Create bootloader configuration
mkdir -p /mnt/boot/loader/entries
cat <<EOF > /mnt/boot/loader/entries/arch.conf
title     Arch Linux
linux     /vmlinuz-linux
initrd    /initramfs-linux.img
options   root=UUID=${MDDATA} rw
EOF

cat /mnt/boot/loader/entries/arch.conf

# SECTION 9: SYSTEM CONFIGURATION
# Configure mkinitcpio hooks and modules
HOOKS="base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt usr mdadm_udev filesystems shutdown"
MODULES="vfat"

# Update mkinitcpio configuration
echo "/etc/mkinitcpio.conf HOOKS config..."
sed -i -e "s/^HOOKS=(.*$/HOOKS=(${HOOKS})/" /mnt/etc/mkinitcpio.conf
grep -E '^HOOKS=' /mnt/etc/mkinitcpio.conf

echo "/etc/mkinitcpio.conf MODULES config..."
sed -i -e "s/^MODULES=(.*$/MODULES=(${MODULES})/" /mnt/etc/mkinitcpio.conf
grep -E '^MODULES=' /mnt/etc/mkinitcpio.conf

# Set keyboard layout
echo "KEYMAP=us" > /mnt/etc/vconsole.conf

# Configure sudo access for wheel group
echo '%wheel ALL=(ALL) ALL' > /mnt/etc/sudoers.d/wheel

# Enter chroot environment to complete installation
arch-chroot /mnt /bin/bash
