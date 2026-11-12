# ПМ.07 · Учебная практика · Вариант 05 — «Гостиница»

Соадминистрирование и автоматизация баз данных и серверов.
Предметная область: гостиница. СУБД: MariaDB 10. ОС: Debian 12.

| Параметр | Значение |
|---|---|
| Исходная база | `pm07_v05` |
| Проверочная база | `pm07_v05_restore` |
| Предметные таблицы | `rooms`, `guests`, `bookings` |
| Служебная таблица | `access_probe` (id=1, value=10) |
| Учётные записи | `admin` (своя база), `app_user` (CRUD), `readonly` (SELECT) |
| Индивидуальная операция | сжатие старых бэкапов `.sql` → `.sql.gz`, удаление архивов старше 14 суток |
| Расписание | ежедневно в 03:00 (`0 3 * * *`) |
| Журнал | `logs/run.log` |

## Состав

| Файл | Назначение |
|---|---|
| `input.sql` | исходный набор варианта 05: структура и данные `rooms`, `guests`, `bookings`, `access_probe` |
| `sql/01_create_db_and_users.sql` | создание баз, трёх серверных учётных записей и выдача прав (выполняет root) |
| `sql/02_load_input.sql` | выбор базы `pm07_v05` и загрузка `input.sql` под `admin` |
| `sql/03_control_values.sql` | контрольные `COUNT(*)`, `SUM(id)`, `SUM(amount)` и проверка `access_probe` |
| `config.env` | несекретные параметры: имена базы, клиента и утилиты дампа, путь к профилю, `AS_OF`, параметры дополнения |
| `auth/client.cnf.example` | образец парольного профиля; рабочий файл `auth/client.cnf` в репозиторий не входит |
| `run.sh` | каркас маршрута MariaDB 10 · Linux с функцией `run_task` своей операции |
| `evidence/` | протоколы контрольных значений, прав, резервного копирования и запусков |
| `README.md` | эта инструкция |

## Подготовка (однократно)

```bash
mkdir -p "$HOME/pm07"
cd "$HOME/pm07"            # сюда положить файлы этого комплекта
mkdir -p auth
cp auth/client.cnf.example auth/client.cnf
nano auth/client.cnf       # подставить свой учебный пароль admin
chmod 600 auth/client.cnf
```

Подстановки в `sql/01_create_db_and_users.sql` (`<ADMIN_PASSWORD>`, `<APP_PASSWORD>`,
`<READ_PASSWORD>`) заменяются своими учебными паролями до выполнения. Значения
паролей в репозиторий, отчёт и снимки не записываются.

## Порядок выполнения

```bash
# 1. Начальный администратор: базы, учётные записи, права
mariadb -h 127.0.0.1 -P 3306 -u root -p < sql/01_create_db_and_users.sql

# 2. admin: загрузка исходного набора
mariadb -h 127.0.0.1 -P 3306 -u admin -p pm07_v05 < input.sql

# 3. admin: контрольные значения (ожидается 4 / 10 / 100 в каждой таблице)
mariadb --defaults-file=auth/client.cnf pm07_v05 < sql/03_control_values.sql

# 4. Ручная полная копия и её SHA-256
mariadb-dump --defaults-file=auth/client.cnf --single-transaction \
  --default-character-set=utf8mb4 --result-file=manual.sql pm07_v05
sha256sum manual.sql

# 5. Восстановление в отдельную пустую базу pm07_v05_restore
mariadb --defaults-file=auth/client.cnf pm07_v05_restore < manual.sql

# 6. Ручной запуск операции варианта
bash ./run.sh; echo $?
tail -n 8 logs/run.log
ls -l backups
```

## Что делает операция

`run_task` в `run.sh`:

1. сжимает все файлы `backups/pm07_v05_*.sql` в `.sql.gz` (gzip, без перезаписи
   существующего архива — при конфликте gzip отказывает и скрипт завершается
   с ненулевым кодом и записью `ERROR` в журнале);
2. удаляет архивы `backups/pm07_v05_*.sql.gz` с возрастом более 14 суток
   (`find -mtime +13`) и пишет имя каждого удалённого файла в журнал;
3. пишет в журнал применённые параметры и счётчики `compressed=` / `deleted=`.

Файлы других баз (`other_test_old.sql.gz`) не затрагиваются: фильтр по префиксу
`${DB}_`.

## Индивидуальное дополнение

Срок хранения и уровень сжатия вынесены в `config.env` (`RETENTION_DAYS`,
`GZIP_LEVEL`), в образце они были фиксированными (`-mtime +13`). Значение
`RETENTION_DAYS=14` даёт прежнее поведение (`-mtime +13`). Отдельный опыт:
`RETENTION_DAYS=1` в тестовой копии конфигурации удаляет архив возрастом 2 суток,
который при значении по умолчанию сохраняется. Проверка — `evidence/addition-check.txt`.

## Расписание

```cron
SHELL=/bin/bash
0 3 * * * /bin/bash "$HOME/pm07/run.sh" >> "$HOME/pm07/logs/cron.log" 2>&1
```

Проверочный запуск выполняется по временной строке `*/2 * * * *` и после
подтверждения наступления триггера заменяется одной постоянной записью.

## Ожидаемый результат

* код завершения `0`, в журнале `START`, `params`, `compressed=`, `END result=OK`;
* новые файлы `backups/pm07_v05_<метка>.sql.gz`, проверяемые `gzip -t`;
* удалён только архив с префиксом `pm07_v05` и возрастом более 14 суток.

## Секреты

В комплекте нет паролей: `auth/client.cnf` создаётся из примера на месте и
исключён из репозитория (`.gitignore`). SQL-файлы содержат только обозначения
`<ADMIN_PASSWORD>`, `<APP_PASSWORD>`, `<READ_PASSWORD>`.
