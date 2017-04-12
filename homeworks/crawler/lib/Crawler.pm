package Crawler;

use 5.010;
use strict;
use warnings;

use AnyEvent::HTTP;
use Web::Query;
use URI;

use List::Util q/min/;

=encoding UTF8

=head1 NAME

Crawler

=head1 SYNOPSIS

Web Crawler

=head1 run($start_page, $parallel_factor)

Сбор с сайта всех ссылок на уникальные страницы

Входные данные:

$start_page - Ссылка с которой надо начать обход сайта

$parallel_factor - Значение фактора паралельности

Выходные данные:

$total_size - суммарный размер собранных ссылок в байтах

@top10_list - top-10 страниц отсортированный по размеру.

=cut

sub run {
    my ($start_page, $parallel_factor) = @_;
    $start_page or die "You must setup url parameter";
    $parallel_factor or die "You must setup parallel factor > 0";

    my $total_size = 0;
    my @top10_list;

    #............
    #Код crawler-а
    #............
    # $AnyEvent::HTTP::MAX_PER_HOST = 4;
    if (URI::eq($start_page, $start_page . '/')){
        $start_page .= '/';
    }

    my $uri = URI->new($start_page);
    my $hostname = $uri->host;
    my $current_parallel = 1;

    my %seen;
    my %uri_to_size;

    my @queue;
    my $max_collect = 1000;
    my $total_collected = 0;
    push @queue, $start_page;
    $seen{$start_page} = 1;

    my $http_head_cb;
    my $http_get_cb;

    my $cv = AE::cv;

    my $launch = sub {
        $current_parallel--;
        my $to_collect = $max_collect - $total_collected;
        my $parallel_reserv = $parallel_factor - $current_parallel;
        my $queue_elements = @queue;
        my $to_launch = min($to_collect, $parallel_reserv, $queue_elements);

        $cv->end if $to_launch == 0 and $current_parallel == 0;
        # print "launch\n";
        $current_parallel += $to_launch;
        for (1..$to_launch){
            my $url = shift @queue;
            http_head($url, $http_head_cb);
        }
    };

    $http_head_cb = sub {
        my ($data, $headers) = @_;
        # print "http_head\n";
        if (not exists $headers->{'content-type'}
                or not $headers->{'content-type'} =~ q(text/html)
                or not exists $headers->{'URL'}
                or $total_collected == $max_collect){
            $launch->();
            return;
        }
        my $url = $headers->{'URL'};
        http_get($url, $http_get_cb);
    };

    $http_get_cb = sub {
        my ($data, $headers) = @_;
        # print "http_get\n";
        if (not exists $headers->{'URL'}
                or URI->new($headers->{'URL'})->host ne $hostname
                or not exists $headers->{'content-length'}
                or $total_collected == $max_collect){
            $launch->();
            return;
        }
        my $base = $headers->{'URL'};
        my $q = Web::Query->new($data);
        $q->find('a')->each(sub {
            my ($i, $elem) = @_;
            my $rel = $elem->attr('href');
            my $uri = URI->new($rel)->abs($base);
            return unless defined $uri->host;
            return unless $uri->host eq $hostname;
            $uri->fragment(undef);
            $uri->query(undef);
            if ($uri->eq($uri->as_string . '/')){
                $uri = $uri->as_string . '/';
            } else {
                $uri = $uri->as_string;
            }
            return unless $uri =~ /^\Q$start_page\E/;
            return if $seen{$uri};
            $seen{$uri} = 1;
            push @queue, $uri;
        });
        $total_collected++;
        # print "$total_collected\n";
        my $size = $headers->{'content-length'};
        $uri_to_size{$base} = $size;
        $total_size += $size;
        $launch->();
        return;
    };

    $cv->begin;
    $launch->();
    $cv->recv;

    for my $uri (sort {$uri_to_size{$b} <=> $uri_to_size{$a}} keys %uri_to_size) {
        push @top10_list, $uri;
    }
    @top10_list = @top10_list[0..9] if @top10_list > 10;

    return $total_size, @top10_list;
}

1;
