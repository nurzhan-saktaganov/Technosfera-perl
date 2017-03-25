package Local::Row::JSON;
use parent qw/Local::Row/;

use strict;
use warnings;
use JSON qw/decode_json/;

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
    my $json;
    eval {
        $json = decode_json($args{'src'});
        die 'Not hash' if ref $json ne 'HASH';
        1;
    } or do {
        return undef;
    };
    bless $json, ref $self;
    return $json;
}

1;
