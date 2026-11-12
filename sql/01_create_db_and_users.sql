-- ПМ.07, вариант 05 (гостиница). Шаг 1: базы, серверные учётные записи и права.
-- Выполняется НАЧАЛЬНЫМ администратором сервера (root), а не пользователем admin:
-- права admin ограничены одной базой и не позволяют создавать учётные записи.
-- Перед выполнением замените подстановки <ADMIN_PASSWORD>, <APP_PASSWORD>,
-- <READ_PASSWORD> на собственные учебные пароли. В отчёт и репозиторий
-- записываются только обозначения, без значений.

SELECT VERSION() AS server_version, CURRENT_USER() AS current_user, DATABASE() AS current_db;

CREATE DATABASE IF NOT EXISTS `pm07_v05`         CHARACTER SET utf8mb4;
CREATE DATABASE IF NOT EXISTS `pm07_v05_restore` CHARACTER SET utf8mb4;

CREATE USER IF NOT EXISTS 'admin'@'%'    IDENTIFIED BY '<ADMIN_PASSWORD>';
CREATE USER IF NOT EXISTS 'app_user'@'%' IDENTIFIED BY '<APP_PASSWORD>';
CREATE USER IF NOT EXISTS 'readonly'@'%' IDENTIFIED BY '<READ_PASSWORD>';

-- admin управляет только своей базой и её проверочной копией
GRANT ALL PRIVILEGES ON `pm07_v05`.*         TO 'admin'@'%';
GRANT ALL PRIVILEGES ON `pm07_v05_restore`.* TO 'admin'@'%';

-- app_user: CRUD в предметных таблицах, без изменения структуры
GRANT SELECT, INSERT, UPDATE, DELETE ON `pm07_v05`.* TO 'app_user'@'%';

-- readonly: только чтение
GRANT SELECT ON `pm07_v05`.* TO 'readonly'@'%';

SHOW GRANTS FOR 'admin'@'%';
SHOW GRANTS FOR 'app_user'@'%';
SHOW GRANTS FOR 'readonly'@'%';
