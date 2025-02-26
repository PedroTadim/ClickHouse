---
slug: /ru/sql-reference/statements/alter/user
sidebar_position: 45
sidebar_label: USER
---

# ALTER USER {#alter-user-statement}

Изменяет аккаунты пользователей ClickHouse.

Синтаксис:

``` sql
ALTER USER [IF EXISTS] name1 [RENAME TO new_name |, name2 [,...]] 
    [ON CLUSTER cluster_name]
    [NOT IDENTIFIED | RESET AUTHENTICATION METHODS TO NEW | {IDENTIFIED | ADD IDENTIFIED} {[WITH {plaintext_password | sha256_password | sha256_hash | double_sha1_password | double_sha1_hash}] BY {'password' | 'hash'}} | WITH NO_PASSWORD | {WITH ldap SERVER 'server_name'} | {WITH kerberos [REALM 'realm']} | {WITH ssl_certificate CN 'common_name' | SAN 'TYPE:subject_alt_name'} | {WITH ssh_key BY KEY 'public_key' TYPE 'ssh-rsa|...'} | {WITH http SERVER 'server_name' [SCHEME 'Basic']} 
    [, {[{plaintext_password | sha256_password | sha256_hash | ...}] BY {'password' | 'hash'}} | {ldap SERVER 'server_name'} | {...} | ... [,...]]]
    [[ADD | DROP] HOST {LOCAL | NAME 'name' | REGEXP 'name_regexp' | IP 'address' | LIKE 'pattern'} [,...] | ANY | NONE]
    [VALID UNTIL datetime]
    [DEFAULT ROLE role [,...] | ALL | ALL EXCEPT role [,...] ]
    [GRANTEES {user | role | ANY | NONE} [,...] [EXCEPT {user | role} [,...]]]
    [DROP ALL PROFILES]
    [DROP ALL SETTINGS]
    [DROP PROFILES 'profile_name' [,...] ]
    [DROP SETTINGS variable [,...] ]
    [ADD|MODIFY SETTINGS variable [=value] [MIN [=] min_value] [MAX [=] max_value] [READONLY|WRITABLE|CONST|CHANGEABLE_IN_READONLY] [,...] ]
    [ADD PROFILES 'profile_name' [,...] ]
```

Для выполнения `ALTER USER` необходима привилегия [ALTER USER](../grant.md#grant-access-management).

## Секция GRANTEES {#grantees}

Определяет пользователей или роли, которым разрешено получать [привилегии](../../../sql-reference/statements/grant.md#grant-privileges) от указанного пользователя при условии, что этому пользователю также предоставлен весь необходимый доступ с использованием [GRANT OPTION](../../../sql-reference/statements/grant.md#grant-privigele-syntax). Параметры секции `GRANTEES`:

-   `user` — пользователь, которому разрешено получать привилегии от указанного пользователя.
-   `role` — роль, которой разрешено получать привилегии от указанного пользователя.
-   `ANY` — любому пользователю или любой роли разрешено получать привилегии от указанного пользователя. Используется по умолчанию.
-   `NONE` — никому не разрешено получать привилегии от указанного пользователя.

Вы можете исключить любого пользователя или роль, используя выражение `EXCEPT`. Например, `ALTER USER user1 GRANTEES ANY EXCEPT user2`. Это означает, что если `user1` имеет привилегии, предоставленные с использованием `GRANT OPTION`, он сможет предоставить их любому, кроме `user2`.

## Примеры {#alter-user-examples}

Установить ролями по умолчанию роли, назначенные пользователю:

``` sql
ALTER USER user DEFAULT ROLE role1, role2;
```

Если роли не были назначены пользователю, ClickHouse выбрасывает исключение.

Установить ролями по умолчанию все роли, назначенные пользователю:

``` sql
ALTER USER user DEFAULT ROLE ALL;
```

Если роль будет впоследствии назначена пользователю, она автоматически станет ролью по умолчанию.

Установить ролями по умолчанию все назначенные пользователю роли кроме `role1` и `role2`:

``` sql
ALTER USER user DEFAULT ROLE ALL EXCEPT role1, role2;
```

Разрешить пользователю с аккаунтом `john` предоставить свои привилегии пользователю с аккаунтом `jack`:

``` sql
ALTER USER john GRANTEES jack;
```
