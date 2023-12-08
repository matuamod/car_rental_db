from fastapi import FastAPI, status, HTTPException
from pydantic import BaseModel
from typing import List
from server.services import ServiceHandler
from server.models import UserRegister, UserLogin

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
    return {"data": data}


@app.put("/login")
def login(user_login: UserLogin):
    data, stat_code  = serv_handler.login(user_login)
    if stat_code != status.HTTP_200_OK:
        raise HTTPException(status_code=stat_code, detail=data)
    return {"data": data}


@app.put("/user/{user_id}/logout")
def logout(user_id: int, choice: bool = True):
    data, stat_code  = serv_handler.logout(user_id, choice)
    if stat_code != status.HTTP_200_OK:
        raise HTTPException(status_code=stat_code, status=stat_code, detail=data)
    return {"data": data}


# fake_users = [
#     {"id": 1, "role": "admin", "name": "Bob"},
#     {"id": 2, "role": "user", "name": "Dima"},
#     {"id": 3, "role": "owner", "name": "Matvey"},
# ]


# class User(BaseModel):
#     id: int
#     role: str
#     name: str


# @app.get("/users/{user_id}", response_model=List[User])
# async def get_user(user_id: int):
#     return [user for user in fake_users if user.get("id") == user_id]


# fake_trades = [
#     {"id": 1, "user_id": 1, "currency": "BTC", "side": "buy", "price": 123, "amount": 2.12},
#     {"id": 2, "user_id": 1, "currency": "BTC", "side": "sell", "price": 125, "amount": 2.12},
# ]


# @app.get("/trades")
# def get_trades(limit: int = 1, offset: int = 0):
#     return fake_trades[offset:][:limit]


# fake_users2 = [
#     {"id": 1, "role": "admin", "name": "Bob"},
#     {"id": 2, "role": "user", "name": "Dima"},
#     {"id": 3, "role": "owner", "name": "Matvey"},
# ]


# @app.post("/users/{user_id}")
# def change_user_name(user_id: int, new_name: str):
#     current_user = list(filter(lambda user: user.get("id") == user_id, fake_users2))[0]
#     current_user["name"] = new_name
#     return {"status": 200, "data": current_user}


# class Trade(BaseModel):
#     id: int
#     user_id: int
#     currency: str
#     side: str
#     price: float
#     amount: float


# @app.post("/trades")
# def add_trades(trades: List[Trade]):
#     fake_trades.extend(trades)
#     return {"status": 200, "data": fake_trades}
