use Object::Pad ':experimental(:all)';

package BS::Run;

class BS::Run : does(BS::Common);

use utf8;
use v5.40;

use vars '@EXPORT';

@EXPORT = qw(exec);

use parent 'Exporter';

use IPC::Run3;
use List::Util 'any';

field $cmd_aref : param;
field $outbuff  : param = [];
field $errbuff  : param = [];
field $status;
field $err;

sub writeh ( $line, $handle = *STDIN, %opts ) {
    chomp $line;

    $line = "《Info》" if any { $opts{$_} == 1 } qw(info notice help);
    $line = "▶ $line"
      if any { $opts{$_} == 1 } qw(plain say print arrow right_arrow);
    $line = "❌️ $line " if any { $opts{$_} == 1 } qw(error fatal die);
    $line = "‼️ $line"  if any { $opts{$_} == 1 } qw(warn warning danger);

    say $handle->$ $line unless $opts{quiet};

    $line;
}

method fatal ( $err, $status = 255, %opts ) {
    writeh( $err, *STDERR, %opts );
}

method $outh ( $line, %opts ) {

    writeh( $line, %opts );
    push @$outbuff, $line;
}

method $errh ( $line, %opts ) {
    writeh( "$line", %opts );
    push @$errbuff, $line;
}

sub run (
    $cmd_aref,
    $inh  = \undef,
    $outh = sub ( $self, $line ) { $self->$outh($line) },
    $errh = sub ( $self, $line ) { $self->$errh($line) }, %opts
  )
{
    my $exec = __PACKAGE__->new;
    my $run3 = $exec->run3( $cmd_aref, $inh, $outh, $errh );
    fatal( "Unknown error occured while trying to run external command:\n"
          . join " @$cmd_aref" );
}
