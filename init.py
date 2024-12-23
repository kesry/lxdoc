#!/bin/python3

import os
import sqlite3

db_path=os.getenv("DB_PATH")
db_script=os.getenv("DB_INIT_SQL_PATH")

if db_path is None or db_path == "":
    db_path = "/target/lx_doc.db"

if db_script is None or db_script == "":
    db_script = "/source/init.sql"


if __name__ == "__main__":
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    with open(db_script, mode="r") as f:
        cursor.executescript(f.read())
    cursor.close()
    conn.close()
    
