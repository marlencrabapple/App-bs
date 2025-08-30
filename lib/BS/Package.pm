use Object::Pad qw(:experimental(:all));

package BS::Package;

class BS::Package #: does(BS::Package::Meta);

use utf8;
use v5.40;

use Carp;
use List::Util 'any';
use File::chdir;
use Path::Tiny;
use File::Temp;
use Const::Fast;

field $base = "";
field $name = [];
field $ver = "";
field $rel = "";
field $epoch = "";
field $sources = [];
field $checksums = "";

methodo parse_pkgstr : common {
        const my $pkgstr_name_ptn => qr'[a-zA-Z0-9\@_\+]{1}[a-zA-Z0-9\@_\+\.\-]+';

    const my $pkgstr_name_re => qr/
        ^(lib\:)?
        ($pkgstr_name_ptn(\.so(?:\.[0-9\]+)?)
        |$pkgstr_name_ptn)
      /x;

    const my $pkgver_forbidden => quotemeta(':/-') . '\s';

    const my $pkgver_re => qr'
      (\=|[\<\>](?:\=)?)
      ([^$pkgver_forbidden]+)
    'x;
    const my $optdep_re => qr/(:(:)\s+(.+))/;

    const my $pkgstr_re => qr/
        $pkgstr_name_re #
        (?:$pkgver_re)?
        $optdep_re
      /x;

    # Not working...
    #const my $_pkgstr_re => qr/$pkgstr_re_str/;

    #:wqwarn np nojoin => $pkgstr_re join => $_pkgstr_re if $DEBUG;

    my ( $prefix, $_pkgstr, $isfile, $sep, $attr, @extra ) =
      $pkgstr =~ $pkgstr_re;
}

method updchecksums : common {
    $class->bsx( ['updchecksums'] );
}

method writesrcinfo : common ($out, @makepkg_args) {
    $class->printsrcinfo( $out, @makepkg_args )->out;
}

method printsrcinfo : common ($out, @makepkg_args) {
    $class->bsx(
        [ 'makepkg', '--printsrcinfo', @makepkg_args ],
        out => ( ref $out eq 'ARRAY' ? $out : \$out )
    );
}

method fetch : common ($pkgstr, %args) {
    my $pkgres   = BS::Package::Meta->resolve_base($pkgstr);
    my $srccache = path( $args{srccache} // $args{dest} );
    my $workdir  = Path::Tiny->tempdir;
    my $res;

    if ( lc( $args{repo} ) eq 'aur' ) {
        $res = $class->bsx( [qw(git clone --bare $)] );
    }
    elsif (
        any { $args{repo}->{name} eq $_ && $args{repo}->{base_uri} }
        keys $args{repo_enabled}->%*
      )
    {
        $res = $class->bsx( [qw(git clone --bare $)] );
    }
    else {
        $res = $class->bsx(
            [ qw(pkgctl repo clone --protocol=https), $$pkgres{base} ] );
    }

    carp $res->out;

    $class->bsx(
        [
            qw(git clone), "$srccache/$$pkgres{base}",
            "$workdir/$$pkgres{base}"
        ]
    );

    carp $res->out;
}
