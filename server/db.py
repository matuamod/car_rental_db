import psycopg2
from psycopg2 import OperationalError


class DatabaseHandler(object):
    
    def __init__(self, db_name, db_user, db_password, db_host, db_port):
        self.db_name = db_name
        self.db_user = db_user
        self.db_password = db_password
        self.db_host = db_host
        self.db_port = db_port
        self.connection = self.__create_db_connection()
        self.__init_db()
        
        
    def __create_db_connection(self):
        connection = None
        print("==========================================")
        try:
            connection = psycopg2.connect(
                database = self.db_name,
                user = self.db_user,
                password = self.db_password,
                host = self.db_host,
                port = self.db_port,
            )
            print("Connection to PostgreSQL DB successful")
        except OperationalError as e:
            print(f"The error '{e}' occurred")
        print("==========================================")
        return connection
    
    
    def raw_sql(self, query, params=None):
        cursor = self.connection.cursor()
        try:
            cursor.execute(query, params)
            self.connection.commit()
            return cursor
        except OperationalError as e:
            return None, e
    
    
    def __init_db(self):
        self.raw_sql(open("server/sql/init_db.sql", "r").read())