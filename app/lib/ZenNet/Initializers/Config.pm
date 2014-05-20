package ZenNet::Initializers::Config;

use strict;
use warnings;

use File::Spec ();

use constant {

    FILENAME => 'config.yaml',
};

sub main {

    my ( $self, $app ) = @_;

    my $cfg = $app -> plugin( yaml_config => {
        file => File::Spec -> catfile( $app -> root(), FILENAME ),
        class => 'YAML',
    } );

    $app -> helper( cget => sub {

        my $wa = wantarray();
        my ( $self, @keys ) = @_;

        return ( $wa ? @$cfg{ @keys } : $cfg -> { $keys[ 0 ] } );
    } );

    return;
}

1;

__END__
