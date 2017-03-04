package SecretSanta;

use 5.010;
use strict;
use warnings;
use DDP;

sub calculate {
    my @members = @_;

RECALCULATE:
    my @res = ();
    # ...
    #   push @res,[ "fromname", "toname" ];
    # ...
    my @married = ();
    my @single = ();
    my %cannot_give = ();

    for (@members){
        if (ref $_) { 
            push @married, @$_;
            $cannot_give{$_->[0]} = {
                $_->[0] => 1,
                $_->[1] => 1,
            };
            $cannot_give{$_->[1]} = {
                $_->[0] => 1,
                $_->[1] => 1,
            };
        } else {
            push @single, $_;
            $cannot_give{$_} = {$_ => 1};
        }
    }

    # shuffling
    my @presenters = sort {int(rand(3)) - 1} (@married, @single);
    my @recipients = sort {int(rand(3)) - 1} (@married, @single);

    for my $presenter (@presenters) {
        for my $recipient (@recipients){
            if ($cannot_give{$presenter}{$recipient}) {
                next;
            }
            push @res, [$presenter, $recipient];
            $cannot_give{$recipient}{$presenter} = 1;
            last;
        }
    }

    if ($#res < $#presenters) {
        goto RECALCULATE;
    }

    return @res;
}

1;
