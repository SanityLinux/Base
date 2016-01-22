#!/bin/sh
## Repo conf updater for Pür Linux pkgin repos
if ls /usr/local/etc | [ ! grep -q pkgin ] ;then
  mkdir -p /usr/local/etc/pkgin
fi
rm /usr/local/etc/pkgin/repositories.conf
cd /usr/local/etc/pkgin
wget https://github.com/RainbowHackz/Pur-Linux/blob/master/src/usr/local/etc/pkgin/repositories.conf
