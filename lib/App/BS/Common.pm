use Object::Pad;

package App::BS::Common;
role App::BS::Common;

use utf8;
use v5.40;

use Carp;
use IPC::Run3;
use Path::Tiny;
use TOML::Tiny;
use Struct::Dumb;
use Data::Printer;
use Syntax::Keyword::Dynamically;
use Getopt::Long;

Getopt::Long::Configure("bundling");

use constant DEFAULT_ENVPREFIXRE => qr/BS_(.+)/;
use constant DEFAULT_CONFIGPATH => '/etc/pkgbuild/config.toml';

field $env;
field $_config_path :param(config) = path(DEFAULT_CONFIGPATH);
field $config;
field $getopts_setup :param(getopts);
field $cliopts :param(dest) = {};
field %aliases;
field @queue = ();

ADJUST {
  push @$getopts_setup
    , "<>", sub { $self->handle_barearg(@_) };

  GetOptions($cliopts, $getopts_setup->@*);

  #$env     = __CLASS__->filter_env;
  #$config  = __CLASS__->load_config;
  #$%aliases = __CLASS__->alias_namedopt2env($config);
  
  #$env = __CLASS__->setup_env(env2namedopt(env => $env,
  #                            aliases => \%aliases),
  #                            $config, $cliopts)
}

method handle_barearg ($str) {
  if (length $str == 1 && $ARGV[-1] eq $str) {
    $self->cliopts->{seperator} = $str
  }
  else {
    push @queue, $str
  }
}

# method env2namedopt :common (%args) {
#   $args{env} = $class->filter_env() unless scalar %args;
#   map { $args{aliases}->{$_} => delete $args{env}->{$_} } keys $args{env}->%*
# }

# method load_config :common ($config_path = path(DEFAULT_CONFIGPATH)) {
#   my $config = __CLASS__->read_config($config_path);
#   #{ %$config, __CLASS__->conf2env($config, '') }
#   $config
# }

# method read_config :common ($config_path = path(DEFAULT_CONFIGPATH)) {
#   -e $config_path ? TOML::Tiny($config_path->slurp_utf8) : {}
# }

# method conf2env :common ($config, $prefix = 'BS') {
#   $prefix = "$prefix\_" if $prefix;
#   map { "$prefix" . ($_ =~ s/_//r)[0] => \$$config{$_} } keys %$config
# } 

# method alias_namedopt2env :common ($config, $prefix = 'BS') {
#   $prefix = "$prefix\_" if $prefix;
#   map { "$prefix" . ($_ =~ s/_//r)[0] => $_ } keys %$config
# } 

# method filter_env :common ($env_prefix_re = DEFAULT_ENVPREFIXRE) {
#   dynamically $ENV = { %ENV{(grep { $_ =~ $env_prefix_re } keys %ENV)} };
#   my %env = ();

#   foreach my $key (keys %$ENV) {
#     my @path = split /_/, $key;

#     while (my $lvl = shift @path) {
#       state $lastlvl //= $env{$lvl};
#       $$lastlvl{$lvl} = scalar @path > 1 ? {} : delete $$ENV{$key};
#       $lastlvl = $env{$lvl}
#     }
#   }

#   p(%env)
# }

# method setup_env :common ($env, $config, $cliopts = {}) {
#   { %$config,
#     $class->env2config($class->filter_env),
#     $class->cli2named($cliopts) }
# }

