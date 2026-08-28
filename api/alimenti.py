# -*- coding: utf-8 -*-
"""
API REST per la tabella `alimenti` (composizione alimenti CREA/INRAN).

    GET    /api/alimenti              elenco paginato (?q=&categoria=&page=)
    GET    /api/alimenti/categorie    valori distinti di categoria (per un filtro)
    GET    /api/alimenti/campi        metadati campi, raggruppati per sezione
    GET    /api/alimenti/<id>         dettaglio
    POST   /api/alimenti              crea (richiede login)
    PUT    /api/alimenti/<id>         aggiorna (richiede login)
    DELETE /api/alimenti/<id>         elimina (richiede login)

Le operazioni di sola lettura sono pubbliche; le operazioni di scrittura
richiedono il login amministratore, esattamente come nell'app originale.
"""
from flask import Blueprint, request, jsonify

from auth import login_required
from fields import grouped_fields
from models.alimento import Alimento

alimenti_bp = Blueprint("api_alimenti", __name__, url_prefix="/api/alimenti")


@alimenti_bp.route("", methods=["GET"])
def list_alimenti():
    q = request.args.get("q", "").strip()
    categoria = request.args.get("categoria", "").strip()
    page = request.args.get("page", 1, type=int) or 1

    items, meta = Alimento.list(q=q, categoria=categoria, page=page)
    return jsonify({"items": [i.to_dict() for i in items], **meta})


@alimenti_bp.route("/categorie", methods=["GET"])
def categorie():
    return jsonify(Alimento.categorie())


@alimenti_bp.route("/campi", methods=["GET"])
def campi():
    """Metadati dei campi, raggruppati per sezione: permettono al
    front-end di generare form e schede di dettaglio senza duplicare qui
    l'elenco dei ~50 campi (stessa fonte di verita' usata anche server-side)."""
    return jsonify(grouped_fields())


@alimenti_bp.route("/<int:alimento_id>", methods=["GET"])
def get_alimento(alimento_id):
    alimento = Alimento.get(alimento_id)
    if alimento is None:
        return jsonify({"error": "Alimento non trovato."}), 404
    return jsonify(alimento.to_dict())


@alimenti_bp.route("", methods=["POST"])
@login_required
def create_alimento():
    data = request.get_json(silent=True) or {}
    alimento, errors = Alimento.create(data)
    if errors:
        return jsonify({"error": "Dati non validi.", "details": errors}), 400
    return jsonify(alimento.to_dict()), 201


@alimenti_bp.route("/<int:alimento_id>", methods=["PUT"])
@login_required
def update_alimento(alimento_id):
    alimento = Alimento.get(alimento_id)
    if alimento is None:
        return jsonify({"error": "Alimento non trovato."}), 404
    data = request.get_json(silent=True) or {}
    errors = alimento.update(data)
    if errors:
        return jsonify({"error": "Dati non validi.", "details": errors}), 400
    return jsonify(alimento.to_dict())


@alimenti_bp.route("/<int:alimento_id>", methods=["DELETE"])
@login_required
def delete_alimento(alimento_id):
    alimento = Alimento.get(alimento_id)
    if alimento is None:
        return jsonify({"error": "Alimento non trovato."}), 404
    alimento.delete()
    return "", 204
