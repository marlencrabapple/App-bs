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
use Sublike::Extended;
use Syntax::Keyword::Dynamically;

extended method run ( $cmd, : $in = [], : $out = [], : $err = [], %opt ) {
    $opt{autochomp} //= 1;

    # $opt{autoflush} //= 1;

    # dmsg $cmd, $in, $out, $err, \%opt;

    dmsg $self, \%App::BS::Common::;

    ( $in, $out, $err ) = App::BS::Common::ARRAY( $in, $out, $err );

    my $itercb = sub ( $line, @arg ) {
        my $ret;
        foreach my ($cb)
          ( grep { $_ && App::BS::Common::refstr($_) eq 'CODE' } @$out )
        {
            $ret = $cb->($line);
            dynamically $line = $ret // $line;
        }
        $ret;
    };

    my $run = IPC::Nosh::run(
        $cmd,

        out => sub ( $line, @ ) {
            say $line if $opt{verbose};
            $itercb->($line);
        },
        err => sub ( $line, @ ) {
            error $line;
            $itercb->($line);
        },
        %opt
    );

    dmsg $run if $run->status != 0;
    $run;
}
