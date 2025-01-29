use Object::Pad;

package App::BS::Common;
role App::BS::Common;

use utf8;
use v5.40;

use Carp;
use IPC::Run3;
use Path::Tiny;
use TOML::Tiny;
use List::Util 'uniq';
use Struct::Dumb;
use Data::Printer;
use Syntax::Keyword::Dynamically;

use constant DEFAULT_ENVPREFIXRE => qr/^BS_(.+)/;
use constant DEFAULT_CONFIGPATH => '/etc/bs/config.toml';

field $env;
field $config_path :param(config) :accessor = [ path(DEFAULT_CONFIGPATH) ];
field $config;
field $getopts_setup :param(getopts) :accessor;
field $cliopts :param(dest) :accessor = {};
field $aliases = {};
field @queue = ();

ADJUST {
  # push @$getopts_setup
  #   , "<>", sub { $self->handle_barearg(@_) };

  #GetOptions($cliopts, $getopts_setup->@*);

  @$config_path = uniq (@$config_path, (ref $self->config_path ne 'ARRAY'
    ? $self->config_path
    : $self->config_path->@*));

  $env      = __CLASS__->filter_env;
  $config   = __CLASS__->load_config;
  %$aliases = __CLASS__->alias_namedopt2env($config);
  
  $env = __CLASS__->setup_env(__CLASS__->env2namedopt(env => $env,
                             aliases => $aliases),
                             $config, $cliopts);

  p $env, $config, $cliopts;
}

method handle_barearg ($str) {
  if (length $str == 1 && $ARGV[-1] eq $str) {
    $self->cliopts->{seperator} = $str
  }
  else {
    push @queue, $str
  }
}

method add_config ($path) {
  $config = { %$config, __CLASS__->read_config($path) };
  %$aliases = __CLASS__->alias_namedopt2env($config);
  
  $env = __CLASS__->setup_env( __CLASS__->env2namedopt(
                                  env => $env
                                , aliases => $aliases )
                             , $config, $cliopts )
}

method env2namedopt :common (%args) {
  $args{env} = $class->filter_env() unless scalar %args;
  map { $args{aliases}->{$_} => delete $args{env}->{$_} } keys $args{env}->%*
}

method load_config :common ($config_path = path(DEFAULT_CONFIGPATH)) {
  $class->read_config($config_path)
}

method read_config :common ($config_path = path(DEFAULT_CONFIGPATH)) {
  -e $config_path ? TOML::Tiny($config_path->slurp_utf8) : {}
}

method conf2env :common ($config, $prefix = 'BS') {
  $prefix = "$prefix\_" if $prefix;
  map { "$prefix" . ($_ =~ s/_//r)[0] => \$$config{$_} } keys %$config
} 

method alias_namedopt2env :common ($config, $prefix = 'BS') {
  $prefix = "$prefix\_" if $prefix;
  map { "$prefix" . ($_ =~ s/_//r)[0] => $_ } keys %$config
}

method cli2named :common ($cliopts, $wb = '\-') {
  map { ( $_ =~ s/$wb/_/r ) => $$cliopts{$_} } keys %$cliopts
}

method filter_env :common ($env_prefix_re = DEFAULT_ENVPREFIXRE) {
  dynamically $ENV = { %ENV{(grep { $_ =~ $env_prefix_re } keys %ENV)} };
  my %env = ();

  foreach my $key (keys %$ENV) {
    my @path = split /_/, $key;

    while (my $lvl = shift @path) {
      state $lastlvl //= $env{$lvl};
      $$lastlvl{$lvl} = scalar @path > 1 ? {} : delete $$ENV{$key};
      $lastlvl = $env{$lvl}
    }
  }

  warn np(%env) if $ENV{DEBUG};
  \%env
}

method setup_env :common ($env, $config, $cliopts = {}) {
  { %$config,
    %$env,
    #$class->env2namedopt($env),
    $class->cli2named($cliopts) }
}

