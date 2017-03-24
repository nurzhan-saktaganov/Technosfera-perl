package myconst;
use parent qw(Exporter);

use strict;
use warnings;
use Scalar::Util 'looks_like_number';

=encoding utf8

=head1 NAME

myconst - pragma to create exportable and groupped constants

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS
package aaa;

use myconst math => {
        PI => 3.14,
        E => 2.7,
    },
    ZERO => 0,
    EMPTY_STRING => '';

package bbb;

use aaa qw/:math PI ZERO/;

print ZERO;             # 0
print PI;               # 3.14
=cut

sub import {
    my $module_name = shift;
    #print "================\n";
    #print "Use $module_name\n";

    our @EXPORT;
    our @EXPORT_OK;
    our %EXPORT_TAGS;

    unless ($module_name eq __PACKAGE__) {
        unshift @_, $module_name;
        # Exporter::import(@_);  WTF??
        # return;
        goto &Exporter::import;
    }

    myconst->export_to_level(1, @EXPORT = qw/import/);

    @EXPORT = qw/@EXPORT @EXPORT_OK %EXPORT_TAGS/;
    my %hash = @_;
    while (my ($k1, $v1) = each %hash){
        if (not ref $v1){
            $v1 = qq($v1);
            eval ("sub $k1 () {return '$v1';}");
            $EXPORT_TAGS{'all'} ||= [];
            push @{$EXPORT_TAGS{'all'}}, "$k1";
            push @EXPORT, "$k1";
            next;
        }
        while (my ($k2, $v2) = each %$v1){
            $v2 = qq($v2);
            eval ("sub $k2 () {return '$v2';}");
            $EXPORT_TAGS{'all'} ||= [];
            push @{$EXPORT_TAGS{'all'}}, "$k2";
            $EXPORT_TAGS{"$k1"} ||= [];
            push @{$EXPORT_TAGS{"$k1"}}, "$k2";
            push @EXPORT, "$k2";
        }
    }
    myconst->export_to_level(1, @EXPORT);

    shift @EXPORT for (1..3);
    @EXPORT_OK = @EXPORT;
}

1;
