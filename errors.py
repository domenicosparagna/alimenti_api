# -*- coding: utf-8 -*-
"""
Gestione centralizzata degli errori dell'API.

Flask/Werkzeug, di default, risponde agli errori (404, 500, ...) con una
pagina HTML: comportamento corretto per l'app originale (che serve pagine),
sbagliato per un'API, il cui unico formato di risposta e' JSON. Questo
modulo registra un gestore per ogni tipo di errore cosi' che *ogni* risposta
di errore, qualunque sia la causa, abbia la stessa forma:

    {"error": "messaggio leggibile", "details": [opzionale, lista di errori di validazione]}
"""
from flask import jsonify
from werkzeug.exceptions import HTTPException


class ApiError(Exception):
    """Eccezione applicativa con uno status HTTP esplicito, da sollevare nei
    blueprint per condizioni non gia' coperte da abort()/HTTPException
    (es. una regola di business violata)."""

    def __init__(self, message, status_code=400, errors=None):
        super().__init__(message)
        self.message = message
        self.status_code = status_code
        self.errors = errors


def register_error_handlers(app):
    @app.errorhandler(ApiError)
    def _handle_api_error(err):
        body = {"error": err.message}
        if err.errors:
            body["details"] = err.errors
        return jsonify(body), err.status_code

    @app.errorhandler(HTTPException)
    def _handle_http_exception(err):
        # Copre 404 (rotta/risorsa inesistente), 405 (metodo non permesso),
        # e qualunque abort(...) chiamato nei blueprint.
        return jsonify({"error": err.description or err.name}), err.code

    @app.errorhandler(Exception)
    def _handle_uncaught(err):
        app.logger.exception("Errore non gestito")
        return jsonify({"error": "Errore interno del server."}), 500
