package App::BS::scratchpad;

use utf8;
use v5.44;

use List::Util qw(uniq);
use IO::Handle::Common;

sub prune_stable(@pkg) {
    my %seen     = ();
    my @seen_ord = ();

    foreach my $pkg (@pkg) {
        my ($novcs) = ($pkg = s/-git$//rg);


        if(exists $seen{$novcs}) {

        }
        else {
        $seen{$novcs}//=0;
        }
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
