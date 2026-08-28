"""
Metadati della tabella `ricette` (dati di testata di ciascuna ricetta).

Segue lo stesso stile di `fields.py` (alimenti) e `larn_fields.py` (LARN):
un'unica fonte di verita' sui campi del form, usata da `ricette_views.py`
e dai template `ricette_form.html` / `ricette_view.html` / `ricette_list.html`.

A differenza di `alimenti` e delle tabelle LARN, `ricette` e' in relazione
1-a-molti con `ricette_ingredienti` (la composizione della ricetta, con
riferimento a `alimenti.codice_alimento`): quella parte e' gestita a parte
in `ricette_views.py`, perche' coinvolge una join con un'altra tabella e
non un semplice CRUD a riga singola.

Tipi di campo supportati: "text", "textarea", "int", "decimal", "select", "bool".
Per "select" e' richiesta la chiave "choices" (lista di valori ammessi).
I campi non obbligatori possono restare NULL.
"""

CATEGORIA_CHOICES = [
    "Colazione", "Primo Piatto", "Secondo Piatto", "Piatto Unico",
    "Contorno", "Spuntino",
]
DIFFICOLTA_CHOICES = ["Facile", "Media", "Difficile"]

RICETTE_TABLE = "ricette"

# Campi di testata (tutti tranne id), nell'ordine in cui compaiono nel form.
RICETTE_FIELDS = [
    {"name": "nome_ricetta", "label": "Nome ricetta", "type": "text",
     "required": True, "maxlength": 150},
    {"name": "categoria_ricetta", "label": "Categoria", "type": "select",
     "choices": CATEGORIA_CHOICES, "required": True},
    {"name": "porzioni", "label": "Porzioni", "type": "int", "required": True, "default": 1},
    {"name": "tempo_preparazione_min", "label": "Tempo di preparazione (min)", "type": "int"},
    {"name": "difficolta", "label": "Difficolta'", "type": "select", "choices": DIFFICOLTA_CHOICES},
    {"name": "descrizione", "label": "Descrizione", "type": "textarea"},
    {"name": "note_nutrizionali", "label": "Note nutrizionali", "type": "textarea"},
    {"name": "tag_dietetici", "label": "Tag dietetici (separati da ;)", "type": "text", "maxlength": 255},
    {"name": "energia_kcal_porzione", "label": "Energia per porzione (kcal)", "type": "decimal"},
    {"name": "proteine_g_porzione", "label": "Proteine per porzione (g)", "type": "decimal"},
    {"name": "lipidi_g_porzione", "label": "Lipidi per porzione (g)", "type": "decimal"},
    {"name": "carboidrati_g_porzione", "label": "Carboidrati per porzione (g)", "type": "decimal"},
    {"name": "fibra_g_porzione", "label": "Fibra per porzione (g)", "type": "decimal"},
    {"name": "sodio_mg_porzione", "label": "Sodio per porzione (mg)", "type": "decimal"},
    {"name": "indice_glicemico_medio", "label": "Indice glicemico medio", "type": "decimal"},
    {"name": "vegano", "label": "Vegano", "type": "bool"},
    {"name": "vegetariano", "label": "Vegetariano", "type": "bool"},
    {"name": "senza_glutine", "label": "Senza glutine", "type": "bool"},
    {"name": "allergeni", "label": "Allergeni (separati da ;)", "type": "text", "maxlength": 255},
]

# Normalizza le voci: aggiunge valori di default alle chiavi opzionali di ogni campo
for _f in RICETTE_FIELDS:
    _f.setdefault("required", False)
    _f.setdefault("maxlength", None)
    _f.setdefault("default", None)

RICETTE_FIELD_NAMES = [f["name"] for f in RICETTE_FIELDS]

# Colonne mostrate nella tabella riassuntiva dell'elenco ricette
LIST_COLUMNS = [
    ("nome_ricetta", "Nome ricetta"),
    ("categoria_ricetta", "Categoria"),
    ("porzioni", "Porzioni"),
    ("tempo_preparazione_min", "Tempo (min)"),
    ("energia_kcal_porzione", "Energia (kcal/porz.)"),
]

# Colonne per cui offrire un filtro a tendina nell'elenco ricette
FILTERS = ["categoria_ricetta", "difficolta"]

# Campi nutrizionali per porzione mostrati nella scheda di dettaglio,
# affiancati al totale ricalcolato dagli ingredienti (vedi ricette_views.py)
VALORI_PORZIONE_FIELDS = [
    ("energia_kcal_porzione", "Energia (kcal)"),
    ("proteine_g_porzione", "Proteine (g)"),
    ("lipidi_g_porzione", "Lipidi (g)"),
    ("carboidrati_g_porzione", "Carboidrati (g)"),
    ("fibra_g_porzione", "Fibra (g)"),
    ("sodio_mg_porzione", "Sodio (mg)"),
]
