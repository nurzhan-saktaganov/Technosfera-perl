package Local::Source::Text;
use parent qw/Local::Source/;

use Local::Source::Array;

use strict;
use warnings;

=encoding utf8

=head1 NAME

Local::Source::Text

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

=cut

sub _init {
    my ($self, %args) = @_;
    unless (exists $args{'text'}) {
        die '"text" param required';
    }
    if (ref $args{'text'}) {
        die '"text" param must be an scalar';
    }
    $args{'delimiter'} = "\n" unless exists $args{'delimiter'};
    if (ref $args{'delimiter'}) {
        die '"delimiter" param must be an scalar';
    }

    my $array_ref = [split($args{'delimiter'}, $args{'text'})];

    $self->{'array_src'} = Local::Source::Array->new(array => $array_ref);
    return $self;
}

sub next {
    my $self = shift;
    return $self->{'array_src'}->next();
}

1;