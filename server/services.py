import os
import json
import psycopg2
from fastapi import status
from server.db import DatabaseHandler
from server.models import Role, UserRegister, UserLogin, EditUser, AddCar


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
                ) AS id;
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
                SELECT user_profile(%s) AS profile;
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
                    %s, %s, %s, %s, %s, %s, %s, %s
                ) AS id;
            """, (
                user_id, car.type_name,
                car.brand, car.model,
                car.fuel_type, car.registration_plate,
                car.price_per_day, car.description
                )
            )
        except psycopg2.Error as e:
            self.db_handler.connection.rollback()
            return f"Cannot add car: {e}".split('\n')[0], status.HTTP_400_BAD_REQUEST
        else:
            self.db_handler.connection.commit()
            return {"id": result.fetchone()[0]}, status.HTTP_200_OK