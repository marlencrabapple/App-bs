use Object::Pad qw(:experimental(:all));

package BS::Package;

role BS::Package : does(BS::Common);    #: does(BS::Package::Meta);

use utf8;
use v5.40;

{
    no warnings 'experimental';
    use re 'strict';
}

use Carp;
use List::Util qw'any uniq';
use File::chdir;
use File::Temp;
use Const::Fast::Exporter;
use IPC::Nosh::IO;

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

role BS::Package::Stub : does(BS::Package::Meta) {
    field $search : inheritable : param : accessor = "";

    method upgrade ( $field_href, %opts ) {
        ...;
    }
};

ADJUSTPARAMS($params) {

    # if ( $search && none( @$name, $base ) ) {
    #     ( $base, $name ) = $self->$search()->@[qw(name base)];
    # }
}

# method $search ( $pkgstr = $search, %opts ) {

# }

method search : common ($search) {
    my $self = BS::Package->new( search => $search );
    $self->$search();

    #$self->p
}

method parse_pkgstr : common ($pkgstr) {
    my ( $prefix, $_pkgidenstr, $isfile, $sep, $attr, @extra ) =
      $pkgstr =~ $pkgstr_re;

    dmsg( $prefix, $_pkgidenstr, $isfile, $sep, $attr, @extra );
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

    carp $res->out;

    $class->bsx(
        [
            qw(git clone), "$srccache/$$pkgres{base}",
            "$workdir/$$pkgres{base}"
        ]
    );

    carp $res->out;
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
