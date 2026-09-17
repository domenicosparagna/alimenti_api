# Registro Alimenti - Studio Nutrizionista 



Applicazione full-stack per la gestione nutrizionale di uno studio di
dietetica/nutrizione clinica: alimenti (composizione CREA/INRAN), tabelle
di riferimento LARN, ricette, pazienti con piani alimentari e
appuntamenti, piramide alimentare Smartfood.

Backend REST in Flask (Python, orientato agli oggetti) + front-end statico
in HTML, CSS e JavaScript puro: nessuna pagina viene generata dal server,
il front-end parla esclusivamente con `/api/*` via `fetch()`.


L’applicazione è disponibile al seguente indirizzo: [Registro Alimenti](https://domenicosparagna.pythonanywhere.com/)

Documentazione API: [Swagger UI](https://domenicosparagna.pythonanywhere.com/api/docs) · [openapi.yaml](https://domenicosparagna.pythonanywhere.com/api/openapi.yaml).


**L'Applicazione è in fase di test**

## Indice

- [Architettura](#architettura)
- [Struttura del progetto](#struttura-del-progetto)
- [Avvio in locale](#avvio-in-locale)
- [Credenziali e sicurezza](#credenziali-e-sicurezza)
- [Documentazione API](#documentazione-api)
- [Glossario](#glossario)
- [Estendere il front-end](#estendere-il-front-end)
- [Verifica e test](#verifica-e-test)
- [Distribuzione online](#distribuzione-online)

## Architettura

Tre livelli netti:

- **`models/`** — livello a oggetti: una classe per entità di dominio
  (`Alimento`, `Paziente`, `PianoAlimentare`, `PianoGiorno`, `Appuntamento`,
  `Ricetta`, `RicettaIngrediente`, `SmartfoodRiga`, il generico `LarnRiga`
  per le 15 tabelle LARN), ciascuna responsabile della propria validazione,
  lettura/scrittura su database e calcoli di dominio (fabbisogno LARN di un
  paziente, valori nutrizionali di una ricetta, kcal di un piano). Le 15
  tabelle LARN condividono un'unica classe generica, un'unica
  implementazione per tutti i casi che seguono la stessa struttura.
- **`api/`** — blueprint Flask, uno per area applicativa, che rispondono
  solo `jsonify(...)`: leggono la richiesta, chiamano un metodo di un
  modello, restituiscono JSON con lo status HTTP appropriato. Restano
  quindi molto sottili: nessuna logica di dominio vive qui. 61 endpoint in
  totale su 7 blueprint.
- **`frontend/`** — interfaccia statica indipendente (HTML/CSS/JS puro,
  nessun framework): un router basato su hash, un client `fetch()` per
  ogni endpoint (`api.js`), e un renderer per ogni schermata (`pages.js`).
  Non riceve mai HTML già pronto dal server.

Per comodità di sviluppo la stessa app Flask serve sia `/api/*` sia i file
statici del front-end (stesso principio di un reverse proxy che smista fra
un backend applicativo e una cartella di file statici): front-end e API
restano disaccoppiati nel codice, pur girando nello stesso processo.

## Struttura del progetto

```
alimenti_api/
├── app.py                  # crea l'app Flask, registra i blueprint, serve il front-end
├── config.py                 # configurazione (DB, sessione, CORS)
├── db.py                      # livello di accesso a MySQL
├── auth.py                     # login/sessione (risponde in JSON, non con redirect)
├── errors.py                    # ogni errore (400/401/404/500) risponde in JSON
├── validation.py                  # validazione dei payload JSON, guidata dai registri campi
├── fields.py, larn_fields.py,
│   ricette_fields.py, smartfood_fields.py,
│   pazienti_fields.py                # registri campi (nomi colonna, etichette, tipi, validazione)
├── larn_lookup.py                       # calcolo dei riferimenti LARN per un paziente
├── models/                                # livello OOP (vedi sopra)
├── api/                                     # blueprint REST (vedi sopra)
├── frontend/                                  # front-end statico
│   ├── index.html, docs.html                    shell app + pagina Swagger UI
│   ├── css/style.css
│   └── js/{api,util,pages,app}.js
├── sql/
│   ├── schema_completo.sql                        schema completo (tutte le tabelle e viste)
│   └── dati_completo.sql                            dati di esempio (oltre 800 alimenti CREA)
├── openapi.yaml                                       documentazione API (OpenAPI 3 / Swagger)
├── requirements.txt
└── smoke_test.py                                        script di verifica opzionale (facoltativo)
```

## Avvio in locale

1. **Database**: crea un database MySQL e importa, in ordine:
   ```bash
   mysql -u <utente> -p <nome_database> < sql/schema_completo.sql
   mysql -u <utente> -p <nome_database> < sql/dati_completo.sql
   ```
2. **Dipendenze**: `pip install -r requirements.txt`
3. **Variabili d'ambiente** (opzionali in locale, hanno un default in
   `config.py`): `MYSQL_HOST`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_DB`,
   `MYSQL_PORT`, `SECRET_KEY`, `ADMIN_USERNAME`, `ADMIN_PASSWORD_HASH`.
4. **Avvio**: `python3 app.py` — apri `http://127.0.0.1:5000/`.

## Credenziali e sicurezza

Le operazioni di sola lettura su alimenti, LARN, ricette e smartfood sono
pubbliche; le operazioni di scrittura su questi moduli e **tutte** le
operazioni sui pazienti (dati clinici) richiedono il login.

Credenziali di default: `admin` / `cambiami123`. **Da cambiare prima di
qualunque uso reale**, insieme alla `SECRET_KEY`:

```bash
# nuova SECRET_KEY
python3 -c "import secrets; print(secrets.token_hex(32))"

# nuovo hash per ADMIN_PASSWORD_HASH
python3 -c "from werkzeug.security import generate_password_hash as g; print(g('LA-TUA-PASSWORD', method='pbkdf2:sha256'))"
```

## Documentazione API

- **Swagger UI**: `http://127.0.0.1:5000/api/docs`
- **Spec OpenAPI**: `http://127.0.0.1:5000/api/openapi.yaml` (importabile in
  Postman/Insomnia)
- 37 percorsi, 61 endpoint, 16 schemi dati

## Glossario

Sigle usate nel codice (LARN, dominio nutrizionale, architettura tecnica): vedi [glossario.md](glossario.md).

## Estendere il front-end

API e pagine sono già complete per tutte le sezioni (Alimenti, LARN,
Ricette, Smartfood, Pazienti/Piani/Giorni, Appuntamenti). Per aggiungere
una nuova schermata:

1. Aggiungi il metodo corrispondente in `api.js` (un client per endpoint).
2. Scrivi un renderer in `pages.js`: prendi come esempio `Pages.alimentiList`
   (elenco semplice) o `Pages.pazienteDetail` (pagina composta da più
   chiamate). I form si generano da soli con `renderFieldsForm(campi,
   valori)` a partire dai metadati che l'API espone (`GET
   /api/<risorsa>/campi`): non serve scrivere un `<input>` per campo a
   mano.
3. Aggiungi la rotta alla tabella `ROUTES` in `app.js`.

## Verifica e test

Il comportamento dell'intera API (autenticazione, CRUD su ogni modulo,
calcolo LARN, ricalcolo nutrizionale di ricette e piani, cascata delle
eliminazioni) e della SPA nel browser è stato verificato con un database
MySQL reale popolato dai dati di `sql/dati_completo.sql`: 48 controlli
sull'API e 23 controlli nel browser (navigazione di ogni sezione,
creazione di un paziente end-to-end con piano, alimenti collegati e
appuntamento), tutti superati.

`smoke_test.py` è incluso come script di verifica opzionale (richiede solo
la libreria `requests`): può essere rimosso senza conseguenze.

```bash
python3 app.py &          # avvia il server in background
python3 smoke_test.py     # esegue i controlli sull'API
```

## Distribuzione online

Per l'installazione su PythonAnywhere, vedi `README_PYTHONANYWHERE.md`:
copre creazione del virtualenv, configurazione del database MySQL, file
WSGI completo, tabella di tutte le variabili di configurazione e
risoluzione dei problemi più comuni.
