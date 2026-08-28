"""
Livello di accesso al database MySQL tramite PyMySQL.

Espone poche funzioni di utilita' (get_db, query_all, query_one, execute)
usate dalle route Flask in app.py. La connessione viene aperta una sola
volta per ogni richiesta HTTP e chiusa automaticamente alla fine (vedi
teardown_appcontext in app.py).
"""

import pymysql
import pymysql.cursors
from flask import g

import config


def get_db():
    """Restituisce la connessione MySQL della richiesta corrente,
    creandola se non esiste ancora."""
    if "db" not in g:
        g.db = pymysql.connect(
            host=config.MYSQL_HOST,
            port=config.MYSQL_PORT,
            user=config.MYSQL_USER,
            password=config.MYSQL_PASSWORD,
            database=config.MYSQL_DB,
            charset="utf8mb4",
            cursorclass=pymysql.cursors.DictCursor,
            autocommit=False,
        )
    return g.db


def close_db(e=None):
    """Chiude la connessione al termine della richiesta, se aperta."""
    db = g.pop("db", None)
    if db is not None:
        db.close()


def query_all(sql, params=None):
    """Esegue una SELECT e restituisce tutte le righe come lista di dict."""
    conn = get_db()
    with conn.cursor() as cur:
        cur.execute(sql, params or ())
        return cur.fetchall()


def query_one(sql, params=None):
    """Esegue una SELECT e restituisce la prima riga (o None)."""
    conn = get_db()
    with conn.cursor() as cur:
        cur.execute(sql, params or ())
        return cur.fetchone()


def execute(sql, params=None):
    """Esegue INSERT/UPDATE/DELETE, fa il commit e restituisce
    l'id dell'ultima riga inserita (utile per le INSERT) e il numero
    di righe modificate."""
    conn = get_db()
    with conn.cursor() as cur:
        cur.execute(sql, params or ())
        conn.commit()
        return cur.lastrowid, cur.rowcount


def init_app(app):
    """Registra la chiusura della connessione alla fine di ogni richiesta."""
    app.teardown_appcontext(close_db)
