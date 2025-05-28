#!/usr/bin/env perl

use utf8;
use v5.40;

use lib 'lib';

use IPC::Run3;
use Const::Fast;
use Data::Dumper;
use List::Util 'uniq';

our $DEBUG        = $ENV{DEBUG}        // 0;
our $SHORTCIRCUIT = $ENV{SHORTCIRCUIT} // 0;

const our $pkgnamebase_re => qr/[:a-zA-Z0-9\@_\+]{1}[a-zA-Z0-9\@_\+\.\+]+/;

# Prepends pkgname
const our $repo_re => qr/(?:([\/])\/)?/;
const our $type_re => qr/(?:(lib)\:)?/;

const our %sep_re => ( ver => qr/(\=|[\<\>]\=?)/, dssc => qr/(:\s*(.+))?/ );
const our $not_pkgver_rew => quotemeta(':/-') . '\s';

const our $fpath_re => qr/^(?:\/)?([a-zA-Z0-9\@_\+\.\+]+\/)?([a-zA-Z0-9\@_\+\.\+]+)$/;

# Apppends pkgname (cmpop, ver, description)

our @pkg        = ();
our %outbuffers = ();

sub expac_parse_line ( $line, %opts ) {
    $opts{on_parse_success}->( $line, %opts );
}

sub handle_run3_out ( $in, %opts ) {
    chomp $in;
    return undef unless $in;

    push $opts{out}->@*, expac_parse_line( $in, %opts );
}

sub parse_pkgline ($pkgstr, %opts) {

}

foreach my $arg (@ARGV) {
    my ( @out, $err );
    run3(
        [ qw"expac -Qs %e", "^$arg\$" ],
        \undef,
        sub ( $in, %opts ) {
            handle_run3_out(
                $in,
                out              => \@out,
                on_parse_success => sub ( $line, %opts ) {
                    push @pkg, $line;
                }
            );
        },
        $err
    );

    my $status = $?;

    if ($err) {
        warn "$status: $err";
        exit $status if $SHORTCIRCUIT;
        next;
    }
}

printf "%s\n", join ' ', @pkg;

warn Dumper(argv => \@ARGV, pkg => \@pkg, diff => (List::Util::uniq @ARGV, @pkg))
