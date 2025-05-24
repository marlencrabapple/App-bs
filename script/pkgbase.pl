#!/usr/bin/env perl

use utf8;
use v5.40;

use IPC::Run3;

our @pkg = ();

foreach my $arg (@ARGV) {
    my ( @out, $err );
    run( [ qw"expac '%e'", "^$arg\$" ], undef, \@out, $err );

    #my $status = $? >> 8;
    my $status = $?;

    if ($err) {
        warn "$?: $err";
        next;
    }

    say join '', @out;
}
