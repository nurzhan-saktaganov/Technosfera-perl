#!/usr/bin/perl

use strict;
use warnings;

use AnyEvent::Socket;
use AnyEvent::Handle;
use AnyEvent::HTTP;

use Data::Validate::URI qw(is_web_uri);

tcp_server '0.0.0.0', 8080, sub {
    my $fh = shift;

    my $remote_url = 'https://mail.ru';

    my $h = AnyEvent::Handle->new(fh=>$fh);

    my $url = sub {
        my $u = shift;
        if (is_web_uri($u)){
            $remote_url = $u;
            $h->push_write("OK\n");
        } else {
            $remote_url = undef;
            $h->push_write("Not url: $u\n");
        }
    };

    my $head = sub {
        unless (defined $remote_url){
            $h->push_write("URL not set\n");
            return;
        }
        http_head($remote_url, sub {
            my ($data, $headers) = @_;
            my $response = '';
            for my $key (keys %{$headers}) {
                $response .= sprintf("%s: %s\n", $key, $headers->{$key});
            }
            my $len = length $response;
            $h->push_write("OK $len\n");
            $h->push_write($response);
        });
    };

    my $get = sub {
        unless (defined $remote_url){
            $h->push_write("URL not set\n");
            return;
        }
        http_get($remote_url, sub {
            my ($data, $headers) = @_;
            my $len = length $data;
            $h->push_write("OK $len\n");
            $h->push_write($data);
        });
    };

    my $fin = sub {
        $h->push_write("OK\n");
        $h->destroy;
    };

    $h->on_error(sub {
        $h->destroy;
    });

    my $reader; $reader = sub {
        my ($hdl, $line) = @_;

        $url->($+{'url'}) if $line =~ q/^URL (?<url>.*)/;
        $head->() if $line =~ q/^HEAD$/;
        $get->() if $line =~ q/^GET$/;
        $fin->() if $line =~ q/^FIN$/;

        print "Got: $line\n";
        $h->push_read(line => $reader);
    };

    $h->push_read(line => $reader);
};

AE::cv->recv;
