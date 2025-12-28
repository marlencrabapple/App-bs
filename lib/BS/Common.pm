use Object::Pad qw(:experimental(:all));

package BS::Common;
role BS::Common;

use utf8;
use v5.40;

use Carp;
use IPC::Run3;
use Tie::File;
use Const::Fast;
use Time::Piece;
use Data::Dumper;
use List::AllUtils qw(any all first);
use Syntax::Keyword::Try;
use Const::Fast::Exporter;
use Syntax::Keyword::Dynamically;
use Time::HiRes qw(gettimeofday);
use FreezeThaw  qw(cmpStr cmpStrHard);
use Data::Dumper::Names;

BEGIN {
    use Exporter;
    use parent 'Exporter';
    use vars '@EXPORT';
    use subs qw(dmsg bsx callstack __pkgfn__ const);

    @EXPORT = qw(dmsg bsx callstack __pkgfn__ const);
}

const our $DEBUG   => ( any { $_ } @ENV{qw(BS_DEBUG DEBUG)} ) || 0;
const our $TRIM_RE => qr/\s*(.+)\s*\n*/i;

eval {
    use Devel::StackTrace::WithLexicals;
    use PadWalker qw(peek_my peek_our);
    use Module::Metadata;
} if $DEBUG;

my class BsxResult {
    use utf8;
    use v5.40;

    use subs qw(dmsg);

    field $debug = $BS::Common::DEBUG;

    field @out;
    field @err;

    field $cmd : param     : reader;
    field $inh : param(in) : reader = \undef;
    field $outh : param(out) : mutator(out) //= \@out;
    field $errh : param(err) : reader //= \@err;
    field $dest   : param : reader = \@out;
    field $status : param : reader = 0;

    ADJUST {
        BS::Common::dmsg { self => $self }
    }
};

field $debug : mutator : param : inheritable = $DEBUG;

APPLY($mop) {
    use utf8;
    use v5.40;

    use Object::Pad ':experimental(:all)';
    use Const::Fast::Exporter;
    use parent 'Exporter';

    use subs qw(dmsg bsx callstack __pkgfn__ const);
    our @EXPORT = qw(dmsg bsx callstack __pkgfn__ const);
}

ADJUST {
    use utf8;
    use v5.40;
    $ENV{DEBUG} = $debug = $BS::Common::DEBUG;

    use parent 'Exporter';

    use subs qw(dmsg bsx callstack __pkgfn__ const);
    our @EXPORT = qw(dmsg bsx callstack __pkgfn__ const);
};

method __pkgfn__ : common ($pkgname = undef) {
    $pkgname //= $class;
    "$pkgname.pm" =~ s/::/\//rg;
}

method callstack : common {
    my @callstack;
    my $i = 0;

    while ( my @caller = caller $i ) {
        {
            no strict 'refs';
            push @caller, \%{"$caller[0]\::"};
            push @caller, $caller[0]->META() if ${"$caller[0]\::"}{META}
        }

        push @callstack, \@caller;
    }
    continue { $i++ }

    @callstack;
}

method alldef : common (@items) {
    all { $_ } @items;
}

sub href_equal_kv : prototype($$) ( $href, $href2 ) {
    $$href{EXTRA}  = $href2;
    $$href2{EXTRA} = $href;

    cmpStr( $href, $href2 );
    cmpStrHard( $href, $href2 );
}

# field %fhcache : reader(handle) = ();

sub writeh( $line, $handle, %opt ) {
    state %fhcache = ();

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

sub outh ($line) {
    writeh( $line, *STDOUT );
}

sub errh ($line) {
    writeh( $line, *STDERR );
}

sub info ($line) {
    outh("▶ $line");
}

sub dmsg  {
    return undef unless $DEBUG;
    my @caller = caller 0;
    local $Data::Dumper::Names::UpLevel = 2;

    my $out;
    $out .= Dumper(@_);
    $out .=
      $DEBUG && $DEBUG == 2
      ?  join "\n", map { ( my $line = $_ ) =~ s/^\t/  /; "  $line" } split /\R/,
      Devel::StackTrace::WithLexicals->new(
        indent      => 1,
        skip_frames => 1
      )->as_string
: "at $caller[1]:$caller[2]\n";

    errh($out);
    $out;
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

method ts : common ($sep = '') {
    join $sep, gettimeofday;
}

method bsx : common ($cmd_aref, %args) {
    %args = ( in => undef, out => [], err => '' ) unless scalar keys %args;

    dmsg { cmd => $cmd_aref, args => \%args };

    run3( $cmd_aref,
        map { ref $_ ? $_ : defined $_ ? \$_ : undef } @args{qw(in out err)} );

    my $res = BsxResult->new(
        cmd    => $cmd_aref,
        status => $?,
        %args{qw(in out err dest)}
    );

    #my %ret = map { $_ => $res->$_ } $args{fields}->@*;
    #   scalar %ret ? \%ret : $res;
    $res;
}

method open_as_href : common ($in, %args) {
    my ( $as_aref, $as_path );

    # Is it 'out' or 'dest'?
    #my $as_href = delete $args{dest} // {};
    my $as_href = first { delete $args{$_} } qw(dest out);

    $as_aref = $class->tie_file( $in, dest => $as_href, %args );

    foreach my $line (@$as_aref) {
        $line =~ s/$TRIM_RE/$1/;

        my ( $key, $val ) =
          $args{parse_line}->( $line, dest => $as_href, %args );

        next unless $key && $val;

        if ( $$as_href{$key} ) {
            if (   $args{no_dupes}
                && $args{dest}->{$key}
                && $$as_href{$key} eq $args{dest}->{$key} )
            {
                next;
            }

            $$as_href{$key} = [ $$as_href{$key} ]
              if ref $$as_href{$key} ne 'ARRAY';
            push $$as_href{$key}->@*, $val;
        }
        else {
            $$as_href{$key} = $val;
        }
    }

    dmsg $as_href;
    $as_href;
}

method tie_file : common ($in, %args) {
    my $as_aref = [];
    my $as_href = $args{dest} // {};

    if ( $in isa Path::Tiny ) {
        tie @$as_aref, 'Tie::File', "$in";
    }
    elsif ( ref $in eq 'GLOB' ) {
        tie @$as_aref, 'Tie::File', $in;
    }
    elsif ( ref $in eq 'ARRAY' ) {

        #$as_aref = $in
        return $in;
    }
    elsif ( !ref $in ) {
        if ( -e "$in" ) {
            my $as_path = path($in);
            tie @$as_aref, 'Tie::File', "$in";
        }
        elsif ( $args{out} ) {
            @$as_aref = split /\n/, $in;
            tie @$as_aref, 'Tie::File', $args{out} if $args{out};
            ...;
        }
    }

    $as_aref;
}

sub issha1 ($str) {
    if ( $str =~ /^[[:alnum:]]{40}$/ ) {
        say "'$str' is a valid SHA1 checksum.";
        return 1;
    }
    undef;
}

