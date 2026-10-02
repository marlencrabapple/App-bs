package App::BS::scratchpad;

use utf8;
use v5.44;

use List::Util qw(uniq);

sub prune_stable(@pkg) {
    my %seen = ();

    foreach my ($pkgname) ( map { chomp $_; $_ } (@pkg) ) {
        say $pkgname;
        my $novcs = ( $pkgname =~ s/-git$//rg );
        for my ( $k, $v ) ( %seen{ ( uniq $pkgname, $novcs ) } ) {
            $v //= 0;
            $v++;
        }
    }
    grep { $seen{$_} == 1 } keys %seen;
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
