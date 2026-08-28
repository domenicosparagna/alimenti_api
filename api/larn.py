# -*- coding: utf-8 -*-
"""
API REST generica per le 15 tabelle LARN.

    GET    /api/larn/tables                     metadati delle 15 tabelle (menu)
    GET    /api/larn/<table_key>                 elenco + filtri
    GET    /api/larn/<table_key>/<id>            dettaglio
    POST   /api/larn/<table_key>                 crea (richiede login)
    PUT    /api/larn/<table_key>/<id>            aggiorna (richiede login)
    DELETE /api/larn/<table_key>/<id>            elimina (richiede login)

`table_key` e' uno tra "acqua", "proteine", "vitamine_pri_ai", ecc. (vedi
GET /api/larn/tables per l'elenco completo con etichette): se non
corrisponde a nessuna tabella nota, tutte le route rispondono 404.
"""
from flask import Blueprint, request, jsonify

from auth import login_required
from models.larn import LarnRiga

larn_bp = Blueprint("api_larn", __name__, url_prefix="/api/larn")


@larn_bp.route("/tables", methods=["GET"])
def tables():
    return jsonify(LarnRiga.tables_meta())


@larn_bp.route("/<table_key>", methods=["GET"])
def list_rows(table_key):
    meta_tabella = LarnRiga.table_meta(table_key)
    if meta_tabella is None:
        return jsonify({"error": "Tabella LARN sconosciuta."}), 404

    filters = {col: request.args.get(col, "") for col in meta_tabella["filters"]}
    items, meta = LarnRiga.list(table_key, filters)
    return jsonify({"table": meta_tabella, "items": [i.to_dict() for i in items], **meta})


@larn_bp.route("/<table_key>/<int:row_id>", methods=["GET"])
def get_row(table_key, row_id):
    riga = LarnRiga.get(table_key, row_id)
    if riga is None:
        return jsonify({"error": "Riga non trovata."}), 404
    return jsonify(riga.to_dict())


@larn_bp.route("/<table_key>", methods=["POST"])
@login_required
def create_row(table_key):
    data = request.get_json(silent=True) or {}
    riga, errors = LarnRiga.create(table_key, data)
    if riga is None and errors == ["Tabella LARN sconosciuta."]:
        return jsonify({"error": errors[0]}), 404
    if errors:
        return jsonify({"error": "Dati non validi.", "details": errors}), 400
    return jsonify(riga.to_dict()), 201


@larn_bp.route("/<table_key>/<int:row_id>", methods=["PUT"])
@login_required
def update_row(table_key, row_id):
    riga = LarnRiga.get(table_key, row_id)
    if riga is None:
        return jsonify({"error": "Riga non trovata."}), 404
    data = request.get_json(silent=True) or {}
    errors = riga.update(data)
    if errors:
        return jsonify({"error": "Dati non validi.", "details": errors}), 400
    return jsonify(riga.to_dict())


@larn_bp.route("/<table_key>/<int:row_id>", methods=["DELETE"])
@login_required
def delete_row(table_key, row_id):
    riga = LarnRiga.get(table_key, row_id)
    if riga is None:
        return jsonify({"error": "Riga non trovata."}), 404
    riga.delete()
    return "", 204
