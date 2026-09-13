use Object::Pad ':experimental(:all)';

package App::BS::Ext::pacman::Config;

role App::BS::Ext::pacman::Config;

use v5.44;
use utf8;

use Path::Try;
use List::Util qw'any all';
use IO::Handle::Common;
use IPC::Nosh;

field $file    : reader : param = '/etc/pacman.conf';
field $content : param = '';
field $lines   : param = [];
field $config = {};

field $repos : reader = [];

field $rootdir             = '/';
field $dbpath              = '';
field $cachedir : accessor = undef;
field $logfile             = '';

field $verbose : param : accessor //= $ENV{VERBOSE};

ADJUST {
    $config = { %$config, $self->pacconf($file)->%* };
    $cachedir //= path( $config->{options}{CacheDir} );
}



method load_config : common ($path, %opt) {
    $class->new( pacman_conf => $path );
}

method pacconf ( $path, %opt ) {
    $path = path($path);

    my $run = run(
        [ qw'pacconf --config', $path ],
        out => sub ( $line, @arg ) {

            push @$lines, $line;
            say $line if $self->verbose;
        },
        autoflush => 1,
        autochomp => 1
    );

    $self->parse_pacman_conf( lines => [ $run->out->lines_utf8 ] );
}


method parse_pacman_conf (%opt) {
    my method parse_pacman_conf_line ($line) {
        return undef unless $line;
        state $section //= $config;

        if ( my ($section_k) = ( $line =~ /^\[([^\]]+)\]$/ ) ) {
            $section = $config->{$section_k} //= {};
        }
        elsif ( my ( $k, $v ) = ( $line =~ /^([^=]+?)\s*=\s*(.+)$/ ) ) {
            return undef
              unless all { $_ } $k, $v;

            my @vsplit = split /\s/, $v;
            $v = \@vsplit if scalar @vsplit > 1;

            if ( my $curr = ( $$section{$k} ) ) {
                if ( ref $curr eq 'ARRAY' ) {
                    push $$section{$k}->@*, $v;
                }
                elsif ( !ref $curr ) {
                    $$section{$k} = [$v];
                }
            }
            else {
                $$section{$k} = $v;
            }
        }
    };

    parse_pacman_conf_line( $self, $_ ) for $opt{lines}->@*;
    $config;
}

