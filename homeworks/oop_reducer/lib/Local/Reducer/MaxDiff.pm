package Local::Reducer::MaxDiff;
use parent qw/Local::Reducer/;

use Scalar::Util qw(looks_like_number);

use strict;
use warnings;

=encoding utf8

=head1 NAME

Local::Reducer::MaxDiff

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

=cut

sub _init {
    my ($self, %args) = @_;
    
    $self->SUPER::_init(%args);

    unless (exists $args{'top'}) {
        die '"top" param required';
    }

    if (ref $args{'top'}) {
        die '"top" param must be an scalar';
    }

    unless (exists $args{'bottom'}) {
        die '"bottom" param required';
    }

    if (ref $args{'bottom'}) {
        die '"bottom" param must be an scalar';
    }

    $self->{'top_name'} = $args{'top'};
    $self->{'bottom_name'} = $args{'bottom'};
    return $self;
}

sub _reduce_once {
    my $self = shift;
    my $src = $self->{'source'}->next();
    return 0 unless defined $src;
    my $row = $self->{'row_class'}->new(src => $src);
    return 1 unless defined $row;
    my $top = $row->get($self->{'top_name'}, undef);
    my $bottom = $row->get($self->{'bottom_name'}, undef);

    return 1 unless $top and $bottom;
    return 1 unless looks_like_number($top) and looks_like_number($bottom);

    my $diff = $top - $bottom;
    $self->{'reduced'} = $diff if $diff > $self->{'reduced'};
    return 1;
}

1;
