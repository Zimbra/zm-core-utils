#!/usr/bin/perl -w
# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2008, 2009, 2010, 2013, 2014, 2016 Synacor, Inc.
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
use strict;
use warnings;
use Getopt::Long;

my $nocase;
my $bufIn;


sub getNextLogLine();
sub getNextFileLine();

GetOptions(
           "i" => \$nocase,
          );

my $grepStr = shift @ARGV;
my $filename = shift @ARGV;

my $usage = <<END_OF_USAGE;
USAGE: $0 [-i] SEARCH_STRING FILE
END_OF_USAGE

if (!defined($grepStr)) {
  die $usage;
}
if (defined $filename) {
  open IN, "$filename" or die "Couldn't open $filename";
}

my $grepOpts = "";
if (defined $nocase) {
  $grepOpts .= "i";
}


my $line;
do {
  $line = getNextLogLine();
  if (defined($line)) {
    my $matched = 0;
    if (defined $nocase) {
      if ($line =~ /$grepStr/i) {
        $matched = 1;
      }
    } else {
      if ($line =~ /$grepStr/) {
        $matched = 1;
      }
    }
    if ($matched == 1) {
      print "$line";
    }
  }
} while (defined($line));
close IN;
exit(0);


sub getNextLogLine() {
  my $curLine = "";
  
  if (defined($bufIn)) {
    $curLine = $bufIn;
  } else {
    $curLine = getNextFileLine();
    if (!defined($curLine)) {
      return $curLine;
    }
  }

  while (1) {
    $bufIn = getNextFileLine();
    if (!defined($bufIn)) {
      return $curLine;
    }
    if ($bufIn =~ /^20[01][0-9]-[01][0-9]/) {
      return $curLine;
    } else {
      $curLine .= $bufIn;
    }
  }
}

sub getNextFileLine() {
  if (defined $filename) {
    return <IN>;
  } else {
    return <STDIN>;
  }
}
