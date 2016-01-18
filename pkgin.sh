#!/bin/sh
echo "This is the Pür Linux pkgin bootstrapper"
echo "It works similarly to the bootstraper for pkgng on FreeBSD"
echo "This file is located in /usr/bin"
echo "Once it has installed pkgin in /usr/local/bin, it will autoremove itself"
if ls /usr/bin | grep -q portfetch.new ;then
	echo "Bootstrapping the Ports Tree"
	/usr/bin/portfetch
fi
cd /usr/ports/databases/sqlite3 && make install clean
cd /usr/ports/pkgtools/libnbcompat && make install clean
cd /usr/ports/net/libfetch && make install clean
cd /usr/ports/archivers/libarchive && make install clean
cd /usr/ports/pkgtools/pkgin && make install clean
rm /usr/bin/pkgin
