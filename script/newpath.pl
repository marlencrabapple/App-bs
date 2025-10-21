#!/usr/bin/env perl
use Object::Pad ':experimental(:all)';

# TODO: CLosing handles with defer, DESTROY block
package BS::Path;
use lib 'lib';

class BS::Path : does(BS::Common);

field $handle;

use utf8;
use v5.40;

use Tie::File;
use Cwd;
use File::chdir;
use Path::Tiny qw();
use BS::Common;
use Digest::SHA qw(sha1_hex sha256_hex sha512_hex);

field $constructor;

field $path;
field $fh;

# v1: common method and AUTOLOAD or symbol table hacking
# v2: subroutine
method $_path ( $pathto, %opts ) {
    my $mode = $opts{mode} // '<';
    state %handles = ();

    if ( -d $pathto ) {

   # opendir my ( $dh, $pathto )
   #   // BS::Commo        # opendir my ( $dh, $pathto )
   #   // BS::Common::fatal( "Could not open '$pathto' as a directory. ($?)",
   #     exit => $? );n::fatal( "Could not open '$pathto' as a directory. ($?)",
   #     exit => $? );
    }
    else {
        open my $fh, $mode, $pathto
          or BS::Common::fatal("Could not open '$pathto' (mode: $mode)");
        $handles{$fh} = $fh;

    }

    BS::Common::dmsg( { handles => \%handles } );
}

#sub path {
#
#}

method path : common ($path, %opts) {

}

