package Local::Reducer;

use strict;
use warnings;

use Scalar::Util qw/blessed/;
use Local::Source;
use Local::Row;

=encoding utf8

=head1 NAME

Local::Reducer - base abstract reducer

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
    unless (exists $args{'source'}) {
        die '"source" param required';
    }
    unless (exists $args{'row_class'}) {
        die '"row_class" param required';
    }

    unless (exists $args{'initial_value'}) {
        die '"initial_value" param required';
    }

    eval {
        blessed($args{'source'}) and $args{'source'}->isa('Local::Source');
    } or do {
        die '"source" param must be an Local::Source instance';
    };

    eval {
        $args{'row_class'}->isa('Local::Row');
    } or do {
        die '"row_class" param must be an Local::Row class';
    };

    $self->{'source'} = $args{'source'};
    $self->{'row_class'} = $args{'row_class'};
    $self->{'reduced'} = $args{'initial_value'};

    return $self;
}

sub reduce_n {
    return undef;
}

sub reduce_all {
    return undef;
}

sub reduced {
    my $self = shift;
    return $self->{'reduced'};
}

1;
