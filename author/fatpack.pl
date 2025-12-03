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
our $input    = path("$modroot/script");
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

sub writeh ( $line, $handle, %opt ) {
    binmode $handle, ":encoding(UTF-8)";
    if ( $line isa 'ARRAY' ) {
        say $handle $line for $handle->@*;
    }
    elsif ( !ref $line ) {
        say $handle $line;
    }
}

sub outh ($line) {
    writeh( $line, *STDOUT );
}

sub errh ($line) {
    writeh( $line, *STDERR );
}

sub info ($line) {
    outh("▶ $line");
}

sub err ($line) {
    errh("❌️ $line");
}

sub fatal ( $line, $status = $? // 255, %opt ) {
    err($line);
    exit $status;
}

sub success ($line) {
    outh("⭕️ $line");
}

sub fatpack {
    $CWD = $modroot;
    run3( [qw(carmel install)] );
    run3( [qw(carmel package)] );
    run3( [qw(carmel rollout)] );

    $ENV{PERL5LIB} = "$locallib:$modroot/lib";

    $outdir->mkdir unless -d $outdir;

    foreach my $in (
          $input->is_dir     ? $input->children
        : $input isa 'ARRAY' ? @$input
        :                      $input
      )
    {
        #fatpack($in->children) if $in->is_dir;

        my $fatstr = "";
        my @cmd    = ( qw(fatpack pack), $in );

        binmode STDERR, ":encoding(UTF-8)";
        info( "Running " . join " ", @cmd );

        run3( \@cmd, \undef, \$fatstr );

        my $fatout = sprintf( ( $outfn || '%s.fat' ), $in->basename );

        if ( my $ext = $in->basename =~ /\.(pl)$/i ) {
            $fatout .= ".$ext";
        }
        else {
            $fatout .= ".pl";
        }

        path("$outdir/$fatout")->spew_utf8($fatstr);

        success("Written to $fatout");
    }
}

fatpack()
