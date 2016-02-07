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
import ftplib

# import main settings
config = configparser.ConfigParser()
config.read('config.ini')
release_ver = config['RELEASE']['pur_release']
destdir = config['FILES']['dir']
workdir = config['FILES']['workdir']
repolist = config['FILES']['repolist']
rsync_host = config['RSYNC']['host']
rsync_user = config['RSYNC']['port']
destdir = re.sub('/?$','/',destdir)

upstream = open(repolist,'r')

def fetchFile(newurl,filename):
	failed = False
	# here's where we actually download files
	req = urllib.request.Request(
		newurl+filename, 
		data=None,
		headers={
			'User-Agent': 'https://github.com/RainbowHackerHorse/Pur-Linux/blob/master/extnltools/release.checker.py'
			#'User-Agent': 'Mozilla/5.0 (Windows NT 6.1; Win64; x64)'
		})
	try:
		source_web = urllib.request.urlopen(req)
	except urllib.error.URLError as e:
		if hasattr(e, 'reason'):
			#print(name + ' failed: ',str(e.reason))
			if e.code:
				with open('urls.error.log','a') as errfile: errfile.write(('{0}: {1} {2} ({3})\n').format(str(int(time.time())),name,e.code,e.reason))
				failed = True
			else:
				with open('urls.error.log','a') as errfile: errfile.write(('{0}: {1} {2})\n').format(str(int(time.time())),name,e.reason))
				failed = True
		elif hasattr(e, 'code'):
			#print('{0} failed: ',str(e.code))
			with open('urls.error.log',"a") as errfile: errfile.write(('{0}: {1} {2} (no reason given))\n').format(str(int(time.time())),name,str(e.code)))
			failed = True
		else:
			#print(('{0} failed: ',''.join(e)).format(name))
			failed = True

	if failed:
		return(False)
	else:
		urllib.request.urlretrieve(newurl,destdir+filename)
		return(True)
	

def checkFile(newurl):
	failed = False
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
			#print(name + ' failed: ',str(e.reason))
			#if e.code:
			#	with open('urls.error.log','a') as errfile: errfile.write(('{0}: {1} {2} ({3})\n').format(str(int(time.time())),name,e.code,e.reason))
			#else:
			#with open('urls.error.log','a') as errfile: errfile.write(('{0}: {1} {2})\n').format(str(int(time.time())),name,e.reason))
			failed = True
		elif hasattr(e, 'code'):
			#print('{0} failed: ',str(e.code))
			#with open('urls.error.log',"a") as errfile: errfile.write(('{0}: {1} {2} (no reason given))\n').format(str(int(time.time())),name,str(e.code)))
			failed = True
		else:
			#print(('{0} failed: ',''.join(e)).format(name))
			failed = True
#	ftplib.error_perm: 550 Failed to change directory
	except ftplib.all_errors as e:
		#print(e)
		#with open("urls.error.log","a") as errfile: errfile.write(('{0}: {1} {2} (no reason given))\n').format(str(int(time.time())),name,str(e)))
		failed = True
	else:
		failed = False

	if failed:
		return(False)
	else:
		return(True)

def getNewVer(name,filename,urlbase,cur_ver):
	#try to loop for remote files until we find one that hits. this might need tweaking/delays if upstream has rate limiting.
	#also, what a mess. this'll be wayyyy easier in the newer implementation since it's all strings in the sqlite3 db
	_cur_ver = cur_ver.split('.')
	try:
		ver = semantic_version.Version(cur_ver,partial=True)
	except:
		pass # it's a malformed version- we can't support 4 or more version points. yet?
	
	if ver:
		rel_iter = 0
		#print(name)
		for release in _cur_ver: #iterate through the number of release points...
			if len(_cur_ver) > 2:
				if rel_iter == 0:
					#print('upgrading major')
					rel = ver.next_major()
					loop_iter = 2
				elif rel_iter == 1:
					#print('upgrading minor')
					rel = ver.next_minor()
					loop_iter = 3
				elif rel_iter == 2:
					#print('upgrading patch')
					rel = ver.next_patch()
					loop_iter = 5
				else:
					# something went haywire
					rel = cur_ver
					loop_iter = 0

			else: 
				# "relaxed" semver most likely, i.e. "1.2" instead of "1.2.0"
				rel = re.sub('\.0$','',str(ver.next_minor()))
				loop_iter = 4
				relaxed = True
	
			while loop_iter > 0:
				if len(_cur_ver) == 3 and (_cur_ver[0] == _cur_ver[1] or _cur_ver[1] == _cur_ver[2] or _cur_ver[0] == _cur_ver[2]):
					if rel_iter == 0:
						# increment the first section
						loop_ver = re.sub('^'+str(_cur_ver[rel_iter])+'\.',str(int(_cur_ver[rel_iter]) + loop_iter)+'.',cur_ver)
					elif rel_iter == 1:
						# increment the second section
						loop_ver = re.sub('\.'+str(_cur_ver[rel_iter])+'\.','.'+str(int(_cur_ver[rel_iter]) + loop_iter)+'.',cur_ver)
					else:
						# increment the third section
						loop_ver = re.sub('\.'+str(_cur_ver[rel_iter])+'$','.'+str(int(_cur_ver[rel_iter]) + loop_iter),cur_ver)
				elif len(_cur_ver) == 2 and _cur_ver[0] == _cur_ver[1]:
					#print('duplicate version detected')
					if rel_iter == 0:
						# increment the first section
						loop_ver = re.sub('^'+str(_cur_ver[rel_iter])+'\.',str(int(_cur_ver[rel_iter]) + loop_iter)+'.',cur_ver)
					elif rel_iter == 1:
						# increment the second section
						loop_ver = re.sub('\.'+str(_cur_ver[rel_iter])+'$','.'+str(int(_cur_ver[rel_iter]) + loop_iter),cur_ver)
					else:
						# this should literally never happen since this particular loop runs against relaxed versioning.
						pass
				else:
					loop_ver = re.sub(str(_cur_ver[rel_iter]),str(int(_cur_ver[rel_iter]) + loop_iter),cur_ver)
				#print(loop_ver)
				newfilename = re.sub(cur_ver,loop_ver,filename)
				newurlbase = re.sub(('/{0}/').format(cur_ver),('/{0}/').format(str(rel)),urlbase)
				findme = checkFile(newurlbase+newfilename)
				if findme:
					fetchFile(newurlbase,newfilename)
					filename = newfilename
					break
				else:
					#rel = rel.next(patch?min?maj?)
					filename = filename
					loop_iter -= 1
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

	ver = getNewVer(name,filename,urlbase,cur_ver)
	print(filename)
	with open(repolist+".new","a") as genfile: genfile.write(('{0}@{1}{2}{3}\n').format(name,urlbase,filename,comment))

upstream.close()
os.rename(repolist+'.new',repolist)
