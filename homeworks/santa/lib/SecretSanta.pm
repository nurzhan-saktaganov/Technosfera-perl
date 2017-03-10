package SecretSanta;

use 5.010;
use strict;
use warnings;
use DDP;

sub shuffle {
	return sort {int(rand(3)) - 1} @_;
}

sub calculate {
    my @members = @_;
    my @res;
    # ...
    #   push @res,[ "fromname", "toname" ];
    # ...

    my @pairs;
    my @single;

    @pairs = grep {ref $_} @members;
    @single = grep {not ref $_} @members;

    if (@pairs == 1 and @single < 2 or @pairs == 0 and @single < 3) {
        die "There is no solution!";
    }

    if (@pairs == 1 ) {
        push @pairs, [shift @single, shift @single];
    }

    # shuffle singles
    @single = shuffle @single;
    # shuffle pairs
    @pairs = shuffle @pairs;
    # shuffle every pair
    @pairs = map {[shuffle @$_]} @pairs;

    my @husbands = map {$_->[0]} @pairs;
    my @wives = map {$_->[1]} @pairs;

    # another more shuffling
    @husbands[1..$#husbands - 1] = shuffle @husbands[1..$#husbands - 1];
    
    my @gift_chain = (@husbands, @wives);
    while (@single > 0) {
        my $insert_at = int(rand(@gift_chain));
        splice @gift_chain, $insert_at, 0, pop @single;
    }

    for my $i (0..$#gift_chain - 1) {
        push @res, [$gift_chain[$i], $gift_chain[$i + 1]];
    }
    push @res, [$gift_chain[-1], $gift_chain[0]];

    return @res;
}

1;
