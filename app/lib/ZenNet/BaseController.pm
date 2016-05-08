package ZenNet::BaseController;

use Mojo::Base 'Mojolicious::Controller';

use Module::Load 'load';

sub error {

    my ( $self, $msg ) = @_;

    return $self -> render( json => { error => $msg } );
}

sub check_app_rights {
    my ($self, $app, $action) = @_;
    load my $pkg = "ZenNet::Apps::${app}";
    my $method = "${pkg}::can_user";

    return (\&$method)->($self, $action);
}

1;

__END__
