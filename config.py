"""
Configurazione dell'applicazione.

Le credenziali vengono lette prima dalle variabili d'ambiente (comodo per lo
sviluppo locale o per chi vuole impostarle nel file WSGI di PythonAnywhere) e,
in mancanza, dai valori di default scritti qui sotto: modifica direttamente
questi valori con quelli del tuo account PythonAnywhere.

Su PythonAnywhere, nella scheda "Databases":
- MYSQL_HOST e' di solito       "<tuo-username>.mysql.pythonanywhere-services.com"
- MYSQL_DB (nome del database)  di solito   "<tuo-username>$diario_alimentare"
- MYSQL_USER                     e' il tuo username PythonAnywhere
- MYSQL_PASSWORD                 la password del database MySQL (impostata da te
                                  nella scheda Databases, puo' essere diversa da
                                  quella di login al sito)
"""

import os

MYSQL_HOST = os.environ.get("MYSQL_HOST", "localhost")
MYSQL_USER = os.environ.get("MYSQL_USER", "root")
MYSQL_PASSWORD = os.environ.get("MYSQL_PASSWORD", "password")
MYSQL_DB = os.environ.get("MYSQL_DB", "diario_alimentare")
MYSQL_PORT = int(os.environ.get("MYSQL_PORT", "3306"))

# Chiave segreta usata da Flask per le sessioni e la protezione CSRF.
# In produzione impostala tramite la variabile d'ambiente SECRET_KEY.
SECRET_KEY = os.environ.get("SECRET_KEY", "cambia-questa-chiave-in-produzione")

# Numero di righe per pagina nell'elenco alimenti
PAGE_SIZE = int(os.environ.get("PAGE_SIZE", "25"))

# ---------------------------------------------------------------------------
# Accesso amministratore
#
# Le operazioni di creazione, modifica ed eliminazione richiedono il login.
# La consultazione dell'elenco e delle schede resta invece pubblica.
#
# Credenziali di DEFAULT (DA CAMBIARE prima di andare online):
#     utente:    admin
#     password:  cambiami123
#
# Per impostare una password personalizzata genera un nuovo hash con:
#     python3 -c "from werkzeug.security import generate_password_hash; \
#         print(generate_password_hash('LA_TUA_PASSWORD', method='pbkdf2:sha256'))"
# e incolla il risultato in ADMIN_PASSWORD_HASH (oppure nella variabile
# d'ambiente ADMIN_PASSWORD_HASH, ad esempio nel file WSGI).
# ---------------------------------------------------------------------------
ADMIN_USERNAME = os.environ.get("ADMIN_USERNAME", "admin")
ADMIN_PASSWORD_HASH = os.environ.get(
    "ADMIN_PASSWORD_HASH",
    "pbkdf2:sha256:1000000$snqU8Yms6N9ZME8C$ac785e44bf68b8f987272f4fcb9efa5a1d0ad16bfef6d0ffc2ffa99ce3307b74",
)

# ---------------------------------------------------------------------------
# CORS (Cross-Origin Resource Sharing)
#
# La modalita' consigliata (vedi README_API.md) e' servire il front-end
# statico dalla STESSA app Flask che espone /api/*: in quel caso front-end e
# API sono sulla stessa origine e CORS non entra nemmeno in gioco. Questa
# impostazione serve solo se si sceglie di ospitare il front-end altrove
# (es. un "live server" su un'altra porta durante lo sviluppo): elenco di
# origini separate da virgola, ammesse a chiamare /api/* con i cookie di
# sessione (credentials).
# ---------------------------------------------------------------------------
CORS_ALLOWED_ORIGINS = os.environ.get(
    "CORS_ALLOWED_ORIGINS",
    "http://127.0.0.1:5500,http://localhost:5500,http://127.0.0.1:5000,http://localhost:5000",
).split(",")
