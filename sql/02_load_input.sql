-- ПМ.07, вариант 05. Шаг 2: загрузка исходного набора.
-- Выполняется в клиенте mariadb под учётной записью admin.
-- Путь к input.sql подставьте свой (на Linux: pwd + /input.sql).
-- Проверка перед загрузкой: grep -n -F 'INSERT INTO access_probe VALUES (1,10);' input.sql

USE `pm07_v05`;
SELECT DATABASE() AS current_db, CURRENT_USER() AS current_user;
SOURCE /home/student/pm07/input.sql;

SHOW TABLES;
