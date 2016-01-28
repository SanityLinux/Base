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
import configparser

# import main settings
config = configparser.ConfigParser()
config.read('config.ini')
release_ver = config['RELEASE']['pur_release']
destdir = config['FILES']['dir']
workdir = config['FILES']['workdir']
repolist = config['FILES']['repolist']
rsync_host = config['RSYNC']['host']
rsync_user = config['RSYNC']['port']

upstream = open(repolist,'r')

def fetchFile(name,filename,newurl,ver):
	# here's where we actually download files
	req = urllib.request.Request(
		newurl, 
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
			if e.code:
				with open('urls.error.log','a') as errfile: errfile.write(('{0}: {1} {2} ({3})\n').format(str(int(time.time())),name,e.code,e.reason))
			else:
				with open('urls.error.log','a') as errfile: errfile.write(('{0}: {1} {2})\n').format(str(int(time.time())),name,e.reason))
		elif hasattr(e, 'code'):
			print('{0} failed: ',str(e.code))
			with open('urls.error.log',"a") as errfile: errfile.write(('{0}: {1} {2} (no reason given))\n').format(str(int(time.time())),name,str(e.code)))
		else:
			print(('{0} failed: ',''.join(e)).format(name))
	

def checkFile(newurl):
	# disable logging, because there'll be a lot of 404's
	# check remote for newer version defined in getNewVer
	req = urllib.request.Request(
		newurl, 
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
			#if e.code:
			#	with open('urls.error.log','a') as errfile: errfile.write(('{0}: {1} {2} ({3})\n').format(str(int(time.time())),name,e.code,e.reason))
			#else:
			#with open('urls.error.log','a') as errfile: errfile.write(('{0}: {1} {2})\n').format(str(int(time.time())),name,e.reason))
		elif hasattr(e, 'code'):
			print('{0} failed: ',str(e.code))
			#with open('urls.error.log',"a") as errfile: errfile.write(('{0}: {1} {2} (no reason given))\n').format(str(int(time.time())),name,str(e.code)))
		else:
			print(('{0} failed: ',''.join(e)).format(name))
#	ftplib.error_perm: 550 Failed to change directory
	except ftplib.all_errors as e:
		print(e)
		#with open("urls.error.log","a") as errfile: errfile.write(('{0}: {1} {2} (no reason given))\n').format(str(int(time.time())),name,str(e)))
	else:
		pass

	print(('{0} done.').format(name))

def getNewVer(name,filename,urlbase,cur_ver,loopnum):
	#try to loop for remote files until we find one that hits. this might need tweaking/delays if upstream has rate limiting.
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
	return(rel)

	 

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
		with open(repolist+".new","a") as genfile: genfile.write(('{0}@{1}{2}{3}\n').format(name,urlbase,filename,comment))
		continue
		print('this should never print')
	else:
		munged_fn = filename

	# now we get the current version number
	cur_ver = re.split('^' + name + '-',munged_fn)
	cur_ver = re.sub('(\.tgz|\.zip|\.tar(\..*)?)$','',cur_ver[1])

	ver = getNewVer(name,filename,urlbase,cur_ver,20)
	print(cur_ver,ver)
	#fetchFile(name,filename,urlbase,ver)
	with open(repolist+".new","a") as genfile: genfile.write(('{0}@{1}{2}{3}\n').format(name,urlbase,filename,comment))

upstream.close()
os.rename(repolist+'.new',repolist)
