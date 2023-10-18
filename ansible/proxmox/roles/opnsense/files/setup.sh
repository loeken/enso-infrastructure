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


# Path to the OPNsense config file
CONFIG_FILE="/conf/config.xml"

# Set vtnet0 for WAN
sed -i -e '/<wan>/,/<\/wan>/ s|<if>.*</if>|<if>vtnet0</if>|' $CONFIG_FILE

# Set vtnet1 for LAN
sed -i -e '/<lan>/,/<\/lan>/ s|<if>.*</if>|<if>vtnet1</if>|' $CONFIG_FILE

# Replace 'vtnet0' with your interface name
INTERFACE="vtnet1"

# Get all IPv6 addresses on the interface
ADDRESSES=$(ifconfig ${INTERFACE} | grep inet6 | awk '{ print $2}')

# Loop through each address and remove it
for addr in ${ADDRESSES}; do
  ifconfig ${INTERFACE} inet6 ${addr} delete
done

sysctl net.inet6.ip6.accept_rtadv=0
sysctl net.inet6.ip6.forwarding=0
sysctl net.inet6.ip6.disable_ipv6=1

# Reload all configurations (you may choose to execute this step manually)
/usr/local/etc/rc.reload_all

pkg update
pkg upgrade -y
pkg install -y os-sunnyvalley nano
pkg install -y os-adguardhome-maxit os-sensei os-sensei-updater os-theme-rebellion

umount /dev/cd0
sleep 3
opnsense-importer cd0
touch /.probe.for.growfs
echo "reboot now, if you want to increase the disk change the disk size before rebooting"
