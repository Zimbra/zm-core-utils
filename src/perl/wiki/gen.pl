#!/usr/bin/perl
# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2006, 2007, 2009, 2010, 2013, 2014, 2016 Synacor, Inc.
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

my @tokens = (0,1,2,3,4,5,6,7,8,9);
my $datadir = "/Users/jylee/ws/main/ZimbraServer/data/wiki/loadtest/";

my $buf;

sub readTemplate($) {
    my ($name) = @_;
    open (TEMPLATE, $name) or die "can't open $name";
    my @lines = <TEMPLATE>;
    $buf = join ("\n", @lines);
    close (TEMPLATE);
}

sub writeFile($) {
    my ($name) = @_;
    open (F, ">$name") or die "can't open $name";
    print F $buf;
    close (F);
}

sub createDirs() {
    my $d1, d2, $f;
    for my $dir (@tokens) {
	$d1 = $datadir . $dir;
	mkdir $d1;
	for my $subdir (@tokens) {
	    $d2 = $d1 . "/" . $subdir;
	    mkdir $d2;
	    for my $file (@tokens) {
		$f = $d2 . "/" . $file;
		writeFile($f);
	    }
	}
    }
}

sub main() {
    readTemplate($datadir . "template");
    createDirs();
}


main();
