"""
Metadati della tabella `smartfood_porzioni_frequenze` (Piramide alimentare
Smartfood — porzioni e frequenze di consumo, rielaborazione Team Smartfood
su dati SINU/CREA/WCRF).

Stesso principio di `fields.py` (dedicato alla tabella `alimenti`): un
unico registro `FIELDS` descrive nome colonna, etichetta in italiano, tipo
di input, obbligatorieta', lunghezza massima e sezione del form. Viene
usato da `smartfood_views.py` per validare i dati del form e dai template
`smartfood_form.html` / `smartfood_view.html` per generare automaticamente
campi e scheda di dettaglio.

Tipi di campo supportati: "text", "textarea", "int", "decimal", "select".
Per "select" e' richiesta la chiave "choices" (lista di valori ammessi).
"""

# Le quattro "fasce" della piramide alimentare, cosi' come organizzate nel
# PDF di origine (dalla base alla punta della piramide).
FREQUENZA_CHOICES = ["giornaliera", "settimanale", "occasionale", "evitare"]

# Etichette e descrizioni mostrate nel menu /smartfood e nei filtri.
FREQUENZA_INFO = {
    "giornaliera": {
        "label": "Ogni giorno",
        "description": "Verdura, frutta, cereali, latte e yogurt, condimenti, acqua: la base della piramide, da consumare tutti i giorni.",
    },
    "settimanale": {
        "label": "Ogni settimana",
        "description": "Legumi, pesce, formaggi, uova, carne, tuberi: alimenti proteici da alternare nell'arco della settimana.",
    },
    "occasionale": {
        "label": "Ogni tanto",
        "description": "Dolci, zuccheri, bevande zuccherate, snack salati: un consumo occasionale, non quotidiano.",
    },
    "evitare": {
        "label": "Da evitare",
        "description": "Carni lavorate e bevande alcoliche: le linee guida internazionali raccomandano di limitarne fortemente il consumo.",
    },
}

FIELDS = [
    # --- Classificazione ------------------------------------------------
    {"name": "frequenza_consumo", "label": "Frequenza di consumo", "type": "select",
     "choices": FREQUENZA_CHOICES, "required": True, "group": "Classificazione"},
    {"name": "gruppo_alimenti", "label": "Gruppo di alimenti", "type": "text",
     "required": True, "maxlength": 60, "group": "Classificazione"},
    {"name": "alimento", "label": "Alimento", "type": "text",
     "required": True, "maxlength": 180, "group": "Classificazione"},
    {"name": "ordine", "label": "Ordine di visualizzazione", "type": "int",
     "required": True, "group": "Classificazione"},

    # --- Porzione ---------------------------------------------------------
    {"name": "porzione_standard", "label": "Porzione standard", "type": "text",
     "required": True, "maxlength": 80, "group": "Porzione"},
    {"name": "porzione_quantita", "label": "Quantita' numerica", "type": "decimal",
     "required": False, "group": "Porzione"},
    {"name": "porzione_unita", "label": "Unita' di misura", "type": "text",
     "required": False, "maxlength": 10, "group": "Porzione"},
    {"name": "corrispondenza", "label": "A cosa corrisponde", "type": "textarea",
     "required": False, "maxlength": 500, "group": "Porzione"},

    # --- Frequenza e consigli ----------------------------------------------
    {"name": "quante_volte", "label": "Quante volte", "type": "text",
     "required": True, "maxlength": 255, "group": "Frequenza e consigli"},
    {"name": "consiglio_smart", "label": "Consiglio smart", "type": "textarea",
     "required": False, "maxlength": None, "group": "Frequenza e consigli"},
]

# Normalizza le voci: aggiunge valori di default alle chiavi opzionali
for _f in FIELDS:
    _f.setdefault("required", False)
    _f.setdefault("maxlength", None)

FIELD_NAMES = [f["name"] for f in FIELDS]

# Ordine delle sezioni cosi' come devono apparire nel form / nella scheda
GROUP_ORDER = ["Classificazione", "Porzione", "Frequenza e consigli"]

# Colonne mostrate nella tabella riassuntiva dell'elenco
LIST_COLUMNS = [
    ("alimento", "Alimento"),
    ("gruppo_alimenti", "Gruppo di alimenti"),
    ("porzione_standard", "Porzione"),
    ("quante_volte", "Quante volte"),
]


def grouped_fields():
    """Restituisce i campi raggruppati per sezione, nell'ordine di GROUP_ORDER."""
    groups = []
    for group_name in GROUP_ORDER:
        items = [f for f in FIELDS if f["group"] == group_name]
        if items:
            groups.append({"name": group_name, "fields": items})
    return groups


def frequenza_label(key):
    """Etichetta leggibile di una fascia di frequenza (es. 'giornaliera' -> 'Ogni giorno')."""
    info = FREQUENZA_INFO.get(key)
    return info["label"] if info else key


def ordered_frequenze():
    """Restituisce le 4 fasce (chiave, info) nell'ordine della piramide."""
    return [(key, FREQUENZA_INFO[key]) for key in FREQUENZA_CHOICES]
