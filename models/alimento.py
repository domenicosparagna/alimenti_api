# -*- coding: utf-8 -*-
"""
Modello Alimento — tabella `alimenti` (composizione degli alimenti,
fonte CREA/INRAN). Stesso dominio dati dell'app originale (vedi fields.py
per il registro completo dei ~50 campi), qui esposto come oggetto invece
che tramite le funzioni di route in app.py.
"""
import math

import pymysql

import config
import db
from fields import FIELDS, FIELD_NAMES, LIST_COLUMNS
from validation import validate_fields

from .base import Model


class Alimento(Model):
    table = "alimenti"

    # ------------------------------------------------------------------
    # Lettura
    # ------------------------------------------------------------------

    @classmethod
    def get(cls, alimento_id):
        row = db.query_one(f"SELECT * FROM {cls.table} WHERE id = %s", [alimento_id])
        return cls._wrap(row)

    @classmethod
    def list(cls, q="", categoria="", page=1, page_size=None):
        """Elenco paginato con ricerca libera (nome/codice) e filtro per
        categoria. Restituisce (items, meta) dove meta contiene
        page/total_pages/total/page_size, utile per la paginazione lato
        client."""
        page_size = page_size or config.PAGE_SIZE
        where_clauses, params = [], []

        if q:
            where_clauses.append("(nome_alimento LIKE %s OR codice_alimento LIKE %s)")
            params += [f"%{q}%", f"%{q}%"]
        if categoria:
            where_clauses.append("categoria = %s")
            params.append(categoria)
        where_sql = ("WHERE " + " AND ".join(where_clauses)) if where_clauses else ""

        total = db.query_one(f"SELECT COUNT(*) AS n FROM {cls.table} {where_sql}", params)["n"]
        total_pages = max(1, math.ceil(total / page_size))
        page = min(max(1, page), total_pages)
        offset = (page - 1) * page_size

        columns_sql = ", ".join(["id"] + [c for c, _ in LIST_COLUMNS])
        rows = db.query_all(
            f"SELECT {columns_sql} FROM {cls.table} {where_sql} "
            f"ORDER BY nome_alimento ASC LIMIT %s OFFSET %s",
            params + [page_size, offset],
        )
        meta = {"page": page, "total_pages": total_pages, "total": total, "page_size": page_size}
        return cls._wrap_many(rows), meta

    @classmethod
    def categorie(cls):
        """Valori distinti di `categoria`, per popolare un filtro a tendina."""
        rows = db.query_all(f"SELECT DISTINCT categoria FROM {cls.table} ORDER BY categoria")
        return [r["categoria"] for r in rows]

    @classmethod
    def options(cls):
        """(codice_alimento, nome_alimento) di tutti gli alimenti, usato per
        popolare le tendine di scelta in ricette e piani alimentari."""
        return db.query_all(
            f"SELECT codice_alimento, nome_alimento FROM {cls.table} ORDER BY nome_alimento"
        )

    # ------------------------------------------------------------------
    # Scrittura
    # ------------------------------------------------------------------

    @classmethod
    def create(cls, data):
        values, errors = validate_fields(FIELDS, data)
        if errors:
            return None, errors

        dup = db.query_one(
            f"SELECT id FROM {cls.table} WHERE codice_alimento = %s", [values["codice_alimento"]]
        )
        if dup:
            return None, [f"Esiste gia' un alimento con codice \"{values['codice_alimento']}\"."]

        columns = ", ".join(FIELD_NAMES)
        placeholders = ", ".join(["%s"] * len(FIELD_NAMES))
        params = [values[name] for name in FIELD_NAMES]
        try:
            new_id, _ = db.execute(
                f"INSERT INTO {cls.table} ({columns}) VALUES ({placeholders})", params
            )
        except pymysql.err.IntegrityError:
            return None, ["Codice alimento gia' esistente."]
        return cls.get(new_id), []

    def update(self, data):
        values, errors = validate_fields(FIELDS, data)
        if errors:
            return errors

        dup = db.query_one(
            f"SELECT id FROM {self.table} WHERE codice_alimento = %s AND id != %s",
            [values["codice_alimento"], self.id],
        )
        if dup:
            return [f"Esiste gia' un altro alimento con codice \"{values['codice_alimento']}\"."]

        set_sql = ", ".join([f"{name} = %s" for name in FIELD_NAMES])
        params = [values[name] for name in FIELD_NAMES] + [self.id]
        try:
            db.execute(f"UPDATE {self.table} SET {set_sql} WHERE id = %s", params)
        except pymysql.err.IntegrityError:
            return ["Codice alimento gia' esistente."]
        self._row = dict(self.get(self.id)._row)
        return []

    def delete(self):
        db.execute(f"DELETE FROM {self.table} WHERE id = %s", [self.id])
