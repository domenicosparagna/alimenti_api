# -*- coding: utf-8 -*-
"""
Validazione generica dei payload JSON in ingresso.

Nell'app originale ogni blueprint (`app.py`, `larn_views.py`,
`ricette_views.py`, `smartfood_views.py`, `pazienti_views.py`) definiva una
propria funzione `_parse_form(...)` per convalidare i dati grezzi (sempre
stringhe) di un <form> HTML, guidata dallo stesso tipo di registro di campi
(nome colonna, etichetta, tipo, obbligatorieta', lunghezza massima: vedi
fields.py / larn_fields.py / ricette_fields.py / pazienti_fields.py /
smartfood_fields.py).

Passando a un'API JSON i dati arrivano gia' tipizzati dal client (numeri
come numeri, booleani come booleani), quindi non serve piu' duplicare
quella funzione in ogni blueprint: `validate_fields` la sostituisce con
un'unica implementazione, riusata da tutti i modelli in `models/`, che
accetta sia il tipo nativo JSON sia una stringa equivalente (per restare
comoda anche da un form HTML del front-end o da uno strumento come curl).
"""
from decimal import Decimal, InvalidOperation
from datetime import date, datetime


def _coerce_bool(raw):
    return 1 if raw in (True, 1, "1", "on", "true", "True") else 0


def _coerce_int(raw, label, errors):
    if isinstance(raw, bool):
        errors.append(f'Il campo "{label}" deve essere un numero intero.')
        return None
    if isinstance(raw, int):
        return raw
    if isinstance(raw, float) and raw.is_integer():
        return int(raw)
    if isinstance(raw, str) and raw.strip():
        try:
            return int(raw.strip())
        except ValueError:
            pass
    errors.append(f'Il campo "{label}" deve essere un numero intero.')
    return None


def _coerce_decimal(raw, label, errors):
    if isinstance(raw, Decimal):
        return raw
    if isinstance(raw, bool):
        errors.append(f'Il campo "{label}" deve essere un numero.')
        return None
    if isinstance(raw, (int, float)):
        return Decimal(str(raw))
    if isinstance(raw, str) and raw.strip():
        try:
            return Decimal(raw.strip().replace(",", "."))
        except InvalidOperation:
            pass
    errors.append(f'Il campo "{label}" deve essere un numero.')
    return None


def _coerce_date(raw, label, errors):
    if isinstance(raw, date):
        return raw
    if isinstance(raw, str) and raw.strip():
        try:
            return datetime.strptime(raw.strip()[:10], "%Y-%m-%d").date()
        except ValueError:
            pass
    errors.append(f'Il campo "{label}" deve essere una data valida (AAAA-MM-GG).')
    return None


def _coerce_datetime(raw, label, errors):
    if isinstance(raw, datetime):
        return raw
    if isinstance(raw, str) and raw.strip():
        text = raw.strip().replace("T", " ")[:19]
        for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d %H:%M"):
            try:
                return datetime.strptime(text, fmt)
            except ValueError:
                continue
    errors.append(f'Il campo "{label}" deve essere una data/ora valida (AAAA-MM-GGTHH:MM).')
    return None


def validate_fields(fields, data, partial=False):
    """Valida `data` (dict, tipicamente il JSON della richiesta) contro un
    registro di campi nello stile di fields.py / larn_fields.py /
    ricette_fields.py / pazienti_fields.py / smartfood_fields.py.

    Tipi di campo supportati: text, textarea, int, decimal, bool, select,
    date, datetime (gli stessi usati nei registri esistenti).

    Se `partial` e' True (aggiornamenti parziali), i campi assenti da
    `data` vengono ignorati invece che trattati come mancanti: utile per
    un futuro PATCH, non usato dai PUT di questa API (che si comportano
    come l'update "totale" dei form originali).

    Restituisce (values, errors): `values` e' pronto per essere passato a
    una INSERT/UPDATE parametrica; `errors` e' una lista di messaggi in
    italiano, gia' nello stesso stile mostrato all'utente dall'app originale.
    """
    values = {}
    errors = []

    for f in fields:
        name = f["name"]
        ftype = f["type"]
        required = f.get("required", False)
        label = f["label"]

        if name not in data:
            if partial:
                continue
            default = f.get("default")
            # Un campo obbligatorio con un default nel registro (es. "stato"
            # di un appuntamento, che nell'app originale il <select> HTML
            # pre-selezionava comunque) viene silenziosamente valorizzato
            # col default invece di essere segnalato come mancante: solo un
            # campo obbligatorio SENZA alcun default e' davvero un errore.
            if required and default is None:
                errors.append(f'Il campo "{label}" e\' obbligatorio.')
            values[name] = default
            continue

        raw = data[name]

        if raw is None or raw == "":
            if required:
                errors.append(f'Il campo "{label}" e\' obbligatorio.')
            values[name] = f.get("default") if ftype == "select" else None
            continue

        if ftype == "bool":
            values[name] = _coerce_bool(raw)

        elif ftype == "select":
            choices = f.get("choices", [])
            if raw not in choices:
                errors.append(f'Valore non valido per "{label}".')
                values[name] = None
            else:
                values[name] = raw

        elif ftype == "int":
            values[name] = _coerce_int(raw, label, errors)

        elif ftype == "decimal":
            values[name] = _coerce_decimal(raw, label, errors)

        elif ftype == "date":
            values[name] = _coerce_date(raw, label, errors)

        elif ftype == "datetime":
            values[name] = _coerce_datetime(raw, label, errors)

        else:  # text / textarea
            text = raw if isinstance(raw, str) else str(raw)
            maxlength = f.get("maxlength")
            if maxlength and len(text) > maxlength:
                errors.append(
                    f'Il campo "{label}" supera la lunghezza massima di {maxlength} caratteri.'
                )
            values[name] = text

    return values, errors
