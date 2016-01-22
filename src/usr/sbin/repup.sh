#!/bin/sh
## Repo conf updater for Pür Linux pkgin repos
mkdir -p /usr/local/etc/pkgin
rm /usr/local/etc/pkgin/repositories.conf
cd /usr/local/etc/pkgin
wget https://github.com/RainbowHackz/Pur-Linux/blob/master/src/usr/local/etc/pkgin/repositories.conf
chmod 644 /usr/local/etc/pkgin/repositories.conf
