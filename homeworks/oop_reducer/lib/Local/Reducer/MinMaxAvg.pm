package Local::Reducer::MinMaxAvg;
use parent qw/Local::Reducer/;

use Scalar::Util qw(looks_like_number);

use strict;
use warnings;

=encoding utf8

=head1 NAME

Local::Reducer::MinMaxAvg

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

=cut

sub _init {
    my ($self, %args) = @_;
    
    $self->SUPER::_init(%args);

    unless (exists $args{'field'}) {
        die '"field" param required';
    }

    if (ref $args{'field'}) {
        die '"field" param must be an scalar';
    }

    $self->{'field_name'} = $args{'field'};
    $self->{'max'} = undef;
    $self->{'min'} = undef;
    $self->{'sum'} = 0;
    $self->{'count'} = 0;
    return $self;
}

sub _reduce_once {
    my $self = shift;
    my $str = $self->{'source'}->next();
    return 0 unless defined $str;
    my $row = $self->{'row_class'}->new(str => $str);
    return 1 unless defined $row;

    my $field_value = $row->get($self->{'field_name'}, undef);
    return 1 unless defined $field_value;
    return 1 unless looks_like_number($field_value);

    $self->{'max'} //= $field_value;
    $self->{'min'} //= $field_value;

    $self->{'max'} = $field_value if $field_value > $self->{'max'};
    $self->{'min'} = $field_value if $field_value < $self->{'min'};
    $self->{'sum'} += $field_value;
    ++$self->{'count'};
    return 1;
}

sub reduced {
    my $self = shift;
    my $avg = $self->{'sum'};
    
    $avg /= $self->{'count'} if ($self->{'count'} != 0);

    return MinMaxAvgResult->new(
        min => $self->{'min'},
        max => $self->{'max'},
        avg => $avg
    );
}

package MinMaxAvgResult;

sub new {
    my ($class, %args) = @_;

    my $self = bless {}, $class;

    for my $name ('min', 'max', 'avg') {
        unless (exists $args{$name}) {
            die "\"$name\" param required";
        }
        if (ref $args{$name}) {
            die "\"$name\" param must be an scalar";
        }
        $self->{$name} = $args{$name};
    }
    return $self;
}

sub get_max {
    my $self = shift;
    return $self->{'max'};
}

sub get_min {
    my $self = shift;
    return $self->{'min'};
}

sub get_avg {
    my $self = shift;
    return $self->{'avg'};
}

1;
