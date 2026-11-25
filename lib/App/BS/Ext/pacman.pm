#!/usr/bin/env perl

use Object::Pad ':experimental(:all)';

package App::BS::Ext::pacman;

role App::BS::Ext::pacman
  : does(App::BS::Common) : does(App::BS::Ext::pacman::Config) :
  does(App::BS::Run);

use utf8;
use v5.44;

no warnings 'experimental::re_strict';
use re 'strict';

use builtin;
use Const::Fast;
use List::Util qw'pairgrep first uniq none any';
use IPC::Nosh  qw'';
use IO::Handle::Common;
use PadWalker;
use Syntax::Keyword::Dynamically;

const our %FIELD_MAP => (
    base                 => '%e',
    arch                 => '%a',
    backup_files         => '%B',
    build_date           => '%b',
    conflicts_nover      => '%C',
    depends_on           => '%D',
    description          => '%d',
    depends_on_nover     => '%E',
    optional_deps        => '%O',
    optional_deps_nodesc => '%o',
    filename             => '%f',
    signature            => '%g',
    groups               => '%G',
    conflicts_with       => '%H',
    md5sum               => '%s',
    sha256sum            => '%h',
    download_size        => '%k',
    licences             => '%L',
    install_size         => '%m',
    name                 => '%n',
    required_by          => '%N',
    version              => '%v',
    url                  => '%u',
    replaces             => '%T',
    replace_nover        => '%R',
    provides_nover       => '%S',
    provides             => '%P',
    packager             => '%p',
    package_valid_method => '%V',
    'literal_%'          => '%%',
);

const our @SORT_ALLOW => qw( buildorder );

const our $ver_req => qr/([=<>]{1}|(?:[<>]=)){,2}/x;

const our $pkgname_re => qr/
([a-z0-9_@+][a-z0-9_@+.-]+)
 (?:
   ([\s-]|[=<>]{1}|[<>]=)
   ([^\s:\/\\-]+?)
 )?/xi;

const our $soname_re => qr/(.+\.so)=([0-9-].+)/xx;

field $in;    #: param;
field $userselect;

# : param(variant);

# field $buildorder : param = 1;

field $sortby  = qw'buildorder';
field $sortdir = 'desc';

# field $asc;
# field $desc;
# field $reverse;

# field $reversedeps : param   = 0;
field $field  = [];
field $fmtstr = '%e';

# Default is hybrid: will do expac -Ss if pkgstr has regex meta-characters
field $exact  = 0;
field $regex  = 1;
field $sep    = ' ';
field $unique = 1;
field $depth  = undef;

field $repo_enabled;

field $db             : accessor : param //= 'sync';
field $updatedb       : accessor : param //= true;
field $filedb_updated : accessor;
field $pkgdb_updated  : accessor;

ADJUST : params (:$repo = [keys $self->repolist->%*]) {
    foreach my ( $k, $v ) ( $self->repolist->%* ) {
        delete $self->repolist->{$k} if none { $_ eq $k } @$repo;
    }
};

method pacman_updarg ( $db, %opt ) {
    my $lastupdate = $db eq 'file' ? 'filedb_updated' : 'pkgdb_updated';

    # dmsg $lastupdate, $self->$lastupdate, $opt{force}, $updatedb;

    if ( ( $updatedb && !$self->$lastupdate ) || $opt{force} ) {
        $self->$lastupdate(time);
        info "▷ Updating " . $self->db . "  database..." if $self->verbose;
        return '-y';
    }
    elsif ( !$updatedb ) {
        say STDERR "▷ --updatedb is disabled, not updating $db database.";
    }

    undef;
}

method pacman ( $cli, %opt ) {
    ( $cli, $opt{dest} ) = App::BS::Common::ARRAY( $cli, $opt{dest} );

    # dmsg $cli, %opt;
    #
    dynamically $cli = [
        'pacman', @$cli,
        ( $self->pacman_conf ? ( '--config', $self->pacman_conf ) : () )
    ];

    if ( my $arg = $self->pacman_updarg( 'package', force => $opt{update_db} ) )
    {
        unshift @$cli, 'sudo';
        push @$cli, $arg;
    }

    my $run = $self->run(
        $cli,
        (
            map  { ( %opt{ ($_) } ) }
            grep { exists $opt{$_} } qw'out err autoflush autochomp'
        )
    );

    if ( $run->status > 0 ) {
        dmsg [ caller 0 ], $run->cmd;
    }
}

method pacman_provides ( $pkg, %opt ) {
    ( $pkg, $opt{dest} ) = App::BS::Common::ARRAY( $pkg, $opt{dest} );

    foreach my $pkg (@$pkg) {
        $self->pacman(
            [ qw(-S --print-format '%P'), $pkg ],
            out => sub( $line, @ ) {
                $self->group_pkgstr( $line, $opt{dest} );
            }
        );
    }

}

method pacman_pkgname( $pkglist, %opt ) {
    ( $pkglist, $opt{dest} ) = App::BS::Common::ARRAY( $pkglist, $opt{dest} );

    my $pkgre = '^(' . ( join '|', uniq @$pkglist ) . ')$';

    my @cmd = qw(-Sqs);

    push @cmd, $pkgre;

    my $run = $self->pacman(
        \@cmd,
        out => sub( $line, @ ) {
            if ( my ($name) = ( $line =~ /^$pkgname_re/ ) ) {
                push $opt{dest}->@*, $name;
            }
        }
    );

    $opt{dest}->@*;
}

method pacman_files ( $filelist, %opt ) {
    ( $filelist, $opt{dest} ) = App::BS::Common::ARRAY( $filelist, $opt{dest} );

    my @cmd = qw(-Fq);

    my $run = $self->pacman(
        [ @cmd, uniq @$filelist ],
        db  => 'file',
        out => sub ( $line, @ ) {
            say $line if $self->verbose;
            if ( my ( $repo, $name ) = $line =~ m!([^/]+)/(.+)!g ) {
                push $opt{dest}->@*, $name
                  if none { $_ eq $name } $opt{dest}->@*;
            }
        }
    );
    $opt{dest}->@*;
}
