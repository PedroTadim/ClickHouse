---
slug: /ru/sql-reference/data-types/enum
sidebar_position: 50
sidebar_label: Enum
---

# Enum {#enum}

Перечисляемый тип данных, содержащий именованные значения.

Именованные значения задаются либо парами `'string' = integer`, либо именами `'string'`. ClickHouse хранит только числа, но допускает операции над ними с помощью заданных имён.

ClickHouse поддерживает:

-   8-битный `Enum`. Может содержать до 256 значений, пронумерованных в диапазоне `[-128, 127]`.
-   16-битный `Enum`. Может содержать до 65536 значений, пронумерованных в диапазоне `[-32768, 32767]`.

ClickHouse автоматически выбирает размерность `Enum` при вставке данных. Чтобы точно понимать размер хранимых данных можно использовать типы `Enum8` или `Enum16`.

## Примеры использования {#primery-ispolzovaniia}

Создадим таблицу со столбцом типа `Enum8('hello' = 1, 'world' = 2)`.

``` sql
CREATE TABLE t_enum
(
    x Enum('hello' = 1, 'world' = 2)
)
ENGINE = TinyLog
```

Номера могут быть опущены - в этом случае ClickHouse автоматически присвоит последовательные номера, начиная с 1.

``` sql
CREATE TABLE t_enum
(
    x Enum('hello', 'world')
)
ENGINE = TinyLog
```

Можно также указать допустимый стартовый номер для первого имени.

``` sql
CREATE TABLE t_enum
(
    x Enum('hello' = 1, 'world')
)
ENGINE = TinyLog
```

``` sql
CREATE TABLE t_enum
(
    x Enum8('hello' = -129, 'world')
)
ENGINE = TinyLog
```

``` text
Exception on server:
Code: 69. DB::Exception: Value -129 for element 'hello' exceeds range of Enum8.
```

В столбец `x` можно сохранять только значения, перечисленные при определении типа, т.е. `'hello'` или `'world'`. Если вы попытаетесь сохранить любое другое значение, ClickHouse сгенерирует исключение. ClickHouse автоматически выберет размерность 8-bit для этого `Enum`.

``` sql
INSERT INTO t_enum VALUES ('hello'), ('world'), ('hello')
```

``` text
Ok.
```

``` sql
insert into t_enum values('a')
```

``` text
Exception on client:
Code: 49. DB::Exception: Unknown element 'a' for type Enum('hello' = 1, 'world' = 2)
```

При запросе данных из таблицы ClickHouse выдаст строковые значения из `Enum`.

``` sql
SELECT * FROM t_enum
```

``` text
┌─x─────┐
│ hello │
│ world │
│ hello │
└───────┘
```

Если необходимо увидеть цифровые эквиваленты строкам, то необходимо привести тип `Enum` к целочисленному.

``` sql
SELECT CAST(x AS Int8) FROM t_enum
```

``` text
┌─CAST(x, 'Int8')─┐
│               1 │
│               2 │
│               1 │
└─────────────────┘
```

Чтобы создать значение типа `Enum` в запросе, также необходимо использовать функцию `CAST`.

``` sql
SELECT toTypeName(CAST('a', 'Enum(\'a\' = 1, \'b\' = 2)'))
```

``` text
┌─toTypeName(CAST('a', 'Enum(\'a\' = 1, \'b\' = 2)'))─┐
│ Enum8('a' = 1, 'b' = 2)                             │
└─────────────────────────────────────────────────────┘
```

## Общие правила и особенности использования {#obshchie-pravila-i-osobennosti-ispolzovaniia}

Для каждого из значений прописывается число в диапазоне `-128 .. 127` для `Enum8` или в диапазоне `-32768 .. 32767` для `Enum16`. Все строки должны быть разными, числа - тоже. Разрешена пустая строка. При указании такого типа (в определении таблицы), числа могут идти не подряд и в произвольном порядке. При этом, порядок не имеет значения.

Ни строка, ни цифровое значение в `Enum` не могут быть [NULL](/operations/settings/formats#input_format_null_as_default).

`Enum` может быть передан в тип [Nullable](nullable.md). Таким образом, если создать таблицу запросом

``` sql
CREATE TABLE t_enum_nullable
(
    x Nullable( Enum8('hello' = 1, 'world' = 2) )
)
ENGINE = TinyLog
```

, то в ней можно будет хранить не только `'hello'` и `'world'`, но и `NULL`.

``` sql
INSERT INTO t_enum_nullable Values('hello'),('world'),(NULL)
```

В оперативке столбец типа `Enum` представлен так же, как `Int8` или `Int16` соответствующими числовыми значениями.
При чтении в текстовом виде, парсит значение как строку и ищет соответствующую строку из множества значений Enum-а. Если не находит - кидается исключение.
При записи в текстовом виде, записывает значение как соответствующую строку. Если в данных столбца есть мусор - числа не из допустимого множества, то кидается исключение. При чтении и записи в бинарном виде, оно осуществляется так же, как для типов данных Int8, Int16.
Неявное значение по умолчанию - это значение с минимальным номером.

При `ORDER BY`, `GROUP BY`, `IN`, `DISTINCT` и т. п., Enum-ы ведут себя так же, как соответствующие числа. Например, при ORDER BY они сортируются по числовым значениям. Функции сравнения на равенство и сравнения на отношение порядка двух Enum-ов работают с Enum-ами так же, как с числами.

Сравнивать Enum с числом нельзя. Можно сравнивать Enum с константной строкой - при этом, для строки ищется соответствующее значение Enum-а; если не находится - кидается исключение. Поддерживается оператор IN, где слева стоит Enum, а справа - множество строк. В этом случае, строки рассматриваются как значения соответствующего Enum-а.

Большинство операций с числами и со строками не имеет смысла и не работают для Enum-ов: например, к Enum-у нельзя прибавить число.
Для Enum-а естественным образом определяется функция `toString`, которая возвращает его строковое значение.

Также для Enum-а определяются функции `toT`, где T - числовой тип. При совпадении T с типом столбца Enum-а, преобразование работает бесплатно.
При ALTER, есть возможность бесплатно изменить тип Enum-а, если меняется только множество значений. При этом, можно добавлять новые значения; можно удалять старые значения (это безопасно только если они ни разу не использовались, так как это не проверяется). В качестве «защиты от дурака», нельзя менять числовые значения у имеющихся строк - в этом случае, кидается исключение.

При ALTER, есть возможность поменять Enum8 на Enum16 и обратно - так же, как можно поменять Int8 на Int16.
