#!/usr/bin/perl

use strict;
use warnings;
use Date::Parse;
use Date::Format;
use List::Util qw(reduce);


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
            map {defined $_ ? 1 : die 'Not defined'} ($ip, $datetime, $code, $sent, $compress_rate);
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

        $datetime =~ s/:\d+ /:00 /;

        push @{$statistics{$ip}}, {
            'timestamp' => $datetime, # str2time($datetime),
            'code' => $code,
            'sent' => $sent,
            'compress_rate' => $compress_rate,
        };
    }
    close $fd;

    # you can put your code here
    $result = {
        'statistics' => \%statistics,
        'codes' => \%codes,
    };

    return $result;
}

sub uniq {
    my %seen;
    return grep {!$seen{$_}++} @_;
}

sub get_really_sent {
    my $array_ref = shift;
    my @really_sent = grep {$_->{'code'} == 200} @$array_ref;
    @really_sent = map {int($_->{'sent'} * $_->{'compress_rate'})} @really_sent;
    my $data = @really_sent ? reduce {$a + $b} @really_sent : 0;
    $data = int($data / 1024);
    return $data;
}

sub get_sent_for_code {
    my ($array_ref, $code) = @_;
    my @sent = grep {$_->{'code'} == $code} @$array_ref;
    @sent = map {$_->{'sent'}} @sent;
    my $result = @sent ? reduce {$a + $b} @sent : 0;
    $result = int($result / 1024);
    return $result;
}

sub report {
    my $result = shift;

    # you can put your code here
    my $statistics = $result->{'statistics'};
    my @codes = sort keys %{$result->{'codes'}};

    my @report;
    my @total_minutes;
    for my $ip (keys %$statistics) {
        my $count = @{$statistics->{$ip}};
        my $data = get_really_sent($statistics->{$ip});
        my @minutes = uniq map {$_->{'timestamp'}} @{$statistics->{$ip}};
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

        push @total_minutes, @minutes;
        push @report, $ip_summary;
    }
    @total_minutes = uniq @total_minutes;
    @report = sort {$b->{'count'} <=> $a->{'count'}} @report;
    my $total = {'IP' => 'total'};
    for my $field ('count', 'data', @codes){
        $total->{$field} = reduce {$a + $b} map {$_->{$field}} @report;
    }
    my $avg = $total->{'count'} / @total_minutes;
    $total->{'avg'} = sprintf("%.2f", $avg);
    @report = @report[0..9];

    unshift @report, $total;

    my @fields = ('IP', 'count', 'avg', 'data', @codes);

    print join("\t", @fields) . "\n";
    # print "total\t22344\t544.98\t7375992\t1784676\t1108\t705\t85\t15469\t11269\t0\t1\t0\t514\n";

    for my $row (@report) {
        my @to_print;
        push @to_print, $row->{$_} for @fields;
        print join("\t", @to_print) . "\n";
    }
}
