#!/usr/bin/perl

use AnyEvent::Socket;
use AnyEvent::Handle;
use Data::Validate::URI qw(is_web_uri);
use URI::URL;

sub transmit {
    my ($remote_url, $method, $write) = @_;

    my $url = URI::URL->new($remote_url);

    my $hostname = $url->host;

    tcp_connect $hostname, 'http', sub {
        my ($fh) = @_
                or die "$address connect failed: $!";

        my $headers;

        my $h = AnyEvent::Handle->new(fh=>$fh);

        my $when_headers_got = sub {
            if ($method eq 'HEAD'){
                my $len = length $headers;
                $write->("OK $len\n$headers");
                $h->destroy;
                return;
            }

            my $len = 'UNKNOWN';
            $len = $+{'len'} if $headers =~ q/\r\nContent-Length: (?<len>\d+)\r\n/; 
            $write->("OK $len\n");
            $h->on_read(sub {
                $write->($_[0]->rbuf);
                $_[0]->rbuf = '';
            });
        };

        $h->on_eof(sub {
            $h->destroy;
        });

        $h->on_error(sub {
            $h->destroy;
        });

        my $reader; $reader = sub {
            my ($hdl, $line) = @_;
            if (length $line) {
                $headers .= $line . "\r\n";
                $h->push_read(line=>$reader);
            } else {
                $when_headers_got->();
            }
        };
        $h->push_read(line => $reader);
                
        $h->push_write(
            "$method $remote_url HTTP/1.1\n" .
            "Host: $hostname\n" .
            "Accept: text/html\n" .
            "User-Agent: GoogleBot\n\n"
        );
   };
};

tcp_server '0.0.0.0', 8080, sub {
    my $fh = shift;

    my $remote_url;
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
        transmit($remote_url, 'HEAD', sub {
            $h->push_write(shift);
        });
    };

    my $get = sub {
        unless (defined $remote_url){
            $h->push_write("URL not set\n");
            return;
        }
        transmit($remote_url, 'GET', sub {
            $h->push_write(shift);
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
