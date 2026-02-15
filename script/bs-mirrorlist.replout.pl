package bs-mirrorlist; use v5.40;
package bs-mirrorlist; use v5.40;
use v5.40
packakge bs_mirrorlist
package bs_mirrorlist
use v5.40
use Path::Tiny
my $mirrorlist_in = path("/etc/pacman.conf/mirrorlist")
$out = $mirrorlist_in->slurp_utf8
my $out = $mirrorlist_in->slurp_utf8
my $mirrorlist_in = path("/etc/pacman.d/mirrorlist")
my $out = $mirrorlist_in->slurp_utf8
$out =~ s/^\n$//
$out =~ s/^\n$//g
$out
$out =~ s/^[\n\r\s]*$//g
$out
$out =~ s/^[\n\r\s]*$//mg
$out
$out =~ s/^#.+$//mg
$out
$out =~ s/^#.+$//g    
$out
my $mirrorlist_in = path("/etc/pacman.d/mirrorlist")
my $out = $mirrorlist_in->slurp_utf8
$out =~ s/^#.+$//g
$out
my $out = $mirrorlist_in->slurp_utf8
$out =~ s/^##.+$//mg 
$out =~ s/\$arch/x86_64/mg 
$out
$out =~ s/^[\n\r]$//r
$out =~ s/^[\n\r\s]$//r
$out =~ s/\n{2,}//r
$out =~ s/\n{1,}//r
$out =~ s/\n{1,}//gr
$out =~ s/\n{2,}//gr
$out =~ s/\n{3,}//gr
$out =~ s/\n{4,}//gr
$out =~ s/[\n\r\s]{4,}//gr
$out =~ s/[\n\r\s]{1,}//gr
$out =~ s/[\n\r\s]{2,}//gr
$out =~ s/[\n\r\s]{2,}/\n/gr
$out =~ s/[\n\r]{2,}/\n/gr
$out =~ s/^[\n\r]{2,}/\n/gr
$out =~ s/^[\s\n\r]{2,}/\n/gr
$out =~ s/[\s\n\r]{2,}/\n/gr
$out =~ s/^[\s\n\r]{2,}/\n/r
$out =~ s/^[\s\n\r]{1,}/\n/r
$out =~ s/^[\s\n\r]+/\n/r
$out =~ s/[\s\n\r]{2,}/\n/gr
$out =~ s/(?:##)?[\s\n\r]{2,}/\n/gr
$out =~ s/(?:##\n)?[\s\n\r]{2,}/\n/gr
$out =~ s/(?:##\n\n)?[\s\n\r]{2,}/\n/gr
$out =~ s/(?:##\n)?[\s\n\r]{2,}/\n/gr
$out =~ s/\n//r
$out =~ s/\n{2,}/\n/r
$out =~ s/\n{2,}/\n/gr
$out =~ s/\n{2,}/\n/g
$out =~ s/\n//gr
$out =~ s///gr
$out =~ s/##\n//gr
path("/bs/target/mirrorlist-x86_64-" . time)->spew_utf8($out)
path("/bs/target/mirrorlist-x86_64-" . time)->slurp_utf8
path("/bs/target/mirrorlist-x86_64*")->slurp_utf8
path("/bs/target/")->children
`perldoc Devel::REPL`
my $devel_repl_plaintxt = `perldoc Devel::REPL`
path("$ENV{HOME}/devel-repl-pod.txt")->spew_utf8($devel_repl_plaintxt)
path("$ENV{HOME}/devel-repl-pod.txt")->slurp_utf8
$_REPL
package bs-mirrorlist; use v5.40;
use Data::Dumper;
use Dotfiles::p5;
Dotfiles::p5::dmsg($_REPL)
Dotfiles::p5::Base::dmsg($_REPL)
$ENV{DEBUG}=1; Dotfiles::p5::Base::dmsg($_REPL)
$ENV{DEBUG}=1; Dotfiles::p5::Base::dmsg(keys %$_REPL)
$ENV{DEBUG}=1; Dotfiles::p5::Base::dmsg($$_REPL{history})
path("$ENV{HOME}/dotfiles++/App-bs/script/bs-mirrorlist.replout.pl")->spew_utf8($$_REPL{history})
path("$ENV{HOME}/dotfiles++/App-bs/script/bs-mirrorlist.replout.pl")->slurp_utf8
path("$ENV{HOME}/dotfiles++/App-bs/script/bs-mirrorlist.replout.pl")->spew_utf8(join "\n", $$_REPL{history}->@*)