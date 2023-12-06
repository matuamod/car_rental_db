import os
from .db import DatabaseHandler


db = DatabaseHandler(
    db_user=os.getenv("PG_USER"),
    db_password=os.getenv("PG_PASSWORD"),
    db_name=os.getenv("PG_DB"),
    db_host="172.21.0.2",
    db_port=os.getenv("PG_PORT"),
    )