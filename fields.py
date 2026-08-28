"""
Metadati delle colonne della tabella `alimenti`.

Ogni voce descrive un campo del form (nome colonna, etichetta in italiano,
tipo di input HTML, se e' obbligatorio, lunghezza massima e il gruppo/
sezione a cui appartiene). Questa unica fonte di verita' viene usata da:

- app.py         per validare e leggere i dati inviati dal form
- templates/form.html  per generare automaticamente i campi del form
- templates/view.html  per mostrare la scheda alimento raggruppata per sezione
- templates/index.html per scegliere le colonne mostrate in tabella

Tipi supportati: "text", "textarea", "decimal", "bool".
"""

FIELDS = [
    # --- Anagrafica -------------------------------------------------
    {"name": "nome_alimento", "label": "Nome alimento", "type": "text",
     "required": True, "maxlength": 150, "group": "Anagrafica"},
    {"name": "categoria", "label": "Categoria", "type": "text",
     "required": True, "maxlength": 100, "group": "Anagrafica"},
    {"name": "codice_alimento", "label": "Codice alimento", "type": "text",
     "required": True, "maxlength": 10, "group": "Anagrafica"},
    {"name": "gruppo_alimentare_crea", "label": "Gruppo alimentare CREA", "type": "text",
     "required": False, "maxlength": 60, "group": "Anagrafica"},
    {"name": "parte_edibile", "label": "Parte edibile", "type": "text",
     "required": False, "maxlength": 20, "group": "Anagrafica"},
    {"name": "porzione", "label": "Porzione", "type": "text",
     "required": False, "maxlength": 20, "group": "Anagrafica"},
    {"name": "allergeni", "label": "Allergeni (separati da ;)", "type": "text",
     "required": False, "maxlength": 255, "group": "Anagrafica"},
    {"name": "informazioni", "label": "Informazioni", "type": "textarea",
     "required": False, "maxlength": None, "group": "Anagrafica"},

    # --- Etichette dietetiche ----------------------------------------
    {"name": "vegano", "label": "Vegano", "type": "bool",
     "required": False, "group": "Etichette dietetiche"},
    {"name": "vegetariano", "label": "Vegetariano", "type": "bool",
     "required": False, "group": "Etichette dietetiche"},
    {"name": "senza_glutine", "label": "Senza glutine", "type": "bool",
     "required": False, "group": "Etichette dietetiche"},

    # --- Energia e macronutrienti --------------------------------------
    {"name": "acqua_g", "label": "Acqua (g)", "type": "decimal", "group": "Energia e macronutrienti"},
    {"name": "energia_kcal", "label": "Energia (kcal)", "type": "decimal", "group": "Energia e macronutrienti"},
    {"name": "energia_kj", "label": "Energia (kJ)", "type": "decimal", "group": "Energia e macronutrienti"},
    {"name": "proteine_g", "label": "Proteine (g)", "type": "decimal", "group": "Energia e macronutrienti"},
    {"name": "lipidi_g", "label": "Lipidi (g)", "type": "decimal", "group": "Energia e macronutrienti"},
    {"name": "carboidrati_disponibili_g", "label": "Carboidrati disponibili (g)", "type": "decimal", "group": "Energia e macronutrienti"},
    {"name": "amido_g", "label": "Amido (g)", "type": "decimal", "group": "Energia e macronutrienti"},
    {"name": "zuccheri_solubili_g", "label": "Zuccheri solubili (g)", "type": "decimal", "group": "Energia e macronutrienti"},
    {"name": "alcool_g", "label": "Alcool (g)", "type": "decimal", "group": "Energia e macronutrienti"},
    {"name": "fibra_totale_g", "label": "Fibra totale (g)", "type": "decimal", "group": "Energia e macronutrienti"},
    {"name": "indice_glicemico", "label": "Indice glicemico", "type": "decimal", "group": "Energia e macronutrienti"},
    {"name": "carico_glicemico", "label": "Carico glicemico", "type": "decimal", "group": "Energia e macronutrienti"},

    # --- Zuccheri semplici --------------------------------------------
    {"name": "saccarosio_g", "label": "Saccarosio (g)", "type": "decimal", "group": "Zuccheri semplici"},
    {"name": "glucosio_g", "label": "Glucosio (g)", "type": "decimal", "group": "Zuccheri semplici"},
    {"name": "fruttosio_g", "label": "Fruttosio (g)", "type": "decimal", "group": "Zuccheri semplici"},
    {"name": "fruttoligosaccaridi_g", "label": "Fruttoligosaccaridi (g)", "type": "decimal", "group": "Zuccheri semplici"},

    # --- Minerali -------------------------------------------------------
    {"name": "sodio_mg", "label": "Sodio (mg)", "type": "decimal", "group": "Minerali"},
    {"name": "potassio_mg", "label": "Potassio (mg)", "type": "decimal", "group": "Minerali"},
    {"name": "calcio_mg", "label": "Calcio (mg)", "type": "decimal", "group": "Minerali"},
    {"name": "fosforo_mg", "label": "Fosforo (mg)", "type": "decimal", "group": "Minerali"},
    {"name": "ferro_mg", "label": "Ferro (mg)", "type": "decimal", "group": "Minerali"},
    {"name": "magnesio_mg", "label": "Magnesio (mg)", "type": "decimal", "group": "Minerali"},
    {"name": "rame_mg", "label": "Rame (mg)", "type": "decimal", "group": "Minerali"},
    {"name": "zinco_mg", "label": "Zinco (mg)", "type": "decimal", "group": "Minerali"},
    {"name": "manganese_mg", "label": "Manganese (mg)", "type": "decimal", "group": "Minerali"},

    # --- Vitamine ---------------------------------------------------------
    {"name": "vitamina_c_mg", "label": "Vitamina C (mg)", "type": "decimal", "group": "Vitamine"},
    {"name": "vitamina_a_retinolo_eq_mcg", "label": "Vitamina A ret. eq. (µg)", "type": "decimal", "group": "Vitamine"},
    {"name": "retinolo_mcg", "label": "Retinolo (µg)", "type": "decimal", "group": "Vitamine"},
    {"name": "carotene_beta_mcg", "label": "Carotene beta (µg)", "type": "decimal", "group": "Vitamine"},
    {"name": "vitamina_b6_mg", "label": "Vitamina B6 (mg)", "type": "decimal", "group": "Vitamine"},
    {"name": "vitamina_b12_mcg", "label": "Vitamina B12 (µg)", "type": "decimal", "group": "Vitamine"},
    {"name": "vitamina_d_mcg", "label": "Vitamina D (µg)", "type": "decimal", "group": "Vitamine"},

    # --- Altri componenti ---------------------------------------------------
    {"name": "colesterolo_mg", "label": "Colesterolo (mg)", "type": "decimal", "group": "Altri componenti"},
    {"name": "acido_fitico_g", "label": "Acido fitico (g)", "type": "decimal", "group": "Altri componenti"},
    {"name": "polifenoli_mg", "label": "Polifenoli (mg)", "type": "decimal", "group": "Altri componenti"},

    # --- Profilo lipidico -----------------------------------------------
    {"name": "acidi_grassi_saturi_pct", "label": "Acidi grassi saturi (%)", "type": "decimal", "group": "Profilo lipidico"},
    {"name": "acidi_grassi_monoinsaturi_pct", "label": "Acidi grassi monoinsaturi (%)", "type": "decimal", "group": "Profilo lipidico"},
    {"name": "acidi_grassi_polinsaturi_pct", "label": "Acidi grassi polinsaturi (%)", "type": "decimal", "group": "Profilo lipidico"},
    {"name": "rapporto_polinsaturi_saturi", "label": "Rapporto Polinsaturi/Saturi", "type": "decimal", "group": "Profilo lipidico"},

    # --- Profilo proteico ------------------------------------------------
    {"name": "indice_chimico", "label": "Indice chimico", "type": "decimal", "group": "Profilo proteico"},
    {"name": "aminoacido_limitante", "label": "Aminoacido limitante", "type": "text",
     "required": False, "maxlength": 50, "group": "Profilo proteico"},
]

# Normalizza le voci: aggiunge 'required': False e 'maxlength': None di default
for _f in FIELDS:
    _f.setdefault("required", False)
    _f.setdefault("maxlength", None)

FIELD_NAMES = [f["name"] for f in FIELDS]

# Ordine delle sezioni cosi' come devono apparire nel form / nella scheda
GROUP_ORDER = [
    "Anagrafica",
    "Etichette dietetiche",
    "Energia e macronutrienti",
    "Zuccheri semplici",
    "Minerali",
    "Vitamine",
    "Altri componenti",
    "Profilo lipidico",
    "Profilo proteico",
]


def grouped_fields():
    """Restituisce i campi raggruppati per sezione, nell'ordine di GROUP_ORDER."""
    groups = []
    for group_name in GROUP_ORDER:
        items = [f for f in FIELDS if f["group"] == group_name]
        if items:
            groups.append({"name": group_name, "fields": items})
    return groups


# Colonne mostrate nella tabella riassuntiva dell'elenco alimenti
LIST_COLUMNS = [
    ("codice_alimento", "Codice"),
    ("nome_alimento", "Nome alimento"),
    ("categoria", "Categoria"),
    ("energia_kcal", "Energia (kcal)"),
    ("proteine_g", "Proteine (g)"),
    ("lipidi_g", "Lipidi (g)"),
    ("carboidrati_disponibili_g", "Carboidrati (g)"),
]
