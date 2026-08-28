# -*- coding: utf-8 -*-
"""
API di autenticazione: login/logout/stato corrente per l'unico utente
amministratore (stesse credenziali dell'app originale, vedi config.py).
"""
from flask import Blueprint, request, jsonify, session

from auth import verify_credentials, is_logged_in

auth_bp = Blueprint("api_auth", __name__, url_prefix="/api/auth")


@auth_bp.route("/login", methods=["POST"])
def login():
    data = request.get_json(silent=True) or {}
    username = (data.get("username") or "").strip()
    password = data.get("password") or ""

    if verify_credentials(username, password):
        session.clear()
        session["logged_in"] = True
        session["username"] = username
        return jsonify({"logged_in": True, "username": username})

    return jsonify({"error": "Utente o password non corretti."}), 401


@auth_bp.route("/logout", methods=["POST"])
def logout():
    session.clear()
    return jsonify({"logged_in": False})


@auth_bp.route("/me", methods=["GET"])
def me():
    return jsonify({"logged_in": is_logged_in(), "username": session.get("username")})
