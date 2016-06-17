#!/usr/bin/perl -w
# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2005, 2007, 2009, 2010, 2013, 2014, 2016 Synacor, Inc.
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

use Time::HiRes qw ( time );
use strict;

use lib '.';

use LWP::UserAgent;

use XmlElement;
use XmlDoc;
use Soap;

######################################################################
#
# Set these here right now in lieu of command-line args
#
######################################################################
my $URL = 'http://localhost:7070/service/soap';
my $USER = 'user1';
my $PASSWORD = 'test123';
######################################################################

my $ACCTNS = "urn:zimbraAccount";
my $MAILNS = "urn:zimbraMail";

my $SOAP = $Soap::Soap12;
my $d = new XmlDoc;
$d->start('AuthRequest', $ACCTNS);
$d->add('account', undef, { by => "name"}, $USER);
$d->add('password', undef, undef, $PASSWORD);
$d->end();

my $authResponse = $SOAP->invoke($URL, $d->root());

print "AuthResponse = ".$authResponse->to_string("pretty")."\n";

my $authToken = $authResponse->find_child('authToken')->content;
print "authToken($authToken)\n";

my $sessionId = $authResponse->find_child('sessionId')->content;
print "sessionId = $sessionId\n";

my $context = $SOAP->zimbraContext($authToken, $sessionId);

my $contextStr = $context->to_string("pretty");
print("Context = $contextStr\n");


# <SaveRulesRequest>
#   <rules>
#     <r name="test">
#       <g op="anyof">
#         <c name="address" mod=":all" op=":contains" k0="From" k1="foo@bar.com"/>
#       </g>
#       <action name="tag">
#         <arg>fromme</arg>
#       </action>   
#     </r>
#   </rules>
# </SaveRulesRequest>

$d = new XmlDoc;
$d->add('GetRulesRequest', $MAILNS, undef);

print "\nOUTGOING XML:\n-------------\n";
my $out =  $d->to_string("pretty")."\n";
$out =~ s/ns0\://g;
print $out."\n";

my $response = $SOAP->invoke($URL, $d->root(), $context);
print "\nRESPONSE:\n--------------\n";
$out =  $response->to_string("pretty")."\n";
$out =~ s/ns0\://g; #hack - remove the soap namespace, makes response more pleasant on my eye
$out =~ s/\[&quot;/\"/g;
$out =~ s/\]&quot;/\"/g;
$out =~ s/&quot;/\"/g;
print $out."\n";



