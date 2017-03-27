package Local::Row;

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

sub new {
    my ($class, %args) = @_;
    unless (exists $args{'str'}) {
        die '"str" param required';
    }
    if (ref $args{'str'}) {
        return undef;
    }
    my $self = bless {}, $class;
    return $self->_init(%args);
}

sub _init {
    my $self = shift;
    return $self;
}

sub get {
    my ($self, $name, $default) = @_;
    return $self->{$name} if exists $self->{$name};
    return $default;
}

1;
