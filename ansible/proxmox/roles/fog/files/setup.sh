#!/bin/bash
apt update
apt upgrade -y
apt install git -y
git clone https://github.com/fogproject/fogproject.git fogproject-master
cd fogproject-master/bin
./installfog.sh -Y