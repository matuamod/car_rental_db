import os
import json
import psycopg2
from fastapi import status
from server.db import DatabaseHandler
from server.models import Role, UserRegister, UserLogin, EditUser, AddCar, UpdateCar, RentalDeal


class ServiceHandler(object):
    
    def __init__(self):
        self.db_handler = DatabaseHandler(
            db_user=os.getenv("PG_USER"),
            db_password=os.getenv("PG_PASSWORD"),
            db_name=os.getenv("PG_DB"),
            db_host="172.23.0.2",
            db_port=os.getenv("PG_PORT"),
        )
        
    
    def __row_to_entity(self, row, pydantic_model):
        return pydantic_model(**{
            key: row[i] for i, key in enumerate(pydantic_model.__fields__.keys())
        })


    def __cursor_to_entities(self, cursor, pydantic_model):
        entities = []
        
        for row in cursor:
            entity = self.__row_to_entity(row, pydantic_model)
            entities.append(entity)
        return entities


    def get_all_roles(self):
        result = self.db_handler.raw_sql("""SELECT name, permission FROM roles;""")
        roles = self.__cursor_to_entities(result, Role)
        return roles, status.HTTP_200_OK
    
    
    def register(self, user_register: UserRegister):
        try:
            result = self.db_handler.raw_sql(
            """
                SELECT user_registration(
                    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
                );
            """, (
                user_register.given_name, user_register.surname, 
                user_register.passport_no, user_register.identification_no, 
                user_register.license_no, user_register.telephone_no,
                user_register.email, user_register.date_of_birth, 
                user_register.password, user_register.avatar_url
                )
            )
        except psycopg2.Error as e:
            self.db_handler.connection.rollback()
            return f"Cannot register: {e}".split('\n')[0], status.HTTP_400_BAD_REQUEST
        else:
            self.db_handler.connection.commit()
            return {"id": result.fetchone()[0]}, status.HTTP_200_OK
    
    
    def login(self, user_login: UserLogin):
        try:
            _ = self.db_handler.raw_sql(
            """
                CALL user_login(%s, %s);
            """, (user_login.email, user_login.password)
            )
        except psycopg2.Error as e:
            self.db_handler.connection.rollback()
            return f"Cannot login: {e}".split('\n')[0], status.HTTP_400_BAD_REQUEST
        else:
            self.db_handler.connection.commit()
            return "Successful login!", status.HTTP_200_OK
        
        
    def logout(self, user_id: int, choice: bool):
        try:
            _ = self.db_handler.raw_sql(
            """
                CALL user_logout(%s, %s);
            """, (user_id, choice)
            )
        except psycopg2.Error as e:
            self.db_handler.connection.rollback()
            return f"Cannot logout: {e}".split('\n')[0], status.HTTP_400_BAD_REQUEST
        else:
            self.db_handler.connection.commit()
            return "Successful logout!", status.HTTP_200_OK
        
        
    def user_profile(self, user_id: int):
        try:
            result = self.db_handler.raw_sql(
            """
                SELECT user_profile(%s);
            """, (user_id,)
            )
        except psycopg2.Error as e:
            self.db_handler.connection.rollback()
            return f"Cannot get user profile: {e}".split('\n')[0], status.HTTP_400_BAD_REQUEST
        else:
            self.db_handler.connection.commit()
            
            data_string = result.fetchone()[0]
            data_list = list(map(lambda x: x.replace('\"', ''), data_string[1:-1].split(',')))

            formatted_data = {
                "given_name": data_list[0],
                "surname": data_list[1],
                "passport_no": data_list[2],
                "identification_no": data_list[3],
                "license_no": data_list[4],
                "telephone_no": data_list[5],
                "email": data_list[6],
                "date_of_birth": data_list[7],
                "password": data_list[8],
                "is_owner": data_list[9],
                "avatar_url": data_list[10],
                "status": data_list[11],
                "role_name": data_list[12],
                "role_permission": data_list[13]
            }
            
            json_data = json.dumps(formatted_data, indent=2)
            
            return json_data, status.HTTP_200_OK
        
        
    def edit_profile(self, user_id: int, edit_user: EditUser):
        try:
            _ = self.db_handler.raw_sql(
            """
                CALL edit_profile(%s, %s, %s, %s);
            """, (
                user_id, edit_user.old_password, 
                edit_user.new_password, edit_user.new_avatar_url
                )
            )
        except psycopg2.Error as e:
            self.db_handler.connection.rollback()
            return f"Cannot edit profile: {e}".split('\n')[0], status.HTTP_400_BAD_REQUEST
        else:
            self.db_handler.connection.commit()
            return "Successful editing!", status.HTTP_200_OK
        
        
    def add_car(self, user_id: int, car: AddCar):
        try:
            result = self.db_handler.raw_sql(
            """
                SELECT add_car(
                    %s, %s, %s, %s, %s, %s, %s, %s,
                    ARRAY[%s]::VARCHAR[]
                ) AS id;
            """, (
                user_id, car.type_name,
                car.brand, car.model,
                car.fuel_type, car.registration_plate,
                car.price_per_day, car.description,
                car.images
                )
            )
        except psycopg2.Error as e:
            self.db_handler.connection.rollback()
            return f"Cannot add car: {e}".split('\n')[0], status.HTTP_400_BAD_REQUEST
        else:
            self.db_handler.connection.commit()
            return {"id": result.fetchone()[0]}, status.HTTP_200_OK
        
    
    def delete_car(self, user_id: int, car_id: int):
        try:
            _ = self.db_handler.raw_sql(
            """
                CALL delete_car(%s, %s);
            """, (user_id, car_id)
            )
        except psycopg2.Error as e:
            self.db_handler.connection.rollback()
            return f"Cannot delete car: {e}".split('\n')[0], status.HTTP_400_BAD_REQUEST
        else:
            self.db_handler.connection.commit()
            return "Successful deliting!", status.HTTP_200_OK
        
        
    def update_car(self, user_id: int, car_id: int, update_car: UpdateCar):
        try:
            _ = self.db_handler.raw_sql(
            """
                CALL update_car(%s, %s, %s, %s);
            """, (
                user_id, car_id, 
                update_car.new_price_per_day, update_car.new_description
                )
            )
        except psycopg2.Error as e:
            self.db_handler.connection.rollback()
            return f"Cannot update car: {e}".split('\n')[0], status.HTTP_400_BAD_REQUEST
        else:
            self.db_handler.connection.commit()
            return "Successful updating!", status.HTTP_200_OK
        
        
    def get_available_cars(self):
        try:
            result = self.db_handler.raw_sql(
            """
                SELECT get_available_cars();
            """
            )
        except psycopg2.Error as e:
            self.db_handler.connection.rollback()
            return f"Cannot get available cars: {e}".split('\n')[0], status.HTTP_400_BAD_REQUEST
        else:
            self.db_handler.connection.commit()
            
            data = result.fetchall()
            
            parsed_data = []
            for item in data:
                item_data = item[0].strip('()').split(',')
                parsed_data.append({
                    'car_id': int(item_data[0]),
                    'type_name': item_data[1],
                    'brand': item_data[2],
                    'model': item_data[3],
                    'fuel_type': item_data[4],
                    'price_per_day': float(item_data[5]),
                    'main_image_url': item_data[6]
                })

            json_data = json.dumps(parsed_data, indent=2)
            
            return json_data, status.HTTP_200_OK
        
        
    def get_available_car(self, car_id: int):
        try:
            result = self.db_handler.raw_sql(
            """
                SELECT get_available_car(%s);
            """, (car_id,)
            )
        except psycopg2.Error as e:
            self.db_handler.connection.rollback()
            return f"Cannot get available car: {e}".split('\n')[0], status.HTTP_400_BAD_REQUEST
        else:
            self.db_handler.connection.commit()
            
            data_string = result.fetchone()[0]
            data_string = data_string[1:-1]

            split_data = []
            current = ''
            quoted = False

            for char in data_string:
                if char == ',' and not quoted:
                    split_data.append(current)
                    current = ''
                elif char == '"':
                    quoted = not quoted
                    current += char
                else:
                    current += char

            split_data.append(current) 
            split_data = [item.replace('"', '') for item in split_data]

            car_data = {
                "type_name": split_data[0],
                "brand": split_data[1],
                "model": split_data[2],
                "fuel_type": split_data[3],
                "registration_plate": split_data[4],
                "price_per_day": float(split_data[5]),
                "description": split_data[6],
                "images": split_data[7][1:-1].split(','),  # Преобразуем в список из одного элемента
                "given_name": split_data[8],
                "telephone_no": split_data[9]
            }

            # Преобразуем в JSON
            json_data = json.dumps(car_data, indent=2)
            
            return json_data, status.HTTP_200_OK
        
        
    def make_review(self, user_id: int, car_id: int, message: str):
        try:
            result = self.db_handler.raw_sql(
            """
                SELECT make_review(
                    %s, %s, %s
                ) AS id;
            """, (
                user_id, car_id, message
                )
            )
        except psycopg2.Error as e:
            self.db_handler.connection.rollback()
            return f"Cannot make review: {e}".split('\n')[0], status.HTTP_400_BAD_REQUEST
        else:
            self.db_handler.connection.commit()
            return {"id": result.fetchone()[0]}, status.HTTP_200_OK
        
        
    def get_reviews(self, car_id: int):
        try:
            result = self.db_handler.raw_sql(
            """
                SELECT get_reviews(%s);
            """, (car_id,)
            )
        except psycopg2.Error as e:
            self.db_handler.connection.rollback()
            return f"Cannot get reviews: {e}".split('\n')[0], status.HTTP_400_BAD_REQUEST
        else:
            self.db_handler.connection.commit()
            
            data = result.fetchall()
            
            parsed_data = []
            for item in data:
                item_data = item[0].strip('()').split(',')
                parsed_data.append({
                    'given_name': item_data[0],
                    'message': item_data[1]
                })

            json_data = json.dumps(parsed_data, indent=2)
            
            return json_data, status.HTTP_200_OK
        
    
    def add_to_favourites(self, user_id: int, car_id: int):
        try:
            result = self.db_handler.raw_sql(
            """
                SELECT add_to_favourites(
                    %s, %s
                ) AS id;
            """, (user_id, car_id)
            )
        except psycopg2.Error as e:
            self.db_handler.connection.rollback()
            return f"Cannot add to favourites: {e}".split('\n')[0], status.HTTP_400_BAD_REQUEST
        else:
            self.db_handler.connection.commit()
            return {"id": result.fetchone()[0]}, status.HTTP_200_OK
        
        
    def get_favourites(self, user_id: int):
        try:
            result = self.db_handler.raw_sql(
            """
                SELECT get_favourites(%s);
            """, (user_id,)
            )
        except psycopg2.Error as e:
            self.db_handler.connection.rollback()
            return f"Cannot get favourite cars: {e}".split('\n')[0], status.HTTP_400_BAD_REQUEST
        else:
            self.db_handler.connection.commit()
            
            data = result.fetchall()
            
            parsed_data = []
            for item in data:
                item_data = item[0].strip('()').split(',')
                parsed_data.append({
                    'car_id': int(item_data[0]),
                    'type_name': item_data[1],
                    'brand': item_data[2],
                    'model': item_data[3],
                    'fuel_type': item_data[4],
                    'price_per_day': float(item_data[5]),
                    'main_image_url': item_data[6]
                })

            json_data = json.dumps(parsed_data, indent=2)
            
            return json_data, status.HTTP_200_OK
        
        
    def make_rent(self, user_id, car_id, rental_deal: RentalDeal):
        try:
            result = self.db_handler.raw_sql(
            """
                SELECT make_rent(%s, %s, %s, %s, %s, %s);
            """, (
                user_id, car_id, rental_deal.start_location, rental_deal.end_location,
                rental_deal.start_date, rental_deal.end_date
                )
            )
        except psycopg2.Error as e:
            self.db_handler.connection.rollback()
            return f"Cannot add to favourites: {e}".split('\n')[0], status.HTTP_400_BAD_REQUEST
        else:
            self.db_handler.connection.commit()
            return {"id": result.fetchone()[0]}, status.HTTP_200_OK