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
DROP TYPE IF EXISTS ACTIVITY_STATUS_TYPE CASCADE;
DROP TYPE IF EXISTS CAR_TYPE CASCADE;
DROP TYPE IF EXISTS CAR_BRAND CASCADE;
DROP TYPE IF EXISTS FUEL_TYPE CASCADE;


CREATE TYPE ACTIVITY_STATUS_TYPE AS ENUM (
    'active', 'inactive'
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


CREATE TYPE CAR_TYPE AS ENUM (
    'sedan', 'station wagon', 'coupe',
    'hatchback', 'SUV', 'convertible',
    'minivan', 'pickup', 'van'
);


CREATE TABLE IF NOT EXISTS car_types (
    id SERIAL PRIMARY KEY NOT NULL UNIQUE,
    type_name CAR_TYPE NOT NULL
);


CREATE TYPE CAR_BRAND AS ENUM (
    'Toyota', 'Volkswagen', 'Ford',
    'Chevrolet', 'Nissan', 'Honda',
    'BMW', 'Mercedes-Benz', 'Audi',
    'Hyundai', 'Kia', 'Volvo',
    'Tesla', 'Subaru', 'Mazda',
    'Fiat', 'Peugeot', 'Renault',
    'Skoda', 'Land Rover', 'Jeep',
    'Lexus', 'Mitsubishi', 'Mini',
    'Porsche', 'Suzuki', 'Chrysler',
    'Acura', 'Infiniti', 'Jaguar'
);


CREATE TABLE IF NOT EXISTS brands (
    id SERIAL PRIMARY KEY NOT NULL UNIQUE,
    name CAR_BRAND NOT NULL,
    model VARCHAR(50) NOT NULL
);


CREATE TYPE FUEL_TYPE AS ENUM (
    'gasoline', 'diesel', 'electric', 'hybrid'
);


CREATE TABLE IF NOT EXISTS fuel_types (
    id SERIAL PRIMARY KEY NOT NULL UNIQUE,
    type_name FUEL_TYPE NOT NULL
);


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
) RETURNS INT AS $$
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
                    UPDATE users SET status = 'active', role_id = 2 WHERE email = email_to_check;
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
                UPDATE users SET status = 'inactive', role_id = 1 WHERE id = user_id;
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


CREATE OR REPLACE PROCEDURE check_user_status(user_id INT) AS $$
DECLARE
    user_exists BOOLEAN;
    user_status ACTIVITY_STATUS_TYPE;
BEGIN
    SELECT EXISTS(SELECT 1 FROM users WHERE id = user_id) INTO user_exists;

    IF NOT user_exists THEN
        RAISE EXCEPTION 'User with id % does not exist', user_id;
    END IF;

    SELECT status INTO user_status FROM users WHERE id = user_id;

    IF user_status = 'inactive' THEN
        RAISE EXCEPTION 'User is inactive';
    END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION user_profile(user_id INT) RETURNS TABLE (
    given_name VARCHAR, surname VARCHAR,
    passport_no VARCHAR, identification_no VARCHAR,
    license_no VARCHAR, telephone_no VARCHAR,
    email VARCHAR, date_of_birth DATE,
    password VARCHAR, is_owner BOOLEAN,
    avatar_url VARCHAR, status ACTIVITY_STATUS_TYPE,
    role_name VARCHAR, permission VARCHAR
) AS $$
BEGIN
    CALL check_user_status(user_id);

    RETURN QUERY
    SELECT
        users.given_name, users.surname,
        users.passport_no, users.identification_no,
        users.license_no, users.telephone_no,
        users.email, users.date_of_birth,
        users.password, users.is_owner,
        users.avatar_url, users.status,
        roles.name AS role_name, roles.permission
    FROM
        users 
    LEFT JOIN
        roles ON users.role_id = roles.id
    WHERE
        users.id = user_id;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE edit_profile(user_id INT, old_password VARCHAR, new_password VARCHAR, new_avatar_url VARCHAR) AS $$
DECLARE
    user_status ACTIVITY_STATUS_TYPE;
    current_password VARCHAR;
BEGIN
    CALL check_user_status(user_id);

    SELECT password INTO current_password FROM users WHERE id = user_id;

    IF old_password <> current_password THEN
        RAISE EXCEPTION 'Old password is incorrect';
    END IF;

    IF new_password <> 'string' THEN
        UPDATE users SET password = new_password WHERE id = user_id;
    END IF;

    IF new_avatar_url <> 'string' THEN
        UPDATE users SET avatar_url = new_avatar_url WHERE id = user_id;
    END IF;

    IF new_password = 'string' AND new_avatar_url = 'string' THEN
        RAISE EXCEPTION 'Both new password and new avatar cannot be clear, nothing to edit';
    END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE validate_add_car(
    user_id INT, type_name CAR_TYPE,
    brand CAR_BRAND, model VARCHAR,
    fuel_type FUEL_TYPE, registration_plate VARCHAR,
    price_per_day NUMERIC, description VARCHAR
) AS $$
BEGIN
    CALL check_user_status(user_id);

    IF LENGTH(model) > 50 THEN
        RAISE EXCEPTION 'Brands model length should not exceed 50 characters.';
    END IF;
    
    IF NOT (registration_plate ~ '^[0-9]{4} [A-Z]{2}-[0-9]{1}$') THEN
        RAISE EXCEPTION 'Invalid registration plate format. Example: 1234 AB-1';
    END IF;

    IF price_per_day <= 0 THEN
        RAISE EXCEPTION 'Price per day should be a positive number.';
    END IF;

    IF LENGTH(description) > 500 THEN
        RAISE EXCEPTION 'Cars description length should not exceed 500 characters.';
    END IF;

END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION create_car_type(
    car_type_name CAR_TYPE
) RETURNS INT AS $$
DECLARE
    car_type_id INT;
BEGIN
    SELECT id INTO car_type_id FROM car_types WHERE type_name = car_type_name LIMIT 1;

    IF FOUND THEN
        RETURN car_type_id;
    ELSE
        INSERT INTO car_types (type_name) VALUES (car_type_name) RETURNING id INTO car_type_id;
        RETURN car_type_id;
    END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION create_brand(
    car_name CAR_BRAND,
    car_model VARCHAR
) RETURNS INT AS $$
DECLARE
    brand_id INT;
BEGIN
    SELECT id INTO brand_id FROM brands WHERE name = car_name AND model = car_model LIMIT 1;

    IF FOUND THEN
        RETURN brand_id;
    ELSE
        INSERT INTO brands (name, model) VALUES (car_name, car_model) RETURNING id INTO brand_id;
        RETURN brand_id;
    END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION create_fuel_type(
    car_fuel_type FUEL_TYPE
) RETURNS INT AS $$
DECLARE
    fuel_type_id INT;
BEGIN
    SELECT id INTO fuel_type_id FROM fuel_types WHERE type_name = car_fuel_type LIMIT 1;

    IF FOUND THEN
        RETURN fuel_type_id;
    ELSE
        INSERT INTO fuel_types (type_name) VALUES (car_fuel_type) RETURNING id INTO fuel_type_id;
        RETURN fuel_type_id;
    END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION add_car(
    user_id INT, type_name CAR_TYPE, 
    brand CAR_BRAND, model VARCHAR, 
    fuel_type FUEL_TYPE, registration_plate VARCHAR, 
    price_per_day NUMERIC, description VARCHAR
) RETURNS INT AS $$
DECLARE
    car_type_id INT;
    brand_id INT;
    fuel_type_id INT;
BEGIN
    CALL validate_add_car(
        user_id, type_name, 
        brand, model, 
        fuel_type, registration_plate, 
        price_per_day, description
    );

    PERFORM create_car_type(type_name) AS car_type_id;
    PERFORM create_brand(brand, model) AS brand_id;
    PERFORM create_fuel_type(fuel_type) AS fuel_type_id;

    INSERT INTO cars (
        owner_id, car_type_id, 
        brand_id, fuel_type_id, 
        registration_plate, 
        price_per_day, description
        ) 
    VALUES (
        user_id, car_type_id, 
        brand_id, fuel_type_id, 
        registration_plate, 
        price_per_day, description
        );

    RETURN user_id;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION update_owner_status()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = NEW.owner_id AND is_owner = TRUE) THEN
        UPDATE users SET is_owner = TRUE WHERE id = NEW.owner_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_owner_status
AFTER INSERT ON cars
FOR EACH ROW
EXECUTE FUNCTION update_owner_status();
