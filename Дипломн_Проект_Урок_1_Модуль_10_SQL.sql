# Блок SQL

# ВАЖНО: Возможно, что при загрузке БД у вас могут возникнуть ошибки, пожалуйста, воспользуйтесь инструкцией ниже: 
# https://us02web.zoom.us/clips/share/yuU65B2DRki0vhyvUXHz7A

# Используя данные таблиц customer_info.xlsx (информация о клиентах) и transactions_info.xlsx (информация о транзакциях 
# за период с 01.06.2015 по 01.06.2016), нужно вывести:

# 1. список клиентов с непрерывной историей за год, то есть каждый месяц на регулярной основе без пропусков за 
# указанный годовой период, средний чек за период с 01.06.2015 по 01.06.2016, средняя сумма покупок за месяц, 
# количество всех операций по клиенту за период; информацию в разрезе месяцев:


# 2. 
# a. средняя сумма чека в месяц;
# b. среднее количество операций в месяц;
# c. среднее количество клиентов, которые совершали операции;
# d. долю от общего количества операций за год и долю в месяц от общей суммы операций;
# e. вывести % соотношение M/F/NA в каждом месяце с их долей затрат;

# 3. возрастные группы клиентов с шагом 10 лет и отдельно клиентов, у которых нет данной информации, 
# с параметрами сумма и количество операций за весь период, и поквартально - средние показатели и %.

# =================================================================================================================

# ДЛЯ РЕШЕНИЯ ЗАДАНИЙ И ПОДГОТОВКИ ОТВЕТОВ  ---  НУЖНО ПОДГОТОВИТЬ БАЗУ ДАННЫХ И ТАБЛИЦЫ ДЛЯ РАБОТЫ С НИМИ !!!

# 1. Создать базу данных Final_Project

CREATE DATABASE Final_Project;

# 2. Создать таблицу - customer_info (информация о клиентах) 

CREATE TABLE customer_info (
    Id_client INT PRIMARY KEY,
    Total_amount DECIMAL(12,2),
    Gender VARCHAR(10),
    Age INT,
    Count_city INT,
    Response_communcation INT,
    Communication_3month INT,
    Tenure INT
);

# 3. Создать таблицу - transactions_info (информация о транзакциях)

DROP TABLE IF EXISTS transactions_info;

CREATE TABLE transactions_info (
    date_new DATE,
    Id_check INT,
    ID_client INT,
    Count_products DECIMAL(12,3),
    Sum_payment DECIMAL(12,2),
    FOREIGN KEY (ID_client) REFERENCES customer_info(Id_client)
);

# 4. Загрузка 2-х нужных CSV файлов (customer_info, transactions_info) в MySQL, но с начало 
# пересохранил их из Excel в CSV формат.

# 4.1. customer_info загружен через использование - Table Data Import Wizard

# Проверка содержимого загруженного файла customer_info:

SELECT * FROM customer_info;

SELECT SUM(Total_amount) AS Total_amount,
count(ID_client) as Users_count
FROM customer_info;

# 4.2. Загрузка файла transactions_info через использование - Table Data Import Wizard показало, что за 4 часа
# загрузилось только 19000 строк из 419 тыс. строк, поэтому я решил загрузить через следующий запрос - LOAD DATA INFILE

# Для этого я определил место нахождение папки для загрузки данных MySQL на моем ноутбуке через запрос: 

SHOW VARIABLES LIKE 'secure_file_priv';

# 4.2.1. Исправил в таблице формат даты, необходимый для загрузки в MySQL (YYYY-MM-DD)

# 4.2.2. Чтобы ускорить загрузку данных отключил autocommit и Проверку FOREIGN_KEY:

# Перед импортом
SET autocommit=0;
SET FOREIGN_KEY_CHECKS=0;

# После импорта:
COMMIT;
SET FOREIGN_KEY_CHECKS=1;
SET autocommit=1;

# 4.2.3. Загрузка данных в MySQL через запрос LOAD DATA INFILE

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/transactions_info_2.csv'
INTO TABLE transactions_info
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(date_new, Id_check, ID_client, Count_products, Sum_payment);

# 4.2.4. Проверка содержимого загруженного файла transactions_info:

SELECT * FROM transactions_info;
DESCRIBE transactions_info;

SELECT SUM(Sum_payment) AS Total_payment,
count(ID_client) as Users_count
FROM transactions_info;

# ===========================================================================================================

# ОТВЕТЫ НА ЗАДАНИЯ  ---  ПОДГОТОВКА БАЗЫ ДАННЫХ И ТАБЛИЦ ЗАКОНЧЕНА !!!

# ТЕПЕРЬ РЕШЕНИЕ ЗАДАНИЙ

# 1. ЗАДАНИЕ - список клиентов с непрерывной историей за год, то есть каждый месяц на регулярной основе без пропусков за 
# указанный годовой период, средний чек за период с 01.06.2015 по 01.06.2016, средняя сумма покупок за месяц, 
# количество всех операций по клиенту за период; информацию в разрезе месяцев:

WITH period_data AS (
    SELECT 
        t.ID_client,
        DATE_FORMAT(t.date_new, '%Y-%m') AS `year_month`,
        t.Sum_payment
    FROM transactions_info t
    WHERE t.date_new >= '2015-06-01'
      AND t.date_new < '2016-06-01'
),

-- считаем сколько месяцев у клиента
months_count AS (
    SELECT 
        ID_client,
        COUNT(DISTINCT `year_month`) AS months_active
    FROM period_data
    GROUP BY ID_client
),

-- оставляем только тех, у кого 12 месяцев
full_year_clients AS (
    SELECT ID_client
    FROM months_count
    WHERE months_active = 12
)

SELECT 
    p.ID_client,
    p.`year_month`,
    COUNT(*) AS operations_in_month,
    ROUND(SUM(p.Sum_payment),2) AS monthly_sum,
    ROUND(AVG(p.Sum_payment),2) AS avg_check_month
FROM period_data p
JOIN full_year_clients f 
    ON p.ID_client = f.ID_client
GROUP BY p.ID_client, p.`year_month`
ORDER BY p.ID_client, p.`year_month`;

# 2. ЗАДАНИЕ
# a. средняя сумма чека в месяц;
# b. среднее количество операций в месяц;
# c. среднее количество клиентов, которые совершали операции;
# d. долю от общего количества операций за год и долю в месяц от общей суммы операций;
# e. вывести % соотношение M/F/NA в каждом месяце с их долей затрат;


WITH period_data AS (
    -- Берём только данные за год и вычисляем месяц
    SELECT 
        t.ID_client,
        DATE_FORMAT(t.date_new, '%Y-%m') AS `year_month`,
        t.Sum_payment
    FROM transactions_info t
    WHERE t.date_new >= '2015-06-01'
      AND t.date_new < '2016-06-01'
),
monthly_stats AS (
    -- Общие показатели по месяцу
    SELECT
        pd.year_month,
        COUNT(*) AS total_operations_month,
        SUM(pd.Sum_payment) AS total_sum_month,
        AVG(pd.Sum_payment) AS avg_check_month,
        COUNT(DISTINCT pd.ID_client) AS active_clients_month
    FROM period_data pd
    GROUP BY pd.year_month
),
yearly_stats AS (
    -- Общие показатели за год
    SELECT
        COUNT(*) AS total_operations_year,
        SUM(Sum_payment) AS total_sum_year
    FROM period_data
),
gender_stats AS (
    -- M/F/NA по месяцам
    SELECT
        pd.year_month,
        CASE 
            WHEN c.Gender IS NULL OR c.Gender = '' THEN 'NA'
            ELSE c.Gender
        END AS Gender,
        COUNT(*) AS operations_gender,
        SUM(pd.Sum_payment) AS sum_gender
    FROM period_data pd
    LEFT JOIN customer_info c
        ON pd.ID_client = c.Id_client
    GROUP BY pd.year_month, Gender
)
SELECT 
    m.year_month,
    ROUND(m.avg_check_month,2) AS avg_check_month,
    ROUND(m.total_operations_month / m.active_clients_month,2) AS avg_operations_per_client,
    m.active_clients_month AS active_clients,
    ROUND(m.total_operations_month / y.total_operations_year * 100,2) AS operations_share_percent,
    ROUND(m.total_sum_month / y.total_sum_year * 100,2) AS sum_share_percent,
    g.Gender,
    g.operations_gender,
    ROUND(g.sum_gender,2) AS sum_gender,
    ROUND(g.operations_gender / SUM(g.operations_gender) OVER (PARTITION BY g.year_month) * 100,2) AS operations_percent,
    ROUND(g.sum_gender / SUM(g.sum_gender) OVER (PARTITION BY g.year_month) * 100,2) AS sum_percent
FROM monthly_stats m
CROSS JOIN yearly_stats y
LEFT JOIN gender_stats g
    ON m.year_month = g.year_month
ORDER BY m.year_month, g.Gender;

# 3. Задание - возрастные группы клиентов с шагом 10 лет и отдельно клиентов, у которых нет данной информации, 
# с параметрами сумма и количество операций за весь период, и поквартально - средние показатели и %.

WITH period_data AS (
    -- Берём транзакции за весь период и добавляем дату и возраст
    SELECT 
        t.ID_client,
        t.Sum_payment,
        t.date_new,
        c.Age
    FROM transactions_info t
    LEFT JOIN customer_info c
        ON t.ID_client = c.Id_client
),
age_groups AS (
    -- Разбиваем клиентов на группы по 10 лет + отдельная группа NA
    SELECT
        ID_client,
        Sum_payment,
        CASE
            WHEN Age IS NULL THEN 'NA'
            WHEN Age < 10 THEN '0-9'
            WHEN Age BETWEEN 10 AND 19 THEN '10-19'
            WHEN Age BETWEEN 20 AND 29 THEN '20-29'
            WHEN Age BETWEEN 30 AND 39 THEN '30-39'
            WHEN Age BETWEEN 40 AND 49 THEN '40-49'
            WHEN Age BETWEEN 50 AND 59 THEN '50-59'
            WHEN Age BETWEEN 60 AND 69 THEN '60-69'
            WHEN Age BETWEEN 70 AND 79 THEN '70-79'
            ELSE '80+'
        END AS age_group,
        QUARTER(date_new) AS quarter,
        YEAR(date_new) AS year
    FROM period_data
),
-- Общие показатели по возрастным группам за весь период
total_stats AS (
    SELECT
        age_group,
        COUNT(*) AS total_operations,
        SUM(Sum_payment) AS total_sum
    FROM age_groups
    GROUP BY age_group
),
-- Поквартальные показатели по возрастным группам
quarterly_stats AS (
    SELECT
        age_group,
        year,
        quarter,
        COUNT(*) AS operations_quarter,
        SUM(Sum_payment) AS sum_quarter,
        ROUND(AVG(Sum_payment),2) AS avg_check_quarter
    FROM age_groups
    GROUP BY age_group, year, quarter
)
-- Финальный SELECT объединяет квартальные и общие показатели
SELECT
    q.age_group,
    q.year,
    q.quarter,
    q.operations_quarter,
    q.sum_quarter,
    q.avg_check_quarter,
    t.total_operations,
    t.total_sum,
    ROUND(q.operations_quarter / t.total_operations * 100,2) AS operations_percent,
    ROUND(q.sum_quarter / t.total_sum * 100,2) AS sum_percent
FROM quarterly_stats q
JOIN total_stats t
    ON q.age_group = t.age_group
ORDER BY q.age_group, q.year, q.quarter;