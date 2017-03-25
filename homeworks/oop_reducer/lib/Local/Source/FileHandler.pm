package Local::Source::FileHandler;
use parent qw/Local::Source/;

use strict;
use warnings;

=encoding utf8

=head1 NAME

Local::Source::FileHandler

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

=cut

sub _init {
    my ($self, %args) = @_;
    unless (exists $args{'fh'}){
        die '"fh" param required';
    }
    $self->{'fh'} = $args{'fh'};
    return $self;
}

sub next {
    my $self = shift;
    return readline($self->{'fh'});
}

1;