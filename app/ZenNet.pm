package ZenNet;

use Mojolicious::Lite;

get '/' => sub {

    my ( $self ) = @_;

    $self -> render( text => 'Hello, world!' );
};

app -> start();
