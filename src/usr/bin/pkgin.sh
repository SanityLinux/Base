#!/bin/sh
echo "This is the Pür Linux pkgin bootstrapper"
echo "It works similarly to the bootstraper for pkgng on FreeBSD"
echo "This file is located in /usr/bin"
echo "Once it has installed pkgin in /usr/local/bin, it will autoremove itself"
if ls /usr/local/bin | grep -q bmake ;then
	echo "Ports already bootstrapped. Updating"
	portsnag update
else
	echo "Bootstrapping the Ports Tree"
	portsnag bootstrap
fi
cd /usr/ports/databases/sqlite3 && make install clean
cd /usr/ports/pkgtools/libnbcompat && make install clean
cd /usr/ports/net/libfetch && make install clean
cd /usr/ports/archivers/libarchive && make install clean
cd /usr/ports/pkgtools/pkgin && make install clean
touch /usr/local/etc/pkgin/repositories.conf
# Add pkgin repo info once the buildhost is up and producing packages.
rm /usr/bin/pkgin
