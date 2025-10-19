#!/usr/bin/env perl
use Object::Pad ':experimental(:all)';

# TODO: CLosing handles with defer, DESTROY block
package BS::Path;
use lib 'lib';

class BS::Path : does(BS::Common);
field $handle;

use utf8;
use v5.40;

use BS::Common;
use Digest::SHA qw(sha1_hex sha256_hex sha512_hex);
field $pathto;

# v1: common method and AUTOLOAD or symbol table hacking
# v2: subroutine
method $_path ( $pathto, %opts ) {
    my $mode = $opts{mode} // '<';
    state %handles = ();
    open my $fh, $mode, $pathto
      or BS::Common::fatal("Could not open '$pathto' (mode: $mode)");
    $handles{$fh} = $fh;
    BS::Common::dmsg( { handles => \%handles } );
}

#sub path {
#
#}

method path : common () {

}

