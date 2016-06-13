#!/usr/bin/perl -w
# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2005, 2007, 2008, 2009, 2010, 2013, 2014, 2016 Synacor, Inc.
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

use Date::Parse;
use Time::HiRes qw ( time );
use strict;

use lib '.';

use LWP::UserAgent;
use Getopt::Long;
use ZimbraSoapTest;
use XmlElement;
use XmlDoc;
use Soap;

# specific to this app
my ($to, $msg, $typing, $html);

#standard options
my ($user, $pw, $host, $help);  #standard

GetOptions("u|user=s" => \$user,
           "pw=s" => \$pw,
           "h|host=s" => \$host,
           "help|?" => \$help,
           # add specific params below:
           "typing"=>\$typing,
           "t=s"=>\$to,
           "m=s"=>\$msg,
           "html=s"=>\$html,
          );

if (!defined($user) || !defined($to)) {
    print "USAGE: imsend -u USER [-typing] -t (ADDRESS|THREAD) [-m MESSAGE] [-html HTML]\n";
    exit 1;
}

my $z = ZimbraSoapTest->new($user, $host, $pw);
$z->doStdAuth();

my $d = new XmlDoc;
$d->start('IMSendMessageRequest', $Soap::ZIMBRA_IM_NS);

if ($to =~ m/.*\@.*/) {
    $d->start('message', undef, { "addr" => $to} );
} else {
    $d->start('message', undef, { "thread" => $to} );
}

if (defined($msg)) {
  $d->start("body");

  if (defined($msg)) {
    $d->add("text", undef, undef, $msg);
  }

  if (defined($html)) {
    $d->add("html", undef, undef, $html);
  }
  
  $d->end();
}

if (defined($typing)) {
  $d->add("typing");
}

$d->end(); #message
$d->end(); #request


my $response = $z->invokeMail($d->root());

print "REQUEST:\n-------------\n".$z->to_string_simple($d);
print "RESPONSE:\n--------------\n".$z->to_string_simple($response);

