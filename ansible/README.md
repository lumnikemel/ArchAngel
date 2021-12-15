```
echo -e "password\npassword" | sudo -S passwd
sudo systemctl start sshd
```
----
```
mount -o remount,size=2G /run/archiso/cowspace
pacman -Sy
pacman -Qq | grep python | pacman -S - git ansible python-passlib --noconfirm

```
----
```
cd /root
rm -r ArchAngel
git clone -b Ansible-Install https://github.com/lumnikemel/ArchAngel
cd ArchAngel/ansible
ansible-playbook -i localhost install.yml

```
