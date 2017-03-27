package Local::MatrixMultiplier;

use List::Util qw/min/;

use strict;
use warnings;

sub mult ($$$) {
    my ($mat_a, $mat_b, $max_child) = @_;
    my $res = [];

    unless (is_square_matrix($mat_a)
            and is_square_matrix($mat_b)){
        die 'not square matrices';
    }

    if (@$mat_a != @$mat_b) {
        die 'non-corresponding matrices';
    }

    $max_child = int($max_child);

    if ($max_child < 1){
        die 'process count must be a positive number';
    }

    my $size = @$mat_a;

    my $process_count = min($size, $max_child);

    my @children;
    my @pipes;
    my $pid;
    my $w;
    for (0..$process_count - 1){
        my $r; # bug if $r is not local
        pipe($r, $w);
        if ($pid = fork()){
            close($w);
            push @pipes, $r;
            push @children, $pid;
        } else {
            close($w), close($r) unless defined $pid;
            close($r) if defined $pid;
            last;
        }
    }

    my $my_id = @children;

    if ($pid == 0){
        my $begin = int($size * $my_id / $process_count);
        my $end = int($size * ($my_id + 1) / $process_count);
        my @rows;
        for my $i ($begin..$end - 1){
            my $row = [];
            for my $j (0..$size - 1){
                my $element;
                for my $k (0..$size - 1) {
                    $element += $mat_a->[$i][$k] * $mat_b->[$k][$j];
                }
                push @$row, $element;
            }
            push @rows, $row;
        }
        for my $row (@rows){
            print $w join(' ', @$row) . "\n";
        }

        select((select($w), $| = 1)[0]);
        close($w);
        exit;
    }

    waitpid($_, 0) for @children;

    if (@children == $process_count){
        for my $r (@pipes){
            while (<$r>) {
                chomp;
                my $row = [split(' ', $_)];
                push @$res, $row;
            }
        }
    }

    close($_) for @pipes;

    return $res;
}

sub is_square_matrix ($) {
    my $mat = shift;

    if (ref $mat ne 'ARRAY') {
        die 'param must be an array of arrays';
    }

    my $size = @$mat;

    for my $row (@$mat) {
        if (ref $row ne 'ARRAY'){
            die 'param must be an array of arrays';
        }
        return 0 if $size != @$row;
    }
    return 1;
}


1;
