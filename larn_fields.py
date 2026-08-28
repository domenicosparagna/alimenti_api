"""
Metadati delle tabelle LARN (Livelli di Assunzione di Riferimento di
Nutrienti ed energia — fonte SINU).

A differenza di `fields.py` (dedicato alla sola tabella `alimenti`), qui
descriviamo *tutte* le 15 tabelle LARN in un unico registro `LARN_TABLES`,
cosi' che un'unica implementazione CRUD generica (vedi `larn_views.py`)
possa gestirle tutte senza duplicare codice per ognuna.

Ogni voce del registro descrive:
    table         nome reale della tabella nel database
    label         etichetta singolare mostrata nell'interfaccia
    plural_label  etichetta plurale (usata nei titoli di elenco)
    description   breve descrizione del contenuto/fonte
    fields        elenco dei campi (nome colonna, etichetta, tipo, ecc.)
    list_columns  colonne mostrate nella tabella riassuntiva dell'elenco
    filters       colonne per cui offrire un filtro a tendina nell'elenco
    default_order colonna/e usate per l'ORDER BY di default

Tipi di campo supportati: "text", "textarea", "int", "decimal", "select".
Per "select" e' richiesta la chiave "choices" (lista di valori ammessi).
I campi non obbligatori possono restare NULL.
"""

# Ordine in cui le categorie vengono proposte nel menu /larn
LARN_TABLE_ORDER = [
    "metadati",
    "acqua",
    "energia_lattanti",
    "energia_1_17_anni",
    "energia_adulti",
    "carboidrati_fibra",
    "lipidi",
    "proteine",
    "vitamine_pri_ai",
    "vitamine_ar",
    "vitamine_ul",
    "minerali_pri_ai",
    "minerali_ar",
    "minerali_ul",
    "minerali_sdt",
]

_SESSO_CHOICES = ["M", "F", "ND"]
_UNITA_ETA_CHOICES = ["mesi", "anni"]

# Campi ricorrenti nella maggior parte delle tabelle LARN: fascia d'eta'
# anagrafica (con etichetta libera ed estremi numerici) e sesso/condizione.
def _campi_fascia_eta(sesso_choices=None):
    sesso_choices = sesso_choices or _SESSO_CHOICES
    return [
        {"name": "fascia", "label": "Fascia", "type": "text", "required": True, "maxlength": 30},
        {"name": "eta_label", "label": "Etichetta eta'", "type": "text", "required": True, "maxlength": 20},
        {"name": "eta_min", "label": "Eta' minima", "type": "decimal"},
        {"name": "eta_max", "label": "Eta' massima", "type": "decimal"},
        {"name": "unita_eta", "label": "Unita' eta'", "type": "select", "choices": _UNITA_ETA_CHOICES, "default": "anni"},
        {"name": "sesso", "label": "Sesso/condizione", "type": "select", "choices": sesso_choices, "default": "ND"},
    ]


LARN_TABLES = {

    # -----------------------------------------------------------------
    "metadati": {
        "table": "larn_metadati",
        "label": "Metadato",
        "plural_label": "Metadati della fonte",
        "description": "Informazioni sulla fonte e sull'ambito dei dati LARN.",
        "default_order": "id",
        "filters": [],
        "fields": [
            {"name": "chiave", "label": "Chiave", "type": "text", "required": True, "maxlength": 50},
            {"name": "valore", "label": "Valore", "type": "text", "required": True, "maxlength": 255},
        ],
        "list_columns": ["chiave", "valore"],
    },

    # -----------------------------------------------------------------
    "acqua": {
        "table": "larn_acqua",
        "label": "Valore acqua",
        "plural_label": "Acqua (AI, mL/die)",
        "description": "Assunzione Adeguata (AI) di acqua per fascia d'eta', sesso e condizione fisiologica.",
        "default_order": "id",
        "filters": ["fascia", "sesso"],
        "fields": _campi_fascia_eta() + [
            {"name": "valore_ml_die", "label": "Valore (mL/die)", "type": "int", "required": True},
            {"name": "tipo_valore", "label": "Tipo di valore", "type": "select",
             "choices": ["assoluto", "incremento"], "default": "assoluto"},
            {"name": "note", "label": "Note", "type": "text", "maxlength": 150},
        ],
        "list_columns": ["fascia", "eta_label", "sesso", "valore_ml_die", "tipo_valore"],
    },

    # -----------------------------------------------------------------
    "energia_lattanti": {
        "table": "larn_energia_lattanti",
        "label": "Riga energia lattanti",
        "plural_label": "Energia — lattanti 7-12 mesi",
        "description": "Fabbisogno energetico medio (AR) nel secondo semestre di vita, mese per mese.",
        "default_order": "sesso, eta_mesi",
        "filters": ["sesso"],
        "fields": [
            {"name": "sesso", "label": "Sesso", "type": "select", "choices": ["M", "F"], "required": True},
            {"name": "eta_mesi", "label": "Eta' (mesi)", "type": "int", "required": True},
            {"name": "peso_kg", "label": "Peso (kg)", "type": "decimal", "required": True},
            {"name": "velocita_crescita_g_die", "label": "Velocita' crescita (g/die)", "type": "decimal", "required": True},
            {"name": "tee_kcal_die", "label": "TEE (kcal/die)", "type": "int", "required": True},
            {"name": "energia_depositata_kcal_die", "label": "Energia depositata (kcal/die)", "type": "int", "required": True},
            {"name": "fabbisogno_kcal_die", "label": "Fabbisogno (kcal/die)", "type": "int", "required": True},
            {"name": "fabbisogno_kcal_kg_die", "label": "Fabbisogno (kcal/kg/die)", "type": "int", "required": True},
        ],
        "list_columns": ["sesso", "eta_mesi", "peso_kg", "fabbisogno_kcal_die", "fabbisogno_kcal_kg_die"],
    },

    # -----------------------------------------------------------------
    "energia_1_17_anni": {
        "table": "larn_energia_1_17_anni",
        "label": "Riga energia 1-17 anni",
        "plural_label": "Energia — 1-17 anni (per PAL)",
        "description": "Fabbisogno energetico medio (AR) da 1 a 17 anni, a diversi livelli di attivita' fisica (PAL).",
        "default_order": "sesso, eta_anni",
        "filters": ["sesso"],
        "fields": [
            {"name": "sesso", "label": "Sesso", "type": "select", "choices": ["M", "F"], "required": True},
            {"name": "eta_anni", "label": "Eta' (anni)", "type": "decimal", "required": True},
            {"name": "peso_kg", "label": "Peso (kg)", "type": "decimal", "required": True},
            {"name": "bmr_kcal_die", "label": "BMR (kcal/die)", "type": "int", "required": True},
            {"name": "fabbisogno_pal_1_2", "label": "Fabbisogno PAL 1.2", "type": "int"},
            {"name": "fabbisogno_pal_1_4", "label": "Fabbisogno PAL 1.4", "type": "int"},
            {"name": "fabbisogno_pal_1_6", "label": "Fabbisogno PAL 1.6", "type": "int"},
            {"name": "fabbisogno_pal_1_8", "label": "Fabbisogno PAL 1.8", "type": "int"},
            {"name": "fabbisogno_pal_2_0", "label": "Fabbisogno PAL 2.0", "type": "int"},
        ],
        "list_columns": ["sesso", "eta_anni", "peso_kg", "bmr_kcal_die"],
    },

    # -----------------------------------------------------------------
    "energia_adulti": {
        "table": "larn_energia_adulti",
        "label": "Riga energia adulti",
        "plural_label": "Energia — adulti ed eta' geriatrica (per PAL)",
        "description": "Fabbisogno energetico medio (AR) per adulti e anziani, per statura e livello di attivita' fisica (PAL).",
        "default_order": "sesso, fascia_eta, statura_m",
        "filters": ["sesso", "fascia_eta"],
        "fields": [
            {"name": "sesso", "label": "Sesso", "type": "select", "choices": ["M", "F"], "required": True},
            {"name": "fascia_eta", "label": "Fascia eta'", "type": "text", "required": True, "maxlength": 10},
            {"name": "eta_min", "label": "Eta' minima", "type": "int", "required": True},
            {"name": "eta_max", "label": "Eta' massima", "type": "int", "required": True},
            {"name": "statura_m", "label": "Statura (m)", "type": "decimal", "required": True},
            {"name": "peso_kg", "label": "Peso (kg)", "type": "decimal", "required": True},
            {"name": "bmr_kcal_die", "label": "BMR (kcal/die)", "type": "int", "required": True},
            {"name": "fabbisogno_pal_1_2", "label": "Fabbisogno PAL 1.2", "type": "int"},
            {"name": "fabbisogno_pal_1_4", "label": "Fabbisogno PAL 1.4", "type": "int"},
            {"name": "fabbisogno_pal_1_6", "label": "Fabbisogno PAL 1.6", "type": "int"},
            {"name": "fabbisogno_pal_1_8", "label": "Fabbisogno PAL 1.8", "type": "int"},
            {"name": "fabbisogno_pal_2_0", "label": "Fabbisogno PAL 2.0", "type": "int"},
        ],
        "list_columns": ["sesso", "fascia_eta", "statura_m", "peso_kg", "bmr_kcal_die"],
    },

    # -----------------------------------------------------------------
    "carboidrati_fibra": {
        "table": "larn_carboidrati_fibra",
        "label": "Riga carboidrati/fibra",
        "plural_label": "Carboidrati, zuccheri e fibra",
        "description": "Intervalli di riferimento (RI/AI/SDT) per carboidrati totali, zuccheri semplici e fibra alimentare.",
        "default_order": "id",
        "filters": ["nutriente", "parametro"],
        "fields": [
            {"name": "nutriente", "label": "Nutriente", "type": "text", "required": True, "maxlength": 50},
            {"name": "gruppo_eta", "label": "Gruppo eta'", "type": "text", "required": True, "maxlength": 30},
            {"name": "eta_min", "label": "Eta' minima", "type": "decimal"},
            {"name": "eta_max", "label": "Eta' massima", "type": "decimal"},
            {"name": "parametro", "label": "Parametro", "type": "select",
             "choices": ["RI", "AI", "SDT", "Osservazionale"], "required": True},
            {"name": "valore_min", "label": "Valore minimo", "type": "decimal"},
            {"name": "valore_max", "label": "Valore massimo", "type": "decimal"},
            {"name": "unita", "label": "Unita' di misura", "type": "text", "required": True, "maxlength": 20},
            {"name": "note", "label": "Note", "type": "textarea"},
        ],
        "list_columns": ["nutriente", "gruppo_eta", "parametro", "valore_min", "valore_max", "unita"],
    },

    # -----------------------------------------------------------------
    "lipidi": {
        "table": "larn_lipidi",
        "label": "Riga lipidi",
        "plural_label": "Lipidi",
        "description": "Riferimenti (SDT/AI/RI) per lipidi totali e profilo degli acidi grassi, per fascia d'eta'.",
        "default_order": "id",
        "filters": ["fascia", "tipo_lipide"],
        "fields": [
            {"name": "fascia", "label": "Fascia", "type": "text", "required": True, "maxlength": 30},
            {"name": "eta_label", "label": "Etichetta eta'", "type": "text", "required": True, "maxlength": 20},
            {"name": "eta_min", "label": "Eta' minima", "type": "decimal"},
            {"name": "eta_max", "label": "Eta' massima", "type": "decimal"},
            {"name": "unita_eta", "label": "Unita' eta'", "type": "select", "choices": _UNITA_ETA_CHOICES, "default": "anni"},
            {"name": "tipo_lipide", "label": "Tipo di lipide", "type": "text", "required": True, "maxlength": 30},
            {"name": "sdt", "label": "SDT", "type": "text", "maxlength": 60},
            {"name": "ai", "label": "AI", "type": "text", "maxlength": 100},
            {"name": "ri", "label": "RI", "type": "text", "maxlength": 30},
            {"name": "note", "label": "Note", "type": "text", "maxlength": 200},
        ],
        "list_columns": ["fascia", "eta_label", "tipo_lipide", "sdt", "ai", "ri"],
    },

    # -----------------------------------------------------------------
    "proteine": {
        "table": "larn_proteine",
        "label": "Riga proteine",
        "plural_label": "Proteine",
        "description": "Fabbisogno medio (AR), assunzione raccomandata (PRI) e obiettivo di prevenzione (SDT) per le proteine.",
        "default_order": "id",
        "filters": ["fascia", "sesso"],
        "fields": _campi_fascia_eta(["M", "F"]) + [
            {"name": "peso_kg", "label": "Peso (kg)", "type": "decimal"},
            {"name": "ar_g_kg_die", "label": "AR (g/kg/die)", "type": "decimal"},
            {"name": "ar_g_die", "label": "AR (g/die)", "type": "decimal"},
            {"name": "pri_g_kg_die", "label": "PRI (g/kg/die)", "type": "decimal"},
            {"name": "pri_g_die", "label": "PRI (g/die)", "type": "decimal"},
            {"name": "sdt_g_kg_die", "label": "SDT (g/kg/die)", "type": "decimal"},
            {"name": "sdt_g_die", "label": "SDT (g/die)", "type": "decimal"},
            {"name": "tipo_valore", "label": "Tipo di valore", "type": "select",
             "choices": ["assoluto", "incremento"], "default": "assoluto"},
            {"name": "note", "label": "Note", "type": "text", "maxlength": 200},
        ],
        "list_columns": ["fascia", "eta_label", "sesso", "ar_g_die", "pri_g_die"],
    },

    # -----------------------------------------------------------------
    "vitamine_pri_ai": {
        "table": "larn_vitamine_pri_ai",
        "label": "Riga vitamine PRI/AI",
        "plural_label": "Vitamine — PRI/AI",
        "description": "Assunzione raccomandata (PRI) o adeguata (AI) per le vitamine, per fascia d'eta' e sesso.",
        "default_order": "id",
        "filters": ["fascia", "sesso"],
        "fields": _campi_fascia_eta() + [
            {"name": "tiamina_mg_1000kcal", "label": "Tiamina (mg/1000kcal)", "type": "decimal"},
            {"name": "riboflavina_mg", "label": "Riboflavina (mg)", "type": "decimal"},
            {"name": "niacina_mg", "label": "Niacina (mg)", "type": "decimal"},
            {"name": "ac_pantotenico_mg", "label": "Acido pantotenico (mg)", "type": "decimal"},
            {"name": "vit_b6_mg", "label": "Vitamina B6 (mg)", "type": "decimal"},
            {"name": "biotina_ug", "label": "Biotina (µg)", "type": "decimal"},
            {"name": "folati_ug", "label": "Folati (µg)", "type": "decimal"},
            {"name": "vit_b12_ug", "label": "Vitamina B12 (µg)", "type": "decimal"},
            {"name": "vit_c_mg", "label": "Vitamina C (mg)", "type": "decimal"},
            {"name": "vit_a_ug", "label": "Vitamina A (µg)", "type": "decimal"},
            {"name": "vit_d_ug", "label": "Vitamina D (µg)", "type": "decimal"},
            {"name": "vit_d_ug_over75", "label": "Vitamina D over 75 (µg)", "type": "decimal"},
            {"name": "vit_e_mg", "label": "Vitamina E (mg)", "type": "decimal"},
            {"name": "vit_k_ug", "label": "Vitamina K (µg)", "type": "decimal"},
            {"name": "note", "label": "Note", "type": "text", "maxlength": 200},
        ],
        "list_columns": ["fascia", "eta_label", "sesso", "vit_c_mg", "vit_d_ug", "folati_ug"],
    },

    # -----------------------------------------------------------------
    "vitamine_ar": {
        "table": "larn_vitamine_ar",
        "label": "Riga vitamine AR",
        "plural_label": "Vitamine — fabbisogno medio (AR)",
        "description": "Fabbisogno medio (AR) per le vitamine per cui e' definibile, per fascia d'eta' e sesso.",
        "default_order": "id",
        "filters": ["fascia", "sesso"],
        "fields": _campi_fascia_eta() + [
            {"name": "tiamina_mg_1000kcal", "label": "Tiamina (mg/1000kcal)", "type": "decimal"},
            {"name": "riboflavina_mg", "label": "Riboflavina (mg)", "type": "decimal"},
            {"name": "niacina_mg", "label": "Niacina (mg)", "type": "decimal"},
            {"name": "vit_b6_mg", "label": "Vitamina B6 (mg)", "type": "decimal"},
            {"name": "folati_ug", "label": "Folati (µg)", "type": "decimal"},
            {"name": "vit_c_mg", "label": "Vitamina C (mg)", "type": "decimal"},
            {"name": "vit_a_ug", "label": "Vitamina A (µg)", "type": "decimal"},
            {"name": "vit_d_ug", "label": "Vitamina D (µg)", "type": "decimal"},
            {"name": "note", "label": "Note", "type": "text", "maxlength": 200},
        ],
        "list_columns": ["fascia", "eta_label", "sesso", "vit_c_mg", "folati_ug"],
    },

    # -----------------------------------------------------------------
    "vitamine_ul": {
        "table": "larn_vitamine_ul",
        "label": "Riga vitamine UL",
        "plural_label": "Vitamine — livello massimo tollerabile (UL)",
        "description": "Livello massimo tollerabile di assunzione (UL) per le vitamine per cui e' definibile.",
        "default_order": "id",
        "filters": ["fascia", "sesso"],
        "fields": _campi_fascia_eta() + [
            {"name": "niacina_na_mg", "label": "Niacina come nicotinamide (mg)", "type": "decimal"},
            {"name": "niacina_acn_mg", "label": "Niacina come ac. nicotinico (mg)", "type": "decimal"},
            {"name": "vit_b6_mg", "label": "Vitamina B6 (mg)", "type": "decimal"},
            {"name": "folati_ug", "label": "Folati sintetici (µg)", "type": "decimal"},
            {"name": "vit_a_ug", "label": "Vitamina A (µg)", "type": "decimal"},
            {"name": "vit_d_ug", "label": "Vitamina D (µg)", "type": "decimal"},
            {"name": "vit_e_mg", "label": "Vitamina E (mg)", "type": "decimal"},
            {"name": "note", "label": "Note", "type": "text", "maxlength": 200},
        ],
        "list_columns": ["fascia", "eta_label", "sesso", "vit_a_ug", "vit_d_ug"],
    },

    # -----------------------------------------------------------------
    "minerali_pri_ai": {
        "table": "larn_minerali_pri_ai",
        "label": "Riga minerali PRI/AI",
        "plural_label": "Minerali — PRI/AI",
        "description": "Assunzione raccomandata (PRI) o adeguata (AI) per i minerali, per fascia d'eta' e sesso.",
        "default_order": "id",
        "filters": ["fascia", "sesso"],
        "fields": _campi_fascia_eta() + [
            {"name": "ca_mg", "label": "Calcio (mg)", "type": "decimal"},
            {"name": "p_mg", "label": "Fosforo (mg)", "type": "decimal"},
            {"name": "mg_mg", "label": "Magnesio (mg)", "type": "decimal"},
            {"name": "na_g", "label": "Sodio (g)", "type": "decimal"},
            {"name": "k_mg", "label": "Potassio (mg)", "type": "decimal"},
            {"name": "cl_g", "label": "Cloro (g)", "type": "decimal"},
            {"name": "fe_mg", "label": "Ferro (mg)", "type": "decimal"},
            {"name": "zn_mg", "label": "Zinco (mg)", "type": "decimal"},
            {"name": "cu_mg", "label": "Rame (mg)", "type": "decimal"},
            {"name": "se_ug", "label": "Selenio (µg)", "type": "decimal"},
            {"name": "i_ug", "label": "Iodio (µg)", "type": "decimal"},
            {"name": "mn_mg", "label": "Manganese (mg)", "type": "decimal"},
            {"name": "mo_ug", "label": "Molibdeno (µg)", "type": "decimal"},
            {"name": "cr_ug", "label": "Cromo (µg)", "type": "decimal"},
            {"name": "f_mg", "label": "Fluoro (mg)", "type": "decimal"},
            {"name": "note", "label": "Note", "type": "text", "maxlength": 250},
        ],
        "list_columns": ["fascia", "eta_label", "sesso", "ca_mg", "fe_mg", "zn_mg"],
    },

    # -----------------------------------------------------------------
    "minerali_ar": {
        "table": "larn_minerali_ar",
        "label": "Riga minerali AR",
        "plural_label": "Minerali — fabbisogno medio (AR)",
        "description": "Fabbisogno medio (AR) per calcio, ferro e zinco (gli unici minerali per cui l'AR e' definibile).",
        "default_order": "id",
        "filters": ["fascia", "sesso"],
        "fields": _campi_fascia_eta() + [
            {"name": "ca_mg", "label": "Calcio (mg)", "type": "decimal"},
            {"name": "fe_mg", "label": "Ferro (mg)", "type": "decimal"},
            {"name": "zn_mg", "label": "Zinco (mg)", "type": "decimal"},
            {"name": "note", "label": "Note", "type": "text", "maxlength": 250},
        ],
        "list_columns": ["fascia", "eta_label", "sesso", "ca_mg", "fe_mg", "zn_mg"],
    },

    # -----------------------------------------------------------------
    "minerali_ul": {
        "table": "larn_minerali_ul",
        "label": "Riga minerali UL",
        "plural_label": "Minerali — livello massimo tollerabile (UL)",
        "description": "Livello massimo tollerabile di assunzione (UL) per i minerali per cui e' definibile.",
        "default_order": "id",
        "filters": ["fascia", "sesso"],
        "fields": _campi_fascia_eta() + [
            {"name": "ca_mg", "label": "Calcio (mg)", "type": "decimal"},
            {"name": "zn_mg", "label": "Zinco (mg)", "type": "decimal"},
            {"name": "cu_mg", "label": "Rame (mg)", "type": "decimal"},
            {"name": "se_ug", "label": "Selenio (µg)", "type": "decimal"},
            {"name": "i_ug", "label": "Iodio (µg)", "type": "decimal"},
            {"name": "mo_ug", "label": "Molibdeno (µg)", "type": "decimal"},
            {"name": "f_mg", "label": "Fluoro (mg)", "type": "decimal"},
            {"name": "note", "label": "Note", "type": "text", "maxlength": 200},
        ],
        "list_columns": ["fascia", "eta_label", "sesso", "ca_mg", "zn_mg"],
    },

    # -----------------------------------------------------------------
    "minerali_sdt": {
        "table": "larn_minerali_sdt",
        "label": "Riga minerali SDT",
        "plural_label": "Minerali — obiettivo di prevenzione (SDT)",
        "description": "Obiettivo nutrizionale di prevenzione (SDT) per sodio, cloro e potassio.",
        "default_order": "id",
        "filters": ["fascia", "sesso"],
        "fields": _campi_fascia_eta() + [
            {"name": "na_g", "label": "Sodio (g)", "type": "decimal"},
            {"name": "cl_g", "label": "Cloro (g)", "type": "decimal"},
            {"name": "k_mg", "label": "Potassio (mg)", "type": "decimal"},
        ],
        "list_columns": ["fascia", "eta_label", "sesso", "na_g", "cl_g", "k_mg"],
    },
}

# Normalizza le voci: aggiunge valori di default alle chiavi opzionali di ogni campo
for _cfg in LARN_TABLES.values():
    for _f in _cfg["fields"]:
        _f.setdefault("required", False)
        _f.setdefault("maxlength", None)
        _f.setdefault("default", None)
    _cfg["field_names"] = [f["name"] for f in _cfg["fields"]]
    _cfg.setdefault("filters", [])


def get_table_config(key):
    """Restituisce la configurazione della tabella LARN identificata da `key`,
    oppure None se la chiave non corrisponde a nessuna tabella nota."""
    return LARN_TABLES.get(key)


def ordered_tables():
    """Restituisce la lista (key, config) nell'ordine di visualizzazione del menu."""
    return [(key, LARN_TABLES[key]) for key in LARN_TABLE_ORDER if key in LARN_TABLES]
