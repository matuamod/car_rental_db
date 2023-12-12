from typing import Optional, List
from pydantic import BaseModel
from datetime import date


class Role(BaseModel):
    name: str
    permission: str
    
    
class UserRegister(BaseModel):
    given_name: str
    surname: str
    passport_no: str
    identification_no: str
    license_no: str
    telephone_no: str
    email: str
    date_of_birth: date
    password: str
    avatar_url: Optional[str] = "Basic avatar image url"
    
    
class UserLogin(BaseModel):
    email: str
    password: str
    
    
class UserProfile(BaseModel):
    given_name: str
    surname: str
    passport_no: str
    identification_no: str
    license_no: str
    telephone_no: str
    email: str
    date_of_birth: date
    password: str
    is_owner: bool
    avatar_url: str
    status: str
    role_name: str
    role_permission: str
    
    
class EditUser(BaseModel):
    old_password: str
    new_password: str
    new_avatar_url: str
    
    
class AddCar(BaseModel):
    type_name: str
    brand: str
    model: str
    fuel_type: str
    registration_plate: str
    price_per_day: float
    description: str
    images: List[str] = ["Basic car image url"]
    
    
class Cars(BaseModel):
    car_id: int
    type_name: str
    brand: str
    model: str
    fuel_type: str
    price_per_day: float
    main_image_url: str
    
    
class CurrentCar(BaseModel):
    type_name: str
    brand: str
    model: str
    fuel_type: str
    registration_plate: str
    price_per_day: float
    description: str
    images: List[str]
    given_name: str
    telephone_no: str