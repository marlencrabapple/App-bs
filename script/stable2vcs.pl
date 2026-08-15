#!/usr/bin/env perl

use utf8;
use v5.44;

use Path::Tiny;
use IO::Handle::Common;

my $indir  = path( shift @ARGV );
my $inpath = path("$indir/PKGBUILD");
my @out;

my %rulemap = (
    source => { reg => qr/^\s*source=/ },
    sub    => sub ($line) {
        my $commit = '';
        ( "_commit=$commit", ( $line =~ s/#.+$/#commit=\$_commit"/r ) );
    }
);
%rulemap = map { $rulemap{$_}->{final} //= 1 } ( keys %rulemap );

my $i = 0;

LINE: foreach my $line ( map { chomp $_; $_ } $inpath->lines_utf8 ) {
    foreach my ( $name, $rule ) (%rulemap) {
        my $sub = sub ($line) {
            info '[' . ( $i + 1 ) . "] Running '$name'";
            dmsg $line, $rule;

            my @append = $$rule{sub}->($line);

            dmsg \@append;
            say STDERR ( scalar(@append) - 1 ) . ' lines added';

            $i++;
            @append;
        };
        my @append = $line =~ $$rule{reg} ? ( $sub->($line) ) : ($line);

        push @out, @append;
        next LINE if $rule->{final};
    }
}

say join "\n", @out
