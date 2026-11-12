-- ПМ.07, вариант 05. Шаг 3: контрольные значения исходной базы.
-- Ожидается по каждой предметной таблице: 4 строки, SUM(id)=10, SUM(amount)=100.
-- Таблица access_probe проверяется отдельно: одна строка id=1, value=10.

SELECT 'rooms' AS table_name, COUNT(*) AS row_count, SUM(id) AS id_sum, SUM(amount) AS amount_sum
FROM `rooms`
UNION ALL
SELECT 'guests', COUNT(*), SUM(id), SUM(amount) FROM `guests`
UNION ALL
SELECT 'bookings', COUNT(*), SUM(id), SUM(amount) FROM `bookings`;

SELECT id, name, event_at, amount, link_id, quantity, expires_on FROM `rooms`    ORDER BY id;
SELECT id, name, event_at, amount, link_id, quantity, expires_on FROM `guests`   ORDER BY id;
SELECT id, name, event_at, amount, link_id, quantity, expires_on FROM `bookings` ORDER BY id;

SELECT COUNT(*) AS probe_rows, SUM(id) AS probe_id_sum, SUM(value) AS probe_value_sum
FROM access_probe;
