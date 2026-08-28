# -*- coding: utf-8 -*-
"""
Autenticazione per l'API.

Stesso schema dell'app originale: un solo utente amministratore, le cui
credenziali sono in config.py (ADMIN_USERNAME / ADMIN_PASSWORD_HASH), e una
sessione Flask (cookie firmato) per ricordare che il login e' avvenuto.

La differenza rispetto all'originale e' nella *risposta* quando manca
l'autenticazione: la app a pagine reindirizzava (302) alla schermata di
login HTML; qui, dato che il client e' codice (fetch dal front-end, curl,
Swagger UI, ...) e non un browser che segue redirect mostrando una pagina,
`login_required` restituisce direttamente 401 con un corpo JSON. La UI del
front-end (vedi frontend/js/app.js) intercetta questo 401 e mostra lei la
schermata di login, invece di lasciare che sia il server a "navigare" al
posto dell'utente.
"""
from functools import wraps

from flask import session, jsonify
from werkzeug.security import check_password_hash

import config


def verify_credentials(username, password):
    """True se la coppia utente/password corrisponde all'amministratore
    configurato. Il confronto della password usa sempre l'hash (mai la
    password in chiaro), esattamente come nell'app originale."""
    if not username or username != config.ADMIN_USERNAME:
        return False
    return check_password_hash(config.ADMIN_PASSWORD_HASH, password or "")


def is_logged_in():
    return bool(session.get("logged_in"))


def login_required(view):
    """Decorator per le route che richiedono il login (le stesse operazioni
    di scrittura protette nell'app originale: creazione, modifica,
    eliminazione). Le operazioni di sola lettura restano pubbliche."""

    @wraps(view)
    def wrapped(*args, **kwargs):
        if not is_logged_in():
            return jsonify({"error": "Autenticazione richiesta."}), 401
        return view(*args, **kwargs)

    return wrapped
