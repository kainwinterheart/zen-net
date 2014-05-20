package ZenNet;

use Mojo::Base 'Mojolicious';

use ZenNet::Initializers::Config ();
use ZenNet::Initializers::Router ();
use ZenNet::Initializers::Plugins ();

use Cwd ();
use File::Spec ();
use File::Basename ();

# This method will run once at server start
sub startup {

    my ( $self ) = @_;

    my $root = Cwd::realpath( File::Spec -> catfile(
        File::Basename::dirname( $INC{ 'ZenNet.pm' } ),
        File::Spec -> updir()
    ) );

    $self -> helper( root => sub{ $root } );

    ZenNet::Initializers::Config -> main( $self );

    ZenNet::Initializers::Plugins -> main(
        sub{ return $self -> cget( @_ ) },
        sub{ return $self -> plugin( @_ ) }
    );

    ZenNet::Initializers::Router -> main( $self -> routes() );

    return;
}

1;

__END__
