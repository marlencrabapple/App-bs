use Object::Pad qw(:experimental(:all));

package BS::Package;

role BS::Package;

use utf8;
use v5.40;

no warnings 'experimental';
use re 'strict';

use List::Util qw'any uniq';
use Const::Fast;
use IPC::Nosh::IO;

const our $pkgname_common_re => qr'[^.-]{1}[a-z0-9@_+.-]+?'xi;

const our $pkgprefix_re => qr/(?:(lib)\:)?/;

const our $pkgstr_re => qr/$pkgprefix_re
          		           ($pkgname_common_re(\.so(?:\.[0-9]+)?)
			              | $pkgname_common_re )
                          /xxi;

const our $epoch_re  => qr'([0-9]+?)'xi;
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

const our $pkgspec_re => qr'$pkgstr_re
                            -(?:$epoch_re:)?
                            $pkgver_re-$pkgrel_re
	               		    -$arch_re
			                (.$pkgext_re)?
			               'xxi;

method parse_pkg_fname : common ($pkgfile) {
    $pkgfile = path($pkgfile);

    my $basename = $pkgfile->basename;
    my @match    = ( $pkgfile =~ /^$pkgfile_re$/g );

    dmsg( $pkgfile, $basename, @match );

    @match;
}

method parse_pkgstr : common ($pkgstr) {
    my @match = ( $pkgstr =~ $pkgstr_re );
    my ( $_pkgidenstr, $isfile, $sep, $attr, @extra ) = @match;

    dmsg( $pkgstr, $_pkgidenstr, $isfile, $sep, $attr, @extra );

    @match;
}

method lookup : common ($field_href, %opts) {
    my $stub = BS::Package::Stub->new(%$field_href);

    if ( $stub->is_file ) {

    }
    else {
        # TODO: More constraints
        if ( $stub->version ) {

        }
    }

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

    dmsg( $res->out );

    $class->bsx(
        [
            qw(git clone), "$srccache/$$pkgres{base}",
            "$workdir/$$pkgres{base}"
        ]
    );

    dmsg( $res->out );
}

method pkgfile_glob : common ( $srcinfo, $pkgver ) {
    my $pkgver_str;

    if ( $srcinfo isa 'BS::SRCINFO' ) {

    }
    else {
        # BS::Package::SRCINFO->
    }

    BS::Common::dmsg( { srcinfo => $srcinfo, pkgver => $pkgver } );

    if ($pkgver) {
        if (
            my $pkgver_href =
            ( ( $pkgver && ref $pkgver eq 'HASH' ) ? \%$pkgver : undef ) // (
                $pkgver eq $ENV{PKGVER_CURR}
                ? { $srcinfo->%{qw'epoch ver rel'} }
                : undef
            )
          )
        {
            $pkgver_str .= "$$pkgver_href{epoch}:" if $$pkgver_href{epoch};
            $pkgver_str .= $$pkgver_href{ver};
            $pkgver_str .= "-$$pkgver_href{rel}" if $$pkgver_href{rel};
        }
        elsif ($pkgver) {
            $pkgver_str = $pkgver;
        }
    }
    my $glob =
      $$srcinfo{pkgname} eq 'ARRAY'
      ? '{' . ( join ',', $$srcinfo{pkgname}->@* ) . '}-'
      : "$$srcinfo{pkgname}"
      . (
        ref $$srcinfo{arch} eq 'ARRAY'
        ? ( $pkgver_str ? " -$pkgver_str-" : "-*" ) . "-{"
          . ( join ',', $$srcinfo{arch}->@* ) . '}'
        : "-$$srcinfo{arch}"
      ) . ".pkg.tar.zst";

    $glob;
}
