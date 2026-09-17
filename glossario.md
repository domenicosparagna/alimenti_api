# Glossario delle sigle

Elenco delle sigle usate nel codice dell'app (tabelle LARN, dominio nutrizionale
e architettura tecnica), con il significato e dove compaiono.

## Sigle nutrizionali (tabelle LARN — `larn_fields.py`, `larn_lookup.py`)

- **LARN** — Livelli di Assunzione di Riferimento di Nutrienti ed energia (fonte SINU); nome dell'intero registro di tabelle nutrizionali dell'app.
- **SINU** — Società Italiana di Nutrizione Umana, l'ente che pubblica i LARN.
- **PRI** — Popolazione di Riferimento per l'Intake: assunzione raccomandata di un nutriente (proteine, minerali).
- **AI** — Assunzione Adeguata (Adequate Intake): usata quando non ci sono dati sufficienti per fissare un PRI (acqua, carboidrati/fibra, lipidi, vitamine, minerali).
- **AR** — Fabbisogno medio (Average Requirement): copre il fabbisogno del 50% della popolazione; usato per energia, proteine, vitamine, minerali.
- **UL** — Livello massimo tollerabile di assunzione (Upper Level): vitamine e minerali per cui è definibile.
- **SDT** — Obiettivo nutrizionale per la prevenzione (Suggested Dietary Target): carboidrati/fibra, lipidi, proteine, minerali (sodio, cloro, potassio).
- **RI** — Intervallo di riferimento per l'assunzione (Reference Intake range): carboidrati/fibra e lipidi.
- **PAL** — Livello di Attività Fisica (Physical Activity Level): moltiplicatore (1.2–2.0) usato nelle tabelle energia per calcolare il fabbisogno calorico a partire dal BMR.
- **BMR** — Metabolismo Basale (Basal Metabolic Rate), in kcal/die; base di calcolo del fabbisogno energetico nelle tabelle energia.
- **ND** — terza opzione nel campo "sesso" (insieme a M/F), per righe valide indipendentemente dal sesso.

## Sigle di dominio (piramide alimentare / smartfood — `smartfood_fields.py`)

- **CREA** — Consiglio per la ricerca in agricoltura e l'analisi dell'economia agraria; una delle fonti dei dati su porzioni e frequenze.
- **WCRF** — World Cancer Research Fund; altra fonte citata per le linee guida di consumo.

## Sigle tecniche (architettura dell'app — `app.py`, `config.py`, `auth.py`, `errors.py`)

- **API** — Application Programming Interface: l'intera app è esposta come API REST sotto `/api/*`.
- **REST** — Representational State Transfer: stile architetturale dell'API.
- **JSON** — JavaScript Object Notation: formato di scambio dati di richieste/risposte dell'API.
- **CORS** — Cross-Origin Resource Sharing: gestito in `config.py`/`app.py` per permettere al front-end di chiamare l'API da un'origine diversa.
- **CSRF** — Cross-Site Request Forgery: protezione legata alla chiave segreta di Flask per le sessioni (`config.py`).
- **WSGI** — Web Server Gateway Interface: menzionato in `config.py` per il deploy su PythonAnywhere.
- **HTML / CSS / JS** — front-end statico servito dall'app.
- **CRUD** — Create/Read/Update/Delete: pattern citato in `ricette_fields.py` per la gestione delle righe.

---

*Generato da Claude il 2026-09-17, a partire dai commenti e dai docstring del codice.*
