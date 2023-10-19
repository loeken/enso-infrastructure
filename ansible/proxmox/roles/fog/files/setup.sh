#!/bin/bash
apt update
apt upgrade -y
apt install git -y
cd /tmp
git clone https://github.com/fogproject/fogproject.git fogproject-master
cd /tmp/fogproject-master/bin/
pwd
/bin/bash installfog.sh -Y > /tmp/fog_install.log