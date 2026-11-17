#!/usr/bin/env perl

use Object::Pad ':experimental(:all)';

package App::BS::Ext::Common;

role App::BS::Ext::Common
  : does(App::BS::Common) : does(App::BS::Ext::pacman::Config) :
  does(App::BS::Run);

use utf8;
use v5.44;

no warnings 'experimental::re_strict';
use re 'strict';

use Const::Fast;

const our $ver_req => qr/([=<>]{1}|(?:[<>]=)){,2}/x;

const our $pkgname_re => qr/
([a-z0-9_@+][a-z0-9_@+.-]+)
 (?:
   ([\s-]|[=<>]{1}|[<>]=)
   ([^\s:\/\\-]+?)
 )?/xi;

const our $soname_re => qr/(.+\.so)=([0-9-].+)/xx;

const our %FIELD_MAP => (
    base                 => '%e',
    arch                 => '%a',
    backup_files         => '%B',
    build_date           => '%b',
    conflicts_nover      => '%C',
    depends_on           => '%D',
    description          => '%d',
    depends_on_nover     => '%E',
    optional_deps        => '%O',
    optional_deps_nodesc => '%o',
    filename             => '%f',
    signature            => '%g',
    groups               => '%G',
    conflicts_with       => '%H',
    md5sum               => '%s',
    sha256sum            => '%h',
    download_size        => '%k',
    licences             => '%L',
    install_size         => '%m',
    name                 => '%n',
    required_by          => '%N',
    version              => '%v',
    url                  => '%u',
    replaces             => '%T',
    replace_nover        => '%R',
    provides_nover       => '%S',
    provides             => '%P',
    packager             => '%p',
    package_valid_method => '%V',
    'literal_%'          => '%%',
);
