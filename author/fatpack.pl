#!/usr/bin/env perl

use utf8;
use v5.40;

use lib 'lib';

use Cwd;
use File::chdir;
use Path::Tiny;
use Getopt::Long
qw(GetOptionsFromArray :config no_ignore_case bundling auto_abbrev);

use IPC::Nosh 'run';
use IPC::Nosh::IO;

our $modroot  = path('./')->absolute;
our $input    = path("$modroot/script");
our $outdir   = path( "$modroot/fatpackout." . time );
our $outfn    = "%s.fat";
our $locallib = path("$modroot/local");
our $verbose  = 1;
our $debug    = $verbose;

dmsg( $ENV{PERL5LIB} );

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
    run( [qw(carton install)], out => [] );

    #run( [qw(carton vendor)] );
    #run( [qw(carmel)] );

    $ENV{PERL5LIB} = "$locallib:$modroot/lib";

    $outdir->mkdir unless -d $outdir;

    foreach my $in (
          $input->is_dir     ? $input->children
        : $input isa 'ARRAY' ? @$input
        :                      $input
      )
    {
        #fatpack($in->children) if $in->is_dir;
        my @fatlines;
        my $fatstr = "";
        my @cmd    = ( qw(fatpack pack), $in );

        binmode STDERR, ":encoding(UTF-8)";
        info( "Running " . join " ", @cmd );

        run( \@cmd, out => \@fatlines, autoflush => 1, autochomp => 1 );
        
        $fatstr = join "\n", @fatlines;

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
