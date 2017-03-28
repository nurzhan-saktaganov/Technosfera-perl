#!/usr/bin/perl

use strict;
use warnings;
our $VERSION = 1.0;

my $filepath = $ARGV[0];
die "USAGE:\n$0 <log-file>\n"  unless $filepath;
die "File '$filepath' not found\n" unless -f $filepath;

my $parsed_data = parse_file($filepath);
report($parsed_data);
exit;

sub parse_file {
    my $file = shift;

    # you can put your code here

       my $fd;
    if ($file =~ /\.bz2$/) {
        open $fd, "-|", "bunzip2 < $file" or die "Can't open '$file' via bunzip2: $!";
    } else {
        open $fd, "<", $file or die "Can't open '$file': $!";
    }

    my $result = {
        'total' => {
            'IP' => 'total',
            'minutes' => {},
        },
    };

    while (my $log_line = <$fd>) {

        # you can put your code here
        # $log_line contains line from log file
        $log_line =~ qr/
            ^
            (?<ip>(\d+\.){3}\d+)\s
            \[(?<datetime>[^:]+(:\d\d){2})[^\]]+\]\s
            "(?<request>[^"]+)"\s
            (?<code>\d+)\s
            (?<sent>\d+)\s
            "(?<refferer>[^"]+)"\s
            "(?<user_agent>[^"]+)"\s
            "(?<compress_rate>[\d\.-]+)"
            $
        /x or next;

        my $ip = $+{'ip'};
        my $datetime = $+{'datetime'};
        my $code = $+{'code'};
        my $sent = $+{'sent'};
        my $compress_rate = $+{'compress_rate'};

        $compress_rate = 1.0 if $compress_rate eq '-';
        
        for my $ip ($ip, 'total') {
            $result->{$ip} ||= {};
            $result->{$ip}{'IP'} //= $ip;
            $result->{$ip}{'minutes'}{$datetime} = 1;
            $result->{$ip}{$code} += $sent;
            $result->{$ip}{'data'} += int($sent * $compress_rate) if $code eq '200';
            ++$result->{$ip}{'count'};
        }
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
