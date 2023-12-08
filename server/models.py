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
    
    
