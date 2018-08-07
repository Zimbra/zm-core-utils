package ZCS::CustomAPI;

use strict;
use warnings;

use SOAP::Lite ();

our $Debug = 0;
our $Error = '';

BEGIN {
    # avoid self signed SSL certificate rejection
    $ENV{"PERL_LWP_SSL_VERIFY_HOSTNAME"} = 0;

    # avoid default SSL_verify_mode SSL_VERIFY_NONE deprecated warning
    use LWP::Protocol::http ();
    @LWP::Protocol::http::EXTRA_SOCK_OPTS = ( SSL_verify_mode => 0 );
}

=head1 NAME

ZCS::CustomAPI - perl module for accessing Zimbra SOAP API

This program extracted required features from https://github.com/plobbes/zcs-api/blob/master/lib/ZCS/API.pm

=cut

sub new {
    my $class = shift;
    die("new: invalid arguments\n") if ( @_ % 2 );

    my $self = bless( {}, ref($class) || $class );
    my @args = @_;
    my ( $err, $key, $val );
    for ( my $i = 0 ; $i < $#args ; $i += 2 ) {
        ( $key, $val ) = ( $args[$i], $args[ $i + 1 ] );
        local ($@);
        eval {
            my $func = "arg_$key";
            $self->$func($val);
        };
        $err = $@;
        last if $err;
    }
    if ($err) {
        chomp($err);
        die("new: $key($val) failed: $err\n");
    }

    # attempt to populate conf via ENV if necessary
    $self->conf( {} ) unless ( $self->conf );

    return $self;
}

sub arg_conf  { shift->conf(@_); }
sub arg_debug { shift->Debug(@_); }

sub Debug {
    $Debug = $_[1] if ( @_ > 1 );
    return $Debug;
}

sub Error {
    $Error = $_[1] if ( @_ > 1 );
    return $Error;
}

sub conf_keys { return qw(SOAPURI SOAPUser SOAPPass); }

sub conf {
    my ( $self, $conf ) = @_;
    if ( @_ > 1 ) {
        die("conf not a HASHREF\n") unless ( ref($conf) eq "HASH" );
        my @req = $self->conf_keys;
        my @err;
        foreach my $k (@req) {
            push( @err, $k ) unless ( defined( $conf->{$k} ) );
        }
        die( ref($self) . "->conf: missing info: ", join( ", ", @err ), "\n" )
          if @err;
        $self->{_conf} = $conf;
    }
    return $self->{_conf};
}

sub soap {
    my $self = shift;
    unless ( exists( $self->{_soap} ) ) {

        #SOAP::Lite->import( +trace => "all" ) if $self->Debug;
        $self->{_soap} = SOAP::Lite->new(
            proxy    => $self->conf->{SOAPURI},
            autotype => 0
        );
    }
    return $self->{_soap};
}

sub soap_call {
    my $self = shift;
    my %opt  = @_;

    my $req = SOAP::Data->name( $opt{req} );
    $req->attr( $opt{attr} ) if $opt{attr};

    my @body = ref $opt{body} eq "ARRAY" ? @{ $opt{body} } : ( $opt{body} );
    my $resp;

    my ( $err, $try, $maxtry, $sec ) = ( undef, 0, 3, 0 );
    while ( !$resp && $try++ < $maxtry ) {
        local ($@);
        eval { $resp = $self->soap->call( $req, $opt{head}, @body ); };
        $err = $@;
        if ( _err($resp) =~ /Client auth credentials have expired/ ) {

            # reauthenticate for long running processes
            $opt{head} = $self->reauth( $opt{head} );
            $resp = undef;    # force retry
        }
        elsif ($err) {
            chomp($err);
            last unless ( $try < $maxtry );
            $sec += $try;    # back off a little more on each retry
            warn("soap_call $opt{req}: sleep($sec): try#$try error: $err\n");
            sleep($sec);
        }
    }

    if ( $err || $resp->fault ) {
        $self->Error( "error: $opt{req}"
              . ( $try > 1 ? " (try #$try)" : "" ) . ": "
              . ( $err || _err($resp) ) );
        return undef;
    }

    return $resp;
}

sub _err {
    my ($resp) = @_;
    return ("no response object") unless ($resp);
    if ( $resp->fault ) {
        return (
            (
                     $resp->faultcode
                  || $resp->valueof('/Envelope/Body/Fault/Detail/Error/Code')
            )
            . " "
              . (
                     $resp->faultstring
                  || $resp->valueof('/Envelope/Body/Fault/Reason/Text')
              )
              . (
                $Debug
                ? ( "; "
                      . $resp->fault->{detail}->{Error}->{Code} . ": "
                      . $resp->fault->{detail}->{Error}->{Trace} )
                : ""
              )
        );
    }
    if ( defined( $resp->valueof("//Fault/faultcode") ) ) {
        return (
                $resp->valueof("//Fault/faultcode") . " "
              . $resp->valueof("//Fault/faultstring")
              . (
                $Debug
                ? ( "; "
                      . $resp->valueof('//Fault/detail/Error/Code') . ": "
                      . $resp->valueof('//Fault/detail/Error/Trace') )
                : ""
              )
        );
    }
}

# expect no issues with token expiring
sub auth {
    my $self = shift;
    unless ( exists( $self->{_zimbra_auth} ) ) {

        # authenticate with zimbra to get AuthToken
        my $req = "AuthRequest";
        my $attr = { "xmlns" => "urn:zimbraAdmin" };
        my $head =
          SOAP::Header->name("context")->attr( { "xmlns" => "urn:zimbra" } );
        my $body = [
            SOAP::Data->name( name => $self->conf->{SOAPUser} )->type("string"),
            SOAP::Data->name( password => $self->conf->{SOAPPass} )
              ->type("string")
        ];

        my $resp = $self->soap_call(
            req  => $req,
            attr => $attr,
            head => $head,
            body => $body
        );
        die $self->Error unless $resp;

        # Convert authToken into value that can be passed to zimbra requests
        # and cache for all future requests
        $self->{_zimbra_auth} = SOAP::Header->name(
            "context" => \SOAP::Header->value(
                SOAP::Header->name(
                    "authToken" => $resp->valueof('//authToken')
                ),
            )
        )->attr( { xmlns => "urn:zimbra" } );
    }
    return $self->{_zimbra_auth};
}

=head2 reauth(auth)

Must pass the auth value that you want to reauthenticate.

This shouldn't ever need to be called directly soap_call should detect when a
token is no longer valid and automatically attempt to generate a new one
using this method.

  $za->reauth($self->auth);                         # re-auth admin

=cut

sub reauth {
    my ( $self, $auth ) = @_;
    if ( $auth == $self->{_zimbra_auth} ) {
        delete( $self->{_zimbra_auth} );
        return $self->auth;
    }
}

sub getaccount {
    my ( $self, $account ) = @_;

    my $req = "GetAccountRequest";
    my $attr = { "xmlns" => "urn:zimbraAdmin" };
    my $body =
      SOAP::Data->name( account => $account )->type("string")
      ->attr( { by => "name" } );

    return $self->soap_call(
        req  => $req,
        attr => $attr,
        head => $self->auth,
        body => $body
    );
}

sub modifyaccount {
    my ( $self, $id, $data ) = @_;

    #my $resp = $self->getaccount($account);

    my @attrs;
    foreach my $a ( keys %$data ) {
        push( @attrs,
            SOAP::Data->name( a => $data->{$a} )->type("string")
              ->attr( { n => $a } ) );
    }

    my $req  = "ModifyAccountRequest";
    my $attr = {
        "xmlns" => "urn:zimbraAdmin",
        "id"    => $id
    };

    return $self->soap_call(
        req  => $req,
        attr => $attr,
        head => $self->auth,
        body => \@attrs
    );
}

sub searchdirectory {
    my ( $self, %args ) = @_;

    my $req  = "SearchDirectoryRequest";
    my $attr = {
        "xmlns" => "urn:zimbraAdmin",
        "types" => "accounts",
        "query" => $args{query},
        'attrs' => "$args{attrs}"
    };
    my $body = SOAP::Data->type( "xml" => "" );

    return $self->soap_call(
        req  => $req,
        attr => $attr,
        head => $self->auth,
        body => $body
    );
}

sub sendmessage {
	my ( $self, $mail_data ) = @_;
    my $req  = "SendMsgRequest";
    my $attr = {
        "xmlns"  => "urn:zimbraMail",
        "noSave" => 1
    };

    #noSave - not to save in sent folder
    my $body = SOAP::Data->name(
        "m" => \SOAP::Data->value(
            SOAP::Data->name("e")
              ->attr( { t => 't', a => $mail_data->{'to'} } ),
            SOAP::Data->name( "su" => $mail_data->{'subject'} ),
            SOAP::Data->name("mp")
              ->attr( { ct => 'text/html', content => $mail_data->{'body'} } )
        )
    );

    return $self->soap_call(
        req  => $req,
        attr => $attr,
        head => $self->auth,
        body => $body
    );
}

1;
