import json
from fastapi import FastAPI, status, HTTPException
from typing import List
from server.services import ServiceHandler
from server.models import UserRegister, UserLogin, UserProfile, EditUser, AddCar

app = FastAPI(
    title="Car Rental App"
)

serv_handler = ServiceHandler()


@app.get("/roles")
def get_all_roles():
    data, status_code  = serv_handler.get_all_roles()
    
    if status_code != status.HTTP_200_OK:
        raise HTTPException(status_code=status_code, detail=data)
    return data


@app.post("/register")
def register(user_register: UserRegister):
    data, stat_code = serv_handler.register(user_register)
    
    if stat_code != status.HTTP_200_OK:
        raise HTTPException(status_code=stat_code, detail=data)
    return data


@app.put("/login")
def login(user_login: UserLogin):
    data, stat_code  = serv_handler.login(user_login)
    
    if stat_code != status.HTTP_200_OK:
        raise HTTPException(status_code=stat_code, detail=data)
    return data


@app.put("/user/{user_id}/logout")
def logout(user_id: int, choice: bool = True):
    data, stat_code  = serv_handler.logout(user_id, choice)
    
    if stat_code != status.HTTP_200_OK:
        raise HTTPException(status_code=stat_code, detail=data)
    return data


@app.get("/user/{user_id}/profile", response_model=UserProfile)
def user_profile(user_id: int):
    json_data, stat_code  = serv_handler.user_profile(user_id)
    
    if stat_code != status.HTTP_200_OK:
        raise HTTPException(status_code=stat_code, detail=json_data)
    
    data_dict = json.loads(json_data)
    user_profile_data = UserProfile(**data_dict)
    return user_profile_data


@app.put("/user/{user_id}/profile/edit")
def edit_profile(user_id: int, edit_user: EditUser):
    data, stat_code = serv_handler.edit_profile(user_id, edit_user)
    
    if stat_code != status.HTTP_200_OK:
        raise HTTPException(status_code=stat_code, detail=data)
    return data


@app.post("/user/{user_id}/add_car")
def add_car(user_id: int, car: AddCar):
    data, stat_code = serv_handler.add_car(user_id, car)
    
    if stat_code != status.HTTP_200_OK:
        raise HTTPException(status_code=stat_code, detail=data)
    return data


@app.delete("/user/{user_id}/delete_car/{car_id}")
def delete_car(user_id: int, car_id: int):
    pass


@app.get("/car/{car_id}")
def get_car(car_id: int):
    pass

