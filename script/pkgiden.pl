#!/usr/bin/env perl

use v5.40;

use List::Util   qw( uniq );
use Getopt::Long qw(:config no_ignore_case bundling auto_abbrev);
use Const::Fast::Exporter;
use Syntax::Keyword::Dynamically;

use BS::Common;

const our %fieldmap  => ( base => 'e', name => 'n' );
const our %fieldmaph => reverse(%fieldmap);
our $outfield  = 'e';
our $delimeter = ' ';
our @pkgin;

GetOptions(
    'outfield|field=s',
    'delimeter=s',
    '<>',
    sub ($barearg) {
        push @pkgin, $barearg;
    }
);

if ( $outfield =~ /^[en]{1}$/i ) {
    $outfield = { $outfield => $fieldmaph{$outfield} };
}
elsif ( $outfield =~ /^(?:pkg)?(name|base)$/ ) {
    $outfield = { $fieldmap{$outfield} => $outfield };
}
else {
    die "Invalid field '$outfield' given, Accetable values are: " . join ", ",
      (%fieldmap);
}

sub run () {
    say STDERR "▶ Printing packages as " . (%$outfield)[1] . "(s)...";

    my @rebuildorder =
      ( '--no-reverse-depends', '--repos', 'universe,core,extra,multilib' );
    my $rebuildorder = join " ", @rebuildorder;

    my @pkgout =
      map { chomp $_; $_ } uniq
      map {
        my $pkgfieldin = $_;

        BS::Common::dmsg(
            { outfield => $outfield, pkgfield_in => $pkgfieldin } );
        dynamically $outfield = (%$outfield)[0];

        $outfield eq 'n'
          ? ( split /[\s]+/, $pkgfieldin )
          : (`expac -S '$outfield' $pkgfieldin`)
      }
      map {
        $rebuildorder .= $_;
        BS::Common::dmsg( { rebuildorder => $rebuildorder } );
        `arch-rebuild-order $rebuildorder $_`
      } join " ", uniq map { chomp $_; $_ }
      map { `expac -S "%n" $_` } join " ", uniq map { chomp $_; qq{"$_"} }
      map { chomp $_; `pactree -lus "$_"` }
      map { `expac -Ss "%n" $_` } (@pkgin);

    BS::Common::dmsg( { pkgout => @pkgout } );

    say join "$delimeter", @pkgout;
    @pkgout;
}

run()
