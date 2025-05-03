use Object::Pad;

package BS::Ext::pacman;
role BS::Ext::pacman : does(BS::Common);

use utf8;
use v5.40;

use Carp;
use BS::Common;
use Const::Fast;
use Data::Printer;
use BS::Package::Meta;
use List::Util 'any';

const our $REPOPKG_STR_RE => qr/(^[^\/]+)?\/($VALID_PKG_RE_NB[^\n])$/;
const our %DBPATTERN_MAP  => qw(package p(?:ac)?ka?ge? file file);
const our $VALIDDB_RE => map { qr /^($_)$/i }
  ( join '|', values %DBPATTERN_MAP );

field $sync;

method db_valid : common (@list) {
    grep { $VALIDDB_RE } @list;
}

method sync : common (%args) {
    my @db_enabled = $class->db_valid(
        ref $args{database} eq 'ARRAY'
        ? $args{database}->@*
        : $args{database}
    );

    my $now = time;
    state $sync = $now;

    $args{res}  //= {};
    $args{dest} //= [];
    $args{now}  //= time;

    my ( @query_opts, %res );

    if ( $args{sync} || ( $args{last_sync} && $args{now} == $args{last_sync} ) )
    {
        push @query_opts, qw(-y -y);
    }

    $res{package} =
      BS::Common->bsx( [ qw(sudo pacman -Su), @query_opts ], %args )
      if $args{package};

    $res{file} = BS::Common->bsx( [ qw(sudo pacman -F), @query_opts ], %args )
      if $args{file};

    %res->(qw(package file));
}

method file_query : common ($filestr, %args) {
    my $now = time;
    state $sync = $now;
    $class->query(
        $filestr,
        query_opts => ['-Fq'],
        now        => $now
        ,
        %args, last_sync => $sync
    );
}

method pkg_query : common ($pkgstr, %args) {
    my $now = time;
    state $sync = $now;
    $class->query(
        $pkgstr,
        query_opts => ['-Sqs'],
        now        => $now
        ,
        %args, last_sync => $sync
    );
}

method query : common ($str, %args) {
    $args{dest} //= [];
    $args{now}  //= time;

    carp np $str, %args if $ENV{DEBUG};

    const my $pacman_query_outh => sub ( $line, @opts ) {
        BS::Common::dmsg( $line, @opts );
        if ( my ( $repo, $pkgname ) = $class->filter_output( $line, %args ) ) {
            BS::Common::dmsg {
                line   => $line,
                args   => \%args,
                fields => { repo => $repo, pkgname => $pkgname }
            };

            push $args{dest}->@*, { repo => $repo, pkgname => $pkgname };
        }
    };

    if ( $args{sync} || ( $args{last_sync} && $args{now} == $args{last_sync} ) )
    {
        push $args{query_opts}->@*, qw(-y -y);
    }

    my $res = BS::Common->bsx(
        [ qw(sudo pacman), $args{query_opts}->@*, $str ],
        %args,
        in  => undef,
        out => $pacman_query_outh
    );

    BS::Common::dmsg( $res, \%args );

    $res;
}

method parse_line : common ( $line, %opts ) {
    chomp $line;
    my ( $repo, $pkgstr ) = $line =~ $REPOPKG_STR_RE;

    BS::Common::dmsg { line => $line, repo => $repo, pkgstr => $pkgstr };

    my %ret = ( pkgstr => $pkgstr );
    $ret{repo} = $repo if any { $_ eq 'repo' } $opts{fields}->@*;

    BS::Common::dmsg \%ret;

    %ret;
}

method filter_output : common ($line, %opts) {
    if ( my %fields = ( $class->parse_line( $line, %opts ) ) ) {
        BS::Common::dmsg \%fields;
        return \%fields;
    }

    undef;
}

const our @default_repo => qw(core extra multilib);

const our $default_repo_str => join '\n\n',
  map {
    <<'...';
[$_]
SigLevel          = Required DatabaseOptional
LocalFileSigLevel = Optional
...
  } @default_repo;

const our $pacman_conf_default => <<'...'
[options]
ParallelDownloads = 10
#DownloadUser = bs
SigLevel    = Required DatabaseOptional
LocalFileSigLevel = Optional
...
  . $default_repo_str
