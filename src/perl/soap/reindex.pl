#!/usr/bin/perl -w
# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2005, 2006, 2007, 2008, 2009, 2010, 2013, 2014, 2016 Synacor, Inc.
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

use Time::HiRes qw ( time );
use strict;

use lib '.';

use LWP::UserAgent;
use Getopt::Long;
use XmlElement;
use XmlDoc;
use Soap;
use ZimbraSoapTest;

my $ACCTNS = "urn:zimbraAdmin";
my $MAILNS = "urn:zimbraAdmin";

# If you're using ActivePerl, you'll need to go and install the Crypt::SSLeay
# module for htps: to work...
#
#         ppm install http://theoryx5.uwinnipeg.ca/ppms/Crypt-SSLeay.ppd
#

# app-specific options
my ($mbox, $action, $types, $ids);

#standard options
my ($user, $pw, $host, $help);  #standard
GetOptions("u|user=s" => \$user,
           "pw=s" => \$pw,
           "h|host=s" => \$host,
           "m|mbox=s" => \$mbox,
           "a|action=s" => \$action,
           "t|types=s" => \$types,
           "ids=s" => \$ids,
           "help|?" => \$help);

if (!defined($user)) {
  die "USAGE: $0 -u USER -m MAILBOXID -a ACTION [-pw PASSWD] [-h HOST] [-t TYPES] [-ids IDS]";
}

my $z = ZimbraSoapTest->new($user, $host, $pw);
$z->doAdminAuth();

my %args = ( 'action' => $action );


my $d = new XmlDoc;
$d = new XmlDoc;
$d->start('ReIndexRequest', $MAILNS, \%args); {
  my %mbxArgs = ( 'id' => $mbox );
  if (defined $ids) {
    $mbxArgs{'ids'} = $ids;
  }
  if (defined $types) {
    $mbxArgs{'types'} = $types;
  }
  $d->add('mbox', $MAILNS, \%mbxArgs);
} $d->end();

print "\nOUTGOING XML:\n-------------\n";
my $out =  $d->to_string("pretty");
$out =~ s/ns0\://g;
print $out."\n";

my $start = time;
my $firstStart = time;

my $response = $z->invokeAdmin($d->root());

print "\nRESPONSE:\n--------------\n";
$out =  $response->to_string("pretty");
$out =~ s/ns0\://g;
print $out."\n";


