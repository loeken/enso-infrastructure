#!/bin/sh
# Your original script
echo 'mimugmail: {
  url: "https://opn-repo.routerperformance.net/repo/${ABI}",
  priority: 190,
  enabled: yes
}' > /usr/local/etc/pkg/repos/mimugmail.conf

pkg update
pkg upgrade -y
pkg install -y os-sunnyvalley nano
pkg install -y os-adguardhome-maxit os-sensei os-sensei-updater os-theme-rebellion elasticsearch5

opnsense-importer cd0
touch /.probe.for.growfs
echo "reboot now, if you want to increase the disk change the disk size before rebooting"
