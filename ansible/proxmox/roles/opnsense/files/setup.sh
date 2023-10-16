#!/bin/sh
fetch -o /usr/local/etc/pkg/repos/mimugmail.conf https://www.routerperformance.net/mimugmail.conf
pkg update
pkg upgrade -y
umount /mnt/cdrom
opnsense-importer cd0
pkg install -y os-adguardhome-maxit os-sensei os-sensei-updater os-sunnyvalley os-theme-rebellion
reboot
