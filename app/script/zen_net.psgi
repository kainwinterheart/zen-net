#!/usr/bin/perl -w

use strict;
use warnings;

use Plack::Builder;

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

builder {

    require Mojolicious::Commands;
    Mojolicious::Commands->start_app('ZenNet');
};
