package App::BS::scratchpad;

use utf8;
use v5.44;

sub prune_stable {
    my %seen = ();

    foreach my ($pkgname) ( map { chomp $_; $_ } (`pkgtree nautilus`) ) {
        say $pkgname;
        my $novcs = ( $pkgname =~ s/-git$//r );
        if ( $seen{$novcs} ) {
            delete $seen{$novcs};
        }
        $seen{$pkgname} = 1;
    }
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
