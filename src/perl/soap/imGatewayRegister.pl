#!/usr/bin/perl -w
# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2007, 2009, 2010, 2013, 2014, 2016 Synacor, Inc.
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
my ($op, $gwName, $remName, $remPw);

#standard options
my ($user, $pw, $host, $help); #standard
GetOptions("u|user=s" => \$user,
           "pw=s" => \$pw,
           "h|host=s" => \$host,
           "help|?" => \$help,
           # add specific params below:
           "op=s" => \$op,
           "gw=s" => \$gwName,
           "rn=s" => \$remName,
           "rp=s" => \$remPw,
          );

my $usage = <<END_OF_USAGE;
USAGE: $0 -u USER -op reg -gw GATEWAY_NAME -rn REMOTE_NAME -rp REMOTE_PASSWORD
USAGE: $0 -u USER -op unreg -gw GATEWAY_NAME
END_OF_USAGE

if (!defined($user) || !defined($gwName) || !defined($op) || defined($help)) {
  die $usage;
}

if ($op eq "reg" && (!defined($remName) || !defined($remPw))) {
  die $usage;
}

my $z = ZimbraSoapTest->new($user, $host, $pw);
$z->doStdAuth();

my $d = new XmlDoc;

my %args = (
            'service' => $gwName,
            'op' => $op,
           );

if ($op eq "reg") {
  $args{'name'} = $remName;
  $args{'password'} = $remPw;
}

$d->add("IMGatewayRegisterRequest", $Soap::ZIMBRA_IM_NS, \%args);
my $response = $z->invokeMail($d->root());

print "REQUEST:\n-------------\n".$z->to_string_simple($d);
print "RESPONSE:\n--------------\n".$z->to_string_simple($response);

