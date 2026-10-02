use Object::Pad qw(:experimental(:all));

package BS::Common;
role BS::Common;

use utf8;
use v5.40;

use Tie::File;
use Const::Fast;
use Time::Piece;
use List::Util qw(any all first);
use Syntax::Keyword::Try;
use Syntax::Keyword::Dynamically;
use Time::HiRes qw(gettimeofday);
use FreezeThaw  qw(cmpStr cmpStrHard);
use builtin;
use IO::Handle::Common;

field $debug : mutator : param : inheritable = $ENV{DEBUG};

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

method ts : common ($sep = '') {
    join $sep, gettimeofday;
}

method open_as_href : common ($in, %args) {
    my ( $as_aref, $as_path );

    # Is it 'out' or 'dest'?
    #my $as_href = delete $args{dest} // {};
    my $as_href = first { delete $args{$_} } qw(dest out);

    $as_aref = $class->tie_file( $in, dest => $as_href, %args );

    foreach my $line (@$as_aref) {
        $line = builtin::trim($line);

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

