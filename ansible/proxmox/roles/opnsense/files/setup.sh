#!/bin/sh

# Check if script is running from /mnt/cdrom/setup.sh
if [ "$0" != "/root/setup.sh" ]; then
  cp /mnt/cdrom/setup.sh /root/setup.sh
  chmod +x /root/setup.sh
  exec /root/setup.sh
  exit 0
fi

# Your original script
echo 'mimugmail: {
  url: "https://opn-repo.routerperformance.net/repo/${ABI}",
  priority: 190,
  enabled: yes
}' > /usr/local/etc/pkg/repos/mimugmail.conf

pkg update
pkg upgrade -y
pkg install -y os-sunnyvalley nano
pkg install -y os-adguardhome-maxit os-sensei os-sensei-updater os-theme-rebellion

umount /dev/cd0
sleep 3
opnsense-importer cd0
echo "reboot now"
