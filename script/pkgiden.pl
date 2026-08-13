#!/usr/bin/env perl
use Object::Pad ':experimental(:all)';

package BS::pkgiden;

class BS::pkgiden : does(BS::Common);

use v5.40;

use List::Util   qw( uniq );
use Getopt::Long qw(:config no_ignore_case bundling auto_abbrev);
use Const::Fast::Exporter;
use Syntax::Keyword::Dynamically;

use BS::Common;

const our %fieldmap  => ( base => 'e', name => 'n' );
const our %fieldmaph => reverse(%fieldmap);
const our %fieldsub => (
    $fieldmap{base} => \&get_pkgbase,
    $fieldmaph{e}   => \&get_pkgbase,
    $fieldmap{name} => \&get_pkgname,
    $fieldmaph{n}   => \&get_pkgname
);

our $outfield  = 'e';
our $delimeter = ' ';
our $filter    = qr/lib32/;
our @pkgin;

GetOptions(
    'outfield|field=s',
    'delimeter=s',
    'filter=s',
    '<>' => sub ($barearg) {
        push @pkgin, $barearg;
    }
);

if ( $outfield =~ /^[en]{1}$/i ) {
    $outfield = { $outfield => $fieldmaph{$outfield} };
}
elsif ( $outfield =~ /^(?:pkg)?(name|base)$/ ) {
    $outfield = { $fieldmap{$outfield} => $outfield };
}
else {
    die "Invalid field '$outfield' given, Accetable values are: " . join ", ",
      (%fieldmap);
}

my class PacmanConf {
    field $file : param = '/etc/pacman.conf';
    field $readbuff     = [];
    field $_ogcontents  = [];
    field $conf_href    = {};

    field $repos : reader = [];

    field $rootdir  = '/';
    field $dbpath   = '';
    field $cachedir = '';
    field $logfile  = '';

    BUILD {

        $file = $self->_load_file($file);
    }

    method parse_val (%option) {
        split /[\s]+/, $option{ (%option)[0] };
    }

    method parse_line ($line) {
        state $section;
        $line =~ s/^\s*(.*)\s*/$1/g;
        return undef unless $line;

        # Context switch
        if ( my $sectkey = ( $line =~ /^\s*\[([^\]]+)\]\s*$/ ) ) {
            $section = $$conf_href{$sectkey};
        }
        elsif ( my ( $k, $v ) = /([^=]+?)=([^=]+)\s*/ ) {
            return undef unless $k && $v;

            if ( my $curr = $$section{$k} ) {
                push @$curr, split /[\s]+/, $v;

            }
            else {
                my @vsplit = split /[\s]+/, $v;
                $$section{$k} = [$v];
            }
        }

        %$section;
    }

    method _load_file($path) {
        foreach my $line ( $path->lines_utf8 ) {
            $_ogcontents .= $line;

            state $section;
            chomp $line;

            # ...;
            # push @$readbuf . $line;...;
            # my ($$self->parse_line($line, );
        }
    }
};

our $pacmanconf = PacmanConf->new('/etc/pacman.conf');

sub arch_rebuild_order : lvalue ( $pkgnames, $no_reverse_depends= 1,
  $repos = $pacmanconf->repos ) {
    dmsg(
        {
            pkgnames           => $pkgnames,
            no_reverse_depends => $no_reverse_depends,
            repos              => $pacmanconf->repos,
            pacmanconfg        => $pacmanconf
        }
    );

    BS::Common::bsx(
        [
            'arch-rebuild-order',
            grep { $_ } ( $no_reverse_depends ? '--noreverse-depends' : undef ),
            '--repos',
            join ',',
            @$repos,
            join " ",
            map { "$_" } @$pkgnames
        ]
    );
}

sub get_pkgfield ( $field, @pkglist ) {
    $fieldsub{$field}->(@pkglist);
}

sub get_pkgbase : lvalue ( @pkglist ) {
    grep { !$filter } map { `expac -S "%e" $_` } join " ",
      uniq map { chomp $_; qq{"$_"} } @pkglist;
}

sub get_pkgname : lvalue ( @pkglist ) {
    grep { !$filter } map { `expac -S "%n" $_` } join " ",
      uniq map { chomp $_; qq{"$_"} } @pkglist;
}

sub run () {
    say STDERR "▶ Printing packages as " . (%$outfield)[1] . "(s)...";

    my @rebuildorder =
      ( '--no-reverse-depends', '--repos', 'universe,core,extra,multilib' );
    my $rebuildorder = join " ", @rebuildorder;

    my @pkgout = ();

    my @rebuildin =
      uniq map        { chomp $_; $_ }
      get_pkgbase map { chomp $_; `pactree -lus "$_"` }
      map             { `expac -Ss "%n" $_` } (@pkgin);

    @pkgout = get_pkgfield(
        (%$outfield)[0],
        arch_rebuild_order(
            @rebuildin, 1, "universe,core,extra,multilib", $pacmanconf
        )
    );

    BS::Common::dmsg( { pkgout => @pkgout } );

    say join "$delimeter", @pkgout;
    @pkgout;
}

run()
