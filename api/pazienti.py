# -*- coding: utf-8 -*-
"""
API REST per pazienti, piani alimentari, giorni e appuntamenti.

Tutte le route di quest'area richiedono il login (come nell'app originale:
a differenza di alimenti/LARN/ricette/smartfood, i dati dei pazienti sono
clinici e non sono mai pubblici, nemmeno in lettura).

    GET    /api/pazienti                                          elenco (?q=&attivi=&page=)
    GET    /api/pazienti/campi                                    metadati campi paziente
    POST   /api/pazienti                                          crea
    GET    /api/pazienti/<id>                                     dettaglio
    PUT    /api/pazienti/<id>                                     aggiorna
    DELETE /api/pazienti/<id>                                     elimina (CASCADE su piani e appuntamenti)
    GET    /api/pazienti/<id>/larn                                fabbisogno di riferimento (energia/proteine/acqua)
    GET    /api/pazienti/<id>/piani                                elenco piani
    POST   /api/pazienti/<id>/piani                                crea piano (genera anche i 7 giorni)
    GET    /api/pazienti/<id>/piani/<piano_id>                     dettaglio piano + panoramica dei 7 giorni
    PUT    /api/pazienti/<id>/piani/<piano_id>                     aggiorna intestazione piano
    DELETE /api/pazienti/<id>/piani/<piano_id>                     elimina piano (CASCADE sui giorni)
    GET    /api/pazienti/<id>/piani/<piano_id>/giorni/<giorno>     dettaglio giorno (pasti + alimenti collegati + kcal/proteine)
    PUT    /api/pazienti/<id>/piani/<piano_id>/giorni/<giorno>     aggiorna i pasti (testo libero) del giorno
    POST   .../giorni/<giorno>/ricalcola-kcal                     ricalcola e salva le kcal dagli alimenti collegati
    POST   .../giorni/<giorno>/alimenti                            collega un alimento a un pasto
    DELETE .../giorni/<giorno>/alimenti/<link_id>                  rimuove un alimento collegato

    GET    /api/appuntamenti           agenda su tutti i pazienti (?q=&stato=&passati=&page=)
    POST   /api/appuntamenti           crea (body include paziente_id)
    GET    /api/appuntamenti/<id>
    PUT    /api/appuntamenti/<id>
    DELETE /api/appuntamenti/<id>
    GET    /api/appuntamenti/campi     metadati campi + stati/tipi ammessi
"""
from flask import Blueprint, request, jsonify

from auth import login_required
from pazienti_fields import (
    PAZIENTI_FIELDS,
    PIANI_FIELDS,
    GIORNO_SECTIONS,
    PASTI_LABELS,
    GIORNI_SETTIMANA_LABEL,
    APPUNTAMENTI_FIELDS,
    APPUNTAMENTI_TIPO_CHOICES,
    APPUNTAMENTI_STATO_CHOICES,
)
from models.paziente import Paziente, PianoAlimentare, PianoGiorno, Appuntamento
from models.base import jsonable_dict

pazienti_bp = Blueprint("api_pazienti", __name__, url_prefix="/api/pazienti")
appuntamenti_bp = Blueprint("api_appuntamenti", __name__, url_prefix="/api/appuntamenti")


def _paziente_or_404(paziente_id):
    p = Paziente.get(paziente_id)
    if p is None:
        return None, (jsonify({"error": "Paziente non trovato."}), 404)
    return p, None


def _piano_or_404(paziente_id, piano_id):
    piano = PianoAlimentare.get(paziente_id, piano_id)
    if piano is None:
        return None, (jsonify({"error": "Piano non trovato."}), 404)
    return piano, None


def _giorno_or_404(piano_id, giorno):
    pg = PianoGiorno.get(piano_id, giorno)
    if pg is None:
        return None, (jsonify({"error": "Giorno non valido o piano inesistente."}), 404)
    return pg, None


# ---------------------------------------------------------------------
# Pazienti
# ---------------------------------------------------------------------

@pazienti_bp.route("/campi", methods=["GET"])
@login_required
def campi():
    return jsonify({"paziente": PAZIENTI_FIELDS, "piano": PIANI_FIELDS, "giorno_sezioni": GIORNO_SECTIONS})


@pazienti_bp.route("", methods=["GET"])
@login_required
def list_pazienti():
    q = request.args.get("q", "").strip()
    solo_attivi = request.args.get("attivi", "1") == "1"
    page = request.args.get("page", 1, type=int) or 1
    items, meta = Paziente.list(q=q, solo_attivi=solo_attivi, page=page)
    return jsonify({"items": [i.to_dict() for i in items], **meta})


@pazienti_bp.route("", methods=["POST"])
@login_required
def create_paziente():
    data = request.get_json(silent=True) or {}
    paziente, errors = Paziente.create(data)
    if errors:
        return jsonify({"error": "Dati non validi.", "details": errors}), 400
    return jsonify(paziente.to_dict()), 201


@pazienti_bp.route("/<int:paziente_id>", methods=["GET"])
@login_required
def get_paziente(paziente_id):
    paziente, err = _paziente_or_404(paziente_id)
    if err:
        return err
    return jsonify(paziente.to_dict())


@pazienti_bp.route("/<int:paziente_id>", methods=["PUT"])
@login_required
def update_paziente(paziente_id):
    paziente, err = _paziente_or_404(paziente_id)
    if err:
        return err
    data = request.get_json(silent=True) or {}
    errors = paziente.update(data)
    if errors:
        return jsonify({"error": "Dati non validi.", "details": errors}), 400
    return jsonify(paziente.to_dict())


@pazienti_bp.route("/<int:paziente_id>", methods=["DELETE"])
@login_required
def delete_paziente(paziente_id):
    paziente, err = _paziente_or_404(paziente_id)
    if err:
        return err
    paziente.delete()
    return "", 204


@pazienti_bp.route("/<int:paziente_id>/larn", methods=["GET"])
@login_required
def paziente_larn(paziente_id):
    paziente, err = _paziente_or_404(paziente_id)
    if err:
        return err
    return jsonify(jsonable_dict(paziente.riferimenti_larn()))


@pazienti_bp.route("/<int:paziente_id>/appuntamenti", methods=["GET"])
@login_required
def paziente_appuntamenti(paziente_id):
    paziente, err = _paziente_or_404(paziente_id)
    if err:
        return err
    return jsonify([a.to_dict() for a in paziente.appuntamenti()])


# ---------------------------------------------------------------------
# Piani alimentari
# ---------------------------------------------------------------------

@pazienti_bp.route("/<int:paziente_id>/piani", methods=["GET"])
@login_required
def list_piani(paziente_id):
    paziente, err = _paziente_or_404(paziente_id)
    if err:
        return err
    return jsonify([p.to_dict() for p in paziente.piani()])


@pazienti_bp.route("/<int:paziente_id>/piani", methods=["POST"])
@login_required
def create_piano(paziente_id):
    paziente, err = _paziente_or_404(paziente_id)
    if err:
        return err
    data = request.get_json(silent=True) or {}
    piano, errors = PianoAlimentare.create(paziente_id, data)
    if errors:
        return jsonify({"error": "Dati non validi.", "details": errors}), 400
    return jsonify(piano.to_dict()), 201


@pazienti_bp.route("/<int:paziente_id>/piani/<int:piano_id>", methods=["GET"])
@login_required
def get_piano(paziente_id, piano_id):
    _, err = _paziente_or_404(paziente_id)
    if err:
        return err
    piano, err = _piano_or_404(paziente_id, piano_id)
    if err:
        return err
    giorni = piano.giorni()
    return jsonify({
        "piano": piano.to_dict(),
        "giorni": [
            {"giorno": g.giorno_settimana if g else None, "dati": (g.to_dict() if g else None)}
            for g in giorni
        ],
        "giorni_label": GIORNI_SETTIMANA_LABEL,
    })


@pazienti_bp.route("/<int:paziente_id>/piani/<int:piano_id>", methods=["PUT"])
@login_required
def update_piano(paziente_id, piano_id):
    piano, err = _piano_or_404(paziente_id, piano_id)
    if err:
        return err
    data = request.get_json(silent=True) or {}
    errors = piano.update(data)
    if errors:
        return jsonify({"error": "Dati non validi.", "details": errors}), 400
    return jsonify(piano.to_dict())


@pazienti_bp.route("/<int:paziente_id>/piani/<int:piano_id>", methods=["DELETE"])
@login_required
def delete_piano(paziente_id, piano_id):
    piano, err = _piano_or_404(paziente_id, piano_id)
    if err:
        return err
    piano.delete()
    return "", 204


# ---------------------------------------------------------------------
# Giorni del piano
# ---------------------------------------------------------------------

@pazienti_bp.route("/<int:paziente_id>/piani/<int:piano_id>/giorni/<giorno>", methods=["GET"])
@login_required
def get_giorno(paziente_id, piano_id, giorno):
    _, err = _paziente_or_404(paziente_id)
    if err:
        return err
    _, err = _piano_or_404(paziente_id, piano_id)
    if err:
        return err
    pg, err = _giorno_or_404(piano_id, giorno)
    if err:
        return err

    per_pasto, totale = pg.kcal_per_pasto_e_totale()
    return jsonify({
        "giorno": pg.to_dict(),
        "giorno_label": GIORNI_SETTIMANA_LABEL.get(giorno, giorno),
        "sezioni": GIORNO_SECTIONS,
        "alimenti_per_pasto": {k: [jsonable_dict(r) for r in v] for k, v in pg.alimenti_per_pasto().items()},
        "pasti_labels": PASTI_LABELS,
        "kcal_per_pasto": jsonable_dict(per_pasto),
        "kcal_totale_collegati": float(totale),
        "proteine_totali_collegate": float(pg.proteine_totali()),
    })


@pazienti_bp.route("/<int:paziente_id>/piani/<int:piano_id>/giorni/<giorno>", methods=["PUT"])
@login_required
def update_giorno(paziente_id, piano_id, giorno):
    _, err = _paziente_or_404(paziente_id)
    if err:
        return err
    _, err = _piano_or_404(paziente_id, piano_id)
    if err:
        return err
    pg, err = _giorno_or_404(piano_id, giorno)
    if err:
        return err
    data = request.get_json(silent=True) or {}
    errors = pg.update(data)
    if errors:
        return jsonify({"error": "Dati non validi.", "details": errors}), 400
    return jsonify(pg.to_dict())


@pazienti_bp.route(
    "/<int:paziente_id>/piani/<int:piano_id>/giorni/<giorno>/ricalcola-kcal", methods=["POST"]
)
@login_required
def ricalcola_kcal(paziente_id, piano_id, giorno):
    _, err = _paziente_or_404(paziente_id)
    if err:
        return err
    _, err = _piano_or_404(paziente_id, piano_id)
    if err:
        return err
    pg, err = _giorno_or_404(piano_id, giorno)
    if err:
        return err
    kcal, errors = pg.ricalcola_kcal()
    if errors:
        return jsonify({"error": errors[0]}), 400
    return jsonify({"kcal_stimate": float(kcal)})


@pazienti_bp.route(
    "/<int:paziente_id>/piani/<int:piano_id>/giorni/<giorno>/alimenti", methods=["POST"]
)
@login_required
def collega_alimento(paziente_id, piano_id, giorno):
    _, err = _paziente_or_404(paziente_id)
    if err:
        return err
    _, err = _piano_or_404(paziente_id, piano_id)
    if err:
        return err
    pg, err = _giorno_or_404(piano_id, giorno)
    if err:
        return err
    data = request.get_json(silent=True) or {}
    new_id, errors = pg.collega_alimento(data)
    if errors:
        return jsonify({"error": "Dati non validi.", "details": errors}), 400
    return jsonify({"id": new_id}), 201


@pazienti_bp.route(
    "/<int:paziente_id>/piani/<int:piano_id>/giorni/<giorno>/alimenti/<int:link_id>",
    methods=["DELETE"],
)
@login_required
def scollega_alimento(paziente_id, piano_id, giorno, link_id):
    _, err = _paziente_or_404(paziente_id)
    if err:
        return err
    _, err = _piano_or_404(paziente_id, piano_id)
    if err:
        return err
    pg, err = _giorno_or_404(piano_id, giorno)
    if err:
        return err
    if not pg.scollega_alimento(link_id):
        return jsonify({"error": "Alimento collegato non trovato."}), 404
    return "", 204


# ---------------------------------------------------------------------
# Appuntamenti (risorsa di primo livello: vedi nota nel modulo)
# ---------------------------------------------------------------------

@appuntamenti_bp.route("/campi", methods=["GET"])
@login_required
def appuntamenti_campi():
    return jsonify({
        "fields": APPUNTAMENTI_FIELDS,
        "tipi": APPUNTAMENTI_TIPO_CHOICES,
        "stati": APPUNTAMENTI_STATO_CHOICES,
    })


@appuntamenti_bp.route("", methods=["GET"])
@login_required
def agenda():
    q = request.args.get("q", "").strip()
    stato = request.args.get("stato", "").strip()
    mostra_passati = request.args.get("passati", "0") == "1"
    page = request.args.get("page", 1, type=int) or 1
    items, meta = Appuntamento.agenda(q=q, stato=stato, mostra_passati=mostra_passati, page=page)
    return jsonify({"items": [i.to_dict() for i in items], **meta})


@appuntamenti_bp.route("", methods=["POST"])
@login_required
def create_appuntamento():
    data = request.get_json(silent=True) or {}
    paziente_id = data.get("paziente_id")
    if not isinstance(paziente_id, int):
        try:
            paziente_id = int(paziente_id)
        except (TypeError, ValueError):
            return jsonify({"error": "Dati non validi.", "details": ["Devi indicare un paziente_id valido."]}), 400
    appuntamento, errors = Appuntamento.create(paziente_id, data)
    if errors:
        return jsonify({"error": "Dati non validi.", "details": errors}), 400
    return jsonify(appuntamento.to_dict()), 201


@appuntamenti_bp.route("/<int:app_id>", methods=["GET"])
@login_required
def get_appuntamento(app_id):
    appuntamento = Appuntamento.get(app_id)
    if appuntamento is None:
        return jsonify({"error": "Appuntamento non trovato."}), 404
    return jsonify(appuntamento.to_dict())


@appuntamenti_bp.route("/<int:app_id>", methods=["PUT"])
@login_required
def update_appuntamento(app_id):
    appuntamento = Appuntamento.get(app_id)
    if appuntamento is None:
        return jsonify({"error": "Appuntamento non trovato."}), 404
    data = request.get_json(silent=True) or {}
    errors = appuntamento.update(data)
    if errors:
        return jsonify({"error": "Dati non validi.", "details": errors}), 400
    return jsonify(appuntamento.to_dict())


@appuntamenti_bp.route("/<int:app_id>", methods=["DELETE"])
@login_required
def delete_appuntamento(app_id):
    appuntamento = Appuntamento.get(app_id)
    if appuntamento is None:
        return jsonify({"error": "Appuntamento non trovato."}), 404
    appuntamento.delete()
    return "", 204
