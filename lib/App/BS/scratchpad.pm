package App::BS::scratchpad;

use utf8;
use v5.44;

use List::Util qw(uniq);
use IO::Handle::Common;

sub prune_stable(@pkg) {
    my %seen     = ();
    my @seen_ord = ();

    my $initkey = sub(@pkgname) {

        # push @seen_ord, grep { /-git$/ } @pkgname if scalar uniq @pkgname > 1;

        #if(

        push @seen_ord, (scalar uniq @pkgname > 1
          ? ( grep { /-git$/ } @pkgname )
          : $pkgname[0]);

        #) {

        # }

        #@seen{@pkgname} //= ( map { 0 } @pkgname );
        # ( @seen{@pkgname} ) //= ( 0 x scalar @pkgname );
        $seen{$_} //= 0 for @pkgname;
        @seen_ord;
    };

    foreach my ($pkgname) ( map { chomp $_; $_ } (@pkg) ) {
        my $novcs = ( $pkgname =~ s/-git$//rg );

        # dmsg $novcs, $pkgname;
        for my $pkg ( $initkey->( $pkgname, $novcs ) ) {

            # $v //= 0;
            # $v++;

            $seen{$pkg}++;
            dmsg $pkgname, $novcs, $pkg, $seen{$pkg}

            # dmsg;
        }
    }

    dmsg \@seen_ord, { %seen{@seen_ord} }, [ @seen{@seen_ord} ];
    grep { $seen{$_} == 1 } @seen_ord;
}

sub repo_gpg_verify {
    my %fail     = ();
    my $checksig = path("./")->children(
        sub ( $path, $state ) {
            my $run =
              run( [ qw'gpg --verify --verbose', $path ], autochomp => 1 );
            $fail{$path} = {
                exit => $run->status,
                err  => [ $run->err->lines_utf8 ],
                out  => [ $run->out->lines_utf8 ]
              }
              if $run->status > 0;
        }
    );
    \%fail;
}
