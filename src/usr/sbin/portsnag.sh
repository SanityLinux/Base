#!/bin/bash
#
# Conceptually based on portsnap, from FreeBSD. 
# No portsnap code is contained in portsnag.
# I'm not awesome enough to successfully rip off Best OS.
# This script relies on CVS to do the heavy lifting, rather than portsnap's
# inbuilt goodness.
# CVS is included in the base of Pür Linux.
# 
# Portsnag replaces portfetch and portupdate for management of
# PürPorts/pkgsrc
#
# This file is located in /usr/sbin/portsnag
#
# Copyright 2016 Pür Linux Project
# Portsnag originally written by Rainbow
# All rights reserved
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted providing that the following conditions 
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

usage() {
	cat <<EOF
usage: portsnag (bootstrap/fetch/update)

Commands:
	bootstrap 	 -- Fetch and bootstrap pkgsrc
	fetch        -- Delete and fetch a new copy of the ports tree.
	update       -- Update ports tree to match current snapshot, replacing
                  files and directories which have changed.
EOF
	exit 0
}

PKGSRCBRANCH=pkgsrc-2016Q1
export PKGSRCBRANCH

# Parse the command line

if [[ ${1} == "bootstrap" ]];
	then
		if ls /usr/local/bin | grep -q bmake;
			then 
			echo "Already bootstrapped baby! Did you mean portsnag fetch or portsnag update?"
			exit 1
		fi
	echo "Bootstrapping PürPorts (NetBSD Pkgsrc)"
	cd /usr
	cvs -q -z2 -d anoncvs@anoncvs.NetBSD.org:/cvsroot checkout -r $PKGSRCBRANCH -P pkgsrc
	mv /usr/pkgsrc /usr/ports
	/usr/ports/bootstrap/bootstrap --prefix /usr/local
	rm /usr/local/etc/mk.conf
#	ln -s /usr/etc/pkgsrcmk.conf /usr/local/etc/mk.conf
	cd /usr/local/etc
	wget https://github.com/RainbowHackz/Pur-Linux/blob/master/src/usr/local/etc/mk.conf
	chmod 644 /usr/local/etc/mk.conf
	echo "Ports Bootstrapped."
	echo "Go ahead! Try it out! Example: cd /usr/ports/shells/fish && bmake install clean"
	echo "More information on Pkgsrc is available at http://www.pkgsrc.org/ "
	echo "Please make sure to run /usr/sbin/repup to ensure your pkgin repositories.conf"
	echo " is up to date, if you use pkgin!"
elif [[ ${1} == "fetch" ]];
	then
	echo "Warning! This will REMOVE your current pkgsrc tree and fetch a BRAND NEW ONE. Cool? (y/n)"
	read -n 1 ch
	if [ "$ch" == "n" ] ; then
		echo "Exiting..."
		exit 1
	fi
	rm -rf /usr/ports
	echo "Deleting and fetching latest PürPorts (NetBSD Pkgsrc)"
	cd /usr
	cvs -q -z2 -d anoncvs@anoncvs.NetBSD.org:/cvsroot checkout -r $PKGSRCBRANCH -P pkgsrc
	mv /usr/pkgsrc /usr/ports
	echo "Please make sure to run /usr/sbin/repup to ensure your pkgin repositories.conf"
	echo " is up to date, if you use pkgin!"
elif [[ ${1} == "update" ]];
	then
	echo "Updating Ports..."
	cd /usr/ports && env CVS_RSH=ssh cvs up -dP
	echo "Please make sure to run /usr/sbin/repup to ensure your pkgin repositories.conf"
	echo " is up to date, if you use pkgin!"
elif [[ ${1} == "" ]];
	then
	usage
fi
