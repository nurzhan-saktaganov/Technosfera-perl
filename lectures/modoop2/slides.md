class: firstpage title

# Программирование на Perl

## Модули и ООП (продолжение)

---

class:note_and_mark title

# Отметьтесь на портале!

---

# План занятия

1. Не такие простые модули
    * таблицы символов
    * caller
    * переопределение встроенных функций
    * фазы работы интерпретатора
1. Тонкости ООП
    * bless
    * наследование
    * декструкторы
    * overload
    * tie
    * AUTOLOAD
1. Mouse
1. Создание модуля

---

# Таблицы символов

```perl
package Some::Package {
    $var = 500; 
    @var = (1,2,3);
    %func = (1 => 2, 3 => 4);
    sub func { return 400 }
    open F, "<", "/dev/null";
}
package Some::Package::Deeper {}

# `%Some::Package::` - symbol table
printf "%-10s => %s\n", $_, $Some::Package::{$_}
    foreach keys %Some::Package::;
```

```perl
F          => *Some::Package::F
Deeper::   => *Some::Package::Deeper::
var        => *Some::Package::var
func       => *Some::Package::func
```

???
Каким же образом хранится информация о пакетах и относящихся к ним переменных, функциях?

---

# Таблицы символов

* TYPEGLOB: `*foo`
    * SCALAR: `$foo`
    * ARRAY: `@foo`
    * HASH: `%foo`
    * CODE: `&foo`
    * IO:  `foo`
    * NAME: `"foo"`
    * PACKAGE: `"main"`

---

# Таблицы символов

```perl
say ${*Some::Package::var{SCALAR}};   # 500
say @{*Some::Package::var{ARRAY}}[2]; # 3
say &{*Some::Package::func{CODE}};    # 400
```
--
```perl
say ${*Some::Package::var};           # 500
say @{*Some::Package::var}[2];        # 3
say &{*Some::Package::func};          # 400
```
--
```perl
say *Some::Package::var{NAME}     # var
say *Some::Package::var{PACKAGE}  # Some::Package
```

---

# Таблицы символов

```perl
 package Local::Math {
     $PI = 3.14159265;
     sub PI { print 3.14 }
 }

* *Other::Math::PI = *Local::Math::PI;
 print $Other::Math::PI, "\n";         # 3.14159265
 Other::Math::PI();                    # 3.14
```

---

# Таблицы символов

```perl
 package Local::Math {
     $PI = 3.14159265;
     sub PI { print 3.14 }
 }

* *Other::Math::PI = \$Local::Math::PI;
 print $Other::Math::PI, "\n";         # 3.14159265
 Other::Math::PI();
 # Undefined subroutine &Other::Math::PI called
```

---

# Таблицы символов

```perl
 package Local::Math {
     $PI = 3.14159265;
     sub PI { print 3.14 }
 }

* *Other::Math::PI = \&Local::Math::PI;
 print $Other::Math::PI, "\n";         # undef
 Other::Math::PI();                    # 3.14
```

---

# Таблицы символов

```perl
*PI = \3.14159265;
print $PI, "\n";      # 3.14159265
$PI = 4;
# Modification of a read-only value attempted
```
--

```perl
sub glob_fqn {
    my $glob = shift;
    return *{$glob}{PACKAGE}."::".*{$glob}{NAME};
}

our $var = 100;
say glob_fqn(*var)
```

---

# Контекст вызова функций
## caller

```perl
package Some::Package;

sub caller_test {
    my ($package, $filename, $line) = caller;
    say "$package, $filename, $line";
}

package main;
Some::Package::caller_test(); # main, script.pl, 10
```
---

# Контекст вызова функций
## caller EXPR

```perl
package Some::Package;

sub caller_test {
    my ($package, $filename, $line,
        $sub, $hasargs, $wantarray
    ) = caller(1);
    say "$package, $filename, $line";
    say "$sub, $hasargs, $wantarray";
}

sub pre_caller_test {
    caller_test(@_);
}

package main;
@res = Some::Package::pre_caller_test(); 
# main, script.pl, 17
# Some::Package::pre_caller_test, 1, 1
```

---

# Контекст вызова функций
## Хвостовая рекурсия


```perl
package Some::Package;

sub caller_test {
    my ($package, $filename, $line) = caller;
    say "$package, $filename, $line";
}

sub pre_caller_test  { `caller_test(@_)` }
sub tail_caller_test { `goto &caller_test` }

package main;
Some::Package::pre_caller_test(); 
#Some::Package, script.pl, 9

Some::Package::tail_caller_test();
#main, script.pl, 17
```

---

# Метод import

```perl
# Local/Math.pm

sub pow { $_[1] ** $_[2] }
sub sqr { $_[0]->pow($_[1], 0.5) }

sub import {
    my $self = shift;
    my ($pkg) = `caller(0)`;
    foreach my $func (@_) {
        `no strict 'refs';`
        `*{"${pkg}::$func"}` = `\&{$func}`;
    }
}
```

```perl
# main.pl
use Local::Math qw/pow sqr/;
print pow(2,8), "\n";             # 256
```

---

# Метод unimport

```perl
# Local/Math.pm
sub unimport {
    my $self = shift;
    my ($pkg) = caller(0);
    {
        `no strict 'refs';`
        delete `${"${pkg}::"}{$_}` foreach @_;
    }
}
```

```perl
# main.pl
use Local::Math qw/pow sqr/;
print pow(2,8), "\n";             # 256
no Local::Math qw/pow/;
print pow(2,8), "\n";
# Undefined subroutine &main::pow called
```
---

# CORE и CORE::GLOBAL
## Переопределение встроенных функций

```perl
BEGIN {
    `*CORE::GLOBAL::`hex = sub { 1 };
}
say hex("0x50");         # 1
say `CORE::`hex("0x50"); # 80
```

```perl
`use subs qw/hex/`;
sub hex { 1 }

say hex("0x50");         # 1
say `CORE::`hex("0x50"); # 80
```

---

# SIGDIE
## TODO

---

# SIGWARN
## TODO

---

# Carp
## TODO

---

# Фазы работы интерпретатора

`${^GLOBAL_PHASE}` – фаза работы интерпретатора perl
* CONSTRUCT
* START
* CHECK
* INIT
* RUN
* END
* DESTRUCT

???
Прежде чем мы перейдем к следующему, самому мощному и широкоиспользуемому инструменту для загрузки модулей,
нам нужно разобраться, что же происходит внутри интерпретатора перл во время его работы.

---

# Фазы работы интерпретатора

```perl
        warn "[${^GLOBAL_PHASE}] Runtime 1\n";
END   { warn "[${^GLOBAL_PHASE}] End 1\n"       }
CHECK { warn "[${^GLOBAL_PHASE}] Check 1\n"     }
UNITCHECK
      { warn "[${^GLOBAL_PHASE}] UnitCheck 1\n" }
INIT  { warn "[${^GLOBAL_PHASE}] Init 1\n"      }
BEGIN { warn "[${^GLOBAL_PHASE}] Begin 1\n"     }
END   { warn "[${^GLOBAL_PHASE}] End 2\n"       }
CHECK { warn "[${^GLOBAL_PHASE}] Check 2\n"     }
UNITCHECK
  { warn "[${^GLOBAL_PHASE}] UnitCheck 2\n"     }
INIT  { warn "[${^GLOBAL_PHASE}] Init 2\n"      }
BEGIN { warn "[${^GLOBAL_PHASE}] Begin 2\n"     }
        warn "[${^GLOBAL_PHASE}] Runtime 2\n";
```

---

# Фазы работы интерпретатора

```perl
[START] Begin 1
[START] Begin 2
[START] UnitCheck 2
[START] UnitCheck 1
[CHECK] Check 2
[CHECK] Check 1
[INIT] Init 1
[INIT] Init 2
[RUN] Runtime 1
[RUN] Runtime 2
[END] End 2
[END] End 1
```

---

# Фазы работы интерпретатора

## Особенности выполнения блоков

* `BEGIN`: выполняется *немедленно* после того, как perl обнаружил данный блок и закончил его компиляцию. Компиляция оставшейся части файла продолжится по окончании выполнения блока. FIFO
* `UNITCHECK`: выполняется по завершении компиляции файла (eval'а). LIFO
* `CHECK`: выполняется *по окончании компиляции* всей программы, как завершающий этап фазы компиляции. LIFO
* `INIT`: выполняется *перед началом выполнения* программы. FIFO
* `END`: выполняется *по окончании выполнения программы*, непосредственно перед завершением работы интерпретатора. LIFO

???
Показать, как работает BEGIN в консоли.

---

# Фазы работы интерпретатора

## Особенности выполнения блоков 

* `BEGIN` выполняется *немедленно* после того, как perl обнаружил данный блок и закончил его компиляцию. Даже в `eval`
* блоки `CHECK`, `INIT` внутри `eval` работают, только если их фазы еще не пройдены интерпретатором (иначе блоки игнорируются)
    * не работают в `require`, `do`
    * не работают в `mod_perl` и подобных ему системах
* `CHECK` - последнее, что выполняет команда `perl -c ...`
* `END` внутри `eval` *выполняется по окончании выполнения программы* (!), непосредственно перед завершением работы интерпретатора

---

# Фазы работы интерпретатора

```perl
# Local/Phases.pm
package Local::Phases;
*BEGIN     { say "  module compile start" }
UNITCHECK { say "  module UNITCHECK"     }
CHECK     { say "  module CHECK"         }
INIT      { say "  module INIT"          }
            say "  module runtime";
*BEGIN     { say "  module compile end"   }
```

```perl
# phases.pl
BEGIN     { say "main compile start" }
UNITCHECK { say "main UNITCHECK"     }
CHECK     { say "main CHECK"         }
INIT      { say "main INIT"          }
            say "main runtime";
*           use Local::Phases;
BEGIN     { say "main compile end"   }
```

---

# Фазы работы интерпретатора

```perl
main compile start
*  module compile start
*  module compile end
*  module UNITCHECK
*  module runtime
main compile end
main UNITCHECK
*  module CHECK
main CHECK
main INIT
*  module INIT
main runtime
```

---

# bless
## HASH

```perl
package User;

sub new {
    my ($class, %params) = @_;
    return bless `\%params`, $class;
}

sub full_name {
    $_[0]->{first_name}." ".$$_[0]->{last_name};
}

my $u = User->new(
    first_name => "vasya",
    last_name  => "pupkin",
);

say `$u->{name}`;  # vasya
say $u->full_name; # vasya pupkin
```

---

# bless
## ARRAY

```perl
package Vector;

sub new {
    my ($class, @points) = @_;
    return bless `\@points`, $class;
}

sub len {
    my $self = shift;
    return sqrt($self->[0]**2 + $self->[1]**2); 
}

my $v = Vector->new(3, 4);

say `$v->[0]`; # 3
say $v->len;   # 5
```

---

# bless
## SCALAR

```perl
package Time;
use POSIX qw/strftime/;

sub new {
    my ($class, $time) = @_;
    return bless `\$time`, $class;
}

sub date {
    my ($self) = @_;
    return strftime("%D", localtime $$self);
}

my $t = Time->new(time());

say `$$t`;     # 1491607207
say $t->date;  # 04/08/17
```

---

# Наследование

```perl
package Local::Student;
*BEGIN { our @ISA = ('Local::User'); }
```

```perl
package Local::Teacher;
*use base 'Local::User';
```

```perl
package Local::Professor;
*use parent 'Local::Teacher';
```

```perl
say Local::Professor->isa("Local::Teacher");# 1
say Local::Professor->isa("Local::User");   # 1
say Local::Professor->isa("Local::Student");# undef
```

---

# Наследование
## Класс UNIVERSAL

```perl
# ???
say Local::Professor->isa("UNIVERSAL");     # 1
```

```perl
my $professor = Local::Professor->new;
say $professor->isa("Local::Teacher");      # 1

say UNIVERSAL::isa({}, "Local::User");      # undef
```

```perl
say ref Local::Professor->can("new");       # CODE
say $professor->can("scream");              # undef
```

```perl
say Local::User->VERSION;                   # 1.4
```

---

# Множественное наследование

```perl
package Local::Resident;
use Class::XSAccessor {
  accessors => [qw/
    name snils inn
    passport_id passport_emission passport_date
  /],
};
```

```perl
package Local::ResidentStudent;
use parent qw/Local::Student Local::Resident/;
```

```perl
$resident_user->name(); # ???
# Local::Student->name or Local::Resident->name?
```

---

# Множественное наследование
## Method resolution order

```
       Object
         |
       Stream  Cacheable
       /   \   /
 InStream   CacheableOutStream
       \   /
      IOStream
```

```perl
IOStream->some_method();
# IOStream InStream Stream Object
#     CacheableOutStream Cacheable
```

```perl
$self->SUPER::some_method(@params);

$self->Cacheable::some_method(@params);
```

---

# Множественное наследование
## Method resolution order

```
       Object
         |
       Stream  Cacheable
       /   \   /
 InStream   CacheableOutStream
       \   /
      IOStream
```

```perl
use mro 'c3';

IOStream->some_method();
# IOStream InStream CacheableOutStream
#     Stream Object Cacheable
```

```perl
$self->next::method(@params);
```

---

layout: true

.footer[[overload](http://perldoc.perl.org/overload.html)]

---

# Модуль `overload`

```perl
package Local::User;
use overload '""' => 'to_string';
sub to_string {
    my ($self) = @_;
    return $self->name.' <'.$self->email.'>';
}
```

```perl
print $user;   # Василий Пупкин <vasily@pupkin.ru>
```

---

# Модуль `overload`

```perl
package Local::Vector;
use overload '+' => 'add', '0+' => 'len';
sub new {
    my ($class, $x, $y) = @_;
    bless { x=>$x, y=>$y }, $class;
}
sub add {
    my ($vec1, $vec2) = @_;
    __PACKAGE__->new(
        $vec1->{x} + $vec2->{x},
        $vec1->{y} + $vec2->{y},
    );
}
sub len {
    my ($self) = @_;
    return sqrt($self->{x}**2 + $self->{y}**2);
}
```

---

# Модуль `overload`

```perl
$vec1 = Local::Vector->new(1, 2);
$vec2 = Local::Vector->new(3, 1);

print $vec1+$vec2;    # 5
```

```perl
$vec1 = Local::Vector->new(1, 2);
$vec2 = Local::Vector->new(3, 1);

print Local::Vector::len(
    Local::Vector::add($vec1, $vec2);
);
```

---

layout: true

.footer[[perltie](http://perldoc.perl.org/perltie.html)]

---

# `tie`
## Объект под капотом переменной

```perl
$hash{x} = 'vasily@pupkin.ru';

print $hash{x};
# Василий Пупкин <vasily@pupkin.ru>

print ref $hash{x};
# Local::User

# WTF???
```

---

# `tie`
## Объект под капотом переменной


```perl
package Local::UserHash;

use Tie::Hash;
use base 'Tie::StdHash';

use Local::User;

sub STORE {
  my ($self, $key, $value) = @_;
  $self->{$key} = 
    Local::User->get_by_email($value);
}
```

---

# `tie`
## Объект под капотом переменной

```perl
my %hash;
tie %hash, 'Local::UserHash';

$hash{x} = 'vasily@pupkin.ru';

print $hash{x};
# Василий Пупкин <vasily@pupkin.ru>
```

---
layout: true

.footer[[perlobj](http://perldoc.perl.org/perlobj.html)]

---

# `AUTOLOAD`

```perl
package Local::User;

sub get_by_email      { ... }
sub is_password_valid { ... }
sub name              { ... }

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    return $self->{$AUTOLOAD};
}
```

```perl
print $user->first_name();         # Василий
print $user->can('first_name');    # 0 :-(
```

---
layout: false

# Деструкторы

```perl
package Local::User;

sub DESTROY {
  my ($self) = @_;
  print 'DESTROYED: ', $self->name, "\n";
}
```

```perl
{
  my $user =
    Local::User->get_by_email('vasily@pupkin.ru');
  # ...
}                      # DESTROYED: Василий Пупкин
```

---

# Деструкторы: грабли

* `die`
* `local`
* `AUTOLOAD`
* `${^GLOBAL_PHASE} eq 'DESTRUCT'`

```perl
sub DESTROY {
  my ($self) = @_;
  $self->{handle}->close() if $self->{handle};
}
```

---


# Mouse ООП

## Базовый синтаксис

```perl
package Local::User;
use Mouse;
has first_name => (
  is  => 'rw',
  isa => 'Str',
);
has last_name => (
  is  => 'rw',
  isa => 'Str',
);
```

```perl
Local::User->new(
  first_name => 'Василий',
  last_name  => 'Пупкин',
);
```

---

# Mouse ООП

## Наследование

```perl
package Local::Teacher;

use Mouse;

extends 'Local::User';
```

---

# Mouse ООП

## Инициализация объекта

```perl
has age      => (is => 'ro', isa => 'Int');
has is_adult => (is => 'rw', isa => 'Bool');

sub BUILD {
  my ($self) = @_;
  $self->is_adult($self->age >= 18);
  return;
}
```

---

# Mouse ООП

## Отложенное выполнение

```perl
has age      => (is => 'ro', isa => 'Int');
has is_adult => (
  is => 'ro',
  isa => 'Bool',
  lazy => 1,
  default => sub {
    my ($self) = @_;
    return $self->age >= 18;
  }
);
```

---

# Mouse ООП

## "Ленивые вычисления"

```perl
has age      => (is => 'ro', isa => 'Int');
has is_adult => (
  is => 'ro', isa => 'Bool',
  lazy => 1,  builder => '_build_is_adult',
);

sub _build_is_adult {
  my ($self) = @_;
  return $self->age >= 18;
}
```

```perl
package Local::SuperMan;
extends 'Local::User';
sub _build_is_adult { return 1; }
```

---

# Mouse ООП

## "Ленивые вычисления"

```perl
has [qw(
  file_name
  fh
  file_content
  xml_document
  data
)] => (
  lazy_build => 1,
  # ...
);

sub _build_fh           { open($self->file_name) }
sub _build_file_content { read($self->fh) }
sub _build_xml_document { parse($self->file_content) }
sub _build_data         { find($self->xml_document) }
```

---

# Mouse ООП

## Миксины

```perl
with 'Role::HasPassword';
```

```perl
package Role::HasPassword;
use Mouse::Role;
use Some::Digest;

has passwd => (
  is => 'ro',
  isa => 'Str',
);

sub is_password_valid {
  my ($self, $passwd) = @_;
  ...
}
```

---

# Mouse ООП

## Делегирование

```perl
has doc => (
  is    => 'ro',
  isa   => 'Item',
  handles => [qw(read write size)],
);
```

```perl
has last_login => (
  is    => 'rw',
  isa   => 'DateTime',
  handles => { 'date_of_last_login' => 'date' },
);
```

---

# Mouse ООП

## Декораторы, типы, расширения

```perl
before 'is_adult' => sub { shift->recalculate_age }
```

```perl
subtype 'ModernDateTime'
  => as 'DateTime'
  => where { $_->year() >= 1980 }
  => message { 'The date is not modern enough' };

has 'valid_dates' => (
  isa => 'ArrayRef[DateTime]',
);
```

```perl
package Config;
use MooseX::Singleton;
```

```perl
$meta = $class->meta;
```

---

# Mouse — аналоги

* Moose
* *Mouse*
* Moo
* Mo
* M

---

# Создание модулей
## module-starter

```bash
$ module-starter --module Local::Math \
>      --author Alex --email alex@kazakov.ru
```

```
Local-Math/
├── Changes
├── ignore.txt
├── lib
│   └── Local
│       └── Math.pm
├── Makefile.PL
├── MANIFEST
├── README
└── t
    ├── 00-load.t
    ├── boilerplate.t
    ├── manifest.t
    ├── pod-coverage.t
    └── pod.t
```

---

# Создание модулей
## Makefile.PL

```perl
# Makefile.PL
use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'Local::Math',
    AUTHOR         => 'Alex <alex@kazakov.ru>',
    VERSION_FROM   => 'lib/Local/Math.pm',
    ABSTRACT_FROM  => 'lib/Local/Math.pm',
    LICENSE        => 'Artistic_2_0',
    PL_FILES       => {},
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    # ...
);
```

---

class:lastpage title

# Спасибо за внимание!

## Оставьте отзыв

.teacher[![teacher]()]
