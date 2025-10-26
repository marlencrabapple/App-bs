use Object::Pad ':experimental(:all)';

package BS::Package::SRCINFO;

class BS::Package::SRCINFO;

use utf8;
use v5.40;

use List::Util   qw( any );
use Const::Fast  qw( const );
use Scalar::Util qw( blessed );
use Path::Tiny   qw( path );
use Tie::File    ();
use Syntax::Keyword::Defer;
use Data::Dumper;
use meta;

no warnings 'meta::experimental';

field $pkgname;
field $pkgbase //= ref $pkgname eq 'ARRAY' ? $$pkgname[0] : $pkgname;
field $pkgver;
field $epoch;
field $pkgrel;
field $arch      = 'any';
field $source    = [];
field $conflicts = [];
field $provides  = [];

field $depends = {
    make     => {},
    optional => {},
    depends  => {},
    check    => {}
};

field $cksum   = {};
field $options = [];

field $_file : reader(file) : param(file) //=
  Path::Tiny::tempfile('.SRCINFOXXXXXXX');
field $_srcinfo : reader(srcinfo) : param(str) //= $_file->slurp_utf8;

BUILD {
    BS::Common::dmsg( { '@_' => \@_ } )
}

ADJUSTPARAMS($params) {
    if ($_file) {
        (
            $pkgname,  $pkgbase, $pkgver, $epoch,
            $pkgrel,   $arch,    $source, $conflicts,
            $provides, $depends, $cksum,  $options
        ) = values __PACKAGE__->from_srcinfo($_file)->%*;

        BS::Common::dmsg( __PACKAGE__->from_srcinfo($_file) );
    }
    else {
        ...;
    }
}

method from_srcinfo : common ($in) {
    my $lines = [];    #=  "";
    my $str;
    if ( blessed $in && $in->DOES('lines_utf8') || ref $in eq 'Path::Tiny' ) {
        push @$lines, $in->lines_utf8;
    }
    elsif ( $lines = $class->open_srcinfo($in) ) {

        # DONO
    }
    else {
        # split in $class->parse_srcinfo
        $lines = $in;
    }

    $class->parse_srcinfo($lines);
}

method open_srcinfo : common ($file) {
    try {
        $file = path($file)->assert( sub { $_->exists } )
    }
    catch ($e) {
        warn "Could not open $file: $e ($?)";
        return undef
    }
}

method keys : common (%opts) {
    my $metaclass = Object::Pad::MOP::Class->for_caller;
    grep { /^_/ } map { $_->name } $metaclass->fields;
}

method values (%opts) {
    my $metaclass = Object::Pad::MOP::Class->for_caller;
    map { $_->value } $metaclass->fields;
}

method writeline ( $line, %opts ) {
    $opts{noop} || say $_file->append_utf8($line);
}

method to_href {
    my @fields = SRCINFO->keys->@*;
    map { $_->name, $_->value } @fields;
}

method parse_line : common ( $line, %opts ) {
    const my $SRCINFO_LINE_RE => qr/^\s*([a-z0-9_]+?)\s*=\s*(.+?)[\s\r\n]*$/i;
    const my $XDEPENDS_RE     => qr/depends/i;
    chomp $line;
    ( $line =~ $SRCINFO_LINE_RE );
}

method parse_srcinfo : common ( $in, %opts ) {

    my %srcinfo = ();
    my $path;

    foreach my $line ( ref $in eq 'ARRAY' ? @$in : split /[\n\r]+/, $in ) {
        chomp $line;

        my ( $key, $val ) = $class->parse_line($line);

        chomp $val if $val;
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

    \%srcinfo;
}

method as_SRCINFO (%opts) {
    my @fields = SRCINFO->keys->@*;
    my @lines;
    BS::Common::dmsg( { opts => [ @opts{qw(write update)} ] } );

    defer {
        warn "hihihi";
        $_file->spew_utf8(@lines)
          if any { $_ } @opts{qw(write update)}
          && $_file->exists
    }

    # defer  if ( any { $_ } @opts{qw(write update)} && $_file

    const my $PKGBASENAME_RE => qr/^pkg(name|base)$/;
    my $handle = $opts{writeh} ? $opts{writeh} : *STDOUT;

    foreach my ( $k, $v ) ( map { $_->name, $_->value } @fields ) {
        my $line = "$k=$v";
        $line = "\t$line" if $k !~ $PKGBASENAME_RE;
        say $handle $line if any { $_ } @opts{qw'stdout print'};   #console'} );

    }
    continue {
        state $i = 0;
        $i++;
        $i = 0 if $i == scalar @fields;
        last   if $i == 0;
    }

    BS::Common::dmsg(
        {
            handle => $handle,
            self   => $self,
            fields => @fields,
            lines  => \@lines,
        }
    );

    warn "after defer?";

    $opts{wantarray}
      ? @lines

      #: $opts{self}      ? $self
      : join "\n", @lines;
}

method as_json {

}

method as_toml {

}

method as_yaml {

}

# method as_written {

# }

# method was_written_

# method as_it_was_written

method shenv ( $shcompat = 'bash' ) {

}

# method parse_srcinfo : common ($path) {

#     my $srcinfo = srcinfo::SRCINFO->new(%srcinfo);
#     BS::COmmon::dmsg(
#         { srcinfo => $srcinfo, srcinfo_constructor => \%srcinfo } );

#     $srcinfo;
# }

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
