package ZenNet::SRP::Utils;

use strict;
use warnings;

use Crypt::SRP ();


sub client {

    return Crypt::SRP -> new( 'RFC5054-1024bit', 'SHA1' );
}

sub salt {

    my ( $self, $size ) = @_;

    return unpack( 'H*', $self -> client() -> random_bytes( ( defined( $size ) ? $size : () ) ) );
}


1;

__END__
