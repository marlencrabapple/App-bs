use Object::Pad;

package BS::Common;
role BS::Common;

use utf8;
use v5.40;

use Carp;
use IPC::Run3;
use Tie::File;
use List::Util 'any';
use Const::Fast;
use Data::Dumper;
use Struct::Dumb qw( -named_constructors );
use Data::Printer;

use parent 'Exporter';
our @EXPORT = qw(bsx);

const our $DEBUG   => ( any { $_ } @ENV{qw(BS_DEBUG DEBUG)} ) || 0;
const our $TRIM_RE => qr/\s*(.+)\s*\n*/i;

field $debug : accessor : param = $DEBUG;

ADJUST {
    $ENV{DEBUG} = $debug = $self->cliopts->{debug} // $DEBUG
};

struct BsxResult => [qw(cmd in out err run3exit cmdexit)];

method bsx : common ($cmd_aref, %args) {
    %args = ( in => undef, out => [], err => '' ) unless scalar keys %args;

    if ( $DEBUG // $args{debug} ) {
        warn "${class}::bsx([ '$$cmd_aref[0]', ... ], ...) args:";
        warn np $cmd_aref, %args;
    }

    my $ret = run3( $cmd_aref,
        map { ref $_ ? $_ : defined $_ ? \$_ : undef } @args{qw(in out err)} );

    my $res = BsxResult(
        cmd => $cmd_aref,
        %args{qw(in out err)},
        run3exit => $ret,
        cmdexit  => [ $?, $! ]
    );

    if ( $args{err} && ${ $args{err} } || $ret != 1 ) {
        $args{on_err} && ref $args{on_err} eq 'CODE'
          ? $args{on_err}->( $ret, $args{err}, $args{out} )
          : croak " > $ret: ${$args{err}}", $res;
    }

    $res;
}

method open_as_href : common ($in, %args) {
    my ( $as_aref, $as_path );
    my $as_href = delete $args{dest} // {};

    $as_aref = $class->tie_file( $in, dest => $as_href, %args );

    foreach my $line (@$as_aref) {
        $line =~ s/$TRIM_RE/$1/;

        my ( $key, $val ) =
          $args{parse_line}->( $line, dest => $as_href, %args );

        next unless $key && $val;

        if ( $$as_href{$key} ) {
            if (   $args{no_dupes}
                && $args{dest}->{$key}
                && $$as_href{$key} eq $args{dest}->{$key} )
            {
                next;
            }

            $$as_href{$key} = [ $$as_href{$key} ]
              if ref $$as_href{$key} ne 'ARRAY';
            push $$as_href{$key}->@*, $val;
        }
        else {
            $$as_href{$key} = $val;
        }
    }

    warn Dumper($as_href) if $ENV{DEBUG};
    $as_href;
}

method tie_file : common ($in, %args) {
    my $as_aref = [];
    my $as_href = $args{dest} // {};

    if ( $in isa Path::Tiny ) {
        tie @$as_aref, 'Tie::File', "$in";
    }
    elsif ( ref $in eq 'GLOB' ) {
        tie @$as_aref, 'Tie::File', $in;
    }
    elsif ( ref $in eq 'ARRAY' ) {

        #$as_aref = $in
        return $in;
    }
    elsif ( !ref $in ) {
        if ( -e "$in" ) {
            my $as_path = path($in);
            tie @$as_aref, 'Tie::File', "$in";
        }
        elsif ( $args{out} ) {
            @$as_aref = split /\n/, $in;
            tie @$as_aref, 'Tie::File', $args{out} if $args{out};
            ...;
        }
    }

    $as_aref;
}
