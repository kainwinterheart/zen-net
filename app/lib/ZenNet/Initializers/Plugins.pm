package ZenNet::Initializers::Plugins;

use strict;
use warnings;

sub main {

    my ( $self, $cfg, $plug ) = @_;

    $plug -> ( $self -> _mongo( $cfg -> ( 'mongo' ) ) );
    $plug -> ( $self -> _xml() );

    return;
}

sub _mongo {

    my ( $self, $cfg ) = @_;

    return ( mongodb => {
        host => $cfg -> { 'host' }
    } );
}

sub _xml {

    my ( $self ) = @_;

    return ( 'XML::Loy' => {} );
}

1;

__END__
