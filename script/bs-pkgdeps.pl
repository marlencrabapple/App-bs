#!/usr/bin/env perl
use Object::Pad qw(:experimental(:all));

use utf8;
use v5.40;

use Getopt::Long;
use Pod::Usage;
use IPC::Run3;
use List::Util qw(uniq);
use TOML::Tiny;

our $opts = {
    sync    => 1,
    local   => 0,
    search  => 1,
    'first' => 1,
    filter  => qr'^lib32.+'
};

GetOptions(
    $opts,
    'S',
    'Q',
    's',
    '1',
    'grep-pattern|regex|filter-results=s' =>
      sub ($patternstr) { $$opts{filter} = qr/$patternstrs/ },
    'help|h'    => sub { pod2usage( -verbose => 2 ) },
    'version|v' => sub { say "bs-pkgdeps.pl version 1.0"; exit },
);

sub run {
    foreach my $arg (@ARGV) {
        my $pipesuccess = run3(
            [ qw(expac -Ss -1 '%e'), $arg ],
            \undef,
            my $handle_stdout = sub ($line) {
                chomp $line;
                push @expac_stdout, $line;
                say $line;
            },
            my $handle_stderr = sub ($line) {
                warn $line;
            }
        );
    }
}
