#!/usr/bin/perl
# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2005, 2007, 2009, 2010, 2013, 2014, 2016 Synacor, Inc.
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
# Date2Time:
# Pass in an ascii date string and it prints out seconds-since-epoch
# and milliseconds-since-epoch
use Date::Parse;
use strict;

if ($ARGV[0] eq "") {
    print "USAGE: d2t DATE_STRING\n";
    exit(1);
}

my $argStr;
# there must be some extra-special easy perl way to do this...
my $i = 0;
do {
    $argStr = $argStr . $ARGV[$i] . " ";
    $i++;
} while($ARGV[$i] ne "");

my $val = str2time($argStr);
my $back = localtime($val);
my $msval = $val * 1000;
print "$val\n$msval\n$back\n";
