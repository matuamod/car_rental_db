from typing import Optional
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
    avatar_url: Optional[str] = "https://www.shareicon.net/data/512x512/2015/10/05/651222_man_512x512.png"
    
    
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