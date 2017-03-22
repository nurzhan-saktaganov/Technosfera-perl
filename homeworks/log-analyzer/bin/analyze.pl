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

    my $result;

    my @line_components;
    $line_components[0] = '(?<ip>(\d+\.){3}\d+)';
    $line_components[1] = '\[(?<datetime>[^\]]+)\]';
    $line_components[2] = '"(?<request>[^"]+)"';
    $line_components[3] = '(?<code>\d+)';
    $line_components[4] = '(?<sent>\d+)';
    $line_components[5] = '"(?<refferer>[^"]+)"';
    $line_components[6] = '"(?<user_agent>[^"]+)"';
    $line_components[7] = '"(?<compress_rate>[\d\.-]+)"';

    my $line_regex = '^' . join('\s*', @line_components) . '$';

    my %statistics;
    my %codes;

    open my $fd, "-|", "bunzip2 < $file" or die "Can't open '$file': $!";
    while (my $log_line = <$fd>) {

        # you can put your code here
        # $log_line contains line from log file
        $log_line =~ $line_regex;

        my $ip = $+{'ip'};
        my $datetime = $+{'datetime'};
        my $code = $+{'code'};
        my $sent = $+{'sent'};
        my $compress_rate = $+{'compress_rate'};

        eval {
            for ($ip, $datetime, $code, $sent, $compress_rate) {
               die 'Not defined' if not defined $_;
            }
        };
        if ($@) {
            # warn $log_line;
            next;
        }

        $codes{$code} = 1;

        $statistics{$ip} ||= [];
        $code = int($code);
        $sent = int($sent);
        $compress_rate = 1.0 if $compress_rate eq '-';
        $compress_rate *= 1.0;

        $datetime =~ s/:\d\d \+0300//;

        push @{$statistics{$ip}}, {
            'datetime' => $datetime,
            'code' => $code,
            'sent' => $sent,
            'compress_rate' => $compress_rate,
        };
    }
    close $fd;

    # you can put your code here
    $result = {
        'statistics' => \%statistics,
        'codes' =>[keys %codes],
    };

    return $result;
}

sub get_really_sent {
    my $array_ref = shift;
    return sum0
             map {int($_->{'sent'} * $_->{'compress_rate'})}
               grep {$_->{'code'} == 200} @$array_ref;
}

sub get_sent_for_code {
    my ($array_ref, $code) = @_;
    return sum0
             map {$_->{'sent'}}
               grep {$_->{'code'} == $code} @$array_ref;
}



sub report {
    my $result = shift;

    # you can put your code here
    my $statistics = $result->{'statistics'};
    my @codes = sort @{$result->{'codes'}};

    my @report;
    my %total_minutes;
    for my $ip (keys %$statistics) {
        my $count = @{$statistics->{$ip}};
        my $data = get_really_sent($statistics->{$ip});
        my @minutes = uniq map {$_->{'datetime'}} @{$statistics->{$ip}};
        my $avg = $count / @minutes;

        my $ip_summary = {
            'IP' => $ip,
            'count' => $count,
            'avg' => sprintf("%.2f", $avg),
            'data' => $data,
        };

        for my $code (@codes) {
            $ip_summary->{$code} = get_sent_for_code($statistics->{$ip}, $code);
        }

        $total_minutes{$_} = 1 for @minutes;
        push @report, $ip_summary;
    }
    @report = sort {$b->{'count'} <=> $a->{'count'}} @report;
    my $total = {'IP' => 'total'};
    for my $field ('count', 'data', @codes){
        $total->{$field} = sum0 map {$_->{$field}} @report;
    }
    my $avg = $total->{'count'} / keys %total_minutes;
    $total->{'avg'} = sprintf("%.2f", $avg);
    @report = @report[0..9];

    unshift @report, $total;

    for my $row (@report) {
        $row->{$_} = int($row->{$_} / 1024) for ('data', @codes);
    }

    my @fields = ('IP', 'count', 'avg', 'data', @codes);

    print join("\t", @fields) . "\n";

    for my $row (@report) {
        my @to_print;
        push @to_print, $row->{$_} for @fields;
        print join("\t", @to_print) . "\n";
    }
}
