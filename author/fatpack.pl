#!/usr/bin/env perl

use utf8;
use v5.40;

use Cwd;
use File::chdir;
use Path::Tiny;
use Getopt::Long
  qw(GetOptionsFromArray :config no_ignore_case bundling auto_abbrev);
use IPC::Run3;
use Data::Dumper;

our $modroot  = path('./')->absolute;
our $indir    = path("$modroot/script");
our $outdir   = path( "$modroot/fatpackout." . time );
our $outfn    = "%s.fat";
our $locallib = path("$modroot/local");
our $verbose  = 1;
our $debug    = $verbose;

say STDERR Dumper( { '$ENV{PERL5LIB}' => $ENV{PERL5LIB} } )
  if $ENV{DEBUG} || $verbose || $debug;

GetOptions(
    'input|file|script|=s',
    'outdir|fatpack-out=s',
    'outfilename|outfn|fnfmt|fmtfn|fmt-filename|fmt-outputfn=s',
    'modroot|module-root|module-dir=s',
    'locallib=s',
    'verbose+',
    'debug'
);

sub fatpack {
    $CWD = $modroot;
    run3( [qw(carmel install)] );
    run3( [qw(carmel package)] );
    run3( [qw(carmel rollout)] );

    $ENV{PERL5LIB} = "$locallib:$modroot/lib";

    $outdir->mkdir unless -d $outdir;

    foreach my $in ( $indir->children ) {
        my $fatstr = "";
        my @cmd    = ( qw(fatpack pack), $in );
        say STDERR "▶ Running " . join " ", @cmd;

        run3( \@cmd, \undef, \$fatstr );

        my $fatout = sprintf( $outfn // "%s.fat" ), $in->basename;

        if ( my $ext = $in->basename =~ /\.(pl)$/i ) {
            $fatout .= ".$ext";
        }
        else {
            $fatout .= ".pl";
        }

        path("$outdir/$fatout")->spew_utf8($fatstr);

        say STDERR "⭕️ Written to $fatout";
    }
}

fatpack()
