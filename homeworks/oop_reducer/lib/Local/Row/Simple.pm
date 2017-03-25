package Local::Row::Simple;

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
    my ($class, @args) = @_;
    my $self = bless {}, $class;
    return $self->_init(@args);
}

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

sub get {
    my ($self, $name, $default) = @_;
    return $self->{$name} if exists $self->{$name};
    return $default;
}

1;
