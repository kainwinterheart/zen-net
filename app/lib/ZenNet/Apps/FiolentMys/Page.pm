package ZenNet::Apps::FiolentMys::Page;

use Mojo::Base 'ZenNet::Apps::FiolentMys';

use JSON 'decode_json';
use File::Copy 'move';
use File::Spec ();
use XML::Simple 'XMLin';
use Salvation::TC ();

sub open {
    my $self = shift;

    $self->user_must_can('edit');

    my $path = $self->doc_path($self->req->param('page'));
    my @data = ();

    if(-e $path) {
        if(open(my $fh, '<', $path)) {
            if(flock($fh, 2)) {
                my $id = undef;
                my $type = undef;
                my $data = '';

                while(defined(my $line = readline($fh))) {
                    if($line =~ m/^<!--block([0-9]+):([a-z]+)-->$/) {
                        $id = $1;
                        $type = $2;

                    } elsif(defined($type) && defined($id)) {
                        if($line =~ m/^<!--\/block-->$/) {
                            if($type eq 'gallery') {
                                $data = [map({$_->{href}} @{XMLin($data, ForceArray => 1)->{a}})];
                            }

                            push(@data, [$type, $id, $data]);

                            undef($id);
                            undef($type);

                        } else {
                            $data .= $line;
                        }
                    }
                }

                flock($fh, 8);
                close($fh);

            } else {
                close($fh);
                die("flock(${path}): $!");
            }

        } else {
            die("open(${path}): $!");
        }

    } else {
        warn("Path ${path} does not exist");
    }

    return $self->render(json => {
        page => $self->req->param('page'),
        content => \@data,
    });
}

sub save {
    my $self = shift;

    $self->user_must_can('edit');

    my $path = $self->doc_path($self->req->param('page'));
    my $tmp_path = "${path}.new";
    my $page_dir = do {
        my @parts = File::Spec->splitdir($path);
        pop(@parts);
        File::Spec->catfile(@parts);
    };

    my $header = File::Spec->abs2rel($self->doc_path("inc/header.html"), $page_dir);
    my $footer = File::Spec->abs2rel($self->doc_path("inc/footer.html"), $page_dir);

    my $data = decode_json($self->req->param('data'));
    Salvation::TC->assert($data, 'ArrayRef[ArrayRef(Str type, Int id, ArrayRef[Str]|Str data)]');

    if(open(my $fh, '>', $tmp_path)) {
        if(flock($fh, 2)) {
            $fh->print(sprintf('<!--# include file="%s" -->' . "\n", $header));

            while(defined(my $node = shift(@$data))) {
                $fh->print(sprintf('<!--block%d:%s-->' . "\n", @$node[1, 0]));

                if($node->[0] eq 'gallery') {
                    $fh->print('<div class="gallery">' . "\n");

                    foreach my $node (@{ $node->[2] }) {
                        $fh->print(sprintf('<a href="%s">' . "\n", $node));
                        $fh->print(sprintf('<img src="%s" title="" alt="" class="min-photo" />' . "\n", $node));
                        $fh->print('</a>' . "\n");
                    }

                    $fh->print('</div>' . "\n");

                } else {
                    $fh->print($node->[2] . "\n");
                }

                $fh->print('<!--/block-->' . "\n");
            }

            $fh->print(sprintf('<!--# include file="%s" -->' . "\n", $footer));

            flock($fh, 8);
            close($fh);

            my $move_result = move($tmp_path, $path);

            unless($move_result) {
                die("move(${tmp_path}, ${path}): $!");
            }

        } else {
            close($fh);
            die("flock(${tmp_path}): $!");
        }

    } else {
        die("open(${tmp_path}): $!");
    }

    return $self->render(json => {
        page => $self->req->param('page'),
    });
}

1;

__END__
