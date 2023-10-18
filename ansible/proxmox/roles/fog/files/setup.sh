#!/bin/bash
apt update
apt upgrade -y
apt install git -y
cd /tmp
git clone https://github.com/fogproject/fogproject.git fogproject-master
sh /tmp/fogproject-master/bin/installfog.sh -Y