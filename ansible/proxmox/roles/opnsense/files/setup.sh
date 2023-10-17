fetch -o /usr/local/etc/pkg/repos/mimugmail.conf https://www.routerperformance.net/mimugmail.conf
pkg update
pkg upgrade -y
umount /dev/cd0
opnsense-importer cd0
pkg install -y os-sunnyvalley
pkg install -y os-adguardhome-maxit os-sensei os-sensei-updater os-theme-rebellion
reboot
