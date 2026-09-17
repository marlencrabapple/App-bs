use Object::Pad;

package App::BS::Common;

role App::BS::Common : does(BS::Common);
use utf8;
use v5.40;

use Carp;
use IPC::Run3;
use TOML::Tiny;
use Const::Fast;
use List::Util qw(uniq any);
use Path::Tiny;
use Struct::Dumb;
use Syntax::Keyword::Dynamically;
use parent 'Exporter';

use vars qw'@EXPORT @EXPORT_OK';
@EXPORT = qw'refstr ARRAY';

const our $DEFAULT_ENVPREFIXRE => qr/^(?:BS_)?(.+)/;
const our $DEFAULT_CONFIGPATH  => '/etc/bs/config.toml';

field $config_path : param(config) : mutator = path($DEFAULT_CONFIGPATH);

# field $config;

field $aliases = {};
field $queue : mutator = ();

field $env : mutator = {
    pkgext              => '.pkg.tar.zst',
    debug               => 0,
    charset             => 'utf-8',
    default_config_path => $DEFAULT_CONFIGPATH,

    # arch => $env->%{enabled_targets} // [ $env->{target} // $ENV{CARCH}
    #       // qw(x86_64 x86_64_v3 aarch64 armv7l) ]
};

ADJUST {
    use utf8;
    use v5.40;
    $ENV{DEBUG} = $self->debug = $BS::Common::DEBUG
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
