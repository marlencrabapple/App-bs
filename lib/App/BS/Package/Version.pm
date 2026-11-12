use Object::Pad ':experimental(:all)';

package App::BS::Package::Version;
role App::BS::Package::Version : does(App::BS::Common) : does(App::BS::Run);

use utf8;
use v5.44;

no warnings 'experimental::re_strict';
use re 'strict';

use IO::Handle::Common;
use Const::Fast;
use parent 'Exporter';
use IPC::Nosh;

use vars qw'@EXPORT @EXPORT_OK @EXPORT_COMMON';
@EXPORT_COMMON = qw'vercmp';

const our $pkgname_re => qr/
([a-z0-9_@+][a-z0-9_@+.-]+)
 (?:
   ([\s-]|[=<>]{1}|[<>]=)
   ([^\s:\/\\-]+?)
 )?/xi;

const our $pkgver_re => qr'^[^\s:/\\-]+$'x;

APPLY($class_mop) {
    App::BS::Common->apply($class_mop)
};

# method apply : common ($class_mop) {
#     $class->import_sub( $class_mop, \@EXPORT );
#     $class->import_common( $class_mop, \@EXPORT_COMMON );
# }

# method import : common : override {
#     my $caller = [ caller 1 ];
#     my $mop    = Object::Pad::MOP::Class->try_for_class( $$caller[0] );

#     if ($mop) {
#         my $mop    = App::BS::Common->import_common( $mop, \@EXPORT_COMMON );
#         my @method = $mop->all_methods;
#         my %method = map {
#             (
#                 $_->name => {
#                     meta   => $_,
#                     class  => { meta => $_->class, name => $_->class->name },
#                     common => $_->is_common
#                 }
#             )
#         } @method;
#     }
#     else {

#         dmsg $class->export_to_level( $$caller[0], $class,
#             sub { unshift @_, \&{"${class}::$_"} } )
#           for @EXPORT_COMMON;
#     }
# }

method vercmp : common ($left,$right,%opt) {
    my class VerCmp : does(App::BS::Run) {

    };

    my $run = VerCmp->new->run(
        [
            'vercmp',
            map { $opt{ignore_pkgrel} ? ( $_ =~ s/-[0-9]+$//r ) : $_ }
              ( $left, $right )
        ],
    );

    return ( $run->out->lines_utf8 )[0];
}
