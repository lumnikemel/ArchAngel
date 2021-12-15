```
mount -o remount,size=2G /run/archiso/cowspace
pacman -Qq | grep python | pacman -S -
pacman -Sy git ansible python-passlib
git clone https://github.com/joelbits/arch-ansible
cd arch-ansible
ansible-playbook -i localhost install.yml
```
