# -*- coding: utf-8 -*-
"""Script di verifica opzionale (facoltativo, non richiesto dalla traccia).

Esercita l'intera API con richieste HTTP reali (libreria `requests`): utile
per controllare rapidamente, dopo una modifica, che tutto risponda ancora
come previsto, o come base di partenza per una suite di test piu' formale.
Per eseguirlo serve un'app Flask gia' avviata (`python3 app.py`) su
http://127.0.0.1:5000 con un database MySQL raggiungibile e popolato.

Uso: python3 smoke_test.py
"""
import sys
import requests

BASE = "http://127.0.0.1:5000/api"
ok_count = 0
fail_count = 0


def check(label, condition, extra=""):
    global ok_count, fail_count
    if condition:
        ok_count += 1
        print(f"OK   - {label}")
    else:
        fail_count += 1
        print(f"FAIL - {label} {extra}")


s = requests.Session()

# ---------------------------------------------------------------------
print("\n== Endpoint pubblici ==")
r = s.get(f"{BASE}/alimenti", params={"page": 1})
check("GET /alimenti -> 200", r.status_code == 200, r.text[:200])
data = r.json()
check("GET /alimenti ha items+total_pages", "items" in data and "total_pages" in data)
primo_id = data["items"][0]["id"]

r = s.get(f"{BASE}/alimenti/{primo_id}")
check("GET /alimenti/<id> -> 200", r.status_code == 200)

r = s.get(f"{BASE}/alimenti/9999999")
check("GET /alimenti/<id inesistente> -> 404", r.status_code == 404)

r = s.get(f"{BASE}/alimenti/categorie")
check("GET /alimenti/categorie -> lista non vuota", r.status_code == 200 and len(r.json()) > 0)

r = s.get(f"{BASE}/larn/tables")
tabelle = r.json()
check("GET /larn/tables -> 15 tabelle", r.status_code == 200 and len(tabelle) == 15, str(len(tabelle)))

r = s.get(f"{BASE}/larn/proteine")
check("GET /larn/proteine -> 200 con items", r.status_code == 200 and len(r.json()["items"]) > 0)

r = s.get(f"{BASE}/larn/tabella-inesistente")
check("GET /larn/<key sconosciuta> -> 404", r.status_code == 404)

r = s.get(f"{BASE}/smartfood/fasce")
check("GET /smartfood/fasce -> 4 fasce", r.status_code == 200 and len(r.json()) == 4)

r = s.get(f"{BASE}/smartfood")
check("GET /smartfood -> 200", r.status_code == 200 and r.json()["total"] > 0)

r = s.get(f"{BASE}/ricette")
ricette = r.json()
check("GET /ricette -> 200 con items", r.status_code == 200 and len(ricette["items"]) > 0)
ricetta_id = ricette["items"][0]["id"]

r = s.get(f"{BASE}/ricette/{ricetta_id}/ingredienti")
check("GET /ricette/<id>/ingredienti -> 200", r.status_code == 200)

r = s.get(f"{BASE}/ricette/{ricetta_id}/valori-calcolati")
check("GET /ricette/<id>/valori-calcolati -> 200", r.status_code == 200)

# ---------------------------------------------------------------------
print("\n== Protezione delle route riservate ==")
r = s.get(f"{BASE}/pazienti")
check("GET /pazienti senza login -> 401", r.status_code == 401)

r = s.post(f"{BASE}/alimenti", json={"nome_alimento": "Test"})
check("POST /alimenti senza login -> 401", r.status_code == 401)

# ---------------------------------------------------------------------
print("\n== Autenticazione ==")
r = s.get(f"{BASE}/auth/me")
check("GET /auth/me (non loggato) -> logged_in False", r.status_code == 200 and r.json()["logged_in"] is False)

r = s.post(f"{BASE}/auth/login", json={"username": "admin", "password": "sbagliata"})
check("POST /auth/login credenziali errate -> 401", r.status_code == 401)

r = s.post(f"{BASE}/auth/login", json={"username": "admin", "password": "cambiami123"})
check("POST /auth/login credenziali corrette -> 200", r.status_code == 200 and r.json()["logged_in"] is True)

r = s.get(f"{BASE}/auth/me")
check("GET /auth/me (loggato) -> logged_in True", r.status_code == 200 and r.json()["logged_in"] is True)

# ---------------------------------------------------------------------
print("\n== Alimenti: scrittura (CRUD completo) ==")
nuovo = {
    "nome_alimento": "Alimento di prova API",
    "categoria": "Test",
    "codice_alimento": "TEST001",
    "energia_kcal": 100,
    "proteine_g": 5,
    "lipidi_g": 2,
    "carboidrati_disponibili_g": 10,
}
r = s.post(f"{BASE}/alimenti", json=nuovo)
check("POST /alimenti -> 201", r.status_code == 201, r.text[:300])
alimento_test_id = r.json()["id"]

r = s.post(f"{BASE}/alimenti", json={"categoria": "Test"})
check("POST /alimenti dati incompleti -> 400 con details", r.status_code == 400 and "details" in r.json())

r = s.put(f"{BASE}/alimenti/{alimento_test_id}", json={**nuovo, "energia_kcal": 150})
check("PUT /alimenti/<id> -> 200", r.status_code == 200 and float(r.json()["energia_kcal"]) == 150.0)

r = s.delete(f"{BASE}/alimenti/{alimento_test_id}")
check("DELETE /alimenti/<id> -> 204", r.status_code == 204)

r = s.get(f"{BASE}/alimenti/{alimento_test_id}")
check("GET dopo DELETE -> 404", r.status_code == 404)

# ---------------------------------------------------------------------
print("\n== LARN: scrittura generica su una tabella (acqua) ==")
nuova_riga = {
    "fascia": "Test", "eta_label": "test", "eta_min": 1, "eta_max": 2,
    "unita_eta": "anni", "sesso": "ND", "valore_ml_die": 1000, "tipo_valore": "assoluto",
}
r = s.post(f"{BASE}/larn/acqua", json=nuova_riga)
check("POST /larn/acqua -> 201", r.status_code == 201, r.text[:300])
larn_id = r.json()["id"]

r = s.put(f"{BASE}/larn/acqua/{larn_id}", json={**nuova_riga, "valore_ml_die": 1200})
check("PUT /larn/acqua/<id> -> 200", r.status_code == 200 and r.json()["valore_ml_die"] == 1200)

r = s.delete(f"{BASE}/larn/acqua/{larn_id}")
check("DELETE /larn/acqua/<id> -> 204", r.status_code == 204)

# ---------------------------------------------------------------------
print("\n== Ricette: ingredienti + ricalcolo ==")
r = s.post(f"{BASE}/ricette", json={
    "nome_ricetta": "Ricetta di prova API", "categoria_ricetta": "Contorno", "porzioni": 2,
})
check("POST /ricette -> 201", r.status_code == 201, r.text[:300])
ricetta_test_id = r.json()["id"]

r = s.get(f"{BASE}/ricette/alimenti-options")
check("GET /ricette/alimenti-options -> 200", r.status_code == 200 and len(r.json()) > 0)
codice_alimento_opzione = r.json()[0]["codice_alimento"]

r = s.post(f"{BASE}/ricette/{ricetta_test_id}/ingredienti",
           json={"codice_alimento": codice_alimento_opzione, "quantita_g": 100})
check("POST .../ingredienti -> 201", r.status_code == 201, r.text[:300])

r = s.post(f"{BASE}/ricette/{ricetta_test_id}/ricalcola")
check("POST /ricette/<id>/ricalcola -> 200", r.status_code == 200, r.text[:300])

r = s.delete(f"{BASE}/ricette/{ricetta_test_id}")
check("DELETE /ricette/<id> -> 204 (CASCADE ingredienti)", r.status_code == 204)

# ---------------------------------------------------------------------
print("\n== Pazienti: percorso completo (piano -> 7 giorni -> alimenti -> kcal, LARN, appuntamento) ==")
r = s.post(f"{BASE}/pazienti", json={
    "nome": "Mario", "cognome": "TestApi", "data_nascita": "1990-05-15",
    "sesso": "M", "altezza_cm": 178, "peso_kg": 75, "livello_attivita_fisica": "1.6",
})
check("POST /pazienti -> 201", r.status_code == 201, r.text[:300])
paziente_id = r.json()["id"]

r = s.get(f"{BASE}/pazienti/{paziente_id}/larn")
larn_paziente = r.json()
check("GET /pazienti/<id>/larn -> calcola kcal energia", r.status_code == 200 and larn_paziente["energia"]["kcal"] is not None, r.text[:300])

r = s.post(f"{BASE}/pazienti/{paziente_id}/piani", json={"titolo": "Piano di prova"})
check("POST /pazienti/<id>/piani -> 201", r.status_code == 201, r.text[:300])
piano_id = r.json()["id"]

r = s.get(f"{BASE}/pazienti/{paziente_id}/piani/{piano_id}")
piano_data = r.json()
check("GET piano -> 7 giorni generati", r.status_code == 200 and len(piano_data["giorni"]) == 7, str(len(piano_data.get("giorni", []))))

giorno = "Lunedi"
r = s.get(f"{BASE}/pazienti/{paziente_id}/piani/{piano_id}/giorni/{giorno}")
check("GET giorno -> 200", r.status_code == 200, r.text[:300])

r = s.put(f"{BASE}/pazienti/{paziente_id}/piani/{piano_id}/giorni/{giorno}",
          json={"colazione_latte": "200 ml di latte parzialmente scremato"})
check("PUT giorno (testo pasto) -> 200", r.status_code == 200, r.text[:300])

r = s.post(f"{BASE}/pazienti/{paziente_id}/piani/{piano_id}/giorni/{giorno}/alimenti",
           json={"pasto": "colazione", "codice_alimento": codice_alimento_opzione, "quantita_g": 50})
check("POST collega alimento a pasto -> 201", r.status_code == 201, r.text[:300])
link_id = r.json()["id"]

r = s.post(f"{BASE}/pazienti/{paziente_id}/piani/{piano_id}/giorni/{giorno}/ricalcola-kcal")
check("POST ricalcola-kcal -> 200 con kcal_stimate > 0", r.status_code == 200 and r.json()["kcal_stimate"] > 0, r.text[:300])

r = s.delete(f"{BASE}/pazienti/{paziente_id}/piani/{piano_id}/giorni/{giorno}/alimenti/{link_id}")
check("DELETE alimento collegato -> 204", r.status_code == 204)

r = s.post(f"{BASE}/appuntamenti", json={
    "paziente_id": paziente_id, "data_ora": "2026-09-15T10:00", "tipo": "Prima visita",
})
check("POST /appuntamenti -> 201", r.status_code == 201, r.text[:300])
app_id = r.json()["id"]

r = s.get(f"{BASE}/appuntamenti", params={"passati": "1"})
check("GET /appuntamenti (agenda) -> include il nuovo appuntamento", r.status_code == 200 and any(a["id"] == app_id for a in r.json()["items"]))

r = s.delete(f"{BASE}/appuntamenti/{app_id}")
check("DELETE /appuntamenti/<id> -> 204", r.status_code == 204)

r = s.delete(f"{BASE}/pazienti/{paziente_id}/piani/{piano_id}")
check("DELETE piano -> 204", r.status_code == 204)

r = s.delete(f"{BASE}/pazienti/{paziente_id}")
check("DELETE paziente -> 204", r.status_code == 204)

# ---------------------------------------------------------------------
print("\n== Logout ==")
r = s.post(f"{BASE}/auth/logout")
check("POST /auth/logout -> 200", r.status_code == 200)
r = s.get(f"{BASE}/pazienti")
check("GET /pazienti dopo logout -> 401", r.status_code == 401)

# ---------------------------------------------------------------------
print(f"\n=== RISULTATO: {ok_count} OK, {fail_count} FALLITI ===")
sys.exit(1 if fail_count else 0)
