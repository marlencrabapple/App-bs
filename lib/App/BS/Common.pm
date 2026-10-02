use Object::Pad;

package App::BS::Common;

role App::BS::Common : does(BS::Common);

use utf8;
use v5.44;

use TOML::Tiny;
use Const::Fast;
use List::Util qw(uniq any);
use Path::Try;
use Struct::Dumb;
use Syntax::Keyword::Dynamically;
use parent 'Exporter';
use IO::Handle::Common;

use vars qw'@EXPORT @EXPORT_OK';
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

sub refstr : prototype($) ($ref) {

    # die "Value for \$ref is undefined." unless defined $ref;
    reftype($ref) || "";
}

sub ARRAY : prototype(@) (@in) {
    my @ret;

    foreach my ($var) (@in) {
        $var //= [];
        my $type = reftype($var);

        if ( !$type ) {
            push @ret, [$var];
        }
        elsif ( $type ne 'ARRAY' ) {
            my $name = PadWalker::var_name( 0, $var );
            die "\$name must be an ARRAY ref or a scalar value. (Got: $type)";
        }
        elsif ( $type eq 'ARRAY' ) {
            push @ret, $var;
        }
    }

    @ret;
}
