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

    our @EXPORT;
    our @EXPORT_OK;
    our %EXPORT_TAGS;

    unless ($module_name eq __PACKAGE__) {
        unshift @_, $module_name;
        # Exporter::import(@_);  WTF??
        # return;
        goto &Exporter::import;
    }
    die 'Even-sized list expected ' if @_ % 2;
    for my $i (0..$#_){
       die 'Wrong hash key' if $i % 2 == 0 and not $_[$i];
    }
    myconst->export_to_level(1, @EXPORT = qw/import/);

    @EXPORT = qw/@EXPORT @EXPORT_OK %EXPORT_TAGS/;

    my %hash = @_;
    while (my ($k1, $v1) = each %hash){
        if (not ref $v1){
            _register_const($k1, $v1, 'all');
            next;
        } elsif (ref $v1 ne 'HASH'){
            die 'HASH ref expected';
        }
        while (my ($k2, $v2) = each %$v1){
            _register_const ($k2, $v2, 'all', $k1);
        }    
    }
    myconst->export_to_level(1, @EXPORT);

    shift @EXPORT for (1..3);
    @EXPORT_OK = @EXPORT;
}

sub _register_const($$$@) {
    our @EXPORT;
    our %EXPORT_TAGS;
    my ($name, $value, @groups) = @_;
    # print "_reg_const: @_\n";
    die 'Refs are forbidden' if (ref $name or ref $value);
    die 'Const name is not valid' unless $name =~ m/^[[:alpha:]_][\w_]*$/;
    $value = quotemeta($value);
    eval ("sub $name () {return \"$value\";}");
    die $@ if $@;
    for my $group (@groups) {
        die 'Group name is not valid' unless $group =~ m/^[[:alpha:]_][\w_]*$/;
        $EXPORT_TAGS{$group} ||= [];
        push @{$EXPORT_TAGS{$group}}, "$name";
        push @EXPORT, "$name";
    }
    return;
}

1;
