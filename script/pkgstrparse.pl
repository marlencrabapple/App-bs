#!/usr/bin/env perl

use utf8;
use v5.42;

use IPC::Run3;
use Const::Fast;
use List::Util qw'uniq reduce';
use Syntax::Keyword::Dynamically;
use Module::CoreList;
use Getopt::Long qw':config bundling auto_abbrev';

use BS::Common;

#const our $module_re = qr/::/;
#const our $pkgname = qr/perl-[...]/;

const our $pkgstr_name_ptn => qr'[a-zA-Z0-9\@_\+]{1}[a-zA-Z0-9\@_\+\.\-]+';

const our $pkgstr_name_re => qr/^(lib\:)?
			      ( $pkgstr_name_ptn(\.so(?:\.[0-9\]+)?)
			        | $pkgstr_name_ptn )
			     /x;

foreach my $pkgstr (@ARGV) {
  if (matches)
}