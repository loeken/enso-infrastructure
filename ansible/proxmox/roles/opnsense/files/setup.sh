#!/bin/sh
fetch -o /usr/local/etc/pkg/repos/mimugmail.conf https://www.routerperformance.net/mimugmail.conf
pkg update
pkg upgrade -y
pkg install -y os-adguardhome-maxit os-sensei os-sensei-updater os-sunnyvalley os-theme-rebellion
opnsense-importer cd0
reboot