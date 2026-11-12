use Object::Pad ':experimental(:all)';

package App::BS::Common;

role App::BS::Common : does(BS::Common);

use utf8;
use v5.44;

no warnings 'experimental::signature_named_parameters';
no warnings 'experimental::re_strict';
use re 'strict';

use TOML::Tiny;
use Const::Fast;
use List::Util qw(uniq any none);
use Path::Try;
use Struct::Dumb;
use Syntax::Keyword::Dynamically;
use parent 'Exporter';
use IO::Handle::Common;

use vars qw'@EXPORT @EXPORT_OK @EXPORT_INSTANCE @EXPORT_COMMON @EXPORT_SUB';
@EXPORT = qw'refstr ARRAY';

const our $DEFAULT_ENVPREFIXRE => qr/^(?:BS_)?(.+)/;

field $aliases = {};
field $queue : mutator = ();

field $env : mutator = {
    pkgext  => '.pkg.tar.zst',
    debug   => $ENV{DEBUG} // 0,
    charset => 'utf-8',

    # default_config_path => $DEFAULT_CONFIGPATH,

    # arch => $env->%{enabled_targets} // [ $env->{target} // $ENV{CARCH}
    #       // qw(x86_64 x86_64_v3 aarch64 armv7l) ]
};

APPLY($class_mop) {
    __PACKAGE__->apply($class_mop)
};

method import_list : common ( $mop, $export_var ) {
    my @export;
    my @meth = $mop->all_methods;

    # foreach my $export (@$export_var) {
    #     push @export, $export if ;

    # }
    # @export

    grep {
        my $export = $_;
        none { $export eq $_ } map { $_->name } @meth
    } @$export_var;
}

method import : common : override {
    my $caller = [ caller 1 ];
    my $mop    = Object::Pad::MOP::Class->try_for_class( $$caller[0] );

    # my @$methods
    if ($mop) {

        App::BS::Common->import_sub( $mop, \@EXPORT );
        App::BS::Common->import_common( $mop, \@EXPORT_COMMON );

        #
        # my %methdbg = map {
        #     (
        #         $_->name => {
        #             meta   => $_,
        #             class  => { meta => $_->class, name => $_->class->name },
        #             common => $_->is_common
        #         }
        #     )
        # } @meth;
    }
    else {

        dmsg $class->export_to_level(
            $$caller[0],
            $class,
            (
                map {
                    sub { \&{"${class}::$_"} }
                } @EXPORT
            )
        );

        dmsg $class->export_to_level( $$caller[0], $class,
            sub { unshift @_, \&{"${class}::$_"} } )
          for @EXPORT_COMMON;
    }
}

method apply : common ($class_mop) {
    $class->import_sub( $class_mop, \@EXPORT );
    $class->import_common( $class_mop, \@EXPORT_COMMON );
}

method import_sub : common ($class_mop,    $export_sub //= []) {

    foreach my $sub ( $class->import_list( $class_mop, $export_sub ) ) {
        $class_mop->add_method( $sub, common => 1, \&$sub );
    }
    $class_mop;
}

method import_common : common ($class_mop  , $export_common = []) {
    my $class = $class_mop->name;
    foreach
      my $common ( __PACKAGE__->import_list( $class_mop, $export_common ) )
    {

        $class_mop->add_method(
            $common,
            common => 1,
            sub { unshift @_, \&{"${class}::$common"} }
        );
    }
    $class_mop;
}

method import_instance : common ($class_mop) {
    ...;
}

sub matchlist (
    : $quotemeta //= 1,
    : $group //= 1,
    : $capture, : $mod = [], @list
  )
{
    my $str = join '|', @list;
    $str = "?:$group" if $group;
    $str = "($str)"
      if $group || $capture;
    qr/$str/;
}

sub refstr : prototype($) ($ref) {

    # die "Value for \$ref is undefined." unless defined $ref;
    reftype($ref) || "";
}

sub ARRAY : prototype(@) (@in) {
    my @ret;

    foreach my ($var) (@in) {
        $var //= [];
        my $type = reftype($var);

        # if ( !$type ) {
        #     push @ret, [$var];
        # }
        # elsif ( $type ne 'ARRAY' ) {
        #     my $name = PadWalker::var_name( 0, $var );
        #     die "\$name must be an ARRAY ref or a scalar value. (Got: $type)";
        # }
        # elsif ( $type eq 'ARRAY' ) {
        #     push @ret, $var;
        # }

        push @ret, refstr $var eq 'ARRAY' ? $var : [$var];
    }

    @ret;
}

sub epoch( $join = '', %opt ) {
    $opt{ms_pad} //= 6;
    my ( $sec, $ms ) = Time::HiRes::gettimeofday;

    $ms = '0' x ( $opt{ms_pad} - length $ms ) . $ms
      if $opt{ms_pad} && $opt{ms_pad} >= 1;

    join $join, $sec, $ms;
}
