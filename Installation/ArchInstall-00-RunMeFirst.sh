#!/bin/bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Source existing variables
. $SCRIPT_DIR/vars
################################################################################
echo "### Start Installation ###"
#$SCRIPT_DIR/ArchInstall-00-RunMeFirst.sh
#$SCRIPT_DIR/ArchInstall-01-SetUpTmux.sh
$SCRIPT_DIR/ArchInstall-02-GetVars.sh
$SCRIPT_DIR/ArchInstall-03-PartitionDisks.sh
$SCRIPT_DIR/ArchInstall-04.01-FDE.sh
$SCRIPT_DIR/ArchInstall-04.02-FDE.sh
$SCRIPT_DIR/ArchInstall-05-ZFS.sh
$SCRIPT_DIR/ArchInstall-06-MountFilesystems.sh
$SCRIPT_DIR/ArchInstall-07-OtherStuff.sh
$SCRIPT_DIR/ArchInstall-08-SystemInstallation.sh
arch-chroot /mnt $SCRIPT_DIR/ArchInstall-09-SystemInstallation-ArchChroot.sh
$SCRIPT_DIR/ArchInstall-99-PostInstall.sh
