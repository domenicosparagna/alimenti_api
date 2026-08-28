# -*- coding: utf-8 -*-
"""
Modelli dell'area pazienti: Paziente, PianoAlimentare, PianoGiorno e
Appuntamento.

Ricalca il modello a tre livelli dell'app originale (pazienti_fields.py /
pazienti_views.py), ispirato al modulo cartaceo "Giorno_PianoAlimentare":
ogni Paziente puo' avere piu' PianoAlimentare (es. uno per periodo), e ogni
piano ha sempre gli stessi 7 PianoGiorno della settimana (creati
automaticamente alla creazione del piano). Appuntamento e' indipendente dai
piani: un paziente puo' avere appuntamenti (prima visita, controlli, ...)
senza che questo richieda o modifichi un piano alimentare.

`Paziente.riferimenti_larn()` collega il profilo del paziente alle tabelle
LARN tramite `larn_lookup.py` (invariato rispetto all'originale: la logica
di ricerca per eta'/sesso/PAL e' delicata e gia' corretta, non c'era motivo
di riscriverla).
"""
import math
from decimal import Decimal

import pymysql

import config
import db
import larn_lookup
from pazienti_fields import (
    PAZIENTI_FIELDS,
    PAZIENTI_FIELD_NAMES,
    PAZIENTI_LIST_COLUMNS,
    PIANI_FIELDS,
    PIANI_FIELD_NAMES,
    GIORNO_SECTIONS,
    GIORNO_FIELD_NAMES,
    PASTI_CHOICES,
    GIORNI_SETTIMANA,
    APPUNTAMENTI_FIELDS,
    APPUNTAMENTI_FIELD_NAMES,
)
from validation import validate_fields

from .base import Model

GIORNO_ALL_FIELDS = [f for section in GIORNO_SECTIONS for f in section["fields"]]

ALIMENTO_PASTO_FIELDS = [
    {"name": "pasto", "label": "Pasto", "type": "select", "choices": PASTI_CHOICES, "required": True},
    {"name": "codice_alimento", "label": "Alimento", "type": "text", "required": True, "maxlength": 10},
    {"name": "quantita_g", "label": "Quantita' (g)", "type": "decimal", "required": True},
    {"name": "note", "label": "Note", "type": "text", "required": False, "maxlength": 255},
]


class Paziente(Model):
    table = "pazienti"

    # ------------------------------------------------------------------
    # Lettura
    # ------------------------------------------------------------------

    @classmethod
    def get(cls, paziente_id):
        return cls._wrap(db.query_one(f"SELECT * FROM {cls.table} WHERE id = %s", [paziente_id]))

    @classmethod
    def list(cls, q="", solo_attivi=True, page=1, page_size=None):
        page_size = page_size or config.PAGE_SIZE
        where_clauses, params = [], []
        if q:
            where_clauses.append("(cognome LIKE %s OR nome LIKE %s)")
            params += [f"%{q}%", f"%{q}%"]
        if solo_attivi:
            where_clauses.append("attivo = 1")
        where_sql = ("WHERE " + " AND ".join(where_clauses)) if where_clauses else ""

        total = db.query_one(f"SELECT COUNT(*) AS n FROM {cls.table} {where_sql}", params)["n"]
        total_pages = max(1, math.ceil(total / page_size))
        page = min(max(1, page), total_pages)
        offset = (page - 1) * page_size

        columns_sql = ", ".join(["id"] + [c for c, _ in PAZIENTI_LIST_COLUMNS])
        rows = db.query_all(
            f"SELECT {columns_sql} FROM {cls.table} {where_sql} "
            f"ORDER BY cognome ASC, nome ASC LIMIT %s OFFSET %s",
            params + [page_size, offset],
        )
        meta = {"page": page, "total_pages": total_pages, "total": total, "page_size": page_size}
        return cls._wrap_many(rows), meta

    @classmethod
    def options(cls):
        return db.query_all(f"SELECT id, nome, cognome FROM {cls.table} ORDER BY cognome, nome")

    # ------------------------------------------------------------------
    # Scrittura
    # ------------------------------------------------------------------

    @classmethod
    def create(cls, data):
        values, errors = validate_fields(PAZIENTI_FIELDS, data)
        if errors:
            return None, errors
        columns = ", ".join(PAZIENTI_FIELD_NAMES)
        placeholders = ", ".join(["%s"] * len(PAZIENTI_FIELD_NAMES))
        params = [values[name] for name in PAZIENTI_FIELD_NAMES]
        new_id, _ = db.execute(f"INSERT INTO {cls.table} ({columns}) VALUES ({placeholders})", params)
        return cls.get(new_id), []

    def update(self, data):
        values, errors = validate_fields(PAZIENTI_FIELDS, data)
        if errors:
            return errors
        set_sql = ", ".join([f"{name} = %s" for name in PAZIENTI_FIELD_NAMES])
        params = [values[name] for name in PAZIENTI_FIELD_NAMES] + [self.id]
        db.execute(f"UPDATE {self.table} SET {set_sql} WHERE id = %s", params)
        self._row = dict(self.get(self.id)._row)
        return []

    def delete(self):
        # CASCADE su piani_alimentari, piano_giorni e appuntamenti (vedi sql/*.sql).
        db.execute(f"DELETE FROM {self.table} WHERE id = %s", [self.id])

    # ------------------------------------------------------------------
    # Relazioni e calcoli di dominio
    # ------------------------------------------------------------------

    def piani(self):
        rows = db.query_all(
            "SELECT * FROM piani_alimentari WHERE paziente_id = %s ORDER BY attivo DESC, creato_il DESC",
            [self.id],
        )
        return PianoAlimentare._wrap_many(rows)

    def appuntamenti(self):
        rows = db.query_all(
            "SELECT * FROM appuntamenti WHERE paziente_id = %s ORDER BY data_ora ASC", [self.id]
        )
        return Appuntamento._wrap_many(rows)

    def riferimenti_larn(self):
        """Fabbisogno energetico/proteico/idrico di riferimento (tabelle
        LARN), calcolato a runtime dal profilo del paziente (eta', sesso,
        peso, altezza, PAL). Vedi larn_lookup.py."""
        return larn_lookup.riferimenti_paziente(dict(self._row))


class PianoAlimentare(Model):
    table = "piani_alimentari"

    @classmethod
    def get(cls, paziente_id, piano_id):
        row = db.query_one(
            f"SELECT * FROM {cls.table} WHERE id = %s AND paziente_id = %s", [piano_id, paziente_id]
        )
        return cls._wrap(row)

    @classmethod
    def create(cls, paziente_id, data):
        values, errors = validate_fields(PIANI_FIELDS, data)
        if errors:
            return None, errors
        columns = ", ".join(["paziente_id"] + PIANI_FIELD_NAMES)
        placeholders = ", ".join(["%s"] * (len(PIANI_FIELD_NAMES) + 1))
        params = [paziente_id] + [values[name] for name in PIANI_FIELD_NAMES]
        new_id, _ = db.execute(f"INSERT INTO {cls.table} ({columns}) VALUES ({placeholders})", params)

        # Crea automaticamente i 7 giorni della settimana, vuoti e pronti
        # da compilare (stesso comportamento dell'app originale).
        for giorno in GIORNI_SETTIMANA:
            db.execute(
                "INSERT INTO piano_giorni (piano_id, giorno_settimana) VALUES (%s, %s)", [new_id, giorno]
            )
        return cls.get(paziente_id, new_id), []

    def update(self, data):
        values, errors = validate_fields(PIANI_FIELDS, data)
        if errors:
            return errors
        set_sql = ", ".join([f"{name} = %s" for name in PIANI_FIELD_NAMES])
        params = [values[name] for name in PIANI_FIELD_NAMES] + [self.id]
        db.execute(f"UPDATE {self.table} SET {set_sql} WHERE id = %s", params)
        self._row = dict(db.query_one(f"SELECT * FROM {self.table} WHERE id = %s", [self.id]))
        return []

    def delete(self):
        # CASCADE su piano_giorni (vedi sql/pazienti_schema.sql).
        db.execute(f"DELETE FROM {self.table} WHERE id = %s", [self.id])

    def giorni(self):
        """I 7 giorni del piano, sempre nell'ordine Lunedi'...Domenica
        (indipendentemente dall'ordine di inserimento nel DB)."""
        rows = db.query_all("SELECT * FROM piano_giorni WHERE piano_id = %s", [self.id])
        by_day = {r["giorno_settimana"]: r for r in rows}
        out = []
        for giorno in GIORNI_SETTIMANA:
            row = by_day.get(giorno)
            out.append(PianoGiorno(row) if row else None)
        return out


class PianoGiorno(Model):
    table = "piano_giorni"

    @classmethod
    def get(cls, piano_id, giorno):
        if giorno not in GIORNI_SETTIMANA:
            return None
        row = db.query_one(
            f"SELECT * FROM {cls.table} WHERE piano_id = %s AND giorno_settimana = %s",
            [piano_id, giorno],
        )
        return cls._wrap(row)

    def to_dict(self):
        data = super().to_dict()
        data["compilato"] = any(self.value(name) is not None for name in GIORNO_FIELD_NAMES)
        return data

    def update(self, data):
        values, errors = validate_fields(GIORNO_ALL_FIELDS, data)
        if errors:
            return errors
        set_sql = ", ".join([f"{name} = %s" for name in GIORNO_FIELD_NAMES])
        params = [values[name] for name in GIORNO_FIELD_NAMES] + [self.piano_id, self.giorno_settimana]
        db.execute(
            f"UPDATE {self.table} SET {set_sql} WHERE piano_id = %s AND giorno_settimana = %s", params
        )
        self._row = dict(
            db.query_one(
                f"SELECT * FROM {self.table} WHERE piano_id = %s AND giorno_settimana = %s",
                [self.piano_id, self.giorno_settimana],
            )
        )
        return []

    def alimenti_per_pasto(self):
        """Alimenti collegati ai pasti di questo giorno, raggruppati per
        pasto (uno dei valori di PASTI_CHOICES)."""
        rows = db.query_all(
            """
            SELECT ppa.id, ppa.pasto, ppa.quantita_g, ppa.note, ppa.codice_alimento,
                   a.nome_alimento, (a.energia_kcal / 100 * ppa.quantita_g) AS kcal_contributo
            FROM piano_pasto_alimenti ppa
            JOIN alimenti a ON a.codice_alimento = ppa.codice_alimento
            WHERE ppa.piano_giorno_id = %s
            ORDER BY a.nome_alimento
            """,
            [self.id],
        )
        by_pasto = {pasto: [] for pasto in PASTI_CHOICES}
        for r in rows:
            by_pasto[r["pasto"]].append(r)
        return by_pasto

    def kcal_per_pasto_e_totale(self):
        rows = db.query_all(
            """
            SELECT ppa.pasto, SUM(a.energia_kcal / 100 * ppa.quantita_g) AS kcal
            FROM piano_pasto_alimenti ppa
            JOIN alimenti a ON a.codice_alimento = ppa.codice_alimento
            WHERE ppa.piano_giorno_id = %s
            GROUP BY ppa.pasto
            """,
            [self.id],
        )
        per_pasto = {pasto: None for pasto in PASTI_CHOICES}
        for r in rows:
            per_pasto[r["pasto"]] = r["kcal"]
        totale = sum((v for v in per_pasto.values() if v is not None), Decimal("0"))
        return per_pasto, totale

    def proteine_totali(self):
        row = db.query_one(
            """
            SELECT SUM(a.proteine_g / 100 * ppa.quantita_g) AS proteine
            FROM piano_pasto_alimenti ppa
            JOIN alimenti a ON a.codice_alimento = ppa.codice_alimento
            WHERE ppa.piano_giorno_id = %s
            """,
            [self.id],
        )
        return row["proteine"] if row and row["proteine"] is not None else Decimal("0")

    def ricalcola_kcal(self):
        """Ricalcola e SALVA il totale kcal del giorno dagli alimenti
        collegati. Restituisce (kcal_totali, errors)."""
        _, totale = self.kcal_per_pasto_e_totale()
        if totale == 0:
            return None, ["Collega almeno un alimento a un pasto prima di ricalcolare le kcal."]
        totale = round(totale, 1)
        db.execute("UPDATE piano_giorni SET kcal_stimate = %s WHERE id = %s", [totale, self.id])
        self._row["kcal_stimate"] = totale
        return totale, []

    def collega_alimento(self, data):
        """Collega un alimento (con quantita' in grammi) a uno dei pasti del
        giorno. Restituisce (nuovo_id, errors)."""
        values, errors = validate_fields(ALIMENTO_PASTO_FIELDS, data)
        if values.get("quantita_g") is not None and values["quantita_g"] <= 0:
            errors.append("La quantita' deve essere maggiore di zero.")
        if errors:
            return None, errors
        try:
            new_id, _ = db.execute(
                "INSERT INTO piano_pasto_alimenti (piano_giorno_id, pasto, codice_alimento, quantita_g, note) "
                "VALUES (%s, %s, %s, %s, %s)",
                [self.id, values["pasto"], values["codice_alimento"], values["quantita_g"], values["note"]],
            )
        except pymysql.err.IntegrityError:
            return None, ["Alimento non valido."]
        return new_id, []

    def scollega_alimento(self, link_id):
        """Rimuove un alimento collegato. True se trovato ed eliminato."""
        row = db.query_one(
            "SELECT id FROM piano_pasto_alimenti WHERE id = %s AND piano_giorno_id = %s",
            [link_id, self.id],
        )
        if row is None:
            return False
        db.execute("DELETE FROM piano_pasto_alimenti WHERE id = %s", [link_id])
        return True


class Appuntamento(Model):
    table = "appuntamenti"

    @classmethod
    def get(cls, app_id):
        return cls._wrap(db.query_one(f"SELECT * FROM {cls.table} WHERE id = %s", [app_id]))

    @classmethod
    def agenda(cls, q="", stato="", mostra_passati=False, page=1, page_size=None):
        """Appuntamenti su tutti i pazienti, con filtri (usato dalla vista
        "agenda" del front-end): stessa logica dell'app originale, non
        annidata sotto un paziente specifico, perche' un appuntamento e'
        identificato dal proprio id ed e' consultabile/modificabile anche
        direttamente dall'agenda generale."""
        page_size = page_size or config.PAGE_SIZE
        where_clauses, params = [], []
        if q:
            where_clauses.append("(p.nome LIKE %s OR p.cognome LIKE %s)")
            params += [f"%{q}%", f"%{q}%"]
        if stato:
            where_clauses.append("a.stato = %s")
            params.append(stato)
        if not mostra_passati:
            where_clauses.append("a.data_ora >= NOW()")
        where_sql = ("WHERE " + " AND ".join(where_clauses)) if where_clauses else ""

        total = db.query_one(
            f"SELECT COUNT(*) AS n FROM appuntamenti a JOIN pazienti p ON p.id = a.paziente_id {where_sql}",
            params,
        )["n"]
        total_pages = max(1, math.ceil(total / page_size))
        page = min(max(1, page), total_pages)
        offset = (page - 1) * page_size

        rows = db.query_all(
            f"""
            SELECT a.*, p.nome AS paziente_nome, p.cognome AS paziente_cognome
            FROM appuntamenti a
            JOIN pazienti p ON p.id = a.paziente_id
            {where_sql}
            ORDER BY a.data_ora ASC
            LIMIT %s OFFSET %s
            """,
            params + [page_size, offset],
        )
        meta = {"page": page, "total_pages": total_pages, "total": total, "page_size": page_size}
        return cls._wrap_many(rows), meta

    @classmethod
    def create(cls, paziente_id, data):
        if db.query_one("SELECT id FROM pazienti WHERE id = %s", [paziente_id]) is None:
            return None, ["Paziente non valido."]
        values, errors = validate_fields(APPUNTAMENTI_FIELDS, data)
        if errors:
            return None, errors
        columns = ", ".join(["paziente_id"] + APPUNTAMENTI_FIELD_NAMES)
        placeholders = ", ".join(["%s"] * (len(APPUNTAMENTI_FIELD_NAMES) + 1))
        params = [paziente_id] + [values[name] for name in APPUNTAMENTI_FIELD_NAMES]
        new_id, _ = db.execute(f"INSERT INTO {cls.table} ({columns}) VALUES ({placeholders})", params)
        return cls.get(new_id), []

    def update(self, data):
        values, errors = validate_fields(APPUNTAMENTI_FIELDS, data)
        if errors:
            return errors
        set_sql = ", ".join([f"{name} = %s" for name in APPUNTAMENTI_FIELD_NAMES])
        params = [values[name] for name in APPUNTAMENTI_FIELD_NAMES] + [self.id]
        db.execute(f"UPDATE {self.table} SET {set_sql} WHERE id = %s", params)
        self._row = dict(self.get(self.id)._row)
        return []

    def delete(self):
        db.execute(f"DELETE FROM {self.table} WHERE id = %s", [self.id])
