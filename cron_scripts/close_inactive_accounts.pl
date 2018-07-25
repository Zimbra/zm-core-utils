#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';

use Getopt::Long;
use ZCS::API;
use Data::Dumper;
use JSON;
use File::Slurp;
use POSIX qw(strftime);

my $config_file = 'config/config.json';
my %opts = ( last_login_days => 187 );

my $res = GetOptions( \%opts, "help", "debug", "last_login_days=i" );

if ( $opts{help} ) {
    print_usage();
    exit 0;
}
elsif ( !$res ) {
    print_usage();
    exit 1;
}

my $config = JSON->new->utf8->relaxed->decode( scalar read_file $config_file);
die "MAILSTOREHOST is not defined in config file"
  if ( !defined( $config->{MAILSTOREHOST} ) || $config->{MAILSTOREHOST} eq "" );
die "MAILSTOREUSER is not defined in config file"
  if ( !defined( $config->{MAILSTOREUSER} ) || $config->{MAILSTOREUSER} eq "" );
die "MAILSTOREPWD is not defined in config file"
  if ( !defined( $config->{MAILSTOREPWD} ) || $config->{MAILSTOREPWD} eq "" );

my $last_login_days = $opts{last_login_days};
my $last_login_timestamp =
  strftime( '%Y%m%d000000',
    localtime( time() - $last_login_days * ( 24 * 60 * 60 ) ) )
  . "Z";

my $soap_api = ZCS::API->new(
    conf => {
        SOAPURI => "https://"
          . $config->{MAILSTOREHOST}
          . ":7071/service/admin/soap",
        SOAPUser => $config->{MAILSTOREUSER},
        SOAPPass => $config->{MAILSTOREPWD},
    },
    debug => ( $opts{debug} ) ? 1 : 0
);

# search for accounts whose status are either of locked, lockout or pending
# and last login is earlier than specified days $last_login_days
my @data;
if ($soap_api) {
    my %args = (
        "query" =>
"(&(zimbraLastLogonTimestamp<=$last_login_timestamp)(!(zimbraIsAdminAccount=TRUE))(|(zimbraAccountStatus=locked)(zimbraAccountStatus=lockout)(zimbraAccountStatus=pending)))",
        "attrs" => "uid,zimbraId,zimbraAccountStatus,zimbraLastLogonTimestamp"
    );

    if ( my $searched_users = eval { $soap_api->searchdirectory(%args) } ) {
        my $path = "/Envelope/Body/SearchDirectoryResponse";
        my $i    = 0;
        foreach my $acc ( $searched_users->dataof("$path/account") ) {
            $i++;
            my $msom = $searched_users->match("$path/[$i]")
              or die("MATCH '$path/[$i]' failed\n");

            push @data, $acc->attr;
        }
    }
    else {
        warn(   "DEBUG: SearchDirectoryRequest "
              . $soap_api->Error
              . " via $config->{MAILSTOREHOST} \n" );
    }

    if ( scalar @data != 0 ) {
        foreach my $acc (@data) {
            my $zimbraId = $acc->{id};
            my $modify_data = { 'zimbraAccountStatus' => 'closed' };
            if ( my $modify_acc =
                eval { $soap_api->modifyaccount( $zimbraId, $modify_data ) } )
            {
                warn("DEBUG: $acc->{name} modified to closed status \n")
                  if ( $soap_api->Debug );
            }
            else {
                warn(   "DEBUG: ModifyAccountRequest "
                      . $soap_api->Error
                      . " via $config->{MAILSTOREHOST} \n" );
            }
        }
    }
    else {
        warn("DEBUG: No users found! \n") if ( $soap_api->Debug );
    }
}
else {
    warn( ZCS::API->Error );
}

sub print_usage {
    my $prog_name = substr( $0, rindex( $0, '/' ) + 1 );
    print <<END_PRINT;
This script will go through Zimbra's Internal LDAP and look for any account whose status is 'Inactive' and whose last login is greater than specified days. This script will modify their accounts status to 'closed' status.

Usage:
perl $prog_name [options]
--help    - print this message
--debug   - print debug message
--last_login_days - number of days to check for last login
END_PRINT
}
