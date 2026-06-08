
-- 1. Стадионы и места
CREATE TABLE stadiums (
    stadium_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    capacity INT NOT NULL
);

CREATE TABLE stadium_seats (
    seat_id INT PRIMARY KEY AUTO_INCREMENT,
    stadium_id INT,
    sector VARCHAR(10) NOT NULL,
    seat_row INT NOT NULL,  
    seat_number INT NOT NULL,
    FOREIGN KEY (stadium_id) REFERENCES stadiums(stadium_id) ON DELETE CASCADE
);

-- 2. Управление персоналом и игроками
CREATE TABLE positions (
    position_id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(50) NOT NULL -- 'Главный тренер', 'Врач', 'Защитник'
);

CREATE TABLE staff (
    staff_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    position_id INT,
    salary DECIMAL(10,2),
    contract_end DATE,
    FOREIGN KEY (position_id) REFERENCES positions(position_id)
);

CREATE TABLE players (
    player_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    position_id INT, -- Игровая позиция
    jersey_number INT,
    birth_date DATE,
    status VARCHAR(20) DEFAULT 'Здоров', -- 'Здоров', 'Травмирован', 'Дисквалифицирован'
    FOREIGN KEY (position_id) REFERENCES positions(position_id)
);

-- 3. Медицинский кабинет
CREATE TABLE medical_records (
    record_id INT PRIMARY KEY AUTO_INCREMENT,
    player_id INT,
    doctor_id INT,
    injury_title VARCHAR(100),
    recovery_start DATE,
    recovery_end DATE,
    status VARCHAR(20), -- 'Лечение', 'Восстановление', 'Завершено'
    FOREIGN KEY (player_id) REFERENCES players(player_id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES staff(staff_id)
);

-- 4. Календарь матчей
CREATE TABLE matches (
    match_id INT PRIMARY KEY AUTO_INCREMENT,
    opponent VARCHAR(100) NOT NULL,
    match_date DATETIME NOT NULL,
    stadium_id INT,
    match_type VARCHAR(50), -- 'Домашний', 'Выездной'
    status VARCHAR(20) DEFAULT 'Запланирован', -- 'Запланирован', 'Идет', 'Завершен'
    our_score INT DEFAULT 0,
    opponent_score INT DEFAULT 0,
    FOREIGN KEY (stadium_id) REFERENCES stadiums(stadium_id)
);

-- 5. Коммерческий сектор (Продажи)
CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20)
);

CREATE TABLE products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50), -- 'Форма', 'Сувениры'
    price DECIMAL(10,2) NOT NULL,
    stock INT DEFAULT 0
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT,
    order_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10,2) DEFAULT 0.00,
    status VARCHAR(20) DEFAULT 'Новый', -- 'Новый', 'Оплачен', 'Выполнен', 'Отменен'
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    item_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    product_id INT,
    quantity INT NOT NULL,
    price_at_purchase DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE tickets (
    ticket_id INT PRIMARY KEY AUTO_INCREMENT,
    match_id INT,
    seat_id INT,
    customer_id INT NULL,
    price DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'Доступен', -- 'Доступен', 'Забронирован', 'Продан'
    FOREIGN KEY (match_id) REFERENCES matches(match_id) ON DELETE CASCADE,
    FOREIGN KEY (seat_id) REFERENCES stadium_seats(seat_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);


-- Наполнение должностей
INSERT INTO positions (title) VALUES ('Главный тренер'), ('Врач'), ('Нападающий'), ('Защитник');

-- Наполнение стадионов и мест
INSERT INTO stadiums (name, city, capacity) VALUES ('Вектор Арена', 'Москва', 30000);
INSERT INTO stadium_seats (stadium_id, sector, seat_row, seat_number) VALUES 
(1, 'A', 1, 1), (1, 'A', 1, 2), (1, 'B', 10, 15);

-- Наполнение персонала и игроков
INSERT INTO staff (first_name, last_name, position_id, salary, contract_end) VALUES 
('Игорь', 'Петров', 1, 500000.00, '2028-06-01'),
('Олег', 'Иванов', 2, 120000.00, '2027-12-31');

INSERT INTO players (first_name, last_name, position_id, jersey_number, birth_date, status) VALUES 
('Артем', 'Дзюбин', 3, 9, '1995-08-22', 'Здоров'),
('Дмитрий', 'Быстров', 4, 4, '1998-03-15', 'Здоров');

-- Календарь матчей
INSERT INTO matches (opponent, match_date, stadium_id, match_type, status) VALUES 
('ФК Спартак', '2026-06-15 19:00:00', 1, 'Домашний', 'Запланирован'),
('ФК Зенит', '2026-06-22 18:30:00', 1, 'Домашний', 'Запланирован');

-- Генерация билетов на матч
INSERT INTO tickets (match_id, seat_id, price, status) VALUES 
(1, 1, 1500.00, 'Доступен'),
(1, 2, 1500.00, 'Доступен'),
(1, 3, 3000.00, 'Доступен');

-- Каталог товаров
INSERT INTO products (name, category, price, stock) VALUES 
('Домашняя игровая футболка 2026', 'Форма', '4999.00', 150),
('Шарф болельщика ФК Вектор', 'Сувениры', '999.00', 500);

-- База клиентов
INSERT INTO customers (first_name, last_name, email, phone) VALUES 
('Иван', 'Смирнов', 'ivan@mail.ru', '+79991112233');


-- Представление 1: Предстоящие матчи и доступность билетов
CREATE VIEW view_upcoming_matches AS
SELECT 
    m.match_id,
    m.opponent,
    m.match_date,
    s.name AS stadium_name,
    COUNT(t.ticket_id) AS total_tickets,
    SUM(CASE WHEN t.status = 'Доступен' THEN 1 ELSE 0 END) AS available_tickets
FROM matches m
JOIN stadiums s ON m.stadium_id = s.stadium_id
LEFT JOIN tickets t ON m.match_id = t.match_id
WHERE m.status = 'Запланирован'
GROUP BY m.match_id, m.opponent, m.match_date, s.name;

-- Представление 2: Медицинский отчет по травмированным игрокам
CREATE VIEW view_injured_players AS
SELECT 
    p.player_id,
    CONCAT(p.first_name, ' ', p.last_name) AS player_name,
    mr.injury_title,
    mr.recovery_start,
    mr.recovery_end,
    CONCAT(s.first_name, ' ', s.last_name) AS doctor_name
FROM players p
JOIN medical_records mr ON p.player_id = mr.player_id
JOIN staff s ON mr.doctor_id = s.staff_id
WHERE p.status = 'Травмирован' AND mr.status != 'Завершено';


-- 1. Создание (Добавление нового игрока)
INSERT INTO players (first_name, last_name, position_id, jersey_number, birth_date)
VALUES ('Алексей', 'Сидоров', 3, 11, '2001-05-10');

-- 2. Правка (Обновление стоимости товара и остатка на складе)
UPDATE products 
SET price = 4500.00, stock = 140 
WHERE product_id = 1;

-- 3. Удаление (Отмена матча и каскадное удаление билетов к нему)
DELETE FROM matches WHERE match_id = 2;

-- 4. Оформление заказа (Покупка мерча в магазине)
-- Создаем пустой заказ
INSERT INTO orders (customer_id, order_date, status) VALUES (1, NOW(), 'Новый');
-- Добавляем позицию в корзину (футболка, 2 шт)
INSERT INTO order_items (order_id, product_id, quantity, price_at_purchase) 
VALUES (LAST_INSERT_ID(), 1, 2, 4500.00);
-- Обновляем итоговую сумму заказа и списываем склад
UPDATE orders SET total_amount = 9000.00, status = 'Оплачен' WHERE order_id = LAST_INSERT_ID();
UPDATE products SET stock = stock - 2 WHERE product_id = 1;

-- 5. Покупка билета на матч конкретным клиентом
UPDATE tickets 
SET customer_id = 1, status = 'Продан' 
WHERE ticket_id = 1 AND status = 'Доступен';

-- 6. Смена статуса игрока и фиксация травмы (Выполнение процесса лечения)
-- Меняем статус игрока
UPDATE players SET status = 'Травмирован' WHERE player_id = 1;
-- Заносим запись в мед. карту (Доктор Олег Иванов, staff_id = 2)
INSERT INTO medical_records (player_id, doctor_id, injury_title, recovery_start, status)
VALUES (1, 2, 'Растяжение подколенного сухожилия', CURDATE(), 'Лечение');

-- 7. Завершение матча (Смена статуса и фиксация счета)
UPDATE matches 
SET status = 'Завершен', our_score = 2, opponent_score = 1 
WHERE match_id = 1;
