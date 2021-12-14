# README

This script EXPECTS different devices for BOOT and USER drives!

This script will create an Arch Linux installation with the following characteristics:
- [x] UEFI.
- [x] Separate device for EFI and BOOT.
- [x] Full-Disk Encryption (FDE) via dmcrypt and LUKS2.
- [ ] Change from encrypting partition to feeding in full disk.
- [ ] dmcrypt and LUKS follow best-practices.
- [x] LUKS Header is detached and stored on separate BOOT device.
- [ ] Unlocking the FDE using 2-factor authentication with a YubiKey.
- [x] Systemd-Boot.
- [x] ZFS filesystem.
- [ ] Root-on-ZFS with best-practices.
- [x] Swap on ZFS.
- [ ] Multi-root booting using zedfs with ZFS.
- [ ] AUR installer using yay.
- [ ] Secure-Boot w/ TPM.


Further, the installation is designed to be as secure as possible while maintaining user-friendliness.
- KVM
- Docker
- Secure Browsers using KVM and/or Docker.

When fully setup, the only thing the host-system uses the network for is updates and NTP.

# Quick Start
## Run these commands at the ArchIso console:

# Initial setup required from PC/VM console:
# Set password
echo -e "password\npassword" | sudo -S passwd
# Start sshd
sudo systemctl start sshd

`DISKS=$(ls -la /dev/disk/by-id | grep "../" | cut -f 11-13 -d " ")`

`IPADDRESS=$(ip a | grep "inet " | grep -v host | cut -f 6 -d " " | cut -f 1 -d "/")`

echo "\nAvailable disks are:\n$DISKS"
echo "\nIP Address is: ${IPADDRESS}"
echo "Command to SSH in is: ssh root@${IPADDRESS}"

git clone https://gist.github.com/bcfbfdc7645cf5b7401cdbe229d84d98.git ArchInstall
cd ArchInstall
chmod +x *


# Save variables to a file and . source them into each script.

./ArchInstall-Tmux.sh

# VMware-Specific Settings in VMX

## Required to test with YubiKey
```
usb.generic.allowHID = "TRUE"
usb.generic.allowLastHID = "TRUE"
```

## Required to test with SecureBoot
```
uefi.secureBoot.enabled = "FALSE"
uefi.allowAuthBypass = "TRUE"
bios.bootDelay = "3000"
```

## Required to get UUID from SATA disks
```
disk.EnableUUID = "TRUE"
```
