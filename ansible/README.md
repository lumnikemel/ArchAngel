```
mount -o remount,size=2G /run/archiso/cowspace
pacman -Qq | grep python | pacman -S -
pacman -Sy git ansible python-passlib
git clone https://github.com/lumnikemel/ArchAngel
git clone https://github.com/lumnikemel/ArchAngel/Ansible-Install/ansible
cd ArchAngel/Ansible-Install/ansible
ansible-playbook -i localhost install.yml
```
