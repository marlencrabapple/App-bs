use Object::Pad ':experimental(:all)';

package BS::Run;

class BD::Run;

our $VERSION = "0.01";

use utf8;
use v5.40;

use base 'Class::Exporter';
use vars '@EXPORT';

use IPC::Run3;
use IO::Handle;

@EXPORT = qw(run $cmd);

field $cmd = __PACKAGE__;
field $in  : param = \undef;
field $out : param = [];
field $err : param = [];

field $debug = $ENV{DEBUG} // 0;
field %fhcache : reader(handle) = ();


ADJUST {
    my class TieArrayStd {
        use v5.40;
        use Tie::Array;

        use vars '@ISA';
        @ISA = qw(Tie::StdArray);

        field $handle : param //= *STDOUT;
        field $mode   : param //= 'w';
        field $aref   : param = [];

        ADJUST {
            tie @$aref, 'Tie::StdArray';
            $handle = IO::Handle->new_from_fd( fileno($handle), $mode );
        }

        method PUSH (@LIST) {
            $self->writeh( $_, $handle ) for @LIST;
            SUPER->PUSH( $self, @LIST );
        }

        method TIEARRAY { SUPER->TIEARRAY( $self, @_ ) }

        method STORE ( $index, $value ) {

            $self->writeh( $value, $handle );
            SUPER->STORE( $index, $value );
        }
    };

    TieArrayStd->new( aref => $out );
    TieArrayStd->new( aref => $err, handle => *STDERR );
}

method writeh( $line, $handle, %opt ) {
    if ( my $prev = $fhcache{$handle} ) {
        $handle = $prev unless $opt{newh};
    }
    else {
        $handle = $fhcache{$handle} = IO::Handle->new_from_fd( $handle, 'w' );
        binmode $handle, ":encoding(UTF-8)";
    }

    if ( $line isa 'ARRAY' ) {
        $handle->print("$_\n") for $line->@*;
    }
    elsif ( !ref $line ) {
        $handle->print("$line\n");
    }
}

method outh ($line) {
    $self->writeh( $line, *STDOUT );
}

method errh ($line) {
    $self->writeh( $line, *STDERR );
}

method info ($line) {
    $self->outh("▶ $line");
}

method dmsg (@data) {
    my @caller = caller 0;
    local $Data::Dumper::Names::UpLevel = 2;

    my $out;
    $out .= Dumper(@_);
    $out .=
      $debug && $debug == 2
      ? join "\n", map { ( my $line = $_ ) =~ s/^\t/  /; "  $line" } split /\R/,
      Devel::StackTrace::WithLexicals->new(
        indent      => 1,
        skip_frames => 1
      )->as_string
      : "at $caller[1]:$caller[2]\n";

    $self->errh($out);
    $out;
}

method err ($line) {
    $self->errh("❌️ $line");
}

method fatal ( $line, $status = $? // 255, %opt ) {
    $self->err($line);
    exit $status;
}

method success ($line) {
    $self->outh("⭕️ $line");
}

method $run ($cmd) {
    run3( $cmd, $in, $out, $err );
}

method run : common ($cmd, $_in = \undef, $_out = [], $_err = []) {
    my $self = $class->new( in => $_in, out => $_out, err => $_err );

    $self->$run($cmd);
}

__END__

=encoding utf-8

=head1 NAME

IPC::Cmd - It's new $module

=head1 SYNOPSIS

    use IPC::Cmd;

=head1 DESCRIPTION

IPC::Cmd is ...

=head1 LICENSE

Copyright (C) Ian P Bradley.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ian P Bradley E<lt>ian.bradley@studiocrabapple.comE<gt>

=cut

