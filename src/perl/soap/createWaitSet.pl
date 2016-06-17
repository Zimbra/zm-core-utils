#!/usr/bin/perl
# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2007, 2008, 2009, 2010, 2013, 2014, 2016 Synacor, Inc.
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

# If you're using ActivePerl, you'll need to go and install the Crypt::SSLeay
# module for htps: to work...
#
#         ppm install http://theoryx5.uwinnipeg.ca/ppms/Crypt-SSLeay.ppd
#
# specific to this app
my ($defTypes, $accounts, $admin, $allAccounts);

#standard options
my ($user, $pw, $host, $help); #standard
my ($name, $value);
GetOptions("u|user=s" => \$user,
           "pw=s" => \$pw,
           "h|host=s" => \$host,
           "help|?" => \$help,
           # add specific params below:
           "d=s"  => \$defTypes,
           "a=s@" => \$accounts,
           "admin" => \$admin,
           "allAccounts" => \$allAccounts,
          );

if (!defined($user) || defined($help) || !defined($defTypes)) {
  my $usage = <<END_OF_USAGE;
    
USAGE: $0 -u USER -d defTypes [-admin [-allAccounts]] [-a account -a account...]
END_OF_USAGE
    die $usage;
}

my $z = ZimbraSoapTest->new($user, $host, $pw);

my $urn;
my $requestName;

if (defined($admin)) {
  $z->doAdminAuth();
  $urn = $Soap::ZIMBRA_ADMIN_NS;
  $requestName = "AdminCreateWaitSetRequest";
} else {
  $z->doStdAuth();
  $urn = $Soap::ZIMBRA_MAIL_NS;
  $requestName = "CreateWaitSetRequest";
}

my %args =  (  'defTypes' => "$defTypes" );

if (defined $allAccounts) {
  $args{'allAccounts'} = "1";
}
              

my $d = new XmlDoc;
  
$d->start($requestName, $urn, \%args);

if (defined $accounts) {
  $d->start("add");
  {
    foreach my $a (@$accounts) {
      (my $aid, my $tok) = split /,/,$a;
      if (!defined $tok) {
        $d->add("a", undef, { 'name' => $a, }); #'token'=>"608"
      } else {
        $d->add("a", undef, { 'name' => $aid, 'token'=>$tok}); 
      }
    }
  } $d->end(); # add
}
$d->end(); # 'CreateWaitSetRequest'

my $response;

if (defined($admin)) {
  $response = $z->invokeAdmin($d->root());
} else {
  $response = $z->invokeMail($d->root());
}

print "REQUEST:\n-------------\n".$z->to_string_simple($d);
print "RESPONSE:\n--------------\n".$z->to_string_simple($response);

          
