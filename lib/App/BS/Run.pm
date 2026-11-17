use Object::Pad ':experimental(:all)';

package App::BS::Run;

role App::BS::Run : does(App::BS::Common);

use v5.44;
use utf8;

use Const::Fast;
use Path::Tiny;
use List::Util qw'any all';
use IO::Handle::Common;
use Sublike::Extended;
use Syntax::Keyword::Dynamically;

field $autochomp : param = 1;
field $autoflush : param = 1;

my class IPC {
    use v5.44;

    use IPC::Run3;
    use Sublike::Extended;
    use IO::Handle::Common;

    field $cmd    : param;
    field $in     : param = \undef;
    field $out    : param = [];
    field $err    : param = [];
    field $status : reader;
    field $syserr;
    field $ipcfail;
    field $autochomp : param = 1;
    field $autoflush : param = 1;
    field $verbose   : param = 0;

    method exec (%opt) {
        my $itercb = sub ( $line, $dest, @arg ) {

            my $ret;
            foreach my ($cb)
              ( grep { $_ && App::BS::Common::refstr($_) eq 'CODE' } @$dest )
            {
                $ret = $cb->($line);
                dynamically $line = $ret // $line;
            }
            $ret //= $line;

        };
        dmsg $cmd, $in, $out, $err, $self;
        dynamically $ipcfail = run3(
            $cmd, $in,
            sub ($line) {
                chomp $line if $opt{autochomp} // $autochomp;
                say $line   if $opt{verbose}   // $verbose;
                push @$out, $itercb->( $line, $out );
            },
            sub ($line) {
                chomp $line if $opt{autochomp} //= $autochomp;
                error $line;
                push @$err, $itercb->( $line, $err );
            }
        );
        dynamically $status = $? // 0;
        dynamically $syserr = $! // undef;
        $self;
    }

# extended method run :
#   common ( $cmd, $in = \undef, $out = [], $err = [], :$autochomp = 1, :$autoflush = 1 )
# {
#     my %param = (
#         cmd       => $cmd,
#         in        => $in,
#         out       => $out,
#         err       => $err,
#         autochomp => $autochomp,
#         autoflush => $autoflush
#     );

    #     $class->new(%param)->exec;
    # }

    my class IPCHandle {
        use v5.44;

        use IO::Handle::Common '';
        use Unicode::UTF8 qw'decode_utf8';

        field $lines : param //= [];
        field $join_ch;

        ADJUST : params (:$autochomp //= 1) {
            $join_ch =
              $autochomp
            ? "\n"
            : "";
        };

        method lines      { @$lines }
        method lines_utf8 { ( split /\n/, $self->slurp_utf8 ) }
        method slurp      { join $join_ch, @$lines }
        method slurp_utf8 { decode_utf8( $self->slurp ) }
    }

    method in {
        IPCHandle->new();
    }

    method out {
        IPCHandle->new( autochomp => 1, lines => $out );
    }

    method err {
        IPCHandle->new( autochomp => 1, lines => $err );
    }

}

extended method run ( $cmd, : $in = \undef, : $out = [], : $err = [], %opt ) {
    $opt{autochomp} //= 1;

    ( $in, $out, $err ) = App::BS::Common::ARRAY( $in, $out, $err );
    use PadWalker;

    my $lex = App::BS::Common->lexical;

    dmsg $lex;

    IPC->new( $lex->%{qw'cmd in out err autochomp autoflush'}, $lex->{opt}->%* )
      ->exec();
}
