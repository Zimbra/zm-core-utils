#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use JSON;
use File::Slurp qw(read_file);
use POSIX qw(strftime);
use Pod::Usage qw(pod2usage);
use FindBin;

=head1 NAME

close_inactive_accounts.pl - to make inactive accounts to closed status

=head1 SYNOPSIS

  close_inactive_accounts.pl [-help] [-debug] -last_login_days <numDays>
  close_inactive_accounts.pl -last_login_days 187

=head1 DESCRIPTION

This script will search through Zimbra's Internal LDAP via SOAP API for accounts that have a last login older than the specified days and status is one of 'locked/lockout/pending'.
Matching accounts will have their account status updated to 'closed' status.

=head1 OPTIONS

=over

=item -help

Prints the help message.

=item -last_login_days I<numDays>

Specifies number of days to check for last login.

=item -debug

Enable debug output.

=back

=cut

use lib "$FindBin::Bin/lib";
use ZCS::CustomAPI;
my $config_file = "$FindBin::Bin/config/config.json";

my %opts = ( last_login_days => 187 );

GetOptions( \%opts, "help", "debug", "last_login_days=i" )
  or pod2usage( -verbose => 99, -sections => "SYNOPSIS", -exitval => 1 );

pod2usage(1) if ( $opts{help} );

my $conf_content = scalar read_file( $config_file, err_mode => 'carp' )
  or die("Unable to read config file.\n");
my $config = JSON->new->utf8->relaxed->decode($conf_content);
unless ( $config->{MAILSTOREHOST} ) {
    pod2usage(
        -exitval => 1,
        -msg     => "MAILSTOREHOST is not defined in config file."
    );
}
unless ( $config->{MAILSTOREUSER} ) {
    pod2usage(
        -exitval => 1,
        -msg     => "MAILSTOREUSER is not defined in config file."
    );
}
unless ( $config->{MAILSTOREPWD} ) {
    pod2usage(
        -exitval => 1,
        -msg     => "MAILSTOREPWD is not defined in config file."
    );
}

my $last_login_days;
if ( $opts{last_login_days} > 0 ) {
    $last_login_days = $opts{last_login_days};
}
else {
    pod2usage(
        -exitval => 1,
        -msg     => "last_login_days should be greater than 0."
    );
}

my $last_login_timestamp =
  strftime( '%Y%m%d000000',
    localtime( time() - $last_login_days * ( 24 * 60 * 60 ) ) )
  . "Z";

my $soap_api = ZCS::CustomAPI->new(
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
"(&(zimbraLastLogonTimestamp<=$last_login_timestamp)(!(zimbraIsAdminAccount=TRUE))(!(zimbraIsDelegatedAdminAccount=TRUE))(|(zimbraAccountStatus=locked)(zimbraAccountStatus=lockout)(zimbraAccountStatus=pending)))",
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
        pod2usage(
            -exitval => 1,
            -msg     => "SearchDirectoryRequest: "
              . $soap_api->Error . " via "
              . $config->{MAILSTOREHOST}
        );
    }

    if ( scalar @data != 0 ) {
        foreach my $acc (@data) {
            my $zimbraId = $acc->{id};
            my $modify_data = { 'zimbraAccountStatus' => 'closed' };
            if ( my $modify_acc =
                eval { $soap_api->modifyaccount( $zimbraId, $modify_data ) } )
            {
                warn("DEBUG: $acc->{name} modified to closed status\n")
                  if ( $soap_api->Debug );
            }
            else {
                pod2usage( -msg => "ModifyAccountRequest: "
                      . $soap_api->Error . " via "
                      . $config->{MAILSTOREHOST}
                      . "for user: "
                      . $acc->{name} );
            }
        }
    }
    else {
        warn("DEBUG: No users found! \n") if ( $soap_api->Debug );
    }
}
else {
    pod2usage(
        -exitval => 1,
        -msg     => ZCS::CustomAPI->Error
    );
}

