package ZenNet::SRP::Authenticate;

use Mojo::Base 'Mojolicious::Controller';

use ZenNet::SRP::Utils ();

use Email::Valid ();

use Encode 'decode_utf8';;


sub handshake {

    my ( $self ) = @_;

    my $login = lc( decode_utf8( $self -> param( 'I' ) ) );

    unless( Email::Valid -> address( $login ) ) {

        return $self -> error( 'Invalid email' );
    }

    my $user = $self -> model( 'users.list' ) -> find_one( { email => $login } );

    unless( defined $user || ! exists $user -> { 'verifier' } ) {

        return $self -> error( 'Invalid user' );
    }

    my $A = $self -> param( 'A' );

    my $srp = ZenNet::SRP::Utils -> client();

    unless( $srp -> server_verify_A( $A ) ) {

        return $self -> error( 'Invalid request' );
    }

    $srp -> server_init(
        $login,
        $user -> { 'verifier' },
        $user -> { 'salt' }
    );

    my ( $B, $b ) = $srp -> server_compute_B();

    $self -> session( srp_token => [ $login, $A, $B, $b ] );

    return $self -> render_xml( $self -> new_xml(
        r => {
            s => $user -> { 'salt' },
            B => $B,
        }
    ) );
}

sub authenticate {

    my ( $self ) = @_;

    my ( $login, $A, $B, $b ) = @{ $self -> session( 'srp_token' ) || [] };

    unless( $login && $A && $B && $b ) {

        return $self -> error( 'Invalid request' );
    }

    my $user = $self -> model( 'users.list' ) -> find_one( { email => $login } );

    unless( defined $user || ! exists $user -> { 'verifier' } ) {

        return $self -> error( 'Invalid user' );
    }

    my $srp = ZenNet::SRP::Utils -> client();

    $srp -> server_init( $login, $user -> { 'verifier' }, $user -> { 'salt' }, $A, $B, $b );

    my $M1 = $self -> param( 'M' );

    unless( $srp -> server_verify_M1( $M1 ) ) {

        return $self -> error( 'Invalid request' );
    }

    delete $self -> session() -> { 'srp_token' };

    $self -> session( uid => $user -> { '_id' } -> value() );

    my $M2 = $srp -> server_compute_M2();

    return $self -> render_xml( $self -> new_xml( M => $M2 ) );
}

sub error {

    my ( $self, $msg ) = @_;

    my $xml = $self -> new_xml( error => $msg );

    return $self -> render_xml( $xml );
}

1;

__END__
