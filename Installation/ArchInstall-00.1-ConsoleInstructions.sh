# Run these commands at the ArchIso console:

# Initial setup required from PC/VM console:
## Set password
echo -e "password\npassword" | sudo -S passwd

## Start sshd
sudo systemctl start sshd

DISKS=$(ls -la /dev/disk/by-id | grep "../" | cut -f 11-13 -d " ")

IPADDRESS=$(ip a | grep "inet " | grep -v host | cut -f 6 -d " " | cut -f 1 -d "/")

echo "\nAvailable disks are:\n$DISKS"
echo "\nIP Address is: ${IPADDRESS}"
echo "Command to SSH in is: ssh root@${IPADDRESS}"

pacman -Sy --noconfirm git
cd /root
rm -rf ArchInstall
git clone https://github.com/lumnikemel/ArchAngel.git ArchAngel
cp -r ./ArchAngel/Installation ./ArchInstall
rm -r ./ArchAngel
cd ArchInstall
chmod +x *
SCRIPT_DIR=/root/ArchInstall
. $SCRIPT_DIR/vars

./ArchInstall-00-RunMeFirst.sh
