use Object::Pad qw(:experimental(:all));

package BS::Common;
role BS::Common : does(BS::Path);

use utf8;
use v5.40;

use Carp;
use IPC::Run3;
use Tie::File;
use List::AllUtils qw(singleton any);
use Data::Dumper;
use Const::Fast;
use Const::Fast::Exporter;
use Syntax::Keyword::Dynamically;
use Syntax::Keyword::Try;
use BS::Path;
use Time::Piece;

use subs qw(dmsg bsx callstack __pkgfn__ const );

use parent 'Exporter';
our @EXPORT = qw(dmsg bsx callstack __pkgfn__ const);

const our $DEBUG   => ( any { $_ } @ENV{qw(BS_DEBUG DEBUG)} ) || 0;
const our $TRIM_RE => qr/\s*(.+)\s*\n*/i;

eval {
    use Devel::StackTrace::WithLexicals;
    use PadWalker qw(peek_my peek_our);
    use Module::Metadata;
} if $DEBUG;

my class BsxResult {
    use utf8;
    use v5.40;

    use subs qw(dmsg);

    field $debug = $BS::Common::DEBUG;

    field @out;
    field @err;

    field $cmd : param : reader;
    field $inh : param(in) : reader = \undef;
    field $outh : param(out) : reader(out) //= \@out;
    field $errh : param(err) : reader //= \@err;
    field $status : param : reader = 0;

    ADJUST {
        BS::Common::dmsg $self
    }
};

field $debug : accessor : param = $DEBUG;

APPLY {
    use utf8;
    use v5.40;
}

ADJUST {
    use utf8;
    use v5.40;
    $ENV{DEBUG} = $debug = $self->cliopts->{debug} // $BS::Common::DEBUG
};

method __pkgfn__ : common ($pkgname = undef) {
    $pkgname //= $class;
    "$pkgname.pm" =~ s/::/\//rg;
}

method callstack : common {
    my @callstack;
    my $i = 0;

    while ( my @caller = caller $i ) {
        {
            no strict 'refs';
            push @caller, \%{"$caller[0]\::"};
            push @caller, $caller[0]->META() if ${"$caller[0]\::"}{META}
        }

        push @callstack, \@caller;
    }
    continue { $i++ }

    @callstack;
}

sub dmsg (@msgs) {
    my $self =    # Maybe there's a reason to make an anon class here?
      blessed $msgs[0] && $msgs[0]->DOES('BS::Common') ? shift @msgs : undef;

    if ( state $debug = $DEBUG // $ENV{DEBUG} // undef ) {

        my @caller = caller 0;

        my $out = "*** " . localtime->datetime . " - DEBUG MESSAGE ***\n\n";

        {
            local $Data::Dumper::Pad    = "  ";
            local $Data::Dumper::Indent = 1;

            $out .=
                scalar @msgs > 1 ? Dumper(@msgs)
              : ref $msgs[0]     ? Dumper(@msgs)
              :   eval { my $s = $msgs[0] // 'undef'; "  $s\n" };

            $out .= "\n"
        }

        $out .=
          $ENV{DEBUG} && $ENV{DEBUG} == 2
          ? join "\n",
          map { ( my $line = $_ ) =~ s/^\t/  /; "  $line" } split /\R/,
          Devel::StackTrace::WithLexicals->new(
            indent      => 1,
            skip_frames => 1
          )->as_string
          : "at $caller[1]:$caller[2]";

        say STDERR "$out\n";
        $out;
    }
}

method bsx : common ($cmd_aref, %args) {
    %args = ( in => undef, out => [], err => '' ) unless scalar keys %args;

    dmsg "${class}::bsx([ '$$cmd_aref[0]', ... ], ...) args:";
    dmsg $cmd_aref, %args;

    run3( $cmd_aref,
        map { ref $_ ? $_ : defined $_ ? \$_ : undef } @args{qw(in out err)} );

    my $res = BsxResult->new(
        cmd    => $cmd_aref,
        status => $?,
        %args{qw(in out err)}
    );

    my %ret = map { $_ => $res->$_ } $args{fields}->@*;
    scalar %ret ? \%ret : $res;
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

    dmsg $as_href;
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
