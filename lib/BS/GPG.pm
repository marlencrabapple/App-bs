use Object::Pad ':experimental(:all)';

package BS::GPG;

class BS::GPG : does(BS::Common);

use v5.40;

use parent 'Exporter';

use IPC::Run3;
use BS::Common 'dmsg';

sub can_sign ( $gpgiden, %opts ) {
    my @out = ();

    my $ret = run3(
        [ qw(gpg --verbose -a --export), $gpgiden ],
        \undef,
        sub ($line) {
            chomp $line, say $line;
            push @out, $line;
        },
        sub ($line) {
            chomp $line;
            say $line;
        }
    );

    1 if scalar @out;
}
