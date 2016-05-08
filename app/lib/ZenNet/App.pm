package ZenNet::App;

use Mojo::Base 'ZenNet::BaseController';

sub user_must_can {
    my ($self, $action) = @_;

    unless($self->can_user($action)) {
        die("User must can ${action}");
    }

    return;
}

sub can_user {
    my ($self, $action) = @_;
    my $uid = $self->session('uid');

    # TODO
    my $rights = $self->zapp_config->{rights}->{$uid};

    return !!(defined($rights) && $rights->{$action});
}

sub zapp_name {
    my @parts = split(/::/, (ref($_[0]) || $_[0]));

    if(($parts[0] eq 'ZenNet') && ($parts[1] eq 'Apps')) {
        return $parts[2];

    } else {
        die("Bad app: " . join('::', @parts));
    }
}

sub zapp_config {
    return $_[0]->app->cget('app:' . $_[0]->zapp_name);
}

1;

__END__
