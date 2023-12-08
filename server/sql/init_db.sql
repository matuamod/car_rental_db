DROP TABLE IF EXISTS roles CASCADE;
DROP TABLE IF EXISTS admin CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS user_logs CASCADE;
DROP TABLE IF EXISTS car_types CASCADE;
DROP TABLE IF EXISTS brands CASCADE;
DROP TABLE IF EXISTS fuel_types CASCADE;
DROP TABLE IF EXISTS car_images CASCADE;
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS cars CASCADE;
DROP TABLE IF EXISTS favorite_cars CASCADE;
DROP TABLE IF EXISTS pick_up_location CASCADE;
DROP TABLE IF EXISTS rental_deals CASCADE;
DROP TABLE IF EXISTS taxes CASCADE;
DROP TYPE IF EXISTS ACTIVITY_STATUS_TYPE;


CREATE TYPE ACTIVITY_STATUS_TYPE AS ENUM (
    'active',
    'inactive'
);


CREATE TABLE IF NOT EXISTS roles (
    id SERIAL PRIMARY KEY NOT NULL UNIQUE,
    name VARCHAR(50) NOT NULL,
    permission VARCHAR(100) NOT NULL
);


INSERT INTO roles (name, permission) VALUES 
    ('not logined user', 'watch sale announcements'), 
    ('logined user', 'not logined user + make rent'),
    ('moderator', 'delete sale announcements, block users, watch logs'),
    ('landlord', 'logined user + add sale announcements'),
    ('admin', 'moderator + users CRUD operations');


CREATE TABLE IF NOT EXISTS admin (
    id SERIAL PRIMARY KEY NOT NULL UNIQUE,
    role_id INT REFERENCES roles(id) ON DELETE SET NULL UNIQUE DEFAULT 5,
    username VARCHAR(100) NOT NULL,
    password VARCHAR(100) NOT NULL
);


CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY NOT NULL UNIQUE,
    role_id INT REFERENCES roles(id) ON DELETE SET NULL DEFAULT 2,
    given_name VARCHAR(100) NOT NULL,
    surname VARCHAR(100) NOT NULL,
    passport_no VARCHAR(9) NOT NULL UNIQUE,
    identification_no VARCHAR(14) NOT NULL UNIQUE,
    license_no VARCHAR(10) NOT NULL UNIQUE,
    telephone_no VARCHAR(13) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    date_of_birth DATE NOT NULL,
    password VARCHAR(100) NOT NULL UNIQUE,
    is_owner BOOLEAN NOT NULL DEFAULT FALSE,
    avatar_url VARCHAR(200),
    status ACTIVITY_STATUS_TYPE NOT NULL DEFAULT 'active' 
);


CREATE TABLE IF NOT EXISTS payments (
    id SERIAL PRIMARY KEY NOT NULL UNIQUE,
    user_id INT REFERENCES users(id) ON DELETE CASCADE,
    payed_price NUMERIC NOT NULL,
    time TIMESTAMP WITH TIME ZONE NOT NULL
);


CREATE TABLE IF NOT EXISTS user_logs (
    id SERIAL PRIMARY KEY NOT NULL UNIQUE,
    user_id INT REFERENCES users(id) ON DELETE SET NULL, 
    message VARCHAR(500) NOT NULL,
    time TIMESTAMP WITH TIME ZONE NOT NULL
);


CREATE TABLE IF NOT EXISTS car_types (
    id SERIAL PRIMARY KEY NOT NULL UNIQUE,
    type_name VARCHAR(50) NOT NULL
);


CREATE TABLE IF NOT EXISTS brands (
    id SERIAL PRIMARY KEY NOT NULL UNIQUE,
    name VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL
);


CREATE TABLE IF NOT EXISTS fuel_types (
    id SERIAL PRIMARY KEY NOT NULL UNIQUE,
    type_name VARCHAR(50) NOT NULL
);


INSERT INTO fuel_types (type_name) VALUES
    ('petrol'),
    ('diesel'),
    ('electric');


CREATE TABLE IF NOT EXISTS cars (
    id SERIAL PRIMARY KEY NOT NULL UNIQUE,
    owner_id INT REFERENCES users(id) ON DELETE CASCADE,
    car_type_id INT REFERENCES car_types(id) ON DELETE SET NULL,
    brand_id INT REFERENCES brands(id) ON DELETE CASCADE,
    fuel_type_id INT REFERENCES fuel_types(id) ON DELETE SET NULL,
    registration_plate VARCHAR(9) NOT NULL UNIQUE,
    price_per_day NUMERIC NOT NULL,
    description VARCHAR(500),
    is_available BOOLEAN NOT NULL DEFAULT TRUE
);


CREATE TABLE IF NOT EXISTS car_images (
    id SERIAL PRIMARY KEY NOT NULL UNIQUE,
    car_id INT REFERENCES cars(id) ON DELETE CASCADE,
    url VARCHAR(200) NOT NULL
);


CREATE TABLE IF NOT EXISTS reviews (
    id SERIAL PRIMARY KEY NOT NULL UNIQUE,
    car_id INT REFERENCES cars(id) ON DELETE CASCADE,
    message VARCHAR(500) NOT NULL
);


CREATE TABLE IF NOT EXISTS favorite_cars (
    id SERIAL PRIMARY KEY NOT NULL UNIQUE,
    user_id INT REFERENCES users(id) ON DELETE CASCADE,
    car_id INT REFERENCES cars(id) ON DELETE CASCADE
);


CREATE TABLE IF NOT EXISTS pick_up_location (
    id SERIAL PRIMARY KEY NOT NULL UNIQUE,
    start_location VARCHAR(100) NOT NULL,
    end_location VARCHAR(100) NOT NULL
);


CREATE TABLE IF NOT EXISTS rental_deals (
    id SERIAL PRIMARY KEY NOT NULL UNIQUE,
    user_id INT REFERENCES users(id) ON DELETE SET NULL,
    car_id INT REFERENCES cars(id) ON DELETE SET NULL,
    pick_up_id INT REFERENCES pick_up_location(id) ON DELETE SET NULL UNIQUE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_price NUMERIC NOT NULL,
    status ACTIVITY_STATUS_TYPE NOT NULL DEFAULT 'active'
);


CREATE TABLE IF NOT EXISTS taxes (
    id SERIAL PRIMARY KEY NOT NULL UNIQUE,
    rental_deal_id INT REFERENCES rental_deals(id) ON DELETE CASCADE NOT NULL,
    tax_percent NUMERIC NOT NULL,
    price NUMERIC NOT NULL
);


CREATE OR REPLACE FUNCTION validate_user_register() RETURNS TRIGGER AS $$
BEGIN
    -- Проверка на соответствие номера паспорта формату
    IF NOT NEW.passport_no ~ '^[A-Z0-9]{9}$' THEN
        RAISE EXCEPTION 'Passport number is invalid';
    END IF;

    -- Проверка на соответствие идентификационного номера формату
    IF NOT NEW.identification_no ~ '^[0-9]{14}$' THEN
        RAISE EXCEPTION 'Identification number is invalid';
    END IF;

    -- Проверка на соответствие номера лицензии формату
    IF NOT NEW.license_no ~ '^[A-Z0-9]{10}$' THEN
        RAISE EXCEPTION 'License number is invalid';
    END IF;

    -- Проверка на соответствие номера телефона формату
    IF NOT NEW.telephone_no ~ '^\+?[0-9]{10,12}$' THEN
        RAISE EXCEPTION 'Telephone number is invalid';
    END IF;

    -- Проверка на соответствие адреса электронной почты формату
    IF NOT NEW.email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$' THEN
        RAISE EXCEPTION 'Email address is invalid';
    END IF;

    -- Проверка, что пользователю больше 18 лет (дата рождения)
    IF NEW.date_of_birth > CURRENT_DATE - INTERVAL '18 years' THEN
        RAISE EXCEPTION 'User must be at least 18 years old';
    END IF;

    IF LENGTH(NEW.password) > 100 THEN
        RAISE EXCEPTION 'Password length exceeds 100 characters';
    END IF;

    -- Если все проверки пройдены успешно, данные вставляются в таблицу users
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION user_registration(
    given_name VARCHAR, surname VARCHAR,
    passport_no VARCHAR, identification_no VARCHAR,
    license_no VARCHAR, telephone_no VARCHAR,
    email VARCHAR, date_of_birth DATE,
    password VARCHAR, avatar_url VARCHAR
) RETURNS INTEGER AS $$
DECLARE
    user_id INTEGER;
BEGIN
    INSERT INTO users (
        given_name, surname, 
        passport_no, identification_no, 
        license_no, telephone_no, 
        email, date_of_birth, 
        password, avatar_url
    ) 
    VALUES (
        given_name, surname, 
        passport_no, identification_no, 
        license_no, telephone_no, 
        email, date_of_birth, 
        password, avatar_url
    )
    RETURNING id INTO user_id;

    RETURN user_id;
END;
$$ LANGUAGE plpgsql;


-- Назначение триггера для запуска функции перед вставкой данных в таблицу users
CREATE TRIGGER trigger_validate_user_register
BEFORE INSERT ON users
FOR EACH ROW EXECUTE FUNCTION validate_user_register();


CREATE OR REPLACE PROCEDURE user_login(IN email_to_check VARCHAR, IN password_to_check VARCHAR) AS $$
DECLARE
    user_status ACTIVITY_STATUS_TYPE;
BEGIN
    -- Проверка на соответствие адреса электронной почты формату
    IF email_to_check ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$' THEN
        SELECT status INTO user_status FROM users WHERE email = email_to_check;

        IF FOUND THEN
            IF user_status = 'active' THEN
                -- Пользователь уже активен
                RAISE EXCEPTION 'User is already active';
            ELSE
                IF EXISTS (SELECT 1 FROM users WHERE email = email_to_check AND password = password_to_check) THEN
                    -- Меняем статус на 'active', если пользователь неактивен
                    UPDATE users SET status = 'active' WHERE email = email_to_check;
                    RAISE NOTICE 'Login successful! User status changed from inactive to active';
                ELSE
                    -- Пользователь существует, но пароль неверен
                    RAISE EXCEPTION 'Incorrect password';
                END IF;
            END IF;
        ELSE
            -- Пользователя с указанным email не существует
            RAISE EXCEPTION 'User with email % does not exist', email_to_check;
        END IF;
    ELSE
        -- Некорректный формат email
        RAISE EXCEPTION 'Invalid email format';
    END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE user_logout(IN user_id INT, IN choice BOOLEAN) AS $$
DECLARE
    user_status ACTIVITY_STATUS_TYPE;
BEGIN
    IF choice THEN
        SELECT status INTO user_status FROM users WHERE id = user_id;

        IF FOUND THEN
            IF user_status = 'active' THEN
                -- Меняем статус на 'inactive', если пользователь активен
                UPDATE users SET status = 'inactive' WHERE id = user_id;
                RAISE NOTICE 'User status changed from active to inactive';
            ELSE
                -- Пользователь неактивен, ничего не меняем
                RAISE EXCEPTION 'User is already inactive';
            END IF;
        ELSE
            -- Пользователя с указанным ID не существует
            RAISE EXCEPTION 'User with such id % does not exist', user_id;
        END IF;
    ELSE
        -- Выбор пользователя не подтверждён (choice = False)
        RAISE EXCEPTION 'User choice not confirmed';
    END IF;
END;
$$ LANGUAGE plpgsql;
