# -*- coding: utf-8 -*-
"""
Classe base per tutti i modelli dell'applicazione.

Ogni modello concreto (Alimento, Paziente, Ricetta, ...) rappresenta una
riga di una tabella (o di poche tabelle strettamente correlate) come un
oggetto Python con i propri metodi: query di lettura come classmethod
(`get`, `list`, ...), scrittura come metodo d'istanza (`update`, `delete`),
e serializzazione JSON con `to_dict()`.

Questa classe base fornisce le parti comuni:
    - wrapping di una riga (dict restituito da PyMySQL) con accesso sia
      per attributo (`paziente.nome`) sia per chiave (`paziente["nome"]`);
    - conversione dei tipi Python non nativamente JSON-serializzabili
      restituiti da PyMySQL (Decimal, date, datetime, timedelta).
"""
from decimal import Decimal
from datetime import date, datetime, timedelta


def jsonable(value):
    """Converte ricorsivamente un valore (compresi dict e list annidati) in
    una struttura nativamente serializzabile in JSON. Usato da Model.to_dict,
    ma anche da chi costruisce a mano un dizionario di risposta a partire da
    valori calcolati (es. i riferimenti LARN in larn_lookup.py, che sono
    dizionari annidati)."""
    if isinstance(value, Decimal):
        return float(value)
    if isinstance(value, (datetime, date)):
        return value.isoformat()
    if isinstance(value, timedelta):
        return value.total_seconds()
    if isinstance(value, dict):
        return {k: jsonable(v) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [jsonable(v) for v in value]
    return value


def jsonable_dict(row):
    """Applica jsonable() a un intero dict (riga SQL o struttura annidata)."""
    return jsonable(dict(row))


class Model:
    """Classe base: wrappa una riga (dict) in `self._row`.

    Le sottoclassi impostano l'attributo di classe `table` (nome della
    tabella su cui operano di default) e aggiungono i propri metodi di
    lettura/scrittura/calcolo.
    """

    table = None

    def __init__(self, row):
        # dict(...) fa una copia difensiva: modificare self._row non deve
        # alterare la riga originale restituita da PyMySQL.
        self._row = dict(row)

    def __getattr__(self, name):
        # Permette di leggere le colonne come attributi (self.nome, self.id, ...).
        # __getattr__ scatta solo se l'attributo non esiste gia' "normalmente",
        # quindi non interferisce con i metodi/attributi definiti dalle sottoclassi.
        try:
            return self._row[name]
        except KeyError:
            raise AttributeError(
                f"{type(self).__name__!r} non ha un attributo o una colonna {name!r}"
            )

    def __getitem__(self, key):
        return self._row[key]

    def __repr__(self):
        pk = self._row.get("id", "?")
        return f"<{type(self).__name__} id={pk}>"

    def value(self, key, default=None):
        """Accesso "sicuro" a una colonna (equivalente a dict.get).

        Si chiama `value` e non `get` di proposito: quasi tutte le
        sottoclassi (Alimento, Paziente, Ricetta, ...) definiscono un
        CLASSMETHOD chiamato `get(cls, id)` per recuperare una riga dal
        database (es. `Alimento.get(42)`); se questo metodo d'istanza si
        fosse chiamato allo stesso modo, in quelle sottoclassi il
        classmethod avrebbe "oscurato" questo metodo (in Python i due non
        possono coesistere con lo stesso nome), rendendo impossibile
        chiamare `self.get("colonna")` per leggere un campo.
        """
        return self._row.get(key, default)

    def to_dict(self):
        """Rappresentazione JSON-serializzabile della riga."""
        return jsonable_dict(self._row)

    @classmethod
    def _wrap(cls, row, *extra):
        """Costruisce un'istanza da una riga SQL, o None se la riga e' None
        (comodo per i vari `Model._wrap(db.query_one(...))`)."""
        return cls(row, *extra) if row is not None else None

    @classmethod
    def _wrap_many(cls, rows, *extra):
        return [cls(row, *extra) for row in rows]
