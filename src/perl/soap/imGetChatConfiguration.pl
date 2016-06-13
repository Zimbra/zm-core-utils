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
use Getopt::Long;
use lib '.';
use LWP::UserAgent;
use Getopt::Long;
use ZimbraSoapTest;
use XmlElement;
use XmlDoc;
use Soap;

my ($thread, $addr, $ownermode);

my ($user, $pw, $host, $help);  #standard
GetOptions("u|user=s" => \$user,
           "pw=s" => \$pw,
           "h|host=s" => \$host,
           "help|?" => \$help,
           "thread=s" => \$thread,
           "o|ownermode" => \$ownermode,
           "addr=s" => \$addr,
          );

if (!defined($user) ||
    (!defined($thread) && !defined($addr))) {
  print "USAGE: $0 -u USER (-t thread OR -a addr) [-o]\n";
  exit 1;
}

# if (!defined($pw) || ($pw eq "")) {
#   $pw = "test123";
# }

# if (!defined($host) || ($host eq "")) {
#   $host = "http://localhost:7070/service/soap";
# } else {
#   $host = $host . "/service/soap";
# }

#my $cmd;

# if (!defined($ownermode)) {
#   $cmd = "-m $user -p $pw -t im -u $host/service/soap -v IMGetChatConfigurationRequest/\@thread=\"$thread\"";
# } else {
#   $cmd = "-m $user -p $pw -t im -u $host/service/soap -v IMGetChatConfigurationRequest/\@thread=\"$thread\" IMGetChatConfigurationRequest/\@requestOwnerConfig=\"1\"";
# }

# print "Running  'zmsoap $cmd'\n";
# print `zmsoap -v $cmd`;

my $z = ZimbraSoapTest->new($user, $host, $pw);
$z->doStdAuth();

my $d = new XmlDoc;
if (defined($thread)) {
  $d->start('IMGetChatConfigurationRequest', $Soap::ZIMBRA_IM_NS, { 'thread' => $thread,
                                                                    'requestOwnerConfig'=> defined($ownermode) ? "1" : "0",
                                                                  });
} else {
  $d->start('IMGetChatConfigurationRequest', $Soap::ZIMBRA_IM_NS, { 'addr' => $addr,
                                                                    'requestOwnerConfig'=> defined($ownermode) ? "1" : "0",
                                                                  });
}
$d->end();  

my $response = $z->invokeMail($d->root());

print "REQUEST:\n-------------\n".$z->to_string_simple($d);
print "RESPONSE:\n--------------\n".$z->to_string_simple($response);

