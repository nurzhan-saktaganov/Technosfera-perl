package VFS;
use utf8;
use strict;
use warnings;
use 5.010;
use File::Basename;
use File::Spec::Functions qw{catdir};
use JSON::XS;
no warnings 'experimental::smartmatch';

use feature "switch";
use Encode;

sub mode2s {
    # Тут был полезный код для распаковки численного представления прав доступа
    # но какой-то злодей всё удалил.
    my $mode_bin = shift;
    my $mode = {};
    for my $to ('other', 'group', 'user'){
        $mode->{$to} = {};
        for my $acces_type ('exectute', 'write', 'read'){
            $mode->{$to}{$acces_type} = $mode_bin & 1;
            $mode_bin >>= 1;
        }
    }
    return $mode;
}

sub parse_big_endian_int {
    my @byte_array = @_;
    my $int = 0;
    while (@byte_array) {
        my $byte = shift @byte_array;
        $int <<= 8;
        $int += ord($byte);
    }
    return $int;
}

sub parse {
    my $buf = shift;

    # Тут было готовое решение задачи, но выше упомянутый злодей добрался и
    # сюда. Чтобы тесты заработали, вам предстоит написать всё заново.
    die 'Empty imput!' unless $buf;

    my @data = map {chr($_)} unpack "C*", $buf;

    if (@data and $data[0] ne 'D' and $data[0] ne 'Z'){
        die "The blob should start from 'D' or 'Z'";
    }
    my @stack;

    my $mount_point = []; #$root_mount_point;
    push @stack, $mount_point;

    while (@data) {
        my $command = shift @data;
        #print "Command: $command\n";

        given ($command){
            when ('D') {
                my @name_length = splice(@data, 0, 2);
                my $name_length = parse_big_endian_int(@name_length);
                my @dir_name = splice(@data, 0, $name_length);
                my @access_rights = splice(@data, 0, 2);
                my $access_rights = parse_big_endian_int(@access_rights);
                die 'Wrong format!' if 'I' ne shift @data;

                my $path = {};
                $path->{'type'} = 'directory';
                $path->{'name'} = decode('utf8', join('', @dir_name));
                $path->{'mode'} = mode2s($access_rights);
                $path->{'list'} = [];

                push @$mount_point, $path;
                $mount_point = $path->{'list'};
                push @stack, $mount_point;
            }
            when ('F') {
                die 'Wrong format' if @stack == 1;
                my @name_length = splice(@data, 0, 2);
                my $name_length = parse_big_endian_int(@name_length);
                my @file_name = splice(@data, 0, $name_length);
                my @access_rights = splice(@data, 0, 2);
                my $access_rights = parse_big_endian_int(@access_rights);
                my @file_size = splice(@data, 0, 4);
                my $file_size = parse_big_endian_int(@file_size);
                my @sha1 = splice(@data, 0, 20);

                my $path = {};
                $path->{'type'} = 'file';
                $path->{'name'} = decode('utf8', join('', @file_name));
                $path->{'mode'} = mode2s($access_rights);
                $path->{'size'} = $file_size;
                $path->{'hash'} = join '', map {sprintf("%02x", ord($_))} @sha1;

                push @$mount_point, $path;
            }
            when ('U') {
                $mount_point = pop @stack;
                next if @stack > 1;
                die 'Wrong format!' if shift @data ne 'Z';
                last;
            }
            when ('Z') {
                last;
            }
            default {
                die 'Wrong format!';
            }
        }
    }
    $mount_point = pop @stack;

    die "Garbage ae the end of the buffer" if @data;
    # die "Stack" if @stack;
    # die "AHA" if @$mount_point > 1;
    return {} if @$mount_point == 0;
    return $mount_point->[0];
}

1;
