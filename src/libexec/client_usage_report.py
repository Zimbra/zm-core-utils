#!/usr/bin/env zmpython
#
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2012, 2013, 2014, 2016 Synacor, Inc.
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software Foundation,
# version 2 of the License.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with this program.
# If not, see <https://www.gnu.org/licenses/>.
# ***** END LICENSE BLOCK *****
#

import fileinput
import subprocess
import re
from datetime import date

# Number of days of log files to read
numdays = 7

# Find the current total number of log files
p = subprocess.Popen('ls /opt/zimbra/log/access_log* | wc -l', shell=True, stdout=subprocess.PIPE)
numlogfiles = p.stdout.read()

# Get the list of log files to read
lscmdfmt = 'ls /opt/zimbra/log/access_log* | tail -%d | head -%d'
if numlogfiles > numdays:
    lscmd = lscmdfmt % (numdays + 1, numdays)
else:
    lscmd = lscmdfmt % (numdays, numlogfiles - 1)
p = subprocess.Popen(lscmd, shell=True, stdout=subprocess.PIPE)

resultmap = {}

for file in p.stdout.readlines():
    file = file.rstrip()
    subprocess.call('echo Reading %s ..' % file, shell=True)
    for line in fileinput.input([file]):
        l = line.split('"')
        if len(l) < 7:
            continue
        ua = l[5].rstrip()
        if not re.match('(zm.*|ZCS.*|zclient.*|.*ZCB.*|Jakarta.*|curl.*|-)', ua) is None:
            continue
        requrl = l[1]
        if not re.match('(.*/zimbraAdmin.*|.*/service/admin.*)', requrl) is None:
            continue
        result = l[2].split()[0]
        if result != '200':
            continue
        ip = line.split('-')[0].rstrip()
        if (ip == '127.0.0.1' or ip == '::1'):
            continue
        key = ua, ip
        curval = resultmap.get(key)
        if curval is None:
            resultmap[key] = 1
        else:
            resultmap[key] = curval + 1

reportfile = '/opt/zimbra/zmstat/client_usage_report_%s.csv' % (date.today().isoformat())
subprocess.call('rm -f %s' % reportfile, shell=True)
csv = open(reportfile, 'w')
subprocess.call('echo Writing %s ..' % reportfile, shell=True)
csv.write('"user_agent","client_IP","req_count"\n')
for key, value in resultmap.iteritems():
    csv.write('"%s","%s","%s"\n' % (key[0], key[1], value))
csv.close()
