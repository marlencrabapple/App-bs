use Object::Pad ':experimental(:all)';

package App::BS::Ext::pacman::Config;

role App::BS::Ext::pacman::Config : does(App::BS::Common) : does(App::BS::Run);

use v5.44;
use utf8;

use Const::Fast;
use Path::Try;
use List::Util qw'any all none';
use IO::Handle::Common;
use App::BS::Common;
use Syntax::Keyword::Defer;

IO->decorate(1);

field $file : reader(pacman_conf) //= '/etc/pacman.conf';

# field $lines = [];
# field $content;
field $ord : reader              = [];
field $config :                  = {};
field $repo : accessor(repolist) = {};
field $rootdir                   = '/';
field $dbpath                    = '';
field $cachedir : accessor       = undef;
field $logfile                   = '';

ADJUST : params (:$pacman_conf //= $file, %param) {
    $file   = path($pacman_conf);
    $config = { %$config, $self->pacconf($file)->%* };
};

ADJUST {
    $cachedir //= path( $config->{options}{CacheDir} );

    foreach my ( $k, $v ) (%$config) {
        if (   refstr($v) eq 'HASH'
            && refstr( $$v{Server} ) eq 'ARRAY'
            && scalar $$v{Server}->@* > 0 )
        {
            $$repo{$k} = $v;
        }
    }
};

method load_config : common ($path, %opt) {
    const my $mop => Object::Pad::MOP::Class->begin_class('PacmanConf');
    $mop->add_role($class);
    $mop->seal;
    my $realclass = $mop->name;
    $realclass->new( pacman_conf => $path );
}

method to_string ( $configdata //= $config, %opt ) {
    state $section //= $config;

    foreach my ( $k, $v ) (@$ord) {
        if ( ref $$v ) {
            if ( refstr( $$config{$k} ) eq 'ARRAY' ) {
                say "$k = $$config{$k}";
            }
            elsif ( refstr( $$config{k} ) eq 'HASH' ) {
                foreach my ( $_k, $v ) ( $$config{$k}->%* ) {
                    say "$_k = $v" for ARRAY($v);
                }
            }
        }
    }
}

method pacconf ( $path, %opt ) {
    my $run = $self->run( [ qw'pacconf --config', $path ] );
    $self->parse_pacman_conf( lines => [ $run->out->lines_utf8 ] );
}

my method parse_pacman_conf_line ( $line, %opt ) {
    return undef unless $line;
    state $section   //= $config;
    state $section_i //= 0;

    if ( my ($section_k) = ( $line =~ /^\[([^\]]+)\]$/ ) ) {
        $section = $config->{$section_k} //= {};
        push @$ord, $section_k;
        $section_i++;
    }
    elsif ( my ( $k, $v ) = ( $line =~ /^([^=]+?)\s*=\s*(.+)$/ ) ) {
        return undef
          unless all { $_ } $k, $v;

        my @vsplit = split /\s/, $v;
        $v = \@vsplit if scalar @vsplit > 1;

        if ( my $curr = ( $$section{$k} ) ) {
            if ( refstr($curr) eq 'ARRAY' ) {
                push $$section{$k}->@*, $v;
                push $$ord[$section_i]->@*, $k
                  if none { $k eq $_ } $$ord[$section_i]->@*;
            }
            elsif ( !ref $curr ) {
                $$section{$k} = [$v];
                $$ord[$section_i] = [$k];
            }

        }
        else {
            $$section{$k} = $v;
            $$ord[$section_i] = [$k];
        }
    }
}

method parse_pacman_conf (%opt) {
    parse_pacman_conf_line( $self, $_ ) for $opt{lines}->@*;
    $config;
}

# method load_config : common {
#     my class PacmanConf {
#         ADJUST : params (:$config)
#           { $self->load_config( path($config)->absolute ) }
#     };
# }
