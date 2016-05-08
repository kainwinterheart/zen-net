package ZenNet::Apps::FiolentMys::UploadFile;

use Mojo::Base 'ZenNet::Apps::FiolentMys';

use File::Spec ();
use Digest::MD5 'md5_hex';

sub upload {
    my $self = shift;
    my $file = $self->param('file');
    my $max_upload_size = $self->zapp_config('max_upload_size');

    if($file->size > $max_upload_size) {
        $self->res->code(500);

        return $self->render(json => {
            error => 'File is too big',
        });
    }

    my $md5 = md5_hex(scalar($file->slurp));
    my $root = $self->docroot;
    my $path = $root;

    foreach my $part (qw/imgs upload/, substr($md5, 0, 2, ''), substr($md5, 0, 4, '')) {
        $path = File::Spec->catfile($path, $part);

        unless(-e $path) {
            mkdir($path, 0755);
        }
    }

    $path = do {
        my $name = $file->filename;

        $name =~ s/^.*\///;
        $name =~ s/^.*\\//;
        $name =~ s/\0//g;

        File::Spec->catfile($path, "${md5}-${name}");
    };

    $file->move_to($path);

    $path =~ s/^\Q${root}\E//;
    $path = join('/', grep({ length($_) > 0 } File::Spec->splitdir($path)));

    return $self->render(json => {
        url => sprintf('https://%s/%s', $self->req->url->to_abs->host, $path),
    });
}

1;

__END__
