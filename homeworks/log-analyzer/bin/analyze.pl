#!/usr/bin/perl

use strict;
use warnings;
use List::Util qw(sum0);
use List::MoreUtils qw(uniq);
our $VERSION = 1.0;

my $filepath = $ARGV[0];
die "USAGE:\n$0 <log-file.bz2>\n"  unless $filepath;
die "File '$filepath' not found\n" unless -f $filepath;

my $parsed_data = parse_file($filepath);
report($parsed_data);
exit;

sub parse_file {
    my $file = shift;

    # you can put your code here

    my $result = {
        "total" => {
            "IP" => "total",
            "minutes" => {},
        },
    };

    my $line_regex = qr/
        ^
        (?<ip>(\d+\.){3}\d+)\s
        \[(?<datetime>[^\]]+)\]\s
        "(?<request>[^"]+)"\s
        (?<code>\d+)\s
        (?<sent>\d+)\s
        "(?<refferer>[^"]+)"\s
        "(?<user_agent>[^"]+)"\s
        "(?<compress_rate>[\d\.-]+)"
        $
    /x;

    open my $fd, "-|", "bunzip2 < $file" or die "Can't open '$file': $!";
    while (my $log_line = <$fd>) {

        # you can put your code here
        # $log_line contains line from log file
        $log_line =~ $line_regex;

        eval {
            for ('ip', 'datetime', 'code', 'sent', 'compress_rate'){
                die 'Not defined' unless exists $+{$_};
            }
            1;
        } or do {
            warn 'Unexpected log format: ' . $log_line;
            next;
        };

        my $ip = $+{'ip'};
        my $datetime = $+{'datetime'};
        my $code = $+{'code'};
        my $sent = $+{'sent'};
        my $compress_rate = $+{'compress_rate'};

        $datetime =~ s/:\d\d \+0300//;
        $compress_rate = 1.0 if $compress_rate eq '-';
        $result->{$ip} ||= {};

        # ip stats
        $result->{$ip}{'IP'} //= $ip;
        $result->{$ip}{'minutes'}{$datetime} = 1;
        $result->{$ip}{$code} += $sent;
        $result->{$ip}{'data'} += int($sent * $compress_rate) if $code eq '200';
        ++$result->{$ip}{'count'};

        # total stats
        $result->{'total'}{'minutes'}{$datetime} = 1;
        $result->{'total'}{$code} += $sent;
        $result->{'total'}{'data'} += int($sent * $compress_rate) if $code eq '200';
        ++$result->{'total'}{'count'};
    }
    close $fd;

    # you can put your code here
    for my $row (values %$result) {
        $row->{'minutes'} = keys %{$row->{'minutes'}};
    }
    return $result;
}

sub report {
    my $result = shift;

    # you can put your code here
    my @table = sort {$b->{'count'} <=> $a->{'count'}} values %$result;
    my @codes = sort grep {$_ =~ m/\d+/} keys %{$result->{'total'}};
    my @headers = ('IP', 'count', 'avg', 'data', @codes);

    if (@table < 2) {
        return;
    }

    @table = @table[0..10];

    print join("\t", @headers) . "\n";

    for my $row (@table) {
        $row->{$_} //= 0 and $row->{$_} >>= 10 for ('data', @codes);
        my $avg = $row->{'count'} / $row->{'minutes'};
        $row->{'avg'} = sprintf("%.2f", $avg);
        print join("\t", map {$row->{$_}} @headers) . "\n";
    }
}
