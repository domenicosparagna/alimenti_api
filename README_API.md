# Registro Alimenti — trasformazione in API REST

Questo progetto e' la trasformazione di `alimenti_app/` (l'app Flask a pagine
server-renderizzate) in un'architettura **API-based**: un backend che espone
solo JSON (`/api/*`) e un front-end statico e indipendente (HTML, CSS,
JavaScript puro) che lo consuma via `fetch()`. Nessun `render_template` e'
rimasto: puoi verificarlo tu stesso con `grep -rn render_template api/ models/`,
che non trova nulla.

Dati, logica di dominio (calcolo LARN, ricalcolo nutrizionale ricette, kcal
del piano) e regole di validazione sono le stesse dell'app originale: cio'
che e' cambiato e' come sono organizzate ed esposte.

## Perche' questa trasformazione

Confrontando l'app originale con la traccia del Project Work, il punto piu'
importante che mancava era proprio l'architettura: la traccia chiede
un'applicazione "full-stack **API-based**" con un "backend **RESTful**" e un
front-end HTML/CSS/**JavaScript** separato, oltre a un backend
**object-oriented** e alla **documentazione delle API (tipo Swagger)**.
L'app originale era un monolite Flask a rendering server-side, senza una
riga di JavaScript e senza classi proprie. Questo progetto corregge proprio
quei punti, mantenendo intatto tutto cio' che gia' funzionava bene (il
modello dati, le regole di business, la sicurezza delle query).

## Struttura del progetto

```
alimenti_api/
├── app.py                 # crea l'app Flask, registra i blueprint API, serve il front-end
├── config.py               # configurazione (invariato dall'originale) + CORS
├── db.py                    # livello di accesso a MySQL (invariato dall'originale)
├── auth.py                  # login/sessione, adattato per rispondere in JSON (401 invece di redirect)
├── errors.py                 # ogni errore (404/400/401/500) risponde in JSON, mai HTML
├── validation.py              # validazione dei payload JSON, guidata dai registri *_fields.py
├── fields.py, larn_fields.py, ricette_fields.py,
│   smartfood_fields.py, pazienti_fields.py           # registri dei campi (invariati dall'originale)
├── larn_lookup.py            # calcolo dei riferimenti LARN per un paziente (invariato dall'originale)
├── models/                    # NUOVO: livello a oggetti (vedi sotto)
│   ├── base.py                 Model: classe base condivisa
│   ├── alimento.py              class Alimento
│   ├── larn.py                  class LarnRiga (generica, copre le 15 tabelle)
│   ├── ricetta.py                class Ricetta, class RicettaIngrediente
│   ├── smartfood.py              class SmartfoodRiga
│   └── paziente.py               class Paziente, PianoAlimentare, PianoGiorno, Appuntamento
├── api/                        # NUOVO: blueprint Flask, solo jsonify()
│   ├── auth.py, alimenti.py, larn.py, ricette.py, smartfood.py, pazienti.py
├── openapi.yaml                # NUOVO: documentazione delle API (OpenAPI 3 / "tipo Swagger")
├── frontend/                   # NUOVO: front-end statico, separato dal backend
│   ├── index.html, docs.html     shell dell'app + pagina Swagger UI
│   ├── css/style.css              stesso foglio di stile dell'app originale (+ poche aggiunte)
│   └── js/
│       ├── api.js                 unico file che chiama fetch(): un metodo per endpoint
│       ├── util.js                 helper (escape HTML, formattazione, form -> JSON)
│       ├── pages.js                 un renderer per ogni schermata della SPA
│       └── app.js                   router (basato su #hash), intestazione, login
├── sql/                        # stesso schema/dati dell'app originale (invariato)
└── smoke_test.py                # script di verifica opzionale (vedi sotto)
```

## Come si e' arrivati qui: il livello dei modelli (OOP)

Nell'app originale, ogni `*_views.py` mescolava tre cose nella stessa
funzione: interpretare la richiesta, interrogare il database, e generare
HTML. Qui quella logica e' stata **incapsulata in classi** (`models/`):
ogni classe rappresenta un'entita' del dominio (`Alimento`, `Paziente`,
`Ricetta`, ...) e sa fare tutto cio' che riguarda se stessa — leggersi dal
database (`Alimento.get(42)`), validarsi, salvarsi, cancellarsi,
calcolare i propri valori derivati (`ricetta.ricalcola()`,
`paziente.riferimenti_larn()`) — invece di essere un semplice dizionario di
colonne passato in giro tra funzioni. I blueprint in `api/` restano quindi
molto sottili: leggono la richiesta, chiamano un metodo di un modello,
restituiscono JSON. Questo e' il modo in cui il backend soddisfa il
requisito "purche' object-oriented" della traccia.

Le 15 tabelle LARN condividono un'unica classe generica (`LarnRiga`),
esattamente come l'app originale usava un'unica implementazione per tutte
loro: il principio "una sola implementazione per casi simili" e' lo stesso,
solo spostato da funzioni a un oggetto.

## Come eseguirlo

1. **Database**: usa lo stesso `sql/schema_completo.sql` + `sql/dati_completo.sql`
   dell'app originale (`mysql -u <utente> -p < sql/schema_completo.sql`, poi
   lo stesso per i dati sul database `diario_alimentare`).
2. **Dipendenze**: `pip install -r requirements.txt`
3. **Variabili d'ambiente** (opzionali, ci sono default per sviluppo locale
   in `config.py`): `MYSQL_HOST`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_DB`,
   `MYSQL_PORT`, `SECRET_KEY`.
4. **Avvio**: `python3 app.py` — apri `http://127.0.0.1:5000/`.

Questa singola app Flask serve sia `/api/*` (JSON) sia i file statici di
`frontend/` (stesso principio di un server che smista fra un backend
applicativo e una cartella di file statici, come farebbe nginx in
produzione): e' la modalita' piu' semplice, senza alcuna configurazione di
CORS da fare. Se preferisci tenere il front-end su un server separato
durante lo sviluppo (es. l'estensione "Live Server"), il backend accetta
gia' richieste cross-origin con cookie da `http://127.0.0.1:5500` (vedi
`CORS_ALLOWED_ORIGINS` in `config.py`).

**Credenziali di default** (le stesse dell'app originale):
utente `admin`, password `cambiami123` — da cambiare prima di qualunque uso
reale (vedi i commenti in `config.py`).

## Documentazione delle API

- **Swagger UI**: `http://127.0.0.1:5000/api/docs` — esplora e prova ogni
  endpoint direttamente dal browser (il pulsante "Authorize" non serve: il
  login usa un cookie di sessione, quindi accedi prima dal front-end su
  `/#/login` nella stessa scheda, poi torna su `/api/docs`).
- **Spec grezza**: `http://127.0.0.1:5000/api/openapi.yaml` (formato
  OpenAPI 3, importabile in Postman/Insomnia).
- 37 percorsi, 61 endpoint, 16 schemi dati documentati.

## Mappatura con i requisiti della traccia

| Richiesta della traccia | Come e' soddisfatta qui |
|---|---|
| Applicazione full-stack **API-based** | `frontend/` (statico) e `api/` (JSON) sono disaccoppiati: il front-end non riceve mai HTML dal server, solo dati |
| Backend **RESTful** | Risorse su URL prevedibili (`/api/alimenti/42`), verbi HTTP corretti (GET/POST/PUT/DELETE), status code coerenti (200/201/204/400/401/404) |
| Front-end HTML, CSS, **JavaScript** | `frontend/` e' HTML + CSS + JavaScript puro (nessun framework, nessuna riga di codice lato server nel markup) |
| Backend **object-oriented** | `models/`: una classe per entita', con i propri metodi di lettura/scrittura/calcolo (vedi sopra) |
| Documentazione API **tipo Swagger** | `openapi.yaml` + Swagger UI su `/api/docs` |
| Un servizio significativo per un'organizzazione sanitaria | Gestione pazienti, piani alimentari, appuntamenti e fabbisogno nutrizionale di riferimento (LARN): il profilo di uno studio di nutrizione/dietetica — una professione sanitaria riconosciuta in Italia — comparabile a uno "studio medico professionale" |

Restano da preparare **fuori da questo codice** (parte del rapporto, non
dell'applicativo): il racconto del contesto dell'organizzazione, i diagrammi
UML/ER (lo schema in `sql/*.sql` e' gia' una buona base), il resoconto del
processo di sviluppo con gli snippet commentati, gli screenshot, e un
repository Git effettivo su cui pubblicare questo codice.

## Estendere il front-end

Sono complete sia l'API sia le pagine per **tutte** le sezioni (Alimenti,
LARN, Ricette, Smartfood, Pazienti/Piani/Giorni, Appuntamenti). Per
aggiungere una nuova schermata:

1. Aggiungi il metodo corrispondente in `api.js` (un client per endpoint).
2. Scrivi un renderer in `pages.js`: prendi come esempio `Pages.alimentiList`
   (elenco semplice) o `Pages.pazienteDetail` (pagina composta da piu'
   chiamate). I form si generano da soli con `renderFieldsForm(campi, valori)`
   a partire dai metadati che l'API espone (`GET /api/<risorsa>/campi`):
   non serve scrivere un `<input>` per campo a mano.
3. Aggiungi la rotta alla tabella `ROUTES` in `app.js`.

## Verifica

Ho controllato l'intera trasformazione con un database MySQL reale
(popolato con i dati di `sql/dati_completo.sql`): 48 controlli sull'API
(autenticazione, CRUD su ogni modulo, calcolo LARN, ricalcolo ricette/kcal,
cascata delle eliminazioni) e 23 controlli nel browser (navigazione reale
su ogni sezione, creazione di un paziente end-to-end con piano, alimenti
collegati e appuntamento), tutti superati. `smoke_test.py` e' la versione
leggera (solo libreria `requests`) di quella verifica, inclusa come bonus:
non e' richiesta dalla traccia e puoi tranquillamente rimuoverla.
