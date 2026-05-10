use Object::Pad ':experimental(:all)';

package BS::Package::SRCINFO;

class BS::Package::SRCINFO;

use utf8;
use v5.40;

use List::Util qw(any);
use Const::Fast;
use Scalar::Util;
use Path::Tiny;
use Tie::File;
use Syntax::Keyword::Defer;
use Syntax::Keyword::Dynamically;
use meta;
use JSON::MaybeXS;
use TOML::Tiny qw'to_toml from_toml';
use YAML;

use IPC::Nosh;
use IPC::Nosh::Common;

const our $SHENV_RE => qr/^(.*sh(?:env)?|env(?:vironment)?|export|eval)$/;

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

field $file    : reader(file)    : param(file) //= undef;
field $content : reader(content) : param(str)  //= $file->slurp_utf8;
field $href    : reader(as_href);
field $json    : reader(json) { $self->init_json };

ADJUSTPARAMS($params) {

    if ($file) {
        %$href = __PACKAGE__->from_srcinfo($file)->%*;
        (
            $pkgname,  $pkgbase, $pkgver, $epoch,
            $pkgrel,   $arch,    $source, $conflicts,
            $provides, $depends, $cksum,  $options
        ) = values %$href;

        dmsg $href;
    }

    # else {
    #     values %$params;
    # }
}

method from_srcinfo : common ($in, %opts) {
    my @lines = ();    #=  "";
    my $str;

    if ( blessed $in && $in->DOES('lines_utf8') || ref $in eq 'Path::Tiny' ) {
        push @lines, $in->lines_utf8;
    }
    elsif ( @lines = $class->open_srcinfo($in)->lines_utf8 ) {

        # DONO
    }
    else {             # multiline string probably
                       # TODO: check for above
                       # split in $class->parse_srcinfo
        @lines = $in =~ /(.*?)[\n\r]+/mg;
    }

    my $srcinfo = $class->new( $class->parse_srcinfo( \@lines )->%* );
    $opts{as_href} ? $srcinfo->as_href : $srcinfo;
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

# method $fields_as ($type) {
#   $type eq 'ARRAY' ? { $field->name => $field }
# }

method fields (%opts) {
    my $Field = class {
        field $_field   : param(field) : reader(field);
        field $instance : param;
        field $name     : reader = $_field->name =~ s/^\$//r;
        field $value : mutator { $_field->value($instance) }
    };

    my $metaclass = Object::Pad::MOP::Class->for_caller;
    (
        map {
            # my $infield = $_;
            my $field = $Field->new( field => $_, instance => $self );

            $field

# return ($opts{as} eq 'ARRAY' ? { $field->name => $field } : $opts{as} eq 'HASH' ? ($field->name => $field)

            # TODO: $field->name => "$field"
            #  - where stringification is overloaded to $field->value
            #  - should we allow accessing fields (read-only) through
            #    hash interface or just provide accessors?
        } grep { $_->name !~ /^\$_/ } $metaclass->fields
    );
}

method keys : common (%opts) {
    my $metaclass = Object::Pad::MOP::Class->for_caller;
    grep { /^$_/ } map { $_->name } $metaclass->fields;
}

method values (%opts) {
    my $metaclass = Object::Pad::MOP::Class->for_caller;
    map { $_->value($self) } $metaclass->fields;
}

method writeline ( $line, %opts ) {
    $opts{noop} || say $file->append_utf8($line);
}

method to_href (@fields) {
    @fields = $self->fields->@*
      unless scalar @fields;

    foreach my ( $k, $v ) ( map { $_->name => $_->value } @fields ) {

        if ( my $_v = $$href{$k} ) {

            if ( blessed $_v ) {
                ...;
            }
            elsif ( ref $_v ) {
                push @$_v, $v if $_v isa 'ARRAY';

                # $$vcached{ keys %$v } = values %$v
                #   if $vcached isa 'HASH';    # no nested refs?
            }
            else {
                $v = [ $_v, $v ];
            }
        }
    }

    $href;
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

    defer {
        warn "hihihi";
        $file->spew_utf8(@lines)
          if any { $_ } @opts{qw(write update)}
          && $file->exists
    }

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

    warn "after defer?";

        $opts{wantarray} ? @lines
      : $opts{self}      ? $self
      :                    join "\n", @lines;
}

method init_json (%opts) {
    const my @JSON_ALLOWEDKEYS => qw(pretty utf8 allow_blessed allow_nonref);

    state %json_constructor = (
        allow_blessed => 1,
        utf8          => 1,
        pretty        => 1,
        allow_nonref  => 1

        #grep { }  {%opts}->%{@JSON_ALLOWEDKEYS}

    );

    $json = JSON::MaybeXS->new(%json_constructor);

    $json;
}

method as_json ( $href = $self->as_href, %opt ) {
    dynamically $json = $self->init_json(%opt);

    # Consider ordering keys on demand?
    $json->encode($href);
}

method as_toml ( $href = $self->as_href ) {
    to_toml($href);
}

method as_yaml {

}

method $kvpair2str ( $k, $v, $sep = '=' ) {
    join $sep, map { $_ =~ s/$sep/\\$sep/rg } ( $k, $v );
}

method as_shenv ( $ashref = $self->as_href, %opts ) {
    my @out;

    foreach my ( $k, $v ) (%$ashref) {
        if ( my $type = ref $v ) {
            if ( $type eq 'ARRAY' ) {
                if ( $opts{noarray} ) {
                    $v = join ",", map { s/,/\\,/rg } @$v;
                    $v = qq{"$v"};
                }
                else {
                    $v = join " ", map { qq{ "$_" } } @$v;
                    $v = "($v)";
                }
            }
            elsif ( $type eq 'HASH' ) {
                if ( $opts{assoc} ) {
                    ...;
                }
                else {
                    $v = join ':',
                      map { $self->$kvpair2str( $_, $$v{$_} ) } keys %$v;
                }
            }
            else {
                ...;
            }
        }
        else {
            $v =~ s/"/\\"/g;
            $v = qq{"$_"};
        }

        push @out, qq{export $k=$v};
    }

    my $outstr = join "; ", @out;

    $opts{wrapeval} ? qq{eval '$outstr'} : $outstr;
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

method as ( $format, $select, %opt ) {
    const our %srcinfo_as => (
        json      => sub { $self->as_json },
        toml      => sub { $self->as_toml },
        hashref   => sub { $self->as_href },
        $SHENV_RE => sub { $self->as_shenv },

    );
}
