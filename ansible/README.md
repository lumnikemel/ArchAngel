```
echo -e "password\npassword" | sudo -S passwd
sudo systemctl start sshd
echo set -g default-terminal "xterm-256color" > .tmux.conf
env SHELL=/usr/bin/bash tmux new -d -s install
#ip a | grep "inet " | grep -v host | cut -f 6 -d " " | cut -f 1 -d "/"
tmux send-keys -t install 'ip a | grep "inet " | grep -v host | cut -f 6 -d " " | cut -f 1 -d "/"' Enter

```
----
```
tmux attach-session -t install

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
