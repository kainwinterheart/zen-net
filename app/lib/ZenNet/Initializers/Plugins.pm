package ZenNet::Initializers::Plugins;

use strict;
use warnings;

sub main {

    my ( $self, $cfg, $plug ) = @_;

    $plug -> ( $self -> _mongo( $cfg -> ( 'mongo' ) ) );

    return;
}

sub _mongo {

    my ( $self, $cfg ) = @_;

    return ( mongodb => {
        host => $cfg -> { 'host' }
    } );
}

1;

__END__
