package ZenNet;

use Mojo::Base 'Mojolicious';

use ZenNet::Initializers::Config ();
use ZenNet::Initializers::Router ();
use ZenNet::Initializers::Plugins ();

use Cwd ();
use DateTime ();
use File::Spec ();
use Module::Load 'load';
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

    $self -> setup_sessions();

    ZenNet::Initializers::Router -> main( $self -> routes() );

    return;
}

sub setup_sessions {

    my ( $self ) = @_;
    my $oid_class = 'MongoDB::OID';

    return unless eval{ load $oid_class; 1 };

    my $sessions = $self -> sessions();
    my $model = $self -> model( 'users.sessions' );

    $sessions -> serialize( sub {

        my ( $hash ) = @_;
        my ( $sid ) = delete( @$hash{ 'sid', '_id' } );
        $hash -> { 'time' } = DateTime -> now();

        if( defined $sid ) {

            $model -> update(
                { _id => $oid_class -> new( value => $sid ) },
                $hash,
                { safe => 1, upsert => 1 },
            );

        } else {

            $sid = $model -> insert( $hash, { safe => 1 } ) -> value();
        }

        delete( $hash -> { 'time' } );
        return $hash -> { 'sid' } = $sid;
    } );

    $sessions -> deserialize( sub {

        my ( $sid ) = @_;
        my $hash = $model -> find_one( { _id => $oid_class -> new( value => $sid ) } );

        $hash //= {};
        $hash -> { 'sid' } = $sid;
        delete( @$hash{ 'time', '_id' } );

        return $hash;
    } );

    return;
}

1;

__END__
