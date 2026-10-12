use Object::Pad ':experimental(:all)';

package BS::GPG;

class BS::GPG : does(BS::Common);

use utf8;
use v5.40;

use parent 'Exporter';

our @EXPORT = qw(can_sign);

use IPC::Nosh;
use IO::Handle::Common;

field $pubid     : param = "";
field $gnupghome : param = $ENV{BS_GNUPGHOME} // "$ENV{BS_ROOT}/.gnupg";

# my class Path :isa(Path::Tiny) {

# };

# sub path {
#     Path::path(@_)
# }

# method updpath ($old, $new, %opt) {
#     ($old, $new) = map { path($_)->absolute } ($old, $new);
#     if($old ne $new) {
#         $new->realdir
#     }
# }

# method gnupghome ($path //= $gnupghome) {
#   state $cached //= path($path);
#   $cached = $self->updpath($cached, $path);
#   $path;
# }

# method sign_pkgfile ( $path, %opt ) {

# }

sub can_sign ( $gpgiden, %opt ) {
    my @out = ();

    $ENV{GNUPGHOME} //= $ENV{BS_GNUPGHOME}
      if $ENV{BS_GNUPGHOME};

    my $run = run(
        [ qw(gpg --verbose -a --export), $gpgiden ],
        out => sub ( $line, @ ) {
            say $line if $ENV{VERBOSE} || $opt{verbose};
            push @out, $line;
        },
        err => sub ( $line, @ ) {
            say $line;
        },
        autochomp => 1
    );

    dmsg $run;

    1 if scalar @out;
}
