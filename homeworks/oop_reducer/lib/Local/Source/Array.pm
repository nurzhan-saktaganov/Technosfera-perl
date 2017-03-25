package Local::Source::Array;
use parent qw/Local::Source/;

use strict;
use warnings;

=encoding utf8

=head1 NAME

Local::Source::Array

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

=cut

sub _init {
    my ($self, %args) = @_;
    unless (exists $args{'array'}) {
        die '"array" param required';
    }
    unless (ref $args{'array'} eq 'ARRAY') {
        die '"array" param must be an array ref';
    }
    $self->{'array'} = $args{'array'};
    $self->{'current'} = 0;
    $self->{'last'} = @{$args{'array'}};
    return $self;
}

sub next {
    my $self = shift;
    if ($self->{'current'} == $self->{'last'}){
        return undef;
    }
    my $current = $self->{'current'}++;
    return $self->{'array'}[$current];
}

1;