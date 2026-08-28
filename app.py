# -*- coding: utf-8 -*-
"""
Applicazione Flask — API REST per alimenti, tabelle LARN, ricette,
pazienti/piani/appuntamenti e piramide Smartfood.

Trasformazione in API REST + front-end separato dell'app originale
(alimenti_app/), a partire dagli stessi dati e dalla stessa logica di
dominio, riorganizzata in tre livelli:

    models/     livello OOP di accesso ai dati (una o piu' classi per area,
                vedi models/*.py): query SQL, validazione, calcoli di
                dominio (valori nutrizionali di una ricetta, fabbisogno
                LARN di un paziente, ...).
    api/        blueprint Flask che espongono quei modelli come JSON puro
                (nessun render_template): leggono la richiesta, chiamano
                un metodo di un modello, restituiscono una risposta JSON
                con lo status HTTP appropriato.
    frontend/   interfaccia HTML/CSS/JS statica e indipendente, che non
                riceve MAI dati gia' renderizzati dal server: chiama
                esclusivamente gli endpoint /api/... via fetch() e
                costruisce il DOM nel browser.

Per semplicita' di sviluppo, questa stessa app Flask serve sia /api/*
(JSON) sia i file statici del front-end (stesso principio di un reverse
proxy che smista fra un backend applicativo e una cartella di file
statici: la separazione e' nel CODICE, non necessariamente nel processo o
nella porta). Vedi README_API.md per come eseguire front-end e API anche
su origini separate.
"""
import os

from flask import Flask, send_from_directory
from flask_cors import CORS

import config
import db
from errors import register_error_handlers

from api.auth import auth_bp
from api.alimenti import alimenti_bp
from api.larn import larn_bp
from api.ricette import ricette_bp
from api.smartfood import smartfood_bp
from api.pazienti import pazienti_bp, appuntamenti_bp

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
FRONTEND_DIR = os.path.join(BASE_DIR, "frontend")

app = Flask(__name__, static_folder=None)
app.config["SECRET_KEY"] = config.SECRET_KEY
app.config["JSON_SORT_KEYS"] = False
# SameSite=Lax e' sufficiente quando front-end e API sono sulla stessa
# origine (la modalita' di esecuzione consigliata, vedi README_API.md).
app.config["SESSION_COOKIE_SAMESITE"] = "Lax"

db.init_app(app)
register_error_handlers(app)

# CORS su /api/*: serve solo se il front-end viene servito da un'origine
# diversa dall'API (es. un "live server" su un'altra porta in sviluppo).
CORS(app, resources={r"/api/*": {"origins": config.CORS_ALLOWED_ORIGINS}}, supports_credentials=True)

app.register_blueprint(auth_bp)
app.register_blueprint(alimenti_bp)
app.register_blueprint(larn_bp)
app.register_blueprint(ricette_bp)
app.register_blueprint(smartfood_bp)
app.register_blueprint(pazienti_bp)
app.register_blueprint(appuntamenti_bp)


@app.route("/api")
def api_root():
    return {
        "name": "Alimenti API",
        "version": "1.0",
        "documentazione": "/api/docs",
        "openapi": "/api/openapi.yaml",
    }


@app.route("/api/openapi.yaml")
def openapi_spec():
    return send_from_directory(BASE_DIR, "openapi.yaml", mimetype="text/yaml; charset=utf-8")


@app.route("/api/docs")
def api_docs():
    return send_from_directory(FRONTEND_DIR, "docs.html")


# ---------------------------------------------------------------------
# Front-end statico (HTML/CSS/JS puro: parla solo con /api/*, non riceve
# mai HTML gia' pronto dal server)
# ---------------------------------------------------------------------

@app.route("/")
def frontend_index():
    return send_from_directory(FRONTEND_DIR, "index.html")


@app.route("/<path:path>")
def frontend_files(path):
    return send_from_directory(FRONTEND_DIR, path)


if __name__ == "__main__":
    app.run(debug=True, host="127.0.0.1", port=5000)
