# -*- coding: utf-8 -*-
"""
API REST per la tabella `smartfood_porzioni_frequenze` (Piramide
alimentare Smartfood).

    GET    /api/smartfood/fasce     le 4 fasce (giornaliera/settimanale/occasionale/evitare)
    GET    /api/smartfood/campi     metadati campi, raggruppati per sezione
    GET    /api/smartfood/gruppi    valori distinti di gruppo_alimenti (per un filtro)
    GET    /api/smartfood           elenco (?frequenza=&gruppo=&q=)
    GET    /api/smartfood/<id>      dettaglio
    POST   /api/smartfood           crea (richiede login)
    PUT    /api/smartfood/<id>      aggiorna (richiede login)
    DELETE /api/smartfood/<id>      elimina (richiede login)
"""
from flask import Blueprint, request, jsonify

from auth import login_required
from smartfood_fields import grouped_fields
from models.smartfood import SmartfoodRiga

smartfood_bp = Blueprint("api_smartfood", __name__, url_prefix="/api/smartfood")


@smartfood_bp.route("/fasce", methods=["GET"])
def fasce():
    return jsonify(SmartfoodRiga.fasce_meta())


@smartfood_bp.route("/campi", methods=["GET"])
def campi():
    return jsonify(grouped_fields())


@smartfood_bp.route("/gruppi", methods=["GET"])
def gruppi():
    return jsonify(SmartfoodRiga.gruppi())


@smartfood_bp.route("", methods=["GET"])
def list_rows():
    frequenza = request.args.get("frequenza", "").strip()
    gruppo = request.args.get("gruppo", "").strip()
    q = request.args.get("q", "").strip()
    items = SmartfoodRiga.list(frequenza=frequenza, gruppo=gruppo, q=q)
    return jsonify({"items": [i.to_dict() for i in items], "total": len(items)})


@smartfood_bp.route("/<int:row_id>", methods=["GET"])
def get_row(row_id):
    riga = SmartfoodRiga.get(row_id)
    if riga is None:
        return jsonify({"error": "Riga non trovata."}), 404
    return jsonify(riga.to_dict())


@smartfood_bp.route("", methods=["POST"])
@login_required
def create_row():
    data = request.get_json(silent=True) or {}
    riga, errors = SmartfoodRiga.create(data)
    if errors:
        return jsonify({"error": "Dati non validi.", "details": errors}), 400
    return jsonify(riga.to_dict()), 201


@smartfood_bp.route("/<int:row_id>", methods=["PUT"])
@login_required
def update_row(row_id):
    riga = SmartfoodRiga.get(row_id)
    if riga is None:
        return jsonify({"error": "Riga non trovata."}), 404
    data = request.get_json(silent=True) or {}
    errors = riga.update(data)
    if errors:
        return jsonify({"error": "Dati non validi.", "details": errors}), 400
    return jsonify(riga.to_dict())


@smartfood_bp.route("/<int:row_id>", methods=["DELETE"])
@login_required
def delete_row(row_id):
    riga = SmartfoodRiga.get(row_id)
    if riga is None:
        return jsonify({"error": "Riga non trovata."}), 404
    riga.delete()
    return "", 204
