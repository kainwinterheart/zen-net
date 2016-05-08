package ZenNet::Apps::FiolentMys;

use Mojo::Base 'ZenNet::App';

use File::Spec ();

sub docroot {
    return $_[0]->zapp_config->{root};
}

sub doc_path {
    my ($self, $path) = @_;

    $path =~ s/\0//g;

    return File::Spec->rel2abs(
        File::Spec->catfile(
            File::Spec->no_upwards(
                File::Spec->splitdir(
                    File::Spec->abs2rel(
                        $path,
                        $self->docroot
                    )
                )
            )
        ),
        $self->docroot
    );
}

1;

__END__
