package ZenNet::Apps::FiolentMys::Page;

use Mojo::Base 'ZenNet::Apps::FiolentMys';

use JSON 'decode_json';
use Encode 'decode_utf8', 'encode_utf8';
use File::Copy 'move';
use File::Spec ();
use URI::Escape 'uri_escape';
use XML::Simple 'XMLin';
use Salvation::TC ();

sub open {
    my $self = shift;

    $self->user_must_can('edit');

    my $path = $self->doc_path($self->req->param('page'));
    my @data = ();

    if(-e $path) {
        if(CORE::open(my $fh, '<', $path)) {
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
                            eval{ $data = decode_utf8($data) };

                            if($type eq 'gallery') {
                                eval{ $data = [map({$_->{href}} @{XMLin($data, ForceArray => 1)->{a}})] };

                                if($@) {
                                    die("$@: ${data}");
                                }
                            }

                            push(@data, [$type, $id, $data]);

                            undef($id);
                            undef($type);
                            $data = '';

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
        logged_in => !! $self->session('uid'),
    });
}

sub save {
    my $self = shift;

    $self->user_must_can('edit');

    my $page = $self->req->param('page');
    my $path = $self->doc_path($page);
    my $tmp_path = "${path}.new";
    my $page_dir = do {
        my @parts = File::Spec->splitdir($path);
        pop(@parts);
        File::Spec->catfile(@parts);
    };

    my $header = File::Spec->abs2rel($self->doc_path("inc/header.html"), $page_dir);
    my $footer = File::Spec->abs2rel($self->doc_path("inc/footer.html"), $page_dir);

    my $data = $self->req->param('data');
    eval{ $data = decode_utf8($data) };
    $data = decode_json(encode_utf8($data));

    Salvation::TC->assert($data, 'ArrayRef[ArrayRef(Str type, Int id, ArrayRef[Str]|Str data)]');

    if(CORE::open(my $fh, '>', $tmp_path)) {
        if(flock($fh, 2)) {
            $fh->print(sprintf('<!--# include file="%s" -->' . "\n", $header));
            $fh->print('<div id="apps_fiolentmys_widget"></div>' . "\n");
            $fh->print(sprintf('<script type="text/javascript" src="https://autumncoffee.com/app/fiolentmys/widget?page=%s"></script>' . "\n", uri_escape($page)));

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
        page => $page,
        logged_in => !! $self->session('uid'),
    });
}

sub widget {
    my $self = shift;
    my $template = 'no_edit_page';

    if($self->can_user('edit')) {
        $template = 'edit_page';
        $self->stash(page => uri_escape($self->req->param("page")));
    }

    return $self->render(template => "apps/fiolentmys/${template}", format => 'html');
}

1;

__END__
