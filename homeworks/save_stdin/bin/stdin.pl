#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

sub main {
    my $file;
    GetOptions("file:s", \$file);
    die '--file options required' unless defined $file;
    open(my $fh, '>', $file)
            or die "Cannot open file: $file";

    STDIN->autoflush(1);
    STDERR->autoflush(1);
    $fh->autoflush(1);

    my ($lines, $symbols, $avg_lentgh) = (0, 0, 0);

    my $double_sigint = 0;

    $SIG{'INT'} = sub {
        if ($double_sigint){
            $avg_lentgh = $symbols / $lines if $lines > 0;
            print "$symbols $lines $avg_lentgh\n";
            exit;
        }
        $double_sigint++;
        print STDERR "Double Ctrl+C for exit";
        return;
    };

    print "Get ready\n";
    while (<>){
        $double_sigint = 0;
        print $fh $_;
        ++$lines;
        chomp;
        $symbols += length $_;
    }
    $SIG{'INT'} = 'DEFAULT';
    $avg_lentgh = $symbols / $lines if $lines > 0;
    print "$symbols $lines $avg_lentgh\n";
}

main;
