import json
from fastapi import FastAPI, status, HTTPException
from typing import List
from server.services import ServiceHandler
from server.models import UserRegister, UserLogin, UserProfile, EditUser, AddCar, Cars, CurrentCar

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
    data, stat_code = serv_handler.delete_car(user_id, car_id)
    
    if stat_code != status.HTTP_200_OK:
        raise HTTPException(status_code=stat_code, detail=data)
    return data


@app.put("/user/{user_id}/update_car/{car_id}")
def update_car(user_id: int, car_id: int):
    pass


@app.get("/cars", response_model=List[Cars])
def get_cars():
    json_data, stat_code = serv_handler.get_available_cars()
    
    if stat_code != status.HTTP_200_OK:
        raise HTTPException(status_code=stat_code, detail=json_data)
    
    data_dict = json.loads(json_data)
    available_cars_data = [Cars(**car_data) for car_data in data_dict]
    return available_cars_data


@app.get("/cars/{car_id}", response_model=CurrentCar)
def get_car(car_id: int):
    json_data, stat_code  = serv_handler.get_available_car(car_id)
    
    if stat_code != status.HTTP_200_OK:
        raise HTTPException(status_code=stat_code, detail=json_data)
    
    data_dict = json.loads(json_data)
    available_car_data = CurrentCar(**data_dict)
    return available_car_data


@app.post("/cars/{car_id}/make_review")
def make_review(car_id: int):
    pass


@app.post("/cars/{car_id}/add_to_favourites")
def add_to_favourites(car_id: int):
    pass


@app.post("/cars/{car_id}/make_rent")
def make_rent(car_id: int):
    pass


@app.post("/user/{user_id}/profile/payment_history")
def get_payment_history(user_id: int):
    pass