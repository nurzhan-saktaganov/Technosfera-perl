package Local::Reducer::Sum;
use parent qw/Local::Reducer/;

use Scalar::Util qw(looks_like_number);

use strict;
use warnings;

=encoding utf8

=head1 NAME

Local::Reducer::Sum

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

    $self->{'field'} = $args{'field'};
    return $self;
}

sub _reduce_once {
    my $self = shift;
    my $str = $self->{'source'}->next();
    return 0 unless defined $str;
    my $row = $self->{'row_class'}->new(str => $str);
    return 1 unless defined $row;
    my $value = $row->get($self->{'field'}, 0);
    return 1 unless looks_like_number($value);
    $self->{'reduced'} += $value;
    return 1;
}

1;
