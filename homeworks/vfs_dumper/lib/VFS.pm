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
    my $true = JSON::XS::true;
    my $false = JSON::XS::false;
    for my $to ('other', 'group', 'user'){
        $mode->{$to} = {};
        for my $acces_type ('execute', 'write', 'read'){
            $mode->{$to}{$acces_type} = ($mode_bin & 1) ? $true : $false;
            $mode_bin >>= 1;
        }
    }
    return $mode;
}

sub bytes_to_int_BE {
    my @byte_array = @_;
    my $int = 0;
    while (@byte_array) {
        $int <<= 8;
        $int += shift @byte_array;
    }
    return $int;
}

sub extract_name {
    my $array_ref = shift;
    my $name_length = extract_int($array_ref, 2);
    my @name = splice(@$array_ref, 0, $name_length);
    my $name_utf8 = join '', pack("C*", @name);
    my $name = decode('utf8', $name_utf8);
    return $name;
}

sub extract_access_rights {
    my $array_ref = shift;
    my $access_rights = extract_int($array_ref, 2);
    return mode2s($access_rights);
}

sub extract_int {
    my ($array_ref, $length) = @_;
    my @byte_array = splice(@$array_ref, 0, $length);
    return bytes_to_int_BE(@byte_array);
}

sub extract_sha1 {
    my $array_ref = shift;
    my @sha1 = splice(@$array_ref, 0, 20);
    @sha1 = map {sprintf("%02x", $_)} @sha1;
    return join '', @sha1;
}

sub parse {
    my $buf = shift;

    # Тут было готовое решение задачи, но выше упомянутый злодей добрался и
    # сюда. Чтобы тесты заработали, вам предстоит написать всё заново.
    die 'Empty imput!' unless $buf;

    unless ($buf =~ m/^[D|Z]/) {
        die "The blob should start from 'D' or 'Z'";
    }

    my @data = unpack "C*", $buf;

    my ($D, $I, $F, $U, $Z) = unpack "C*", "DIFUZ";

    my @stack;
    my $root = [];
    my $mount_point = $root;

    push @stack, $mount_point;

    while (@data) {
        my $command = shift @data;

        given ($command){
            when ($D) {
                my $dir = {};
                $dir->{'type'} = 'directory';
                $dir->{'name'} = extract_name(\@data);
                $dir->{'mode'} = extract_access_rights(\@data);
                $dir->{'list'} = [];

                die 'Wrong format!' if $I ne shift @data;

                push @$mount_point, $dir;
                $mount_point = $dir->{'list'};
                push @stack, $mount_point;
            }
            when ($F) {
                die 'File cannot be in root level' if @stack == 1;
                my $file = {};
                $file->{'type'} = 'file';
                $file->{'name'} = extract_name(\@data);
                $file->{'mode'} = extract_access_rights(\@data);
                $file->{'size'} = extract_int(\@data, 4);
                $file->{'hash'} = extract_sha1(\@data);

                push @$mount_point, $file;
            }
            when ($U) {
                $mount_point = pop @stack;
                next if @stack > 1;
                die 'Root level forbidden' if shift @data ne $Z;
                last;
            }
            when ($Z) {
                last;
            }
            default {
                die 'Unexpected command: '. chr($command)."\n";
            }
        }
    }

    die "Garbage ae the end of the buffer" if @data;
    return {} if @$root == 0;
    return $root->[0];
}

1;
