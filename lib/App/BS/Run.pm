use Object::Pad ':experimental(:all)';

package App::BS::Run;

role App::BS::Run : does(App::BS::Common);

use v5.44;
use utf8;

use Const::Fast;
use Path::Try;
use List::Util qw'any all';
use IO::Handle::Common;
use IPC::Nosh qw'';
use App::BS::Common;
use Sublike::Extended;

extended method run ( $cmd, : $in = undef, : $out = [], : $err = [], %opt ) {
    $opt{autochomp} //= 1;
    $opt{autoflush} //= 1;

    dmsg $cmd, $in, $out, $err, \%opt;

    # my $outh
    ( $in, $out, $err ) = ARRAY( $in, $out, $err );

    my $run = IPC::Nosh::run(
        $cmd,

        # in  => $in,
        out => sub ( $line, @ ) {
            say $line if $opt{verbose};
            my $ret;
            foreach my ($cb) ( grep { $_ && refstr $_ eq 'CODE' } @$out ) {

                $ret  = $cb->($line);
                $line = $ret // $line;

            }
        },
        err => sub ( $line, @ ) {
            error $line;

            # state $mod
            # my $modified = $_->($line) for @$err
            # my $=
            my $ret;
            foreach my ($cb) ( grep { $_ && refstr $_ eq 'CODE' } @$err ) {

                $ret  = $cb->($line);
                $line = $ret // $line;

            }
        },
        autochomp => 1,
        autoflush => 1,
        %opt
    );

    # dmsg $run;
    $run;
}
