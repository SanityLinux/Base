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

import re
import time
import urllib.request
import urllib.parse
import urllib.request

upstream = open('./urls.txt','r')

def getNewVer(name,filename,urlbase,cur_ver, comment):
	# build a list of the version
	_cur_ver = cur_ver.split('.')

	rel_iter = 0
	#for release in _cur_ver:
	#	while rel_iter >= 20:
	#		new_rel = int(release) + 1
	#		filename = re.sub(release,str(new_rel),filename)
	#		baseurl = re.sub('/{0}/',str(new_rel),filename).format(release)

		#req = urllib.request.Request(
		#	urlbase+

	# health check (with protozoan logging) of upstream mirrors, so we can debug possible issues
	req = urllib.request.Request(
		urlbase + filename, 
		data=None, 
		headers={
			'User-Agent': 'https://github.com/RainbowHackerHorse/Pur-Linux/blob/master/tools/release.checker.py'
			#'User-Agent': 'Mozilla/5.0 (Windows NT 6.1; Win64; x64)'
		})
	try:
		source_web = urllib.request.urlopen(req)
	except urllib.error.URLError as e:
		if hasattr(e, 'reason'):
			print(name + ' failed: ', e.reason)
			with open("urls.txt.new", "a") as genfile: genfile.write('{0}@{1}{2}{3}').format(name,urlbase,filename,comment)
			with open('urls.error.log', 'a') as errfile: errfile.write('{0}: {1} {2} ({3})\n').format(str(int(time.time())),name,str(e.code),e.reason)
		elif hasattr(e, 'code'):
			print(name + ' failed: ',e.code)
			with open("urls.txt.new", "a") as genfile: genfile.write('{0}@{1}{2}{3}').format(name,urlbase,filename,comment)
			with open('urls.error.log', 'a') as errfile: errfile.write('{0}: {1} {2} (no reason given))\n').format(str(int(time.time())),name,str(e.code))
	else:
		with open("urls.txt.new", "a") as genfile:
			genfile.write('{0}@{1}{2}{3}\n').format(name,urlbase,filename,comment)


	 

for source in upstream:
	# parse the line
	line = source.split('@')
	name = line[0]
	url = re.sub('(\s*#.*$|\n)','',''.join(line[1]))
	if re.match('\s*#.*$',source):
		comment = '#'.join(source.split('#')[1:])
	else:
		comment = ''
	urlbase = '/'.join(url.split('/')[:-1]) + '/'
	filename = ''.join(url.split('/')[-1])

	# stupid projects not keeping proper naming standards.
	# so we need to munge some filenames for getting the version number.
	if name == 'check':
		munged_fn = ('{0}-{1}').format(name,filename)
	elif name == 'expect':
		munged_fn = re.sub('^{0}','{0}-',filename).format(name)
	elif name == 'tcl':
		# didn't feel like making a dict, setting up a class/function, etc.
		#  just to do this. so multiple iterations on the same string, because lazy.
		munged_fn = re.sub(name,name + '-',filename)
		munged_fn = re.sub('-src','',munged_fn)
	else:
		munged_fn = filename

	# now we get the current version number
	cur_ver = re.split('^' + name + '-',munged_fn)
	cur_ver = re.sub('(\.tgz|\.zip|\.tar(\..*)?)$','',cur_ver[1])

	new_ver = getNewVer(name,filename,urlbase,cur_ver,comment)
