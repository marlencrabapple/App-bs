use Object::Pad ':experimental(:all)';

package srcinfo::SRCINFO;

use lib 'lib';

class srcinfo::SRCINFO : does(BS::Common);

use utf8;
use v5.40;

use List::Util 'any';
use Const::Fast;
use Scalar::Util 'blessed';
use Path::Tiny;
use Tie::File;
use meta;

no warnings 'meta::experimental';

field $pkgbase;
field $pkgname;
field $pkgver;
field $epoch;
field $pkgrel;
field $arch;
field $source;
field $conflicts;
field $provides;

field $depends = {
    make     => {},
    optional => {},
    depends  => {},
    check    => {}
};

field $cksums  = {};
field $options = [];
field $file :param;

ADJUSTPARAMS($params) {
    if ($file) {
        $self->from_srcinfo($file);
    }

}

method from_srcinfo ($in) {
    if ( blessed $in && $in->DOES('lines_utf8') || ref $in eq 'Path::Tiny' ) {
        $file = $in;
    }
    else {
        $file = path($in)->assert( sub { $_->exists } );
    }

}

method srcinfo (%opts) {
    my $metaclass = Object::Pad::MOP::Class->for_caller;
    my @lines;

    BS::Common::dmsg( { opts => [ @opts{qw(write update)} ] } );

    if ( any { $_ } @opts{qw(write update)} ) {
        tie my @lines, 'Tie::File', $file
          or die "Could not open .SRCINFO file for writing";
    }

    # iterate over fields on class (get from MOP)
    my @fields = $metaclass->fields;

    const my $PKGBASENAME_RE => qr/^pkg(name|base)$/;
    my $handle = $opts{writeh} ? $opts{writeh} : *STDOUT;

    foreach my ( $k, $v ) ( map { $_->name, $_->value } @fields ) {

        my $line = "$k=$v";
        $line = "\t$line" if $k !~ $PKGBASENAME_RE;
        say $handle $line if ( @opts{qw'stdout print console'} );
        push @lines, $line;

    }
    continue {
        state $i = 0;
        $i++;
        $i = 0 if $i == scalar @fields;
        last   if $i == 0;
    }

    $opts{wantarray}
      ? @lines
      : $opts{self}
        ? $self
        : join "\n", @lines;
}

method as_hash {

}

method as_json {

}

method as_toml {

}

method as_yaml {

}

method shenv ( $shcompat = 'bash' ) {

}

method parse_srcinfo : common ($path) {
    const my $SRCINFO_LINE_RE => qr/^\s*([a-z0-9_]+?)\s*=\s*(.+?)[\s\n]*$/i;
    const my $XDEPENDS_RE     => qr/depends/i;

    my %srcinfo = ();

    foreach my $line ( $path->lines_utf8 ) {
        my ( $key, $val ) = ( $line =~ $SRCINFO_LINE_RE );
        next unless $key && $val;

        if ( ref $srcinfo{$key} eq 'ARRAY' ) {
            push $srcinfo{$key}->@*, $val;
        }
        elsif ( $srcinfo{$key} ) {
            $srcinfo{$key} = [ $srcinfo{$key}, $val ];
        }
        else {
            $srcinfo{$key} = $val;
        }
    }

    srcinfo::SRCINFO->new(%srcinfo);
}

method pkgfile_glob ($pkgver) {
    my $pkgver_str;

    const my $PKGVER_CURR => qr/^keep|current|no[-]?update$/;

    if ($pkgver) {
        if (
            my $pkgver_href =
            ( ( $pkgver && ref $pkgver eq 'HASH' ) ? \%$pkgver : undef ) // (
                $pkgver =~ $PKGVER_CURR
                ? { $pkgver, $epoch, $pkgrel }
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
      $pkgname eq 'ARRAY'
      ? '{' . ( join ',', $pkgname->@* ) . '}-'
      : "$pkgname"
      . (
        ref $arch eq 'ARRAY'
        ? ( $pkgver_str ? " -$pkgver_str-" : "-*" ) . "-{"
          . ( join ',', $arch->@* ) . '}'
        : "-$arch"
      ) . ".pkg.tar.zst";

    $glob;
}
