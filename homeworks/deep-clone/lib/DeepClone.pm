package DeepClone;

use 5.010;
use strict;
use warnings;
no if $] >= 5.018, warnings => "experimental::smartmatch";

=encoding UTF8

=head1 SYNOPSIS

Клонирование сложных структур данных

=head1 clone($orig)

Функция принимает на вход ссылку на какую либо структуру данных и отдаюет, в качестве результата, ее точную независимую копию.
Это значит, что ни один элемент результирующей структуры, не может ссылаться на элементы исходной, но при этом она должна в точности повторять ее схему.

Входные данные:
* undef
* строка
* число
* ссылка на массив
* ссылка на хеш
Элементами ссылок на массив и хеш, могут быть любые из указанных выше конструкций.
Любые отличные от указанных типы данных -- недопустимы. В этом случае результатом клонирования должен быть undef.

Выходные данные:
* undef
* строка
* число
* ссылка на массив
* ссылка на хеш
Элементами ссылок на массив или хеш, не могут быть ссылки на массивы и хеши исходной структуры данных.

=cut

sub _clone_ {
    my $orig = shift;
    my $ref_map = shift;

    if (!defined $orig) {
        return undef;
    } elsif (ref \$orig eq 'SCALAR') {
        return $orig;
    } elsif ($ref_map->{$orig}) {
        return $ref_map->{$orig};
    }

    my $cloned;
    my $type = ref $orig;

    given ($type) {
        when ('ARRAY') {
            $cloned = [];
            $ref_map->{$orig} = $cloned;
            push @$cloned, _clone_($_, $ref_map) for @$orig;
        }
        when ('HASH') {
            $cloned = {};
            $ref_map->{$orig} = $cloned;
            $cloned->{$_} = _clone_($orig->{$_}, $ref_map) for keys %$orig;
        }
        default {
            die 'Not supported!';
        }
    }
    return $cloned;
}

sub clone {
    my $orig = shift;
    my $cloned;
    # ...
    # deep clone algorithm here
    # ...
    eval {
        my $ref_map = {};
        $cloned = _clone_($orig, $ref_map);
    } or do {
       $cloned = undef;
    };
    return $cloned;
}

1;
