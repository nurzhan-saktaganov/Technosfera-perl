#!/usr/bin/env perl
use utf8;
use strict;
use warnings;
use 5.010;
use JSON::XS;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use VFS;

our $VERSION = 1.0;

binmode STDOUT, ":utf8";

unless (@ARGV == 1) {
	warn "$0 <file>\n";
}

my $buf;
{
	local $/ = undef;
	$buf = <>;
}

# Вот досада, JSON получается трудночитаемым, совсем не как в задании.
print JSON::XS->new()->pretty(1)->encode(VFS::parse($buf));
