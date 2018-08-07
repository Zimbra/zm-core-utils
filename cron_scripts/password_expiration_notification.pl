#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use JSON;
use File::Slurp qw(read_file);
use POSIX qw(strftime);
use Pod::Usage qw(pod2usage);
use Time::Piece;
use FindBin;
use Parallel::ForkManager;
use LWP::UserAgent;

=head1 NAME

password_expiration_notification.pl - notify end users to change their password before expire

=head1 SYNOPSIS

  password_expiration_notification.pl [-help] [-debug] [-send_sms] [-pass_expiration_days <numExpDays>] [-notification_days <numNotiDays>] [-max_proc <maxNumProc>] -mail_file <mailFilePath> -sms_file <smsFilePath>

=head1 DESCRIPTION

This script allow us to detect in advance when a password is going to expire and notify end users that they need to change their password through Email and SMS.
Mail and SMS content will have two placeholders {displayName} and {numDays} which will be replaced with actual value.
{displayName} - user's display name
{numDays} - number of days that password is going to expire

=head1 OPTIONS

=over

=item -help

Prints the help message.

=item -pass_expiration_days I<numExpDays>

Specifies number of days for password expiration limit (default is 90 days).

=item -notification_days I<numNotiDays>

Specifies notification period in days (default is 14 days).

=item -mail_file I<mailFilePath>

Specifies full file path, this file contains mail content to send for password notification.

=item -sms_file I<smsFilePath>

Specifies full file path, this file contains SMS content to send for password notification.

=item -max_proc I<maxNumProc>

Specifies maximum number of processes to be created to send mail/sms (default is 10).

=item -debug

Enable debug output.

=item -send_sms

Enable sending SMS.


=back

=cut

use lib "$FindBin::Bin/lib";
use ZCS::CustomAPI;

my ( $Debug, $SendSMS );
my $config_file = "$FindBin::Bin/config/config.json";

my %opts   = process_options();
my $config = process_config();

my $notification_compare_days =
  $opts{pass_expiration_days} - $opts{notification_days};
my $pass_expiration_year_days = strftime( '%j',
    localtime( time() - $opts{pass_expiration_days} * ( 24 * 60 * 60 ) ) );
my $notification_timestamp =
  strftime( '%Y%m%d000000',
    localtime( time() - $notification_compare_days * ( 24 * 60 * 60 ) ) )
  . "Z";

my $soap_api = ZCS::CustomAPI->new(
    conf => {
        SOAPURI => "https://"
          . $config->{MAILSTOREHOST}
          . ":7071/service/admin/soap",
        SOAPUser => $config->{MAILSTOREUSER},
        SOAPPass => $config->{MAILSTOREPWD},
    },
    debug => $Debug
);

# search for accounts whose status are either of locked, lockout or pending
# and last login is earlier than specified days $last_login_days
my @data;
if ($soap_api) {
    my %args = (
        "query" =>
"(&(zimbraPasswordModifiedTime<=$notification_timestamp)(zimbraAccountStatus=active)(!(zimbraIsAdminAccount=TRUE))(!(zimbraIsDelegatedAdminAccount=TRUE)))",
        "attrs" =>
          "uid,zimbraId,mobile,mail,displayName,zimbraPasswordModifiedTime"
    );

    if ( my $searched_users = eval { $soap_api->searchdirectory(%args) } ) {
        my $path = "/Envelope/Body/SearchDirectoryResponse";
        my $i    = 0;
        foreach my $acc ( $searched_users->dataof("$path/account") ) {
            $i++;
            my $msom = $searched_users->match("$path/[$i]")
              or die("MATCH '$path/[$i]' failed\n");

            my $users_attr = getSoapResponseData($acc);
            if ( defined $users_attr->{'zimbraPasswordModifiedTime'} ) {
                my $zimbraPasswordModifiedTime =
                  $users_attr->{'zimbraPasswordModifiedTime'};
                $zimbraPasswordModifiedTime =
                  substr $zimbraPasswordModifiedTime, 0, 12;
                my $pass_expiration_year_days_users =
                  Time::Piece->strptime( $zimbraPasswordModifiedTime,
                    "%Y%m%d%H%M%S" );
                my $expire_in_days =
                  $pass_expiration_year_days -
                  $pass_expiration_year_days_users->yday;
                $users_attr->{'expire_in_days'} = $expire_in_days;
            }
            push @data, $users_attr;
        }
    }
    else {
        warn(   "Error: SearchDirectoryRequest "
              . $soap_api->Error
              . " via $config->{MAILSTOREHOST} \n" );
    }
    if ( scalar @data != 0 ) {
        my $pm = Parallel::ForkManager->new( $opts{max_proc} );
      ACCOUNTS:
        foreach my $acc (@data) {
            $pm->start and next ACCOUNTS;
            my $mail           = $acc->{mail};
            my $mobile         = $acc->{mobile};
            my $displayName    = $acc->{displayName} || 'User';
            my $expire_in_days = $acc->{'expire_in_days'};
            if ( $mail ) {
                my $mail_content = $config->{mail_content};
                $mail_content =~ s/{displayName}/$displayName/g;
                $mail_content =~ s/{numDays}/$expire_in_days/g;
                my $mail_data = {
                    'to' => $mail,
                    'subject' =>
"Your Mail access password expire in $acc->{'expire_in_days'} days",
                    'body' => $mail_content
                };
                if ( my $sendmail =
                    eval { $soap_api->sendmessage($mail_data) } )
                {
                    warn("DEBUG: Mail sent to $mail\n") if ($Debug);
                }
                else {
                    warn( "Error: for $mail on sending mail. Message: "
                          . ZCS::CustomAPI->Error );
                }
            }
            if ( $mobile && $SendSMS ) {
                my $sms_content = $config->{sms_content};
                $sms_content =~ s/{displayName}/$displayName/g;
                $sms_content =~ s/{numDays}/$expire_in_days/g;
                my $sms_url =
"$config->{SMSHOST}?username=$config->{SMSUSER}&pin=$config->{SMSPIN}&mnumber=$mobile&message=$sms_content";

#https://hostname/HttpLink?username=zimbra.sms&pin=redacted&message=hifromnic&mnumber=919922429908&signature=NICSMS

                my $sms_res = LWP::UserAgent->new->get($sms_url);

                #{ "_rc": 500, "_msg": "SMS Sent Successfully" }
                if ( $sms_res->{'_rc'} != 000 ) {
                    warn(
"Error: for $mail on sending SMS. Code: $sms_res->{'_rc'} Message: $sms_res->{'_msg'}"
                    );
                }
                else {
                    warn("DEBUG: SMS sent to user $mail\n") if ($Debug);
                }
            }
            $pm->finish;
        }
        $pm->wait_all_children;
    }
    else {
        warn("DEBUG: No users found!\n") if ($Debug);
    }

}
else {
    pod2usage(
        -exitval => 1,
        -msg     => ZCS::CustomAPI->Error
    );
}

sub getSoapResponseData {
    my $searched_result = shift;
    my $inter           = $searched_result->{'_value'}[0];
    my $return_attr     = {};
    foreach my $attrs ( @{ $$inter->{'_value'} } ) {
        $return_attr->{ $attrs->attr->{'n'} } = $attrs->value;
    }
    return $return_attr;
}

sub process_options {
    my %opts = (
        pass_expiration_days => 90,
        notification_days    => 14,
		max_proc             => 10
    );

    GetOptions( \%opts, "help", "debug", "send_sms", "pass_expiration_days=i",
        "notification_days=i", "mail_file=s", "sms_file=s", "max_proc=i" )
      or pod2usage( -verbose => 99, -sections => "SYNOPSIS", -exitval => 1 );

    pod2usage(1) if ( $opts{help} );
    $Debug   = $opts{debug} || 0;
	$SendSMS = $opts{send_sms} || 0;

    podusage( 1, "max_proc should not be negative number." )
      if ( $opts{max_proc} < 0 );
	podusage( 1, "pass_expiration_days should not be negative number." )
      if ( $opts{pass_expiration_days} < 0 );
	podusage( 1, "notification_days should not be negative number." )
      if ( $opts{notification_days} < 0 );  
	  
	return %opts;
}

sub process_config {
    my $config;

    my $conf_content = scalar read_file( $config_file, err_mode => 'carp' )
      or die("Unable to read config file.\n");
    $config = JSON->new->utf8->relaxed->decode($conf_content);
    podusage( 1, "MAILSTOREHOST is not defined in config file." )
      unless ( $config->{MAILSTOREHOST} );
    podusage( 1, "MAILSTOREUSER is not defined in config file." )
      unless ( $config->{MAILSTOREUSER} );
    podusage( 1, "MAILSTOREPWD is not defined in config file." )
      unless ( $config->{MAILSTOREPWD} );
    podusage( 1, "SMSHOST is not defined in config file." )
      unless ( $config->{SMSHOST} );
    podusage( 1, "SMSUSER is not defined in config file." )
      unless ( $config->{SMSUSER} );
    podusage( 1, "SMSPIN is not defined in config file." )
      unless ( $config->{SMSPIN} );
    podusage( 1, "SMSSENDERID is not defined in config file." )
      unless ( $config->{SMSSENDERID} );

    if ( $opts{mail_file} ) {
        $config->{mail_content} =
          scalar read_file( $opts{mail_file}, err_mode => 'carp' )
          or die("Unable to read mail content file.\n");
    }
    else {
        podusage( 1, "file path missing for 'mail_file'." );
    }

    if ( $opts{sms_file} ) {
        $config->{sms_content} =
          scalar read_file( $opts{sms_file}, err_mode => 'carp' )
          or die("Unable to read sms content file.\n");
    }
    else {
        podusage( 1, "file path missing for 'sms_file'." );
    }

    return $config;
}

sub podusage {
    my ( $code, $msg ) = @_;
    pod2usage(
        -exitval => $code,
        -msg     => $msg
    );
}
