# -*- coding: utf-8 -*-
"""
Modello generico per le 15 tabelle LARN (Livelli di Assunzione di
Riferimento di Nutrienti). Come nell'app originale (larn_views.py +
larn_fields.py), un'unica classe copre tutte le tabelle invece di scrivere
15 modelli quasi identici: la tabella su cui operare e' identificata da
`table_key` e risolta tramite il registro `LARN_TABLES` (larn_fields.py).

Nota sulla sicurezza (invariata rispetto all'originale): `table_key` non
finisce mai direttamente in una query SQL. Viene sempre prima cercato nel
dizionario `LARN_TABLES` (un registro fisso definito nel codice, non
derivato dall'input dell'utente); solo il nome di tabella e i nomi di
colonna ricavati da quella voce del registro vengono interpolati nell'SQL,
mentre tutti i *valori* passano sempre come parametri (%s).
"""
import pymysql

import db
from larn_fields import get_table_config, ordered_tables
from validation import validate_fields

from .base import Model


class LarnRiga(Model):
    """Wrappa una riga di una qualsiasi tabella LARN. A differenza degli
    altri modelli non ha una `table` fissa: ogni istanza porta con se' la
    config (`cfg`) e la chiave (`table_key`) della tabella a cui appartiene."""

    def __init__(self, row, cfg, table_key):
        super().__init__(row)
        self.cfg = cfg
        self.table_key = table_key

    def to_dict(self):
        data = super().to_dict()
        data["_table_key"] = self.table_key
        return data

    # ------------------------------------------------------------------
    # Metadati (per il menu /api/larn/tables e per un front-end generico
    # che si auto-configura sui campi, senza dover conoscere in anticipo
    # la struttura di ciascuna delle 15 tabelle)
    # ------------------------------------------------------------------

    @classmethod
    def tables_meta(cls):
        out = []
        for key, cfg in ordered_tables():
            total = db.query_one(f"SELECT COUNT(*) AS n FROM {cfg['table']}")["n"]
            out.append(
                {
                    "key": key,
                    "label": cfg["label"],
                    "plural_label": cfg["plural_label"],
                    "description": cfg["description"],
                    "fields": cfg["fields"],
                    "list_columns": cfg["list_columns"],
                    "filters": cfg["filters"],
                    "total": total,
                }
            )
        return out

    @classmethod
    def table_meta(cls, table_key):
        cfg = get_table_config(table_key)
        if cfg is None:
            return None
        return {
            "key": table_key,
            "label": cfg["label"],
            "plural_label": cfg["plural_label"],
            "description": cfg["description"],
            "fields": cfg["fields"],
            "list_columns": cfg["list_columns"],
            "filters": cfg["filters"],
        }

    # ------------------------------------------------------------------
    # Lettura
    # ------------------------------------------------------------------

    @classmethod
    def list(cls, table_key, filters=None):
        """Restituisce (items, meta) oppure (None, None) se `table_key` non
        e' una tabella LARN nota. `meta` contiene le opzioni disponibili per
        ciascun filtro e i filtri correntemente attivi."""
        cfg = get_table_config(table_key)
        if cfg is None:
            return None, None

        filters = filters or {}
        where_clauses, params = [], []
        active_filters, filter_options = {}, {}

        for col in cfg["filters"]:
            options = db.query_all(
                f"SELECT DISTINCT {col} AS v FROM {cfg['table']} "
                f"WHERE {col} IS NOT NULL AND {col} != '' ORDER BY {col}"
            )
            filter_options[col] = [o["v"] for o in options]

            val = (filters.get(col) or "").strip()
            if val:
                active_filters[col] = val
                where_clauses.append(f"{col} = %s")
                params.append(val)

        where_sql = ("WHERE " + " AND ".join(where_clauses)) if where_clauses else ""
        columns_sql = ", ".join(["id"] + cfg["list_columns"])
        rows = db.query_all(
            f"SELECT {columns_sql} FROM {cfg['table']} {where_sql} ORDER BY {cfg['default_order']}",
            params,
        )
        items = [cls(r, cfg, table_key) for r in rows]
        meta = {"filter_options": filter_options, "active_filters": active_filters}
        return items, meta

    @classmethod
    def get(cls, table_key, row_id):
        cfg = get_table_config(table_key)
        if cfg is None:
            return None
        row = db.query_one(f"SELECT * FROM {cfg['table']} WHERE id = %s", [row_id])
        return cls(row, cfg, table_key) if row is not None else None

    # ------------------------------------------------------------------
    # Scrittura
    # ------------------------------------------------------------------

    @classmethod
    def create(cls, table_key, data):
        cfg = get_table_config(table_key)
        if cfg is None:
            return None, ["Tabella LARN sconosciuta."]

        values, errors = validate_fields(cfg["fields"], data)
        if errors:
            return None, errors

        columns = ", ".join(cfg["field_names"])
        placeholders = ", ".join(["%s"] * len(cfg["field_names"]))
        params = [values[name] for name in cfg["field_names"]]
        try:
            new_id, _ = db.execute(
                f"INSERT INTO {cfg['table']} ({columns}) VALUES ({placeholders})", params
            )
        except pymysql.err.IntegrityError as e:
            return None, [f"Impossibile salvare: {e}"]
        return cls.get(table_key, new_id), []

    def update(self, data):
        values, errors = validate_fields(self.cfg["fields"], data)
        if errors:
            return errors

        set_sql = ", ".join([f"{name} = %s" for name in self.cfg["field_names"]])
        params = [values[name] for name in self.cfg["field_names"]] + [self.id]
        try:
            db.execute(f"UPDATE {self.cfg['table']} SET {set_sql} WHERE id = %s", params)
        except pymysql.err.IntegrityError as e:
            return [f"Impossibile salvare: {e}"]
        self._row = dict(self.get(self.table_key, self.id)._row)
        return []

    def delete(self):
        db.execute(f"DELETE FROM {self.cfg['table']} WHERE id = %s", [self.id])
