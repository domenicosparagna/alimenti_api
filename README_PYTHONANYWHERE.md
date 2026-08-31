# Installare Registro Alimenti (alimenti_api) su PythonAnywhere

Guida completa per pubblicare questa app — backend API REST (Flask +
MySQL) e front-end statico (HTML/CSS/JS) — su PythonAnywhere. Copre ogni
passaggio, tutte le variabili di configurazione necessarie e i problemi
piu' comuni.

## Prerequisiti

- Un account PythonAnywhere. **Nota importante:** da gennaio 2026
  PythonAnywhere ha spostato l'accesso a MySQL dal piano gratuito al piano
  a pagamento "Developer" per i nuovi account; se il tuo account e' stato
  creato prima di allora mantieni MySQL gratis. Se non sei sicuro, vai su
  **Databases** nella dashboard: se vedi la sezione per creare un database
  MySQL, sei a posto.
- I file di questo progetto (questo zip).
- Nessuna conoscenza pregressa di PythonAnywhere: ogni passaggio indica
  esattamente dove cliccare.

## Panoramica: cosa stai installando

Un'unica app Flask (`app.py`) che espone:
- **`/api/*`** — API REST in JSON (alimenti, tabelle LARN, ricette,
  smartfood, pazienti/piani/appuntamenti);
- **`/`, `/css/*`, `/js/*`** — il front-end statico (nessun template
  server-side: e' la stessa app Flask a servire i file cosi' come sono).

Non servono due web app separate su PythonAnywhere: una sola basta per
tutto, perche' front-end e backend condividono lo stesso processo Flask
pur restando disaccoppiati nel codice.

---

## 1. Carica il progetto

1. Dashboard PythonAnywhere -> scheda **Files**.
2. Carica il file `alimenti_api.zip` nella tua home directory
   (`/home/<tuo-username>/`).
3. Apri una **Bash console** (scheda **Consoles** -> **Bash**) ed esegui:

   ```bash
   cd ~
   unzip alimenti_api.zip
   cd alimenti_api
   ls
   ```

   Dovresti vedere `app.py`, `models/`, `api/`, `frontend/`, `sql/`, ecc.
   Da qui in poi tutti i comandi si intendono lanciati da dentro questa
   cartella, salvo indicazione diversa.

## 2. Crea l'ambiente virtuale e installa le dipendenze

Nella stessa Bash console:

```bash
mkvirtualenv --python=python3.10 alimenti-venv
pip install -r requirements.txt
```

Usa la versione di Python piu' recente offerta da PythonAnywhere (controlla
con `python3.X --version`; 3.10 o superiore vanno bene). Segnati il percorso
del virtualenv, ti servira' al passo 7:

```bash
echo $VIRTUAL_ENV
# tipicamente: /home/<tuo-username>/.virtualenvs/alimenti-venv
```

Se in futuro riapri una console e il virtualenv non e' attivo, riattivalo
con `workon alimenti-venv`.

## 3. Crea e configura il database MySQL

1. Scheda **Databases**.
2. Se non l'hai gia' fatto, imposta una **password MySQL** (e' diversa da
   quella di login al sito: usala solo per il database).
3. Nel campo per creare un nuovo database inserisci `diario_alimentare` e
   conferma: PythonAnywhere lo creera' con il nome completo
   `<tuo-username>$diario_alimentare` (il prefisso `<tuo-username>$` e'
   automatico e obbligatorio, tienilo a mente per il passo successivo).
4. In questa stessa pagina trovi anche l'**hostname MySQL**, di solito
   `<tuo-username>.mysql.pythonanywhere-services.com`.

## 4. Importa schema e dati

Dalla Bash console, dentro `~/alimenti_api`:

```bash
mysql -u <tuo-username> -h <tuo-username>.mysql.pythonanywhere-services.com \
      -p '<tuo-username>$diario_alimentare' < sql/schema_completo.sql

mysql -u <tuo-username> -h <tuo-username>.mysql.pythonanywhere-services.com \
      -p '<tuo-username>$diario_alimentare' < sql/dati_completo.sql
```

Ogni comando chiede la password MySQL impostata al passo 3 (non quella del
tuo account PythonAnywhere). Il secondo comando importa l'intero archivio
CREA (oltre 800 alimenti): puo' richiedere un paio di minuti, e' normale.

Usa **solo** `schema_completo.sql` e `dati_completo.sql`: sono le versioni
consolidate che contengono gia' tutte le tabelle e i dati (alimenti, LARN,
ricette, pazienti, smartfood). Gli altri file in `sql/` (`schema.sql`,
`larn_schema.sql`, `ricette_data.sql`, ecc.) sono le versioni per singolo
modulo tenute per riferimento storico: non importarli, altrimenti otterresti
tabelle duplicate o errori di chiave gia' esistente.

Verifica che sia andato tutto a buon fine:

```bash
mysql -u <tuo-username> -h <tuo-username>.mysql.pythonanywhere-services.com \
      -p '<tuo-username>$diario_alimentare' \
      -e "SELECT COUNT(*) AS alimenti FROM alimenti;"
```

Dovresti vedere un numero superiore a 800.

## 5. Crea la web app

1. Scheda **Web** -> **Add a new web app**.
2. Conferma il dominio proposto (`<tuo-username>.pythonanywhere.com`).
3. Alla domanda sul framework scegli **Manual configuration** — non
   "Flask": quell'opzione genera un progetto Flask vuoto da zero, mentre tu
   vuoi collegare il codice che hai gia' caricato.
4. Scegli la stessa versione di Python usata per il virtualenv al passo 2.

## 6. Configura il file WSGI

Nella pagina della tua web app (scheda **Web**), sotto **Code**, clicca sul
link del file WSGI (qualcosa come
`/var/www/<tuo-username>_pythonanywhere_com_wsgi.py`) e **sostituisci tutto
il contenuto** con questo, adattando i valori segnati `<...>` ai tuoi:

```python
import sys
import os

# --- Percorso del progetto -------------------------------------------------
project_home = '/home/<tuo-username>/alimenti_api'
if project_home not in sys.path:
    sys.path.insert(0, project_home)

# --- Connessione al database (vedi passi 3-4) -------------------------------
os.environ['MYSQL_HOST'] = '<tuo-username>.mysql.pythonanywhere-services.com'
os.environ['MYSQL_USER'] = '<tuo-username>'
os.environ['MYSQL_PASSWORD'] = '<la-password-mysql-impostata-al-passo-3>'
os.environ['MYSQL_DB'] = '<tuo-username>$diario_alimentare'

# --- Sicurezza: DA PERSONALIZZARE prima di andare online --------------------
# Chiave segreta per le sessioni Flask: genera la tua con
#   python3 -c "import secrets; print(secrets.token_hex(32))"
os.environ['SECRET_KEY'] = '<una-stringa-casuale-lunga-e-segreta>'

# Credenziali dell'amministratore (chi puo' creare/modificare/eliminare).
# Per cambiare la password genera un nuovo hash con:
#   python3 -c "from werkzeug.security import generate_password_hash as g; print(g('LA-TUA-PASSWORD', method='pbkdf2:sha256'))"
os.environ['ADMIN_USERNAME'] = 'admin'
os.environ['ADMIN_PASSWORD_HASH'] = '<hash-generato-come-sopra>'

# --- Applicazione ------------------------------------------------------------
from app import app as application
```

Salva il file.

## 7. Collega il virtualenv

Nella stessa pagina **Web**, sezione **Virtualenv**, incolla il percorso
segnato al passo 2 (es. `/home/<tuo-username>/.virtualenvs/alimenti-venv`)
e conferma con il segno di spunta.

## 8. (Opzionale) File statici serviti direttamente

Non e' obbligatorio: l'app funziona gia' cosi' com'e', perche' `app.py`
serve da solo i file di `frontend/` tramite le proprie route Flask. Per
un filo di performance in piu' (i file statici passano dal server web di
PythonAnywhere invece che dal processo Python), nella sezione **Static
files** della scheda Web puoi aggiungere:

| URL     | Directory                                          |
|---------|-----------------------------------------------------|
| `/css/` | `/home/<tuo-username>/alimenti_api/frontend/css/`    |
| `/js/`  | `/home/<tuo-username>/alimenti_api/frontend/js/`     |

## 9. Ricarica e verifica

1. In cima alla scheda **Web**, premi il pulsante verde **Reload
   <tuo-username>.pythonanywhere.com**: e' quello che applica ogni modifica
   fatta finora (al file WSGI, al virtualenv, ai file statici).
2. Apri `https://<tuo-username>.pythonanywhere.com`: dovresti vedere la
   home dell'app con le card di Alimenti, LARN, Ricette, ecc.
3. Prova ad aprire `/#/alimenti`: la lista dovrebbe popolarsi con gli
   alimenti importati.
4. Accedi da `/#/login` con `admin` / la password che hai scelto, poi crea
   un paziente di prova per controllare che anche le operazioni di
   scrittura sul database funzionino.
5. Apri `/api/docs`: dovresti vedere la documentazione Swagger dell'API.

Se qualcosa non torna, la scheda **Web** ha un link **Error log**: mostra
il traceback Python completo dell'ultimo errore, quasi sempre sufficiente
per capire cosa non va (vedi anche la tabella di risoluzione problemi piu'
sotto).

---

## Riferimento: tutte le variabili di configurazione

Impostale nel file WSGI come mostrato al passo 6 (oppure, se preferisci
non scriverle nel file WSGI, PythonAnywhere offre anche una sezione
**Environment variables** nella scheda Web, nelle versioni piu' recenti
dell'interfaccia).

| Variabile | Obbligatoria | Default se assente | Cosa mettere su PythonAnywhere |
|---|---|---|---|
| `MYSQL_HOST` | Si | `localhost` | `<tuo-username>.mysql.pythonanywhere-services.com` |
| `MYSQL_USER` | Si | `root` | il tuo username PythonAnywhere |
| `MYSQL_PASSWORD` | Si | `password` | la password MySQL impostata nella scheda Databases |
| `MYSQL_DB` | Si | `diario_alimentare` | `<tuo-username>$diario_alimentare` |
| `MYSQL_PORT` | No | `3306` | lascia il default |
| `SECRET_KEY` | Si (per sicurezza) | valore segnaposto non sicuro | una stringa casuale lunga e segreta (vedi passo 6) |
| `ADMIN_USERNAME` | No | `admin` | lascia il default o personalizzalo |
| `ADMIN_PASSWORD_HASH` | Si (per sicurezza) | hash di `cambiami123` | l'hash della tua password (vedi passo 6) |
| `PAGE_SIZE` | No | `25` | righe per pagina negli elenchi, personalizzabile |
| `CORS_ALLOWED_ORIGINS` | No | origini di sviluppo locale | non serve se front-end e API restano sulla stessa app (caso di questa guida) |

## Prima di condividere il link: checklist di sicurezza

- [ ] Hai generato una nuova `SECRET_KEY` (non quella di default nel codice)?
- [ ] Hai generato un nuovo `ADMIN_PASSWORD_HASH` per una password diversa da `cambiami123`?
- [ ] Il file WSGI (che contiene password in chiaro) resta privato: non
      finisce in un repository pubblico. Se pubblichi il codice su GitHub,
      **non committare mai il file WSGI reale** — nel repository tieni solo
      questo README con i placeholder `<...>`.

## Aggiornare l'app dopo una modifica al codice

1. Carica i file modificati (via **Files**, oppure con `git pull` se il
   progetto e' collegato a un repository: apri una Bash console e lancia
   `cd ~/alimenti_api && git pull`).
2. Se hai aggiunto una dipendenza in `requirements.txt`:
   `workon alimenti-venv && pip install -r requirements.txt`.
3. Se hai modificato lo schema del database, importa il relativo file
   `.sql` con lo stesso comando `mysql` del passo 4.
4. Torna sulla scheda **Web** e premi **Reload**. Le modifiche al codice
   Python non hanno effetto finche' non ricarichi la web app.

## Manutenzione: le web app gratuite scadono se inattive

Su PythonAnywhere una web app inutilizzata per un periodo prolungato viene
sospesa automaticamente (riceverai un'email di avviso prima che succeda).
Per riattivarla basta tornare sulla scheda **Web** e premere il pulsante di
"revive"/riattivazione che compare al posto di Reload: nessun dato va perso,
ne' sul codice ne' sul database.

## Risoluzione dei problemi piu' comuni

| Sintomo | Causa probabile | Soluzione |
|---|---|---|
| Pagina "Something went wrong" / errore 500 | Quasi sempre nel file **Error log** (scheda Web) c'e' il motivo esatto | Apri l'error log, leggi l'ultimo traceback |
| `ModuleNotFoundError: No module named 'flask'` (o simili) nell'error log | Il virtualenv non e' collegato, o le dipendenze non sono installate li' dentro | Rifai il passo 7; verifica con `workon alimenti-venv && pip list` |
| `pymysql.err.OperationalError: (1045, "Access denied for user...")` | Password MySQL sbagliata nel file WSGI, oppure non coincide con quella impostata nella scheda Databases | Reimposta la password in Databases e aggiorna `MYSQL_PASSWORD` nel WSGI |
| `pymysql.err.OperationalError: (1049, "Unknown database...")` | Nome database sbagliato: manca il prefisso `<username>$` | Controlla `MYSQL_DB` nel WSGI: deve essere `<tuo-username>$diario_alimentare` |
| La home page si apre ma le liste (Alimenti, Ricette, ...) restano vuote o in caricamento infinito | Dati non ancora importati, o import fallito a meta' | Ripeti il passo 4 e controlla l'output del comando `mysql` per errori |
| CSS o JS non si caricano (pagina senza stile) | Percorso della cartella `frontend/` sbagliato, o non hai fatto Reload dopo aver caricato i file | Verifica il percorso in `project_home` nel WSGI; premi Reload |
| Il login non funziona con `admin` / `cambiami123` | Hai gia' personalizzato `ADMIN_PASSWORD_HASH` nel WSGI (comportamento corretto) | Usa la password che hai scelto tu, non quella di default |
| Va tutto bene in locale ma non su PythonAnywhere | Quasi sempre una variabile d'ambiente diversa fra i due ambienti | Ricontrolla ogni riga del blocco `os.environ[...]` nel file WSGI |
