use Object::Pad ':experimental(:all)';

package App::BS::Package::Version;
role App::BS::Package::Version;

use utf8;
use v5.44;

no warnings 'experimental::re_strict';
use re 'strict';

use IO::Handle::Common;
use Const::Fast;
use Exporter;
use IPC::Nosh;

const our $pkgname_re => qr/
([a-z0-9_@+][a-z0-9_@+.-]+)
 (?:
   ([\s-]|[=<>]{1}|[<>]=)
   ([^\s:\/\\-]+?)
 )?/xi;

const our $pkgver_re => qr'^[^\s:/\\-]+$'x;

method vercmp : common  ( $ver1, $ver2, %opt ) {
    my @ver = ( $ver1, $ver2 );
    my $run = run(
        [ 'vercmp', $opt{reverse} ? reverse @ver : @ver ],
        autoflush => 1,
        autochomp => 1
    );

    dmsg $run;

    $run->status;
}
