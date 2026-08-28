# -*- coding: utf-8 -*-
"""
Modello SmartfoodRiga — tabella `smartfood_porzioni_frequenze` (Piramide
alimentare Smartfood: porzioni e frequenze di consumo consigliate).
"""
import pymysql

import db
from smartfood_fields import FIELDS, FIELD_NAMES, LIST_COLUMNS, ordered_frequenze
from validation import validate_fields

from .base import Model


class SmartfoodRiga(Model):
    table = "smartfood_porzioni_frequenze"

    # ------------------------------------------------------------------
    # Lettura
    # ------------------------------------------------------------------

    @classmethod
    def get(cls, row_id):
        return cls._wrap(db.query_one(f"SELECT * FROM {cls.table} WHERE id = %s", [row_id]))

    @classmethod
    def fasce_meta(cls):
        """Le 4 fasce della piramide (giornaliera/settimanale/occasionale/
        evitare) con conteggio righe, per il menu /smartfood."""
        out = []
        for key, info in ordered_frequenze():
            total = db.query_one(
                f"SELECT COUNT(*) AS n FROM {cls.table} WHERE frequenza_consumo = %s", [key]
            )["n"]
            out.append({"key": key, **info, "total": total})
        return out

    @classmethod
    def list(cls, frequenza="", gruppo="", q=""):
        where_clauses, params = [], []
        if frequenza:
            where_clauses.append("frequenza_consumo = %s")
            params.append(frequenza)
        if gruppo:
            where_clauses.append("gruppo_alimenti = %s")
            params.append(gruppo)
        if q:
            where_clauses.append("(alimento LIKE %s OR gruppo_alimenti LIKE %s)")
            params += [f"%{q}%", f"%{q}%"]
        where_sql = ("WHERE " + " AND ".join(where_clauses)) if where_clauses else ""

        columns_sql = ", ".join(["id"] + [c for c, _ in LIST_COLUMNS])
        rows = db.query_all(
            f"SELECT {columns_sql} FROM {cls.table} {where_sql} ORDER BY ordine ASC", params
        )
        return cls._wrap_many(rows)

    @classmethod
    def gruppi(cls):
        rows = db.query_all(f"SELECT DISTINCT gruppo_alimenti FROM {cls.table} ORDER BY gruppo_alimenti")
        return [r["gruppo_alimenti"] for r in rows]

    # ------------------------------------------------------------------
    # Scrittura
    # ------------------------------------------------------------------

    @classmethod
    def create(cls, data):
        values, errors = validate_fields(FIELDS, data)
        if errors:
            return None, errors
        columns = ", ".join(FIELD_NAMES)
        placeholders = ", ".join(["%s"] * len(FIELD_NAMES))
        params = [values[name] for name in FIELD_NAMES]
        try:
            new_id, _ = db.execute(
                f"INSERT INTO {cls.table} ({columns}) VALUES ({placeholders})", params
            )
        except pymysql.err.IntegrityError as e:
            return None, [f"Impossibile salvare: {e}"]
        return cls.get(new_id), []

    def update(self, data):
        values, errors = validate_fields(FIELDS, data)
        if errors:
            return errors
        set_sql = ", ".join([f"{name} = %s" for name in FIELD_NAMES])
        params = [values[name] for name in FIELD_NAMES] + [self.id]
        try:
            db.execute(f"UPDATE {self.table} SET {set_sql} WHERE id = %s", params)
        except pymysql.err.IntegrityError as e:
            return [f"Impossibile salvare: {e}"]
        self._row = dict(self.get(self.id)._row)
        return []

    def delete(self):
        db.execute(f"DELETE FROM {self.table} WHERE id = %s", [self.id])
