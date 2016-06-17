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
use lib '.';

use LWP::UserAgent;
use Getopt::Long;
use XmlDoc;
use Soap;
use ZimbraSoapTest;

# specific to this app
my ($threadId, $addr, $nickname, $pass);

#standard options
my ($user, $pw, $host, $help); #standard
GetOptions("u|user=s" => \$user,
           "pw=s" => \$pw,
           "h|host=s" => \$host,
           "help|?" => \$help,
           # add specific params below:
           "t=s", \$threadId,
           "a=s", \$addr,
           "n=s", \$nickname,
           "pass=s", \$pass,
          );



if (!defined($user) || !defined($addr) || defined($help)) {
    my $usage = <<END_OF_USAGE;
    
USAGE: $0 -u USER [-t threadId] -a addr [-n nickname] [-pass room_password]
END_OF_USAGE
    die $usage;
}

my $z = ZimbraSoapTest->new($user, $host, $pw);
$z->doStdAuth();

my $d = new XmlDoc;
my $searchName = "SearchRequest";

my %args = ('addr' => $addr, 'thread' => $threadId);

if (defined $nickname) {
  $args{'nick'} = $nickname;
}

if (defined $pass) {
  $args{'password'} = $pass;
}

$d->start("IMJoinConferenceRoomRequest", $Soap::ZIMBRA_IM_NS, \%args);

$d->end(); 

my $response = $z->invokeMail($d->root());

print "REQUEST:\n-------------\n".$z->to_string_simple($d);
print "RESPONSE:\n--------------\n".$z->to_string_simple($response);

