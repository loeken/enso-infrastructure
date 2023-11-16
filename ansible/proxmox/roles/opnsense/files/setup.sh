#!/bin/sh

echo 'mimugmail: {
  url: "https://opn-repo.routerperformance.net/repo/${ABI}",
  priority: 190,
  enabled: yes
}' > /usr/local/etc/pkg/repos/mimugmail.conf

cp /mnt/cdrom/conf/config.xml /conf/config.xml

umount /dev/cd0
sleep 5
touch /.probe.for.growfs

pkg update
pkg upgrade -y
pkg install -y os-sunnyvalley nano
pkg install -y os-adguardhome-maxit os-sensei os-sensei-updater os-theme-rebellion

reboot