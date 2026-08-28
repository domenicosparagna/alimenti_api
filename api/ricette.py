# -*- coding: utf-8 -*-
"""
API REST per le ricette (tabelle `ricette` e `ricette_ingredienti`).

    GET    /api/ricette                                  elenco + filtri (?q=&categoria_ricetta=&difficolta=&vegano=&vegetariano=&senza_glutine=&page=)
    GET    /api/ricette/campi                             metadati campi testata ricetta
    GET    /api/ricette/<id>                               dettaglio testata
    POST   /api/ricette                                    crea (richiede login)
    PUT    /api/ricette/<id>                               aggiorna (richiede login)
    DELETE /api/ricette/<id>                               elimina, CASCADE sugli ingredienti (richiede login)
    GET    /api/ricette/<id>/ingredienti                   ingredienti (con nome/kcal da `alimenti`)
    POST   /api/ricette/<id>/ingredienti                   aggiungi ingrediente (richiede login)
    PUT    /api/ricette/<id>/ingredienti/<ing_id>          modifica ingrediente (richiede login)
    DELETE /api/ricette/<id>/ingredienti/<ing_id>          rimuovi ingrediente (richiede login)
    GET    /api/ricette/<id>/valori-calcolati              valori per porzione ricalcolati "a volo" (non salva)
    POST   /api/ricette/<id>/ricalcola                     ricalcola e SALVA i valori per porzione (richiede login)
"""
from flask import Blueprint, request, jsonify

from auth import login_required
from ricette_fields import RICETTE_FIELDS, CATEGORIA_CHOICES, DIFFICOLTA_CHOICES
from models.ricetta import Ricetta, RicettaIngrediente
from models.alimento import Alimento
from models.base import jsonable_dict

ricette_bp = Blueprint("api_ricette", __name__, url_prefix="/api/ricette")


def _get_ricetta_or_404(ricetta_id):
    ricetta = Ricetta.get(ricetta_id)
    if ricetta is None:
        return None, (jsonify({"error": "Ricetta non trovata."}), 404)
    return ricetta, None


@ricette_bp.route("/campi", methods=["GET"])
def campi():
    return jsonify({
        "fields": RICETTE_FIELDS,
        "categorie": CATEGORIA_CHOICES,
        "difficolta": DIFFICOLTA_CHOICES,
    })


@ricette_bp.route("", methods=["GET"])
def list_rows():
    q = request.args.get("q", "").strip()
    categoria = request.args.get("categoria_ricetta", "").strip()
    difficolta = request.args.get("difficolta", "").strip()
    page = request.args.get("page", 1, type=int) or 1

    dieta_filters = {}
    for flag in ("vegano", "vegetariano", "senza_glutine"):
        val = request.args.get(flag, "").strip()
        if val in ("1", "0"):
            dieta_filters[flag] = val

    items, meta = Ricetta.list(
        q=q, categoria=categoria, difficolta=difficolta, dieta_filters=dieta_filters, page=page
    )
    return jsonify({"items": [i.to_dict() for i in items], **meta})


@ricette_bp.route("/<int:ricetta_id>", methods=["GET"])
def get_ricetta(ricetta_id):
    ricetta, err = _get_ricetta_or_404(ricetta_id)
    if err:
        return err
    return jsonify(ricetta.to_dict())


@ricette_bp.route("", methods=["POST"])
@login_required
def create_ricetta():
    data = request.get_json(silent=True) or {}
    ricetta, errors = Ricetta.create(data)
    if errors:
        return jsonify({"error": "Dati non validi.", "details": errors}), 400
    return jsonify(ricetta.to_dict()), 201


@ricette_bp.route("/<int:ricetta_id>", methods=["PUT"])
@login_required
def update_ricetta(ricetta_id):
    ricetta, err = _get_ricetta_or_404(ricetta_id)
    if err:
        return err
    data = request.get_json(silent=True) or {}
    errors = ricetta.update(data)
    if errors:
        return jsonify({"error": "Dati non validi.", "details": errors}), 400
    return jsonify(ricetta.to_dict())


@ricette_bp.route("/<int:ricetta_id>", methods=["DELETE"])
@login_required
def delete_ricetta(ricetta_id):
    ricetta, err = _get_ricetta_or_404(ricetta_id)
    if err:
        return err
    ricetta.delete()
    return "", 204


@ricette_bp.route("/<int:ricetta_id>/valori-calcolati", methods=["GET"])
def valori_calcolati(ricetta_id):
    ricetta, err = _get_ricetta_or_404(ricetta_id)
    if err:
        return err
    return jsonify(jsonable_dict(ricetta.valori_calcolati()))


@ricette_bp.route("/<int:ricetta_id>/ricalcola", methods=["POST"])
@login_required
def ricalcola(ricetta_id):
    ricetta, err = _get_ricetta_or_404(ricetta_id)
    if err:
        return err
    calcolati, errors = ricetta.ricalcola()
    if errors:
        return jsonify({"error": errors[0]}), 400
    return jsonify({"ricetta": ricetta.to_dict(), "valori_calcolati": jsonable_dict(calcolati)})


# ---------------------------------------------------------------------
# Ingredienti
# ---------------------------------------------------------------------

@ricette_bp.route("/<int:ricetta_id>/ingredienti", methods=["GET"])
def list_ingredienti(ricetta_id):
    ricetta, err = _get_ricetta_or_404(ricetta_id)
    if err:
        return err
    return jsonify([i.to_dict() for i in ricetta.ingredienti()])


@ricette_bp.route("/<int:ricetta_id>/ingredienti", methods=["POST"])
@login_required
def add_ingrediente(ricetta_id):
    ricetta, err = _get_ricetta_or_404(ricetta_id)
    if err:
        return err
    data = request.get_json(silent=True) or {}
    ingrediente, errors = RicettaIngrediente.create(ricetta_id, data)
    if errors:
        return jsonify({"error": "Dati non validi.", "details": errors}), 400
    return jsonify(ingrediente.to_dict()), 201


@ricette_bp.route("/<int:ricetta_id>/ingredienti/<int:ing_id>", methods=["PUT"])
@login_required
def update_ingrediente(ricetta_id, ing_id):
    ingrediente = RicettaIngrediente.get_in_ricetta(ricetta_id, ing_id)
    if ingrediente is None:
        return jsonify({"error": "Ingrediente non trovato."}), 404
    data = request.get_json(silent=True) or {}
    errors = ingrediente.update(data)
    if errors:
        return jsonify({"error": "Dati non validi.", "details": errors}), 400
    return jsonify(ingrediente.to_dict())


@ricette_bp.route("/<int:ricetta_id>/ingredienti/<int:ing_id>", methods=["DELETE"])
@login_required
def delete_ingrediente(ricetta_id, ing_id):
    ingrediente = RicettaIngrediente.get_in_ricetta(ricetta_id, ing_id)
    if ingrediente is None:
        return jsonify({"error": "Ingrediente non trovato."}), 404
    ingrediente.delete()
    return "", 204


@ricette_bp.route("/alimenti-options", methods=["GET"])
def alimenti_options():
    """(codice_alimento, nome_alimento) per popolare la tendina di scelta
    ingrediente nel front-end (evita di dover paginare /api/alimenti)."""
    return jsonify(Alimento.options())
