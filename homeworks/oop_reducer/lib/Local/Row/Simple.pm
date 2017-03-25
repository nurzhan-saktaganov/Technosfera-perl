package Local::Row::Simple;
use parent qw/Local::Row/;

use strict;
use warnings;

=encoding utf8

=head1 NAME

Local::Row - base abstract row

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

=cut

sub _init {
    my ($self, %args) = @_;
    unless (exists $args{'src'}) {
        die '"src" param required';
    }
    if (ref $args{'src'}) {
        return undef;
    }
    my @src = split(",", $args{'src'});
    for my $key_value (@src){
        return undef unless $key_value =~ m/[^:,]+:[^:,]+/;
        my ($key, $value) = split(":", $key_value);
        $self->{$key} = $value;
    }
    return $self;
}

1;
