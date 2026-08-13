requires 'perl', 'v5.40';

requires 'Data::Dumper::Names';
requires 'DBI';
requires 'Const::Fast::Exporter';
requires 'DBD::SQLite';
requires 'DBIx::Connector';
requires 'Inline';
requires 'Inline::C';
requires 'Inline::Module';
requires 'Object::Pad';
requires 'Syntax::Keyword::Try';
requires 'Syntax::Keyword::Defer';
requires 'Syntax::Keyword::Dynamically';
requires 'Getopt::Long';
requires 'Pod::Usage';
requires 'Path::Tiny';
requires 'Class::Exporter';
requires 'File::chdir';
requires 'IPC::Run3';
requires 'IO::Socket::SSL';
requires 'Net::SSLeay';
requires 'List::Util';
requires 'List::AllUtils';
requires 'Path::Tiny';
requires 'HTTP::Tinyish';
requires 'JSON::MaybeXS';
requires 'TOML::Tiny';
requires 'Struct::Dumb';
requires 'Future::AsyncAwait';
requires 'IO::Async';
requires 'IO::Async::SSL';
requires 'Devel::CheckBin';
requires 'meta';
requires 'FreezeThaw';
requires 'Stream::Buffered';
requires 'Object::Pad::FieldAttr::Trigger';
requires 'YAML::Tiny';

requires 'IO::Handle::Common';
requires 'IPC::Nosh';

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
    requires 'Minilla';
    requires 'Minilla::Profile::ModuleBuildTiny';
    requires 'Perl::Critic';
    requires 'Perl::Tidy';
    requires 'Perl::Critic::Community';
    requires 'Inline';
    requires 'Inline::C';
    requires 'Inline::MakeMaker';
    requires 'ExtUtils::MakeMaker';
    requires 'Devel::StackTrace::WithLexicals', '2.01';
    requires 'Module::Build::XSUtil';
    requires 'App::FatPacker';
    requires 'Carmel';
};

on 'build' => DEV_PREREQS;
on 'develop' => DEV_PREREQS
