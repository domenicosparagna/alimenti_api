# -*- coding: utf-8 -*-
"""
Modelli Ricetta e RicettaIngrediente (tabelle `ricette` e
`ricette_ingredienti`).

Le ricette sono in relazione "testata/righe": una Ricetta ha zero o piu'
RicettaIngrediente, ciascuno riferito a un Alimento tramite
`codice_alimento`. `Ricetta.ricalcola()` somma, per ogni ingrediente, il
contributo nutrizionale preso da `alimenti` (proporzionalmente a
`quantita_g`), divide per il numero di porzioni e salva il risultato nella
testata: stessa logica dell'app originale (vedi ricette_views.py), qui
un metodo dell'oggetto Ricetta invece che una funzione a parte.
"""
import math

import pymysql

import config
import db
from ricette_fields import (
    RICETTE_FIELDS,
    RICETTE_FIELD_NAMES,
    LIST_COLUMNS,
)
from validation import validate_fields

from .base import Model

# Campi di `ricette_ingredienti` gestiti dall'API (oltre a ricetta_id, che
# viene sempre preso dall'URL, mai dal corpo della richiesta).
INGREDIENTE_FIELDS = [
    {"name": "codice_alimento", "label": "Alimento", "type": "text", "required": True, "maxlength": 10},
    {"name": "quantita_g", "label": "Quantita' (g)", "type": "decimal", "required": True},
    {"name": "ordine", "label": "Ordine", "type": "int", "required": False},
    {"name": "note", "label": "Note", "type": "text", "required": False, "maxlength": 255},
]


class RicettaIngrediente(Model):
    table = "ricette_ingredienti"

    @classmethod
    def of(cls, ricetta_id):
        """Ingredienti di una ricetta, joinati con `alimenti` per nome,
        categoria e contributo energetico (kcal) di ciascuno."""
        rows = db.query_all(
            """
            SELECT ri.id, ri.ordine, ri.quantita_g, ri.note, ri.codice_alimento,
                   a.id AS alimento_id, a.nome_alimento, a.categoria AS alimento_categoria,
                   (a.energia_kcal / 100 * ri.quantita_g) AS kcal_contributo
            FROM ricette_ingredienti ri
            JOIN alimenti a ON a.codice_alimento = ri.codice_alimento
            WHERE ri.ricetta_id = %s
            ORDER BY (ri.ordine IS NULL), ri.ordine, ri.id
            """,
            [ricetta_id],
        )
        return cls._wrap_many(rows)

    @classmethod
    def get_in_ricetta(cls, ricetta_id, ing_id):
        row = db.query_one(
            "SELECT * FROM ricette_ingredienti WHERE id = %s AND ricetta_id = %s",
            [ing_id, ricetta_id],
        )
        return cls._wrap(row)

    @classmethod
    def create(cls, ricetta_id, data):
        values, errors = validate_fields(INGREDIENTE_FIELDS, data)
        if values.get("quantita_g") is not None and values["quantita_g"] <= 0:
            errors.append("La quantita' deve essere maggiore di zero.")
        if errors:
            return None, errors

        if values.get("ordine") is None:
            max_ordine = db.query_one(
                "SELECT MAX(ordine) AS m FROM ricette_ingredienti WHERE ricetta_id = %s",
                [ricetta_id],
            )["m"]
            values["ordine"] = (max_ordine or 0) + 1

        try:
            new_id, _ = db.execute(
                "INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) "
                "VALUES (%s, %s, %s, %s, %s)",
                [ricetta_id, values["codice_alimento"], values["quantita_g"], values["ordine"], values["note"]],
            )
        except pymysql.err.IntegrityError:
            return None, ["Alimento non valido."]

        row = db.query_one("SELECT * FROM ricette_ingredienti WHERE id = %s", [new_id])
        return cls._wrap(row), []

    def update(self, data):
        values, errors = validate_fields(INGREDIENTE_FIELDS, data)
        if values.get("quantita_g") is not None and values["quantita_g"] <= 0:
            errors.append("La quantita' deve essere maggiore di zero.")
        if errors:
            return errors
        try:
            db.execute(
                "UPDATE ricette_ingredienti SET codice_alimento = %s, quantita_g = %s, "
                "ordine = %s, note = %s WHERE id = %s",
                [values["codice_alimento"], values["quantita_g"], values["ordine"], values["note"], self.id],
            )
        except pymysql.err.IntegrityError:
            return ["Alimento non valido."]
        self._row = dict(db.query_one("SELECT * FROM ricette_ingredienti WHERE id = %s", [self.id]))
        return []

    def delete(self):
        db.execute("DELETE FROM ricette_ingredienti WHERE id = %s", [self.id])


class Ricetta(Model):
    table = "ricette"

    # ------------------------------------------------------------------
    # Lettura
    # ------------------------------------------------------------------

    @classmethod
    def get(cls, ricetta_id):
        return cls._wrap(db.query_one(f"SELECT * FROM {cls.table} WHERE id = %s", [ricetta_id]))

    @classmethod
    def list(cls, q="", categoria="", difficolta="", dieta_filters=None, page=1, page_size=None):
        page_size = page_size or config.PAGE_SIZE
        dieta_filters = dieta_filters or {}
        where_clauses, params = [], []

        if q:
            where_clauses.append("nome_ricetta LIKE %s")
            params.append(f"%{q}%")
        if categoria:
            where_clauses.append("categoria_ricetta = %s")
            params.append(categoria)
        if difficolta:
            where_clauses.append("difficolta = %s")
            params.append(difficolta)
        for flag, val in dieta_filters.items():
            where_clauses.append(f"{flag} = %s")
            params.append(int(val))
        where_sql = ("WHERE " + " AND ".join(where_clauses)) if where_clauses else ""

        total = db.query_one(f"SELECT COUNT(*) AS n FROM {cls.table} {where_sql}", params)["n"]
        total_pages = max(1, math.ceil(total / page_size))
        page = min(max(1, page), total_pages)
        offset = (page - 1) * page_size

        columns_sql = ", ".join(["id"] + [c for c, _ in LIST_COLUMNS])
        rows = db.query_all(
            f"SELECT {columns_sql} FROM {cls.table} {where_sql} "
            f"ORDER BY nome_ricetta ASC LIMIT %s OFFSET %s",
            params + [page_size, offset],
        )
        meta = {"page": page, "total_pages": total_pages, "total": total, "page_size": page_size}
        return cls._wrap_many(rows), meta

    # ------------------------------------------------------------------
    # Scrittura
    # ------------------------------------------------------------------

    @classmethod
    def create(cls, data):
        values, errors = validate_fields(RICETTE_FIELDS, data)
        if values.get("porzioni") is not None and values["porzioni"] < 1:
            errors.append("Il numero di porzioni deve essere almeno 1.")
        if errors:
            return None, errors

        if db.query_one(f"SELECT id FROM {cls.table} WHERE nome_ricetta = %s", [values["nome_ricetta"]]):
            return None, [f"Esiste gia' una ricetta con nome \"{values['nome_ricetta']}\"."]

        columns = ", ".join(RICETTE_FIELD_NAMES)
        placeholders = ", ".join(["%s"] * len(RICETTE_FIELD_NAMES))
        params = [values[name] for name in RICETTE_FIELD_NAMES]
        try:
            new_id, _ = db.execute(f"INSERT INTO {cls.table} ({columns}) VALUES ({placeholders})", params)
        except pymysql.err.IntegrityError:
            return None, ["Esiste gia' una ricetta con questo nome."]
        return cls.get(new_id), []

    def update(self, data):
        values, errors = validate_fields(RICETTE_FIELDS, data)
        if values.get("porzioni") is not None and values["porzioni"] < 1:
            errors.append("Il numero di porzioni deve essere almeno 1.")
        if errors:
            return errors

        dup = db.query_one(
            f"SELECT id FROM {self.table} WHERE nome_ricetta = %s AND id != %s",
            [values["nome_ricetta"], self.id],
        )
        if dup:
            return [f"Esiste gia' un'altra ricetta con nome \"{values['nome_ricetta']}\"."]

        set_sql = ", ".join([f"{name} = %s" for name in RICETTE_FIELD_NAMES])
        params = [values[name] for name in RICETTE_FIELD_NAMES] + [self.id]
        try:
            db.execute(f"UPDATE {self.table} SET {set_sql} WHERE id = %s", params)
        except pymysql.err.IntegrityError:
            return ["Esiste gia' una ricetta con questo nome."]
        self._row = dict(self.get(self.id)._row)
        return []

    def delete(self):
        db.execute(f"DELETE FROM {self.table} WHERE id = %s", [self.id])

    # ------------------------------------------------------------------
    # Ingredienti e ricalcolo nutrizionale
    # ------------------------------------------------------------------

    def ingredienti(self):
        return RicettaIngrediente.of(self.id)

    def valori_calcolati(self):
        """Somma i contributi nutrizionali di tutti gli ingredienti (presi da
        `alimenti`, proporzionalmente a `quantita_g`) e divide per il numero
        di porzioni. None per i nutrienti privi di ingredienti con quel
        valore noto."""
        row = db.query_one(
            """
            SELECT
                SUM(a.energia_kcal / 100 * ri.quantita_g) AS energia_kcal_porzione,
                SUM(a.proteine_g / 100 * ri.quantita_g) AS proteine_g_porzione,
                SUM(a.lipidi_g / 100 * ri.quantita_g) AS lipidi_g_porzione,
                SUM(a.carboidrati_disponibili_g / 100 * ri.quantita_g) AS carboidrati_g_porzione,
                SUM(a.fibra_totale_g / 100 * ri.quantita_g) AS fibra_g_porzione,
                SUM(a.sodio_mg / 100 * ri.quantita_g) AS sodio_mg_porzione
            FROM ricette_ingredienti ri
            JOIN alimenti a ON a.codice_alimento = ri.codice_alimento
            WHERE ri.ricetta_id = %s
            """,
            [self.id],
        )
        porzioni = self.value("porzioni") or 1
        return {key: (total / porzioni if total is not None else None) for key, total in row.items()}

    def ricalcola(self):
        """Ricalcola e SALVA i valori per porzione dagli ingredienti collegati.
        Restituisce (valori_calcolati, errors)."""
        if not self.ingredienti():
            return None, ["Aggiungi almeno un ingrediente prima di ricalcolare i valori."]

        calcolati = self.valori_calcolati()
        keys = list(calcolati.keys())
        set_sql = ", ".join([f"{k} = %s" for k in keys])
        params = [(round(v, 1) if v is not None else None) for v in calcolati.values()] + [self.id]
        db.execute(f"UPDATE {self.table} SET {set_sql} WHERE id = %s", params)
        self._row = dict(self.get(self.id)._row)
        return calcolati, []
