# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2004, 2005, 2006, 2007, 2010, 2013, 2014, 2016 Synacor, Inc.
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
package SuddsException;

use strict;
use warnings;

use UNIVERSAL qw(isa);

use overload '""' => \&to_string;

BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, @ErrorNames);

    # set the version for version checking
    $VERSION     = 1.00;
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = ();
}

our @EXPORT_OK;

sub new {
    my ($type, $mesg, $doc) = @_;
    my $self = {};
    bless $self, $type;
    $self->{'mesg'} = $mesg;
    $self->{'doc'} = $doc;
    return $self;
}

sub message {
    my $self = shift;
    return $self->{'mesg'};
}

sub document {
    my $self = shift;
    return $self->{'doc'};
}

sub verbose_message {
    my $self = shift;
    my $m = $self->{'mesg'};
    my $doc = $self->{'doc'};
    my $msg = "SuddsException: $m";
    #$msg .= ": doc: ".$doc->to_string() if (defined($doc));
    return $msg;
}

sub to_string {
    my ($self) = @_;
    return $self->verbose_message();
}

1;
