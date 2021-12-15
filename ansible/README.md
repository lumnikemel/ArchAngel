```
mount -o remount,size=2G /run/archiso/cowspace
pacman -Qq | grep python | pacman -S -
pacman -Sy git ansible python-passlib
cd /root
rm -r ArchAngel
git clone -b Ansible-Install https://github.com/lumnikemel/ArchAngel
cd ArchAngel/ansible
ansible-playbook -i localhost install.yml
```
