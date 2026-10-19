requires 'perl', 'v5.44';

use utf8;
use v5.40;

requires 'Const::Fast';
requires 'Const::Fast::Exporter';

use Const::Fast;

sub distname ($pkgname) {
    const my $pkg2dist => qr/::/;
    ( $pkgname =~ s/$pkg2dist/-/rg );
}

const our %pinned => (
    CRABAPP => {
        'Path::Try'          => '0.01_2',
        'IO::Handle::Common' => '0.01_3',

        'IPC::Nosh'          => '0.01.4',

    }
);

requires 'Object::Pad';
requires 'Syntax::Keyword::Try';
requires 'Syntax::Keyword::Defer';
requires 'Syntax::Keyword::Dynamically';
requires 'Getopt::Long';
requires 'Pod::Usage';
requires 'File::chdir';
requires 'IO::Socket::SSL';
requires 'Net::SSLeay';
requires 'List::Util';
requires 'List::AllUtils';
requires 'HTTP::Tinyish';
requires 'JSON::MaybeXS';
requires 'TOML::Tiny';
requires 'Future::AsyncAwait';
requires 'IO::Async';
requires 'IO::Async::SSL';
requires 'Devel::CheckBin';
requires 'meta';
requires 'FreezeThaw';

requires 'Object::Pad::FieldAttr::Trigger';

on 'test' => sub {
    requires 'Test::More',       '0.98';
    requires 'Test::CPAN::Meta', '0.25';
    requires 'Test::Spellunker';
    requires 'Test::MinimumVersion::Fast';
    requires 'Test::Pod';
};

use constant DEV_PREREQS => sub {
    requires 'CPAN::Uploader';
    requires 'Version::Next';
    recommends 'Minilla';
    recommends 'Minilla::Profile::ModuleBuildTiny';
    recommends 'Perl::Critic';
    recommends 'Perl::Tidy';
    recommends 'Perl::Critic::Community';
    requires 'Inline';
    requires 'Inline::C';
    requires 'Inline::MakeMaker';
    requires 'ExtUtils::MakeMaker';
    requires 'Devel::StackTrace::WithLexicals', '2.01';
    requires 'Module::Build::XSUtil';
};

on 'build'   => DEV_PREREQS;
on 'develop' => DEV_PREREQS;

# feature 'pacrelay' => sub {
#     requires 'WWW::pacman::Proxy';
# }
