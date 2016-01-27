#!/usr/bin/env python3
# needs python 3.x
# inspired by https://github.com/anatol/pkgoutofdate but:
# -portable so you can use it with... anything, not just Arch/pacman PKGBUILDS
# -no Ruby. :))))))
# brent s.
# originally for Pür Linux (https://github.com/RainbowHackerHorse/Pur-Linux).
##
# requires a urls.txt file in the same directory listing sources in the following format:
# nammeofsoftware@http://upstream.domain.com/path/to/current/release/filename-1.2.3.tar.gz # additional comment about this source URL (optional)
# e.g.
# linux@https://www.kernel.org/pub/linux/kernel/v4.x/linux-4.4.tar.gz # the linux kernel
# sed@ftp://ftp.gnu.org/gnu/sed/sed-4.2.2.tar.gz # GNU sed
# (etc.)
# NOTE: for sanity reasons, you'll want the LAST actual URL- the TRUE URL- not a redirect.
# you can get this with curl -sIL <url>, look for any "Location:" directives- those are redirects.

import semantic_version
import os
import re
import time
import urllib.request
import urllib.parse
import urllib.request
import ftplib

############
# SETTINGS #
############

# What version of release is this for?
# If blank, assume we're testing. TEST will be used instead.
pur_release = None

# Where should the sources be downloaded to? *THIS MUST BE SET.*
source_dir = '/usr/local/www/nginx/pkgs/'

# If this variable is empty, assume the webroot is on this host.
# If populated, assume that tarball_dir is on the given host and that host has rsync installed
# (and SSH PKI is properly set up to allow for automated uploading).
# This lets you run the checker on a remote box without installing python on the file host if desired.
rsync_host = None

# What remote user, if rsync_host is set, should we use? If blank but rsync_host is populated, the default
# is to use the current local user's username.
# Remember, it is *highly* recommended to use SSH PKI.
# See https://sysadministrivia.com/notes/HOWTO:SSH_Security for help if desired.
rsync_user = None

# What port should we use to connect to rsync, assuming rsync_host is set?
# If blank, use port 22.
rsync_port = None




upstream = open('./urls.txt','r')

def getNewVer(name,filename,urlbase,cur_ver, comment):
	_cur_ver = cur_ver.split('.')
	try:
	        ver = semantic_version.Version(cur_ver,partial=True)
	except:
	        pass # it's a malformed version- we can't support 4 or more version points. yet?
	
	if ver:
	        rel_iter = 0 
	        for release in _cur_ver: #iterate through the number of release points...
	                if rel_iter == 0:
	                        #print('upgrading major')
	                        rel = str(ver.next_major())
	                elif rel_iter == 1:
	                        #print('upgrading minor')
	                        rel = str(ver.next_minor())
	                elif rel_iter == 2:
	                        #print('upgrading patch')
	                        rel = str(ver.next_patch())
	                else:
	                        break
	
	                newfilename = re.sub(cur_ver,rel,filename)
	                newurlbase = re.sub(('/{0}/').format(cur_ver),('/{0}/').format(str(rel)),urlbase)
	                #print(('{0} ==> {1}').format(filename,newfilename))
	                #print(('{0} ==> {1}').format(urlbase,newurlbase))
	                rel_iter += 1
	

	# health check (with protozoan logging) of upstream mirrors, so we can debug possible issues
	req = urllib.request.Request(
		urlbase + filename, 
		data=None,
		headers={
			'User-Agent': 'https://github.com/RainbowHackerHorse/Pur-Linux/blob/master/extnltools/release.checker.py'
			#'User-Agent': 'Mozilla/5.0 (Windows NT 6.1; Win64; x64)'
		})
	try:
		source_web = urllib.request.urlopen(req)
	except urllib.error.URLError as e:
		if hasattr(e, 'reason'):
			print(name + ' failed: ',str(e.reason))
			with open("urls.txt.new","a") as genfile: genfile.write(('{0}@{1}{2}{3}').format(name,urlbase,filename,comment))
			#if e.code:
			#	with open('urls.error.log','a') as errfile: errfile.write(('{0}: {1} {2} ({3})\n').format(str(int(time.time())),name,e.code,e.reason))
			#else:
			with open('urls.error.log','a') as errfile: errfile.write(('{0}: {1} {2})\n').format(str(int(time.time())),name,e.reason))
		elif hasattr(e, 'code'):
			print('{0} failed: ',str(e.code))
			with open("urls.txt.new","a") as genfile: genfile.write(('{0}@{1}{2}{3}').format(name,urlbase,filename,comment))
			with open('urls.error.log',"a") as errfile: errfile.write(('{0}: {1} {2} (no reason given))\n').format(str(int(time.time())),name,str(e.code)))
		else:
			print(('{0} failed: ',''.join(e)).format(name))
#	ftplib.error_perm: 550 Failed to change directory
	except ftplib.all_errors as e:
		print(e)
		with open("urls.error.log","a") as errfile: errfile.write(('{0}: {1} {2} (no reason given))\n').format(str(int(time.time())),name,str(e)))
	else:
		with open("urls.txt.new","a") as genfile: genfile.write(('{0}@{1}{2}{3}\n').format(name,urlbase,filename,comment))

	print(('{0} done.').format(name))

	 

for source in upstream:
	# parse the line, and skip empty lines/just comments
	if re.fullmatch('^\s*(#.*)?\s*$',source):
		continue
	line = source.split('@')
	name = line[0]
	url = re.sub('(\s*#.*$|\n)','',''.join(line[1]))
	if re.search('\s*#.*$\n?',source):
		#comment = '#' + '#'.join(source.split('#')[1:])
		comment = '#' + "#".join(source.split('#')[1:])
		comment = re.sub('\n','',comment)
	else:
		comment = ''
	urlbase = '/'.join(url.split('/')[:-1]) + '/'
	filename = ''.join(url.split('/')[-1])
#	print(url)
	#print(('{0}: {1}').format(name,comment))
	# stupid projects not keeping proper naming standards.
	# so we need to munge some filenames for getting the version number.
	if name == 'check':
		munged_fn = ('{0}-{1}').format(name,filename)
	elif name == 'expect':
		munged_fn = re.sub('^'+name,name+'-',filename).format(name)
	elif name == 'tcl':
		# didn't feel like making a dict, setting up a class/function, etc.
		#  just to do this. so multiple iterations on the same string, because lazy.
		munged_fn = re.sub(name,name + '-',filename)
		munged_fn = re.sub('-src','',munged_fn)
	elif name == 'tzdata':
		# weird and totally incompatible numbering scheme... revisit this in the future maybe.
		with open("urls.txt.new","a") as genfile: genfile.write(('{0}@{1}{2}{3}\n').format(name,urlbase,filename,comment))
		continue
		print('this should never print')
	else:
		munged_fn = filename

	# now we get the current version number
	cur_ver = re.split('^' + name + '-',munged_fn)
	cur_ver = re.sub('(\.tgz|\.zip|\.tar(\..*)?)$','',cur_ver[1])

	new_ver = getNewVer(name,filename,urlbase,cur_ver,comment)

upstream.close()
os.rename('urls.txt.new','urls.txt')
