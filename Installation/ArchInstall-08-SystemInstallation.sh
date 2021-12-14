#!/bin/bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Source existing variables
. $SCRIPT_DIR/vars
################################################################################
echo "#################### INSTALLATION #########################"
mount -o remount,size=2G /run/archiso/cowspace

pacman -Sy
pacstrap /mnt base base-devel efibootmgr mkinitcpio intel-ucode git efitools wget openssh dhcpcd ntp sudo # Note: if the HDD is small, this might need to be done in a couple of commands of Pacman will complain.
#linux linux-firmware linux-headers
#vim python pacman-contrib

echo "Installing systemd-boot"
bootctl --path=/mnt/boot install

#CRYPTUUID=$(blkid -o export $CRYPTDEV | grep -E '^UUID' | cut -d'=' -f2) # Too strict, not used with partitions.
#BOOTUUID=$(blkid -o export $BOOTDEV | grep -E '^UUID' | cut -d'=' -f2) # Too strict, not used with partitions.
#CRYPTUUID=$(blkid -o export $CRYPTDEV | grep -E 'UUID' | cut -d'=' -f2) # Used with attached headers
CRYPTUUID=$(blkid -s UUID -o value /mnt/boot/cryptheader.img) # Used with detached headers
BOOTUUID=$(blkid -o export $BOOTDEV | grep -E '^UUID' | cut -d'=' -f2)
# rd.luks.name=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX=enc
# rd.luks.name=${CRYPTUUID}=luks_zfs

# rd.luks.options=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX=header=/header.img:UUID=ZZZZZZZZ-ZZZZ-ZZZZ-ZZZZ-ZZZZZZZZZZZZ
# rd.luks.options=${CRYPTUUID}=header=/cryptheader.img:UUID=$BOOTUUID

# When using a detached LUKS header, specify the block device with the encrypted data
# rd.luks.data=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX=/dev/disk/by-id/your-disk_id
# rd.luks.data=${CRYPTUUID}=${CRYPTDEV}

mkdir -p /mnt/boot/loader/entries
cat <<EOF > /mnt/boot/loader/entries/arch.conf
title     Arch Linux
linux     /vmlinuz-linux
initrd    /initramfs-linux.img
options   rd.luks.name=${CRYPTUUID}=luks_zfs rd.luks.options=${CRYPTUUID}=header=/cryptheader.img:UUID=$BOOTUUID,timeout=20s,cipher=aes-xts-plain64:sha512,size=512 rd.luks.data=${CRYPTUUID}=${CRYPTDEV} root=zfs:zroot/sys/${SYSTEM_NAME}/ROOT/default rw
EOF
#options   rd.luks.uuid=${CRYPTUUID} rd.luks.name=${CRYPTUUID}=luks_zfs rd.luks.options=${CRYPTUUID}=header=/cryptheader.img:UUID=$BOOTUUID,timeout=20s,cipher=aes-xts-plain64:sha512,size=512 root=zfs:zroot/sys/${SYSTEM_NAME}/ROOT/default rw


#echo "Configuring/generating setup scripts (/mnt/chroot_install.sh /mnt/post_install.sh)"
cat << 'EOF' >> /mnt/etc/pacman.conf
[archzfs]
Server = http://archzfs.com/$repo/x86_64
EOF
################################################################################
HOOKS="base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt sd-zfs usr filesystems shutdown"
MODULES="vfat"

echo "/etc/mkinitcpio.conf HOOKS config..."
sed -i -e "s/^HOOKS=(.*$/HOOKS=(${HOOKS})/" /mnt/etc/mkinitcpio.conf
grep -E '^HOOKS=' /mnt/etc/mkinitcpio.conf

echo "/etc/mkinitcpio.conf MODULES config..."
sed -i -e "s/^MODULES=(.*$/MODULES=(${MODULES})/" /mnt/etc/mkinitcpio.conf
grep -E '^MODULES=' /mnt/etc/mkinitcpio.conf

echo '%wheel ALL=(ALL) ALL' > /mnt/etc/sudoers.d/wheel

# Copy ArchInstall to /mnt/root so that installation can continue:
cp -r $SCRIPT_DIR /mnt/root
