"""
Metadati delle tabelle `pazienti`, `piani_alimentari` e `piano_giorni`.

Segue lo stesso stile di `fields.py` (alimenti) e `ricette_fields.py`
(ricette): un'unica fonte di verita' sui campi dei form, usata da
`pazienti_views.py` e dai relativi template.

Il modello a tre livelli riprende la struttura del modulo cartaceo
"Giorno_PianoAlimentare": ogni PAZIENTE puo' avere piu' PIANI alimentari
(es. uno per periodo/revisione), e ogni piano ha sempre gli stessi 7
GIORNI della settimana (creati automaticamente alla creazione del piano,
sul modello delle 7 pagine del modulo cartaceo), ciascuno con gli stessi
campi liberi (colazione, spuntino, pranzo, merenda, cena) del modulo.

Tipi di campo supportati: "text", "textarea", "date", "int", "decimal", "select".
"""

from larn_lookup import PAL_CHOICES, PAL_LABELS

GIORNI_SETTIMANA = [
    "Lunedi", "Martedi", "Mercoledi", "Giovedi", "Venerdi", "Sabato", "Domenica",
]
GIORNI_SETTIMANA_LABEL = {
    "Lunedi": "Lunedi'", "Martedi": "Martedi'", "Mercoledi": "Mercoledi'",
    "Giovedi": "Giovedi'", "Venerdi": "Venerdi'", "Sabato": "Sabato", "Domenica": "Domenica",
}

# ---------------------------------------------------------------------
# Pazienti
# ---------------------------------------------------------------------

PAZIENTI_FIELDS = [
    {"name": "nome", "label": "Nome", "type": "text", "required": True, "maxlength": 100},
    {"name": "cognome", "label": "Cognome", "type": "text", "required": True, "maxlength": 100},
    {"name": "data_nascita", "label": "Data di nascita", "type": "date"},
    {"name": "sesso", "label": "Sesso", "type": "select", "choices": ["M", "F"],
     "choice_labels": {"M": "Maschio", "F": "Femmina"}},
    {"name": "altezza_cm", "label": "Altezza (cm)", "type": "int"},
    {"name": "peso_kg", "label": "Peso (kg)", "type": "decimal"},
    {"name": "livello_attivita_fisica", "label": "Livello di attivita' fisica (PAL)", "type": "select",
     "choices": PAL_CHOICES, "choice_labels": PAL_LABELS},
    {"name": "email", "label": "Email", "type": "text", "maxlength": 150},
    {"name": "telefono", "label": "Telefono", "type": "text", "maxlength": 30},
    {"name": "note", "label": "Note", "type": "textarea"},
    {"name": "attivo", "label": "In carico", "type": "bool", "default": 1},
]
for _f in PAZIENTI_FIELDS:
    _f.setdefault("required", False)
    _f.setdefault("maxlength", None)
    _f.setdefault("default", None)
    _f.setdefault("choice_labels", None)
PAZIENTI_FIELD_NAMES = [f["name"] for f in PAZIENTI_FIELDS]

PAZIENTI_LIST_COLUMNS = [
    ("cognome", "Cognome"),
    ("nome", "Nome"),
    ("data_nascita", "Data di nascita"),
    ("telefono", "Telefono"),
]

# ---------------------------------------------------------------------
# Piani alimentari (testata)
# ---------------------------------------------------------------------

PIANI_FIELDS = [
    {"name": "titolo", "label": "Titolo del piano", "type": "text", "required": True, "maxlength": 150},
    {"name": "data_inizio", "label": "Data inizio", "type": "date"},
    {"name": "data_fine", "label": "Data fine", "type": "date"},
    {"name": "note", "label": "Note", "type": "textarea"},
    {"name": "attivo", "label": "Piano attualmente in uso", "type": "bool", "default": 1},
]
for _f in PIANI_FIELDS:
    _f.setdefault("required", False)
    _f.setdefault("maxlength", None)
    _f.setdefault("default", None)
PIANI_FIELD_NAMES = [f["name"] for f in PIANI_FIELDS]

# ---------------------------------------------------------------------
# Giorno del piano (i pasti) — raggruppati per sezione, come nel modulo cartaceo
# ---------------------------------------------------------------------

GIORNO_SECTIONS = [
    {
        "key": "colazione",
        "title": "Colazione",
        "fields": [
            {"name": "colazione_latte", "label": "Latte", "type": "text", "maxlength": 255},
            {"name": "colazione_fette_biscottate", "label": "Fette biscottate", "type": "text", "maxlength": 255},
            {"name": "colazione_altro", "label": "Altro", "type": "text", "maxlength": 255},
        ],
    },
    {
        "key": "spuntino_10_30",
        "title": "Spuntino ore 10:30",
        "fields": [
            {"name": "spuntino_10_30", "label": "Spuntino ore 10:30", "type": "text", "maxlength": 255, "hide_label": True},
        ],
    },
    {
        "key": "pranzo",
        "title": "Pranzo",
        "fields": [
            {"name": "pranzo_primo_piatto", "label": "1° piatto", "type": "text", "maxlength": 255},
            {"name": "pranzo_secondo_piatto", "label": "2° piatto", "type": "text", "maxlength": 255},
            {"name": "pranzo_verdure_ortaggi", "label": "Verdure/ortaggi", "type": "text", "maxlength": 255},
            {"name": "pranzo_pane", "label": "Pane", "type": "text", "maxlength": 255},
            {"name": "pranzo_olio_cucchiaini", "label": "Olio extravergine (cucchiaini da caffe')", "type": "decimal"},
            {"name": "pranzo_olio_note", "label": "Olio extravergine, note", "type": "text", "maxlength": 255},
            {"name": "pranzo_frutta", "label": "Frutta", "type": "text", "maxlength": 255},
        ],
    },
    {
        "key": "merenda_17_30",
        "title": "Merenda ore 17:30",
        "fields": [
            {"name": "merenda_17_30", "label": "Merenda ore 17:30", "type": "text", "maxlength": 255, "hide_label": True},
        ],
    },
    {
        "key": "cena",
        "title": "Cena",
        "fields": [
            {"name": "cena_primo_piatto", "label": "1° piatto", "type": "text", "maxlength": 255},
            {"name": "cena_secondo_piatto", "label": "2° piatto", "type": "text", "maxlength": 255},
            {"name": "cena_verdure_ortaggi", "label": "Verdure/ortaggi", "type": "text", "maxlength": 255},
            {"name": "cena_pane", "label": "Pane", "type": "text", "maxlength": 255},
            {"name": "cena_olio_cucchiaini", "label": "Olio extravergine (cucchiaini da caffe')", "type": "decimal"},
            {"name": "cena_olio_note", "label": "Olio extravergine, note", "type": "text", "maxlength": 255},
            {"name": "cena_frutta", "label": "Frutta", "type": "text", "maxlength": 255},
        ],
    },
]

# Normalizza i campi di ogni sezione (stesse chiavi di default di PAZIENTI_FIELDS/PIANI_FIELDS)
for _section in GIORNO_SECTIONS:
    for _f in _section["fields"]:
        _f.setdefault("required", False)
        _f.setdefault("maxlength", None)
        _f.setdefault("default", None)
        _f.setdefault("hide_label", False)

GIORNO_FIELD_NAMES = [f["name"] for section in GIORNO_SECTIONS for f in section["fields"]]

# Coppie (sezione, campo_riassuntivo) mostrate nella card di anteprima di ogni
# giorno nella scheda del piano, per capire a colpo d'occhio cosa e' gia'
# stato compilato senza dover aprire ciascun giorno.
GIORNO_PREVIEW_FIELDS = [
    ("Colazione", "colazione_latte"),
    ("Pranzo", "pranzo_primo_piatto"),
    ("Cena", "cena_primo_piatto"),
]

# ---------------------------------------------------------------------
# Alimenti collegati a un pasto (per il calcolo automatico delle kcal)
# ---------------------------------------------------------------------
# I campi di GIORNO_SECTIONS sono testo libero (come nel modulo cartaceo):
# descrivono il pasto ma non sono legati all'archivio Alimenti. Per poter
# calcolare le kcal, ogni pasto (colazione/spuntino/pranzo/merenda/cena)
# puo' avere in aggiunta zero o piu' alimenti collegati con una quantita'
# in grammi (tabella `piano_pasto_alimenti`), esattamente come gli
# ingredienti di una ricetta sono collegati alla ricetta.

PASTI_CHOICES = [section["key"] for section in GIORNO_SECTIONS]
PASTI_LABELS = {section["key"]: section["title"] for section in GIORNO_SECTIONS}

# ---------------------------------------------------------------------
# Appuntamenti
# ---------------------------------------------------------------------
# Indipendenti dai piani alimentari: un paziente puo' avere appuntamenti
# (prima visita, controlli, ...) senza che questo richieda o modifichi un
# piano alimentare, e viceversa.

APPUNTAMENTI_TIPO_CHOICES = [
    "Prima visita", "Controllo", "Visita di follow-up", "Videochiamata", "Telefonica", "Altro",
]
APPUNTAMENTI_STATO_CHOICES = ["Programmato", "Completato", "Annullato", "Non presentato"]
# Colore/stile del badge di stato nei template (vedi static/style.css: badge-on/badge-off/badge-warn/badge-danger)
APPUNTAMENTI_STATO_BADGE = {
    "Programmato": "badge-on",
    "Completato": "badge-off",
    "Annullato": "badge-danger",
    "Non presentato": "badge-warn",
}

APPUNTAMENTI_FIELDS = [
    {"name": "data_ora", "label": "Data e ora", "type": "datetime", "required": True},
    {"name": "durata_minuti", "label": "Durata (minuti)", "type": "int", "default": 30},
    {"name": "tipo", "label": "Tipo di appuntamento", "type": "select", "required": True,
     "choices": APPUNTAMENTI_TIPO_CHOICES, "default": "Controllo"},
    {"name": "luogo", "label": "Luogo", "type": "text", "maxlength": 150},
    {"name": "stato", "label": "Stato", "type": "select", "required": True,
     "choices": APPUNTAMENTI_STATO_CHOICES, "default": "Programmato"},
    {"name": "note", "label": "Note", "type": "textarea"},
]
for _f in APPUNTAMENTI_FIELDS:
    _f.setdefault("required", False)
    _f.setdefault("maxlength", None)
    _f.setdefault("default", None)
    _f.setdefault("choice_labels", None)
APPUNTAMENTI_FIELD_NAMES = [f["name"] for f in APPUNTAMENTI_FIELDS]

APPUNTAMENTI_LIST_COLUMNS = [
    ("data_ora", "Data e ora"),
    ("tipo", "Tipo"),
    ("luogo", "Luogo"),
    ("stato", "Stato"),
]
