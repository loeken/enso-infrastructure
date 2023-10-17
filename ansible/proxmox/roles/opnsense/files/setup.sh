echo 'mimugmail: {
  url: "https://opn-repo.routerperformance.net/repo/${ABI}",
  priority: 190,
  enabled: yes
}' > /usr/local/etc/pkg/repos/mimugmail.conf
pkg update
pkg upgrade -y
umount /dev/cd0
opnsense-importer cd0
pkg install -y os-sunnyvalley
pkg install -y os-adguardhome-maxit os-sensei os-sensei-updater os-theme-rebellion
reboot
