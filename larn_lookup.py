"""
Aggancio tra il profilo di un paziente e le tabelle LARN.

Le tabelle `larn_*` sono tabelle di riferimento (come un "tabellone" di valori
standard): non hanno e non devono avere una foreign key verso `pazienti` (un
paziente non "appartiene" a una riga LARN, e una riga LARN non "appartiene" a
nessun paziente in particolare). Il collegamento e' quindi fatto qui, a runtime,
con una ricerca per eta'/sesso (e, per l'energia adulti, anche statura e
livello di attivita' fisica) — esattamente come farebbe un nutrizionista che
scorre le tabelle di riferimento con il dito per trovare la riga giusta.

Questo modulo copre tre categorie, le piu' direttamente utili nella scheda di
un paziente e nel confronto con il suo piano alimentare:

    - energia   (larn_energia_lattanti / larn_energia_1_17_anni / larn_energia_adulti)
    - proteine  (larn_proteine)
    - acqua     (larn_acqua, solo informativo: il piano non registra l'acqua bevuta)

Le altre tabelle (lipidi, carboidrati/fibra, vitamine, minerali) hanno la
stessa struttura eta_min/eta_max/sesso e potrebbero essere collegate allo
stesso modo in futuro; non sono incluse qui per tenere il modulo mirato ai
due valori che il piano alimentare calcola gia' (kcal e proteine, da
`piano_pasto_alimenti`).
"""

from datetime import date
from decimal import Decimal, InvalidOperation

import db

# Livelli di Attivita' Fisica (PAL) usati dalle tabelle di energia LARN.
# Le chiavi sono le stesse usate nel campo `pazienti.livello_attivita_fisica`.
PAL_CHOICES = ["1.2", "1.4", "1.6", "1.8", "2.0"]
PAL_LABELS = {
    "1.2": "Sedentario (PAL 1.2)",
    "1.4": "Leggermente attivo (PAL 1.4)",
    "1.6": "Moderatamente attivo (PAL 1.6)",
    "1.8": "Attivo (PAL 1.8)",
    "2.0": "Molto attivo (PAL 2.0)",
}
_PAL_COLUMNS = {
    "1.2": "fabbisogno_pal_1_2",
    "1.4": "fabbisogno_pal_1_4",
    "1.6": "fabbisogno_pal_1_6",
    "1.8": "fabbisogno_pal_1_8",
    "2.0": "fabbisogno_pal_2_0",
}


# ---------------------------------------------------------------------
# Eta' del paziente
# ---------------------------------------------------------------------

def eta_in_anni(data_nascita, alla_data=None):
    """Eta' in anni (Decimal, con parte frazionaria) da una data di nascita,
    oppure None se la data di nascita non e' impostata."""
    if data_nascita is None:
        return None
    oggi = alla_data or date.today()
    giorni = (oggi - data_nascita).days
    if giorni < 0:
        return None
    return Decimal(giorni) / Decimal("365.25")


def eta_in_mesi(data_nascita, alla_data=None):
    """Eta' in mesi compiuti da una data di nascita, oppure None."""
    if data_nascita is None:
        return None
    oggi = alla_data or date.today()
    mesi = (oggi.year - data_nascita.year) * 12 + (oggi.month - data_nascita.month)
    if oggi.day < data_nascita.day:
        mesi -= 1
    return max(mesi, 0)


# ---------------------------------------------------------------------
# Helper generico: trova la fascia d'eta' piu' adatta tra un elenco di righe
# ---------------------------------------------------------------------

def _trova_fascia(righe, eta_anni, eta_mesi_val, soglia_mesi=24):
    """Tra `righe` (dict con chiavi eta_min/eta_max/unita_eta), restituisce
    quella la cui fascia contiene l'eta' del paziente; se nessuna la contiene
    esattamente, la piu' vicina entro una soglia ragionevole (le tabelle LARN
    pediatriche danno spesso un singolo valore per eta', es. "6,5 anni", da
    intendersi come rappresentativo dell'intera fascia annuale). None se
    nessuna riga e' abbastanza vicina o mancano i dati per confrontarla.

    Le righe con `unita_eta = 'mesi'` e quelle con `unita_eta = 'anni'`
    convivono nella stessa tabella (es. larn_proteine ha sia le fasce dei
    lattanti in mesi sia quelle successive in anni): per poterle confrontare
    con un unico criterio di "distanza", tutto viene qui convertito in mesi
    prima del confronto — mescolare distanze in mesi e in anni senza
    convertirle porterebbe a scegliere la fascia sbagliata vicino ai confini
    (es. un lattante di 9 mesi abbinato per errore a una fascia "1,5 anni").
    """
    if eta_mesi_val is None and eta_anni is not None:
        eta_mesi_val = float(eta_anni) * 12
    if eta_mesi_val is None:
        return None

    candidata = None
    distanza_minima = None
    for r in righe:
        if r.get("eta_min") is None and r.get("eta_max") is None:
            # Nessuna fascia d'eta' definita affatto (es. le righe di incremento
            # per gravidanza/allattamento in larn_proteine, selezionabili solo
            # in base a una condizione fisiologica che qui non tracciamo, non
            # in base all'eta'): non e' un riferimento generico per eta', va
            # sempre escluso da questo confronto automatico.
            continue

        fattore = 1 if r.get("unita_eta") == "mesi" else 12
        eta_min_mesi = float(r["eta_min"]) * fattore if r.get("eta_min") is not None else float("-inf")
        eta_max_mesi = float(r["eta_max"]) * fattore if r.get("eta_max") is not None else float("inf")

        if eta_min_mesi <= eta_mesi_val <= eta_max_mesi:
            distanza = 0.0
        elif eta_min_mesi == float("-inf"):
            distanza = abs(eta_mesi_val - eta_max_mesi)
        elif eta_max_mesi == float("inf"):
            distanza = abs(eta_mesi_val - eta_min_mesi)
        else:
            distanza = min(abs(eta_mesi_val - eta_min_mesi), abs(eta_mesi_val - eta_max_mesi))

        if distanza <= soglia_mesi and (distanza_minima is None or distanza < distanza_minima):
            distanza_minima = distanza
            candidata = r
    return candidata


# ---------------------------------------------------------------------
# Energia
# ---------------------------------------------------------------------

def fabbisogno_energetico(eta_anni, eta_mesi_val, sesso, pal, altezza_cm):
    """Fabbisogno energetico di riferimento (kcal/die), cercando nella
    tabella LARN giusta secondo l'eta' (lattanti / 1-17 anni / adulti).
    Restituisce sempre un dict con le chiavi:
        kcal (Decimal o None), fascia (str o None), tabella (str o None),
        messaggio (str o None, spiega perche' il calcolo non e' disponibile).
    """
    if sesso not in ("M", "F"):
        return {"kcal": None, "fascia": None, "tabella": None,
                "messaggio": "Imposta il sesso del paziente per calcolare il fabbisogno energetico LARN."}

    # Lattanti: la tabella LARN copre il secondo semestre di vita (7-12 mesi).
    if eta_mesi_val is not None and 7 <= eta_mesi_val <= 12:
        row = db.query_one(
            "SELECT eta_mesi, fabbisogno_kcal_die FROM larn_energia_lattanti "
            "WHERE sesso = %s ORDER BY ABS(eta_mesi - %s) LIMIT 1",
            [sesso, eta_mesi_val],
        )
        if row:
            return {"kcal": Decimal(row["fabbisogno_kcal_die"]), "fascia": f"{row['eta_mesi']} mesi",
                    "tabella": "larn_energia_lattanti", "messaggio": None}

    # 1-17 anni
    if eta_anni is not None and Decimal("1") <= eta_anni < Decimal("18"):
        if pal not in _PAL_COLUMNS:
            return {"kcal": None, "fascia": None, "tabella": "larn_energia_1_17_anni",
                    "messaggio": "Imposta il livello di attivita' fisica del paziente per calcolare il fabbisogno energetico."}
        col = _PAL_COLUMNS[pal]
        row = db.query_one(
            f"SELECT eta_anni, {col} AS kcal FROM larn_energia_1_17_anni "
            "WHERE sesso = %s ORDER BY ABS(eta_anni - %s) LIMIT 1",
            [sesso, float(eta_anni)],
        )
        if row and row["kcal"] is not None:
            return {"kcal": Decimal(row["kcal"]), "fascia": f"{row['eta_anni']} anni",
                    "tabella": "larn_energia_1_17_anni", "messaggio": None}
        if row:
            return {"kcal": None, "fascia": f"{row['eta_anni']} anni", "tabella": "larn_energia_1_17_anni",
                    "messaggio": f"Il livello di attivita' fisica scelto non e' disponibile per la fascia di {row['eta_anni']} anni."}

    # Adulti ed eta' geriatrica: >= 18 anni
    if eta_anni is not None and eta_anni >= Decimal("18"):
        if pal not in _PAL_COLUMNS:
            return {"kcal": None, "fascia": None, "tabella": "larn_energia_adulti",
                    "messaggio": "Imposta il livello di attivita' fisica del paziente per calcolare il fabbisogno energetico."}
        if not altezza_cm:
            return {"kcal": None, "fascia": None, "tabella": "larn_energia_adulti",
                    "messaggio": "Imposta l'altezza del paziente: la tabella LARN adulti varia per statura."}
        col = _PAL_COLUMNS[pal]
        statura_m = Decimal(altezza_cm) / Decimal(100)
        eta_intera = int(eta_anni)
        row = db.query_one(
            f"SELECT fascia_eta, statura_m, {col} AS kcal FROM larn_energia_adulti "
            "WHERE sesso = %s AND eta_min <= %s AND eta_max >= %s "
            "ORDER BY ABS(statura_m - %s) LIMIT 1",
            [sesso, eta_intera, eta_intera, statura_m],
        )
        if row and row["kcal"] is not None:
            return {"kcal": Decimal(row["kcal"]),
                    "fascia": f"{row['fascia_eta']} anni, statura di riferimento {row['statura_m']} m",
                    "tabella": "larn_energia_adulti", "messaggio": None}
        if row:
            return {"kcal": None, "fascia": row["fascia_eta"], "tabella": "larn_energia_adulti",
                    "messaggio": f"Il livello di attivita' fisica scelto non e' disponibile per la fascia {row['fascia_eta']} anni."}

    return {"kcal": None, "fascia": None, "tabella": None,
            "messaggio": "Eta' non coperta dalle tabelle LARN sintetiche disponibili (es. 0-6 mesi)."}


# ---------------------------------------------------------------------
# Proteine
# ---------------------------------------------------------------------

def fabbisogno_proteico(eta_anni, eta_mesi_val, sesso, peso_kg):
    """Fabbisogno proteico di riferimento (g/die), calcolato come
    PRI (o, in mancanza, AR) g/kg/die moltiplicato per il peso del paziente;
    se il peso non e' impostato, usa il valore assoluto della tabella
    (calcolato su un peso di riferimento, non sul peso del paziente) e lo
    segnala col messaggio. Restituisce un dict con le chiavi:
        g_die (Decimal o None), fascia (str o None), tipo (str o None),
        messaggio (str o None).
    """
    if sesso not in ("M", "F"):
        return {"g_die": None, "fascia": None, "tipo": None,
                "messaggio": "Imposta il sesso del paziente per calcolare il fabbisogno proteico LARN."}

    eta_anni_calc = eta_anni
    eta_mesi_calc = eta_mesi_val
    if eta_anni_calc is None:
        return {"g_die": None, "fascia": None, "tipo": None,
                "messaggio": "Imposta la data di nascita del paziente per calcolare il fabbisogno proteico LARN."}

    righe = db.query_all(
        "SELECT fascia, eta_label, eta_min, eta_max, unita_eta, "
        "ar_g_kg_die, pri_g_kg_die, ar_g_die, pri_g_die "
        "FROM larn_proteine WHERE sesso = %s",
        [sesso],
    )
    candidata = _trova_fascia(righe, eta_anni_calc, eta_mesi_calc)
    if candidata is None:
        return {"g_die": None, "fascia": None, "tipo": None,
                "messaggio": "Nessuna fascia LARN Proteine trovata per questa eta'."}

    peso_ok = peso_kg is not None
    try:
        peso_decimal = Decimal(peso_kg) if peso_ok else None
    except InvalidOperation:
        peso_decimal = None
        peso_ok = False

    if candidata["pri_g_kg_die"] is not None and peso_ok:
        g_die = Decimal(candidata["pri_g_kg_die"]) * peso_decimal
        tipo = "PRI"
        messaggio = None
    elif candidata["ar_g_kg_die"] is not None and peso_ok:
        g_die = Decimal(candidata["ar_g_kg_die"]) * peso_decimal
        tipo = "AR"
        messaggio = None
    elif candidata["pri_g_die"] is not None:
        g_die = Decimal(candidata["pri_g_die"])
        tipo = "PRI"
        messaggio = "Peso del paziente non impostato: valore calcolato sul peso di riferimento della tabella, non su quello del paziente."
    elif candidata["ar_g_die"] is not None:
        g_die = Decimal(candidata["ar_g_die"])
        tipo = "AR"
        messaggio = "Peso del paziente non impostato: valore calcolato sul peso di riferimento della tabella, non su quello del paziente."
    else:
        return {"g_die": None, "fascia": candidata["eta_label"], "tipo": None,
                "messaggio": "Valore non disponibile per questa fascia."}

    return {"g_die": round(g_die, 1), "fascia": candidata["eta_label"], "tipo": tipo, "messaggio": messaggio}


# ---------------------------------------------------------------------
# Acqua (solo informativo: il piano alimentare non registra l'acqua bevuta)
# ---------------------------------------------------------------------

def fabbisogno_idrico(eta_anni, eta_mesi_val, sesso):
    """Assunzione adeguata (AI) di acqua di riferimento (mL/die)."""
    if eta_anni is None:
        return {"ml_die": None, "fascia": None,
                "messaggio": "Imposta la data di nascita del paziente per calcolare il fabbisogno idrico LARN."}

    sesso_query = sesso if sesso in ("M", "F") else "ND"
    righe = db.query_all(
        "SELECT eta_label, eta_min, eta_max, unita_eta, valore_ml_die FROM larn_acqua "
        "WHERE tipo_valore = 'assoluto' AND (sesso = %s OR sesso = 'ND')",
        [sesso_query],
    )
    candidata = _trova_fascia(righe, eta_anni, eta_mesi_val)
    if candidata is None:
        return {"ml_die": None, "fascia": None,
                "messaggio": "Nessuna fascia LARN Acqua trovata per questa eta'."}
    return {"ml_die": candidata["valore_ml_die"], "fascia": candidata["eta_label"], "messaggio": None}


# ---------------------------------------------------------------------
# Punto di ingresso unico: tutti i riferimenti per un paziente
# ---------------------------------------------------------------------

def riferimenti_paziente(paziente):
    """Calcola eta'/mesi dal paziente e restituisce i tre riferimenti LARN
    (energia, proteine, acqua) pronti per il template, in un unico dict:
        {"eta_anni": ..., "energia": {...}, "proteine": {...}, "acqua": {...}}
    `paziente` e' una riga di `pazienti` (dict-like, con data_nascita, sesso,
    peso_kg, altezza_cm, livello_attivita_fisica)."""
    anni = eta_in_anni(paziente.get("data_nascita"))
    mesi = eta_in_mesi(paziente.get("data_nascita"))
    sesso = paziente.get("sesso")
    pal = str(paziente["livello_attivita_fisica"]) if paziente.get("livello_attivita_fisica") is not None else None

    return {
        "eta_anni": round(anni, 1) if anni is not None else None,
        "energia": fabbisogno_energetico(anni, mesi, sesso, pal, paziente.get("altezza_cm")),
        "proteine": fabbisogno_proteico(anni, mesi, sesso, paziente.get("peso_kg")),
        "acqua": fabbisogno_idrico(anni, mesi, sesso),
    }
