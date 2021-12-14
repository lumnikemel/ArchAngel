#!/bin/bash
#SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SCRIPT_DIR=/root/ArchInstall

# Source existing variables
. $SCRIPT_DIR/vars
################################################################################
# Set regional time:
ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime
hwclock --systohc

# Set keyboard mapping:
loadkeys us
localectl set-keymap --no-convert us

# Set language and locale:
sed -i -e 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
echo 'LANG=en_US.UTF-8' >> /etc/locale.conf
locale-gen

# Create systemd-hook sd-zfs:
cd /tmp
wget https://aur.archlinux.org/cgit/aur.git/snapshot/mkinitcpio-sd-zfs.tar.gz
tar -xzf mkinitcpio-sd-zfs.tar.gz
chown nobody:nobody mkinitcpio-sd-zfs
cd mkinitcpio-sd-zfs
sudo -u nobody makepkg
pacman --noconfirm -U *.zst

# Install ZFS:
pacman-key -r F75D9D76
pacman-key --lsign-key F75D9D76
#pacman --noconfirm -Sy sudo vim wget curl
#pacman --noconfirm -Sy zfs-dkms # I couldn't get zfs-linux to install due to old linux version. Couldn't find a way to downgrade package. Will switch to zfs-linux after install.
pacman -Syy
pacman --noconfirm -Sy archzfs-linux

# Set hostname:
echo $SYSTEM_NAME > /etc/hostname

# Set hosts-file:
echo '127.0.0.1 localhost' > /etc/hosts
echo '::1       localhost' >> /etc/hosts
echo "127.0.0.1 ${SYSTEM_NAME}.localdomain ${SYSTEM_NAME}" >> /etc/hosts

# Set user:
echo "Creating user $USER"
useradd -m -g users -G wheel,storage,power -s /bin/bash $USER
echo "Set password for $USER"
echo -e "${USER_PASS}\n${USER_PASS}" | passwd $USER

zpool set cachefile=/etc/zfs/zpool.cache zroot
systemctl enable zfs.target
systemctl enable zfs-import-cache
systemctl enable zfs-mount
systemctl enable zfs-import.target
zgenhostid $(hostid)

# Build init-RAM-disk:
mkinitcpio -p linux

echo "Done with arch-chroot."
