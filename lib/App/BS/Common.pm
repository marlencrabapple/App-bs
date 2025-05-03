use Object::Pad;

package App::BS::Common;
role App::BS::Common : does(BS::Common) : does(BS::Path);

use utf8;
use v5.40;

use Carp;
use IPC::Run3;
use TOML::Tiny;
use Const::Fast;
use List::Util qw(uniq any);
use Struct::Dumb;
use Data::Printer;
use Syntax::Keyword::Dynamically;

const our $DEFAULT_ENVPREFIXRE => qr/^(?:BS_)?(.+)/;
const our $DEFAULT_CONFIGPATH  => '/etc/bs/config.toml';

field $config_path : param(config) : mutator =
  [ BS::Path->path($DEFAULT_CONFIGPATH) ];

field $config;
field $getopts_setup : param(getopts) : accessor;
field $cliopts : param(dest) : mutator = {};
field $aliases                         = {};
field $queue : mutator                 = ();

field $env : mutator = {
    pkgext              => '.pkg.tar.zst',
    debug               => 0,
    charset             => 'utf-8',
    default_config_path => $DEFAULT_CONFIGPATH,
    arch                => $cliopts->%{enabled_targets} // [
        $$cliopts{target} // $ENV{CARCH} // qw(x86_64 x86_64_v3 aarch64 armv7l)
    ]
};

#ADJUST {
#    @$config_path = uniq(
#        @$config_path,
#        (
#            ref $self->config_path ne 'ARRAY'
#            ? $self->config_path
#            : $self->config_path->@*
#        )

#    $env      = __PACKAGE__->filter_env;
#    $config   = __PACKAGE__->load_config;
#    %$aliases = __PACKAGE__->alias_namedopt2env($config);

#    $env = __PACKAGE__->setup_env(
#        __PACKAGE__->env2namedopt(
#            env     => $env,
#            aliases => $aliases
#        ),
#        $config, $cliopts
#    );

#    warn np $env, $config, $cliopts if $self->debug // $ENV{DEBUG};
#}

#method add_config ($path) {
#    $config   = { %$config, __PACKAGE__->read_config($path) };
#    %$aliases = __PACKAGE__->alias_namedopt2env($config);

#    $env = __PACKAGE__->setup_env(
#        __PACKAGE__->env2namedopt(
#            env     => $env,
#            aliases => $aliases
#        ),
#        $config, $cliopts
#    );
#}

#method env2namedopt : common (%args) {
#    $args{env} = $class->filter_env() unless scalar %args;
#    map { $args{aliases}->{$_} => delete $args{env}->{$_} } keys $args{env}->%*;
#}

#method load_config : common ($config_path = $class->path($DEFAULT_CONFIGPATH)) {
#    $class->read_config($config_path);
#}

#method read_config : common ($config_path = $class->path($DEFAULT_CONFIGPATH)) {
#    -e $config_path ? TOML::Tiny( $config_path->slurp_utf8 ) : {};
#}

#method conf2env : common ($config, $prefix = 'BS') {
#    $prefix = "$prefix\_" if $prefix;
#    map { "$prefix" . ( $_ =~ s/_//r )[0] => \$$config{$_} } keys %$config;
#}

#method alias_namedopt2env : common ($config, $prefix = 'BS') {
#    $prefix = "$prefix\_" if $prefix;
#    map { "$prefix" . ( $_ =~ s/_//r )[0] => $_ } keys %$config;
#}

#method cli2named : common ($cliopts, $wb = '\-') {
#    map { ( $_ =~ s/$wb/_/r ) => $$cliopts{$_} } keys %$cliopts;
#}

method import_run_env : common ($patterns, %opts) {
    foreach my ( $key, $value ) (@$patterns) {

    }
}

#method filter_env : common ($env_prefix_re = $DEFAULT_ENVPREFIXRE) {
#    dynamically $ENV = { %ENV{ ( grep { $_ =~ $env_prefix_re } keys %ENV ) } };
#    my %env = ();

#    foreach my $key ( keys %$ENV ) {
#        my @path = split /_/, $key;

#        while ( my $lvl = shift @path ) {
#            state $lastlvl //= $env{$lvl};
#            $$lastlvl{$lvl} = scalar @path > 1 ? {} : delete $$ENV{$key};
#            $lastlvl = $env{$lvl};
#        }
#    }

#    warn np(%env) if $ENV{DEBUG};
#    \%env;
#}

#method setup_env : common ($env, $config, $cliopts = {}) {
#    {
#        %$config, %$env,

#          #$class->env2namedopt($env),
#          $class->cli2named($cliopts)
#    }
#}
