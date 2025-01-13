use Object::Pad;

package BS::Common;
role BS::Common;

use utf8;
use v5.40;

use Carp;
use IPC::Run3;
use Tie::File;
use Struct::Dumb qw( -named_constructors );
use Data::Printer;

use parent 'Exporter';
our @EXPORT = qw(bsx);

struct BsxResult => [qw(cmd in out err run3exit cmdexit)];

method bsx :common ($cmd_aref, %args) {
  %args = (in => undef, out => '', err => '') unless scalar keys %args;

  if ($args{debug}) {
    say "${class}::bsx([ '$$cmd_aref[0]', ... ], ...) args:";
    p $cmd_aref, %args
  }

  my $ret = run3($cmd_aref, map {
    ref $_ ? $_ : defined $_ ? \$_ : undef 
  } @args{qw(in out err)});
  
  my $res = BsxResult( cmd => $cmd_aref,
                       %args{qw(in out err)},
                       run3exit => $ret,
                       cmdexit => [$?, $!] );

  if ($args{err} && ${$args{err}} || $ret != 1) {
      $args{on_err} && ref $args{on_err} eq 'CODE'
        ? $args{on_err}->($ret, $args{err}, $args{out})
        : croak " > $ret: ${$args{err}}", $res
  }

  $res
}

method open_as_href :common ($in, %args) {
  my ($as_aref, $as_path);
  my $as_href = delete $args{dest} // {};

  $as_aref = $class->tie_file($in, dest => $as_href, %args);

  use constant TRIM_RE => qr/\s*(.+)\s*/;

  foreach my $line (@$as_aref) {
    $line =~ s/${\TRIM_RE}/$1/;
    
    my ($key, $val) = $args{parse_line}->($line, $as_href);

    if ($$as_href{$key}) {
      $$as_href{$key} = [ $$as_href{$key} ]
        if ref $$as_href{$key} ne 'ARRAY';
      push $$as_href{$key}->@*, $val
    }
    else {
      $$as_href{$key} = $val
    }
  }

  $as_href
}

method tie_file :common ($in, %args) {
  my $as_aref = [];
  my $as_href = $args{dest} // {};

  # if (any { ref $in eq $_ } qw(Path::Tiny GLOB)) {
  #   p ($in);
  #   tie @$as_aref, 'Tie::File', "$in"
  # }
  if ($in isa Path::Tiny) {
    tie @$as_aref, 'Tie::File', "$in"
  }
  elsif (ref $in eq 'GLOB') {
    tie @$as_aref, 'Tie::File', $in
  }
  elsif (ref $in eq 'ARRAY') {
    #$as_aref = $in
    return $in
  }
  elsif (!ref $in) {
    if (-e "$in") {
      my $as_path = path($in);
      tie @$as_aref, 'Tie::File', "$in"
    }
    elsif ($args{out}) {
      @$as_aref =  split /\n/, $in;
      tie @$as_aref, 'Tie::File', $args{out} if $args{out};
      ...
    }
  }
  # else {
  #   if (ref $in eq 'HASH') {
  #     return $in
  #   }
  # }

  $as_aref
}