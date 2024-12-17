## Set regional time:


ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime
hwclock --systohc


## Set keyboard mapping:


loadkeys us
localectl set-keymap --no-convert us


## Set language and locale:

sed -i -e 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
echo 'LANG=en_US.UTF-8' >> /etc/locale.conf
locale-gen


## Set hostname:

SYSTEM_NAME=testme
echo $SYSTEM_NAME > /etc/hostname


## Set hosts-file:


echo '127.0.0.1 localhost' > /etc/hosts
echo '::1       localhost' >> /etc/hosts
echo "127.0.0.1 ${SYSTEM_NAME}.localdomain ${SYSTEM_NAME}" >> /etc/hosts


## Set user:


USER=arch
USER_PASS=password

echo "Creating user $USER"
useradd -m -g users -G wheel,storage,power -s /bin/bash $USER
echo "Set password for $USER"
echo -e "${USER_PASS}\n${USER_PASS}" | passwd $USER


## Build EFI binary


mkinitcpio -p linux


## Exit chroot


exit
