#!/usr/bin/env perl

use Object::Pad ':experimental(:all)';

package pkgtree;

class pkgtree;

use utf8;
use v5.40;

use lib 'lib';

use Getopt::Long
  qw(GetOptionsFromArray :config no_ignore_case auto_abbrev long_prefix_pattern=--?);
use Const::Fast;
use List::Util qw'first uniq none';
use IPC::Nosh  qw'';
use IO::Handle::Common;

const our @REPO_DEFAULT => qw(
  universe
  core
  extra
);

const our %FIELD_MAP => (
    base      => '%e',
    name      => '%n',
    depends   => '%D',
    files     => '%F',
    conflicts => '%C'
);    #, repo => '')

const our @SORT_ALLOW => qw( buildorder );

const our %RUN_DEFAULT => (
    autochomp => 1,
    err       => sub ( $line, @ ) {

        say STDERR $line;
    }
);

const our $ver_req => qr/([=<>]{1}|(?:[<>]=)) { ,2}/x;

const our $sover_re => qr/^
 ([^=<>]+)\.so

 ([0-9-]+)
$/x;

const our $pkgname_ver => qr/^
 ([^=<>]+)
 ([=<>]{1}|(?:[<>]=)){1,2}
 ([0-9.-]+)
$/x;

field $in : param;

field $buildorder : param = 1;

field $sortby  : param = qw'buildorder';
field $sortdir : param = 'desc';

# field $asc;
# field $desc;
# field $reverse;

field $reversedeps : param = 0;
field $repo        : param = \@REPO_DEFAULT;

field $uniq : param = 1;

# field $base = 1;
# field $name;
field $field : param : accessor = [qw(base)];

# ADJUST : params (:$base, :$name) {...};

field $fmtstr : param : accessor = '%e';

# Default is hybrid: will do expac -Ss if pkgstr has regex meta-characters
field $exact : param : accessor = 0;
field $regex : param : accessor = 1;

field $sep : param = ' ';

field $unique : param = 1;

field $pkgtree = {};

field $filedb_updated : accessor;
field $pkgdb_updated  : accessor;

field $verbose : param = 0;

sub run ( $cmd, %opt ) {
    my $run = IPC::Nosh::run( $cmd, %RUN_DEFAULT, %opt );
    $run;
}

method pkgfield ( $pkgin, $field, %opt ) {
    my $op = '-S';
    $op .= 's' unless $opt{exact};

    $pkgin = [$pkgin] unless ref $pkgin eq 'ARRAY';
    $field = [$field] unless ref $field eq 'ARRAY';

    my @cmd = ( 'expac', $op, ( join ',', @FIELD_MAP{@$field} ) );

    $opt{dest} = [] unless $opt{dest} && ref $opt{dest} eq 'ARRAY';

    my $outh = sub ( $line, @ ) {
        push $opt{dest}->@*, grep {
            my $new = $_;
            none { $_ eq $new } $opt{dest}->@*
        } split /\s/, $line;
    };

    if ( $opt{exact} ) {
        run( [ @cmd, @$pkgin ], out => $outh );
    }
    else {
        foreach my $pkgstr (@$pkgin) {
            run( [ @cmd, $pkgstr ], out => $outh );
        }
    }

    $opt{dest}->@*;
}

method pkgbase ( $pkglist, %opt ) {
    $self->pkgfield( $pkglist, 'base', %opt );
}

method pkgname ( $pkglist, %opt ) {
    $self->pkgfield( $pkglist, 'name', %opt );
}

method pacman_files ( $filelist, %opt ) {
    $opt{dest} //= [];
    for my $file ( ref $filelist eq 'ARRAY' ? @$filelist : split /[\s,]+/,
        $filelist )
    {
        my $run = run(
            [ qw(sudo pacman -Fq), ( $opt{updatedb} ? qw(-y) : () ), $file ],
            out => sub ( $line, @ ) {
                say $line if $verbose;
                if ( my ( $repo, $name ) = $line =~ m!([^/]+)/(.+)!g ) {
                    dmsg $repo, $name, $line;
                    push $opt{dest}->@*, $name
                      if none { $_ eq $name } $opt{dest}->@*;
                }
            }
        );
    }

    $opt{dest}->@*;
}

method pactree ( $pkglist, %opt ) {
    my @res = ();
    $opt{dest} //= [];
    $opt{db}   //= 'sync';
    $pkglist = [ split /[\s,]+/, $pkglist ] unless ref $pkglist eq 'ARRAY';

    const my $soname_re => qr/(.+\.so)=([0-9-].+)/xx;

    const my $pkgname_re => qr/
            ([^=]+)
            (?:
           (=|[<>]=?)
             ([0-9.-]+)
            )?/xx;

    foreach my $pkgstr (@$pkglist) {

        my $run = run(
            [ qw(pactree -lu), ( $opt{db} eq 'sync' ? qw'-s' : () ), $pkgstr ]
        );
        push @res,           $run;
        push $opt{dest}->@*, map {
            my $dep     = $_;
            my @pkgname = ();
            if ( my ( $soname, $sover ) = $dep =~ $soname_re ) {
                push @pkgname, $self->pacman_files($soname);
            }
            elsif ( my ( $name, $cmp, $ver ) = $dep =~ $pkgname_re ) {

      # TODO: check version consraint (I think pacman reads these strings as is)
      #$res = $name;
                push @pkgname, $name;
            }
            else {
                error "'$dep' is unresolvable";
            }
            @pkgname
        } $run->out->lines_utf8;
    }

    $opt{dest}->@*;
}

method arch_rebuild_order( $pkgname_aref, %opt ) {
    my $ordered = $opt{dest} // [];
    my $run     = run(
        [
            qw'arch-rebuild-order --repos',
            $opt{repo} && $opt{repo} eq 'ARRAY' ? $opt{repo}->@* : @$repo,
            (
                ( $opt{reversedeps} // $reversedeps ) ? '--no-reverse-deps' : ()
            ),
            @$pkgname_aref
        ],
        out => sub ( $line, @ ) {
            push @$ordered, split /\s/, $line;
        },
    );

    @$ordered;
}

method resolve ( $pkglist = $in, %opt ) {

    my @pkgname;
    $self->pkgname( $pkglist, %opt, dest => \@pkgname );
    dmsg \@pkgname;

    my @pactree;
    $self->pactree( \@pkgname, dest => \@pactree, exact => 1 );

    @pactree = uniq @pactree if $opt{unique} // $unique;
    dmsg \@pactree;

    my @ordered;

    $self->arch_rebuild_order( \@pactree, dest => \@ordered )
      if $opt{buildorder} // $buildorder;

    dmsg \@ordered;

    $self->pkgfield(
        ( scalar @ordered ? \@ordered : \@pactree ),
        ( $opt{field} // $field // 'base' ),
        exact => 1
    );
}

method cli : common ($argv = \@ARGV, %opt) {
    my %clidest = ( in => [], prune => 'input', sep => ' ' );

    GetOptionsFromArray(
        $argv,
        \%clidest,

        # output fields and format
        'base', 'name',
        'field=s@',
        'fmtstr=s',

        # database to search with pactree, expac and pacman
        'db:s',    # sync or local
        'sync',
        'local',

        # resultset print order
        'sort-by|order-by=s@',
        'build-order|rebuild-order|arch-rebuild-order!',
        'sort-direction|order',
        'asc', 'desc',
        'sep|seperator=s',

        # input search scope
        'exact!',
        'regexp',

        # output verbosity control
        'debug+',
        'verbose+',
        'quiet+',

        # enabled repositories (for sync db)
        'repository=s@',

        # print dependents of input packages
        'reverse-depends|reversedeps!',

        # prune/filter packages at different stages of resolution
        "prune:s",

        # input packages
        '<>' => sub ($barearg) {
            push $clidest{in}->@*, $barearg;
        }
    );

    $clidest{in}->@* = uniq $clidest{in}->@* if $clidest{prune};

    my $self    = $class->new( %clidest, %opt );
    my @pkgtree = $self->resolve;

    dmsg $self, \@pkgtree;

    say join $clidest{sep}, @pkgtree;
}

package pkgtree::CLI;

use utf8;
use v5.40;

pkgtree->cli( \@ARGV )
