#!/usr/bin/env perl

use utf8;
use v5.40;

no warnings 'experimental::re_strict';
use re 'strict';

use lib 'lib';

use File::Basename;
use TOML::Tiny;
use IPC::Run3;
use Const::Fast;
use Data::Dumper;
use List::Util 'uniqstr';

use BS::Common;
use BS::Ext::pacman;
use BS::Ext::expac;

our $DEBUG        => $ENV{DEBUG}        // 0;
our $SHORTCIRCUIT => $ENV{SHORTCIRCUIT} // 0;

const our $pkgnamebase_re => qr/[:a-zA-Z0-9\@_\+]{1}[a-zA-Z0-9\@_\+\.\+]+/;

# Prepends pkgname
const our $repo_re => qr/(?:([\/])\/)?/;
const our $type_re => qr/(?:(lib)\:)?/;

const our %sep_re => ( ver => qr/(\=|[\<\>]\=?)/, dssc => qr/(:\s*(.+))?/ );
const our $not_pkgver_rew => quotemeta(':/-') . '\s';

const our $fpath_re =>
  qr/^(?:\/)?([a-zA-Z0-9\@_\+\.\+]+\/)?([a-zA-Z0-9\@_\+\.\+]+)$/;

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

sub parse_pkgstr ( $pkgstr, %opts ) {

# Should be possible to detect if file, regardless of file ext both before and after parsing as pkgspec

    # Not working...
    #const my $_pkgstr_re => qr/$pkgstr_re_str/;

    #:wqwarn np nojoin => $pkgstr_re join => $_pkgstr_re if $DEBUG;

    const our $pkgname_common_re => qr'[^.-]{1}[a-z0-9@_+.-]+?';

const our $pkgprefix_re => qr/(?:(lib)\:)?/;

const our $pkgstr_re => qr/^$pkgprefix_re
          		           ($pkgname_common_re(\.so(?:\.[0-9]+)?)
			              | $pkgname_common_re )
                          /xxi;

const our $epoch_re  => qr'([0-9]+?):'xi;
const our $pkgver_re => qr'([^\s:/\-]+?)'xi;
const our $pkgrel_re => qr'([0-9]+?)'xi;
const our $arch_re   => qr'(any|aarch64|i368|i638|(?:x86_64(?:_v3)?))'xi;
const our $pkgext_re => qr'(pkg.tar.(?:zst|xz|gz|bz2|zip))'xi;

const our $pkgfile_re => qr'$pkgstr_re
                            -(?:$epoch_re:)?
                            $pkgver_re-$pkgrel_re
	               		    -$arch_re
			                .$pkgext_re
			               'xxi;

const our $pkgspec_re => qr'';

    my ( $prefix, $_pkgstr, $isfile, $sep, $attr, @extra ) =
      $pkgstr =~ $pkgstr_re;

    my %pkgstub = ();

    $pkgstub{name} = $_pkgstr;

    if ($sep) {
        if ( $sep ne ':' ) {
            $pkgstub{version} = $attr;
            $pkgstub{cmp_op}  = $sep;
        }
        elsif ( $sep eq ':' ) {    # Optional dependency most likely
                                   # Will have parsed that out elsewhere
            $pkgstub{description} = $attr;
            $pkgstub{name}        = $_pkgstr;
        }
    }

    if ( $isfile || $opts{database} && $opts{database} eq 'file' ) {
        $pkgstub{file} //= $_pkgstr;

        my $res = BS::Ext::pacman->pacman_query( $_pkgstr, database => 'file' );

        #BS::Common::dmsg { res => $res };

        $pkgstub{repo} = $$res{repo}    if $$res{repo};
        $pkgstub{name} = $$res{pkgname} if $$res{pkgname};
    }

    BS::Common::dmsg(
        {
            _pkgstr => $_pkgstr,
            isfile  => $isfile,
            sep     => $sep,
            attr    => $attr,
            pkgstub => \%pkgstub
        }
    );

    \%pkgstub;
}

foreach my $arg (@ARGV) {
    my ( @out, $err );
    foreach my $db (qw(-Qs -Ss)) {
        run3(
            [ "expac", $db, "%e", "^$arg\$" ],
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
    }

    my $status = $?;

    if ($err) {
        warn "$status: $err";
        exit $status if $SHORTCIRCUIT;
        next;
    }
}

printf "%s\n", join ' ', uniqstr @pkg;

warn Dumper(
    argv => \@ARGV,
    pkg  => \@pkg,
    diff => [ List::Util::uniqstr @ARGV, @pkg ],
  )
  if $DEBUG
