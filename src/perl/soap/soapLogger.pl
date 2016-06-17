#!/usr/bin/perl
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
use warnings;
use lib '.';

use LWP::UserAgent;
use Getopt::Long;
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
# specific to this app
my ($add, $remove, $clear, $list);

#standard options
my ($user, $pw, $host, $help); #standard
my ($name, $value);
GetOptions("u|user=s" => \$user,
           "pw=s" => \$pw,
           "h|host=s" => \$host,
           "help|?" => \$help,
           # add specific params below:
           "a=s" => \$add,
           "r=s" => \$remove,
           "c", => \$clear,
           "l", => \$list
          );

if (!defined($add) && !defined($remove) && !defined($clear) && !defined($list)) {
  my $usage = <<END_OF_USAGE;
    
USAGE: $0 -u USER (-a account | -r account | -c | -l)
END_OF_USAGE
    die $usage;
}

my $z = ZimbraSoapTest->new($user, $host, $pw);
$z->doAdminAuth();

my $d = new XmlDoc;

my %args;

if (defined $add) {
  $args{'op'} = "ADD";
  $args{'id'} = $add;
} elsif (defined $remove) {
  $args{'op'} = "REMOVE";
  $args{'id'} = $remove;
} elsif (defined $clear) {
  $args{'op'} = "CLEAR";
} else {
  $args{'op'} = "LIST";
}

$d->start("SoapLoggerRequest", $MAILNS, \%args);
$d->end(); # 'WaitMultipleAccountsRequest'
  
my $response = $z->invokeAdmin($d->root());

print "REQUEST:\n-------------\n".$z->to_string_simple($d);
print "RESPONSE:\n--------------\n".$z->to_string_simple($response);

          
