#!/usr/bin/perl -w

use strict;
use warnings;

use Plack::Builder;

builder {

    require ZenNet;
};
