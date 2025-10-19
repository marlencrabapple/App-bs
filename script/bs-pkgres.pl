#!/usr/bin/env perl

use Object::Pad ':experimental(:all)';

use lib 'lib';

package bspkgres;

class bspkgres : does(BS::Package) : does(BS::Common);

use utf8;
use v5.40;

use IPC::Run3  qw( run3 );
use List::Util ();

use subs qw'pkgbase pkgname pkgtree depends search rebuild_order';

ADJUSTPARAMS($params) {
    BS::Common::dmsg( { self => $self, params => $params } )
}

# perl -Mv5.40 -MList::Util -e 'say join " ", List::Util::uniq map { split /[\s\r\n]/ } map { `expac -S "%e" $_` } map { say STDERR $_; `arch-rebuild-order --no-reverse-depends  $_` } join " ", List::Util::uniq map {  say STDERR $_; chomp $_; $_ } map {   say STDERR $_;  `expac -S "%n" $_` } join " ", List::Util::uniq grep { $_ ne "" && $_ !~ /lib32|-git/ } map { chomp $_; $_ } map { split /[\s\n\r]/, $_ } map { `expac -Ss "%e %n %D" "$_"` } @ARGV'

method $run {

    #   say join " ", uniq map { split /[\s\r\n]/ }
    #     __PACKAGE__=>pkgbase
    #     __PACKAGE__->rebuild_order join " ", uniq map {
    #         chomp $_; $_
    #       }
    #     __PACKAGE__->pkgname join " "
    #       , uniq grep {
    #         $_ ne "" && $_ !~ /$$env{filter}/
    #       }
    #     map { chomp $_; $_ }
    #     map { split /[\s\n\r]/ }
    #     map { `expac -Ss "%e %n %D" "$_"` } @in
}

method run : common ($argv, $clidest, %opts) {
    $class->$run;
}

method rebuild_order : common ($pkgs, %opts) {
    my @args = ();
    push @args, '--no-reverse-depends' unless $opts{clidest}->{reverse_depends};
    push @args, ( '--repos', join ',', $opts{clidest}->{repositories} );
    my $run3err =
      run3( [ 'arch-rebuild-order', @args, @$pkgs ], \undef, \&out, \&err );
}

method pkgbase : common (@pkgs) {
    map { `expac -S "%e" $_` } @pkgs;
}

method pkgname : common (@pkgs) {

    #my $run3ret
    map { `expac -S "%n" $_` } @pkgs;
}

method pactree : common (@pkgs) {

}

# method search  : override ($pkgs, %opts) {
#     ...;
# }

method depends : common (@pkgs) {

}

package main;
our $clidest = {};
bspkgres->run( \@ARGV, $clidest )

#    my @asdf = qw(spirv-headers libglvnd mesa xf86-video-amdgpu nvidia-utils spirv-tools glslang glslang python systemd glibc zlib libpng libxshmfence libdrm expat clang gcc pugixml wayland libxcb libx11 libxfixes libxext libxxf86vm libxkbcommon vulkan-icd-loader spirv-headers spirv-tools zstd llvm spirv-llvm-translator libclc elfutils pciutils lm_sensors libdecor mesa-amber egl-gbm nvidia-utils libglvnd egl-x11 glu freeglut mesa-demos mesa egl-wayland xf86-video-amdgpu gtkmm-4.0 adriconf systemd pinentry glib2 brotli curl pam libcap coreutils xz glibc zlib lz4 lmdb libxshmfence libxdmcp libxau libunistring libidn2 libtasn1 libpciaccess libnghttp3 libnghttp2 libgpg-error libgcrypt libffi libdrm libassuan keyutils json-c bzip2 expat gcc spirv-tools ncurses readline sqlite pcre2 libcap-ng gdbm libedit icu libxml2 xcb-proto wayland p11-kit ca-certificates libxcb libx11 libxext libxxf86vm libpsl zstd gmp openssl tpm2-tss findutils attr acl util-linux e2fsprogs libssh2 libevent libsecret elfutils nss lm_sensors llvm krb5 libtirpc libnsl libsasl openldap mesa libglvnd sysprof)'
