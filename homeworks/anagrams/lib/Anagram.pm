package Anagram;

use 5.010;
use strict;
use warnings;

use Encode;

=encoding UTF8

=head1 SYNOPSIS

Поиск анаграмм

=head1 anagram($arrayref)

Функцию поиска всех множеств анаграмм по словарю.

Входные данные для функции: ссылка на массив - каждый элемент которого - слово на русском языке в кодировке utf8

Выходные данные: Ссылка на хеш множеств анаграмм.

Ключ - первое встретившееся в словаре слово из множества
Значение - ссылка на массив, каждый элемент которого слово из множества, в том порядке в котором оно встретилось в словаре в первый раз.

Множества из одного элемента не должны попасть в результат.

Все слова должны быть приведены к нижнему регистру.
В результирующем множестве каждое слово должно встречаться только один раз.
Например

anagram(['пятак', 'ЛиСток', 'пятка', 'стул', 'ПяТаК', 'слиток', 'тяпка', 'столик', 'слиток'])

должен вернуть ссылку на хеш


{
    'пятак'  => ['пятак', 'пятка', 'тяпка'],
    'листок' => ['листок', 'слиток', 'столик'],
}

=cut

sub normalize_word {
    return join '', sort {$a cmp $b} split(//, shift);
}

sub anagram {
    my $words_list = shift;
    my %result;

    #
    # Поиск анограмм
    #
    my %anagrams;

    for (@$words_list) {
        # my $word = CORE::fc $_;
        my $word = CORE::fc decode('utf8', $_);
        my $normalized_word = normalize_word($word);
        $anagrams{$normalized_word} ||= [];
        push @{$anagrams{$normalized_word}}, $word
    }

    for my $key (keys %anagrams) {
        if (@{$anagrams{$key}} == 1) {
            next;
        }
        # my $new_key = $anagrams{$key}->[0];
        my $new_key = encode('utf8', $anagrams{$key}->[0]);
        $anagrams{$key} = [sort @{$anagrams{$key}}];

        $result{$new_key} = do {
            my %seen;
            [grep {!$seen{$_}++} map {encode('utf8', $_)} @{$anagrams{$key}}];
        }
    }

    return \%result;
}

1;
