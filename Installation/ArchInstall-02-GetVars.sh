#!/bin/bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Source existing variables
. $SCRIPT_DIR/vars
################################################################################
# Improvements:
# - [ ] Use defaults on reads: https://stackoverflow.com/questions/2642585/read-a-variable-in-bash-with-a-default-value
################################################################################
# Get system name:
if [ -z "${SYSTEM_NAME}" ]; then 
read -e -p "Enter hostname: " SYSTEM_NAME
sed -i "s|SYSTEM_NAME=\"\"|SYSTEM_NAME=${SYSTEM_NAME}|" $SCRIPT_DIR/vars; else
echo "SKIP setting system name; already defined in vars file."
fi

# Get username:
if [ -z "${USER}" ]; then 
read -e -p "Enter username: " USER
sed -i "s|USER=\"\"|USER=${USER}|" $SCRIPT_DIR/vars; else
echo "SKIP setting system name; already defined in vars file."
fi

# Get user password:
if [ -z "${USER_PASS}" ]; then 
read -e -s -p "Enter passphrase for user: " USER_PASS
sed -i "s|USER_PASS=\"\"|USER_PASS=${USER_PASS}|" $SCRIPT_DIR/vars; else
echo "SKIP setting system name; already defined in vars file."
fi

# Swap size:
if [ -z "${SWAPSIZE}" ]; then 
read -e -p "Enter size of swap in GB: " SWAPSIZE
sed -i "s|SWAPSIZE=\"\"|SWAPSIZE=${SWAPSIZE}|" $SCRIPT_DIR/vars; else
echo "SKIP setting system name; already defined in vars file."
fi

# Get disk encryption password:
if [ -z "${CRYPT_PASS}" ]; then 
read -e -s -p "Enter passphrase for encryption: " CRYPT_PASS
sed -i "s|CRYPT_PASS=\"\"|CRYPT_PASS=${CRYPT_PASS}|" $SCRIPT_DIR/vars; else
echo "SKIP setting system name; already defined in vars file."
fi

# Determine disks available to install to:
DISKS=$(lsblk -o NAME,MAJ:MIN,RM,SIZE,RO,TYPE,MODEL,SERIAL,PATH,MOUNTPOINTS | awk '{if ($6 == "disk"||$6 == "TYPE" ) print $0;}' | awk 'NR==1{print $0" DEVICE-ID(S)"}NR>1{dev=$1;gsub("[^[:alnum:]]","",dev);printf $0;system("find /dev/disk/by-id -lname \"*"dev"\" -printf \" %p\"");print "";}')
echo
echo "Disks available to install to:"
echo "${DISKS}"
echo

# Get boot-disk:
if [ -z "${BOOT_DISK}" ]; then 
read -e -p "Which device should the bootloader be installed on (enter NAME only)?: " BOOT_DISK
echo "You chose /dev/${BOOT_DISK}!"

DISK=$(find /dev/disk/by-id -type l -printf "%f:%l\n" | grep -E "${BOOT_DISK}$" | cut -d':' -f 1 | head -n 1)
BOOT_DISK="/dev/disk/by-id/${DISK}"
echo "USING DISK: ${BOOT_DISK} to install the system to!"
sed -i "s|BOOT_DISK=\"\"|BOOT_DISK=${BOOT_DISK}|" $SCRIPT_DIR/vars; else
echo "SKIP setting boot-disk. Boot-disk already defined in vars file."
fi

# Get disk to install system to:
if [ -z "${USER_DISK}" ]; then 
read -e -p "Which device should Arch be installed on (enter NAME only)?: " USER_DISK
echo "You chose /dev/${USER_DISK}!"

DISK=$(find /dev/disk/by-id -type l -printf "%f:%l\n" | grep -E "${USER_DISK}$" | cut -d':' -f 1 | head -n 1)
USER_DISK="/dev/disk/by-id/${DISK}"
echo "USING DISK: ${USER_DISK} to install the system to!"
sed -i "s|USER_DISK=\"\"|USER_DISK=${USER_DISK}|" $SCRIPT_DIR/vars; else
echo "SKIP setting system-disk. User-disk already defined in vars file."
fi

