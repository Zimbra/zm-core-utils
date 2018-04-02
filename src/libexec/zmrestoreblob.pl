#!/usr/bin/perl
#
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2009, 2018 Synacor, Inc.
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

use strict;
use warnings;  #or else.
use lib "/opt/zimbra/common/lib/perl5";
use Data::Dumper;
use File::Basename;
use File::Copy;

my $matched_blob;

my $backup_dir = "/opt/zimbra/backup/blobs";

my $mailbox_id = $ARGV[1];

my $zmblobchk_output = `zmblobchk -m $mailbox_id start`;

my $orphaned_header_check = ($zmblobchk_output =~ /blob not found/g);

my $zmblobchk_noutput = $zmblobchk_output;

if ($orphaned_header_check) {

	my @matches = ($zmblobchk_noutput =~ /(\/opt\/zimbra\/store.*\.msg)/gm);

	for $matched_blob(@matches) {		

		my($filename, $dirs, $suffix) = fileparse($matched_blob);		
		my $blob_fname = basename($filename);
		
		my $backup_path = $backup_dir . "/" . $blob_fname;
		
		if (-f $backup_path) {
			print "[] INFO: Restoring $matched_blob from backup\n";
			copy($backup_path, $matched_blob);
		}
	}
} else {
	print "[] INFO: No Orphaned Headers Found\n";
}