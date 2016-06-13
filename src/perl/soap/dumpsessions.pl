#!/usr/bin/perl -w 
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

#
# Simple SOAP test-harness for the AddMsg API
#

use strict;
use lib '.';

use LWP::UserAgent;
use Getopt::Long;
use XmlElement;
use XmlDoc;
use Soap;
use ZimbraSoapTest;

my ($includeSessions, $groupByAccount);
#standard options
my ($user, $pw, $host, $help); #standard
GetOptions("u|user=s" => \$user,
           "p|port=s" => \$pw,
           "h|host=s" => \$host,
           "help|?" => \$help,
           "l" => \$includeSessions,
           "g" => \$groupByAccount,
          );

if (!defined($user)) {
    die "USAGE: $0 -u USER [-p PASSWD] [-h HOST] [-l] [-a]\n\t-l = list sessions\n\t-g group sessions by accountId";
}

my $z = ZimbraSoapTest->new($user, $host, $pw);
$z->doAdminAuth();

my %args;

if (defined($includeSessions)) {
  $args{'listSessions'} = "1";
}

if (defined($groupByAccount)) {
  $args{'groupByAccount'} = "1";
}

my $d = new XmlDoc;
$d->add('DumpSessionsRequest', $Soap::ZIMBRA_ADMIN_NS, \%args);

my $response = $z->invokeAdmin($d->root());
print "REQUEST:\n-------------\n".$z->to_string_simple($d);
print "RESPONSE:\n--------------\n".$z->to_string_simple($response);

