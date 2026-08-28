-- =====================================================================================
-- DATI DI ESEMPIO — Pazienti e Piano Alimentare Giornaliero
-- Da eseguire DOPO pazienti_schema.sql, e DOPO sql/data.sql (gli alimenti collegati ai
-- pasti in fondo a questo file referenziano alimenti.codice_alimento), nello stesso
-- database.
--
-- Inserisce un paziente di esempio con un piano alimentare settimanale: i 7 giorni
-- vengono creati tutti (come fa l'app quando si crea un nuovo piano dall'interfaccia),
-- con il solo LUNEDI' compilato, sul modello del modulo cartaceo caricato in origine
-- ("Giorno_PianoAlimentare.pdf"). Gli altri 6 giorni restano vuoti, pronti per essere
-- compilati dall'interfaccia (scheda piano -> Modifica su ciascun giorno).
--
-- Per il LUNEDI', oltre alla descrizione testuale dei pasti (come nel modulo cartaceo),
-- alcuni alimenti sono anche collegati con una quantita' (tabella piano_pasto_alimenti),
-- esattamente come fa l'interfaccia quando si usa "Aggiungi alimento" in un pasto: questo
-- permette di calcolare le kcal automaticamente (bottone "Ricalcola kcal"), qui gia'
-- calcolate e salvate in piano_giorni.kcal_stimate per mostrare subito il risultato.
-- Colazione, spuntino e merenda non hanno alimenti collegati in questo esempio (solo
-- descrizione testuale), per mostrare che il calcolo funziona anche su un giorno
-- compilato solo in parte.
-- =====================================================================================

INSERT INTO pazienti
  (nome, cognome, data_nascita, sesso, altezza_cm, peso_kg, livello_attivita_fisica, email, telefono, note, attivo)
VALUES
  ('Mario', 'Rossi', '1985-04-12', 'M', 178, 82.5, '1.6', 'mario.rossi@example.com', '333 1234567',
   'Prima visita: obiettivo perdita di peso graduale. Nessuna allergia nota.', 1);

INSERT INTO piani_alimentari
  (paziente_id, titolo, data_inizio, data_fine, note, attivo)
VALUES
  ((SELECT id FROM pazienti WHERE nome = 'Mario' AND cognome = 'Rossi'),
   'Piano di avvio - Ottobre 2026', '2026-10-01', '2026-10-31',
   'Piano di avvio, da rivedere al controllo dopo 4 settimane.', 1);

INSERT INTO piano_giorni
  (piano_id, giorno_settimana,
   colazione_latte, colazione_fette_biscottate, colazione_altro,
   spuntino_10_30,
   pranzo_primo_piatto, pranzo_secondo_piatto, pranzo_verdure_ortaggi, pranzo_pane,
   pranzo_olio_cucchiaini, pranzo_olio_note, pranzo_frutta,
   merenda_17_30,
   cena_primo_piatto, cena_secondo_piatto, cena_verdure_ortaggi, cena_pane,
   cena_olio_cucchiaini, cena_olio_note, cena_frutta)
VALUES
  ((SELECT id FROM piani_alimentari WHERE titolo = 'Piano di avvio - Ottobre 2026'), 'Lunedi',
   '1 tazza (200 ml), parzialmente scremato', '3 fette', NULL,
   '1 frutto di stagione',
   'Pasta integrale al pomodoro (70 g)', 'Petto di pollo alla griglia (150 g)', 'Zucchine e carote al vapore', '1 panino piccolo (50 g)',
   2.0, 'a crudo, condimento per primo e secondo', '1 mela',
   '1 yogurt bianco magro',
   'Passato di verdure con farro (50 g)', 'Merluzzo al vapore (150 g)', 'Insalata mista', '1 panino piccolo (50 g)',
   2.0, 'a crudo', '1 pera');

-- Gli altri 6 giorni della settimana vengono creati vuoti, esattamente come fa
-- l'app alla creazione di un nuovo piano: pronti per essere compilati in seguito.
INSERT INTO piano_giorni (piano_id, giorno_settimana)
SELECT id, giorno
FROM piani_alimentari
JOIN (
  SELECT 'Martedi' AS giorno UNION ALL SELECT 'Mercoledi' UNION ALL SELECT 'Giovedi'
  UNION ALL SELECT 'Venerdi' UNION ALL SELECT 'Sabato' UNION ALL SELECT 'Domenica'
) AS giorni_mancanti
WHERE titolo = 'Piano di avvio - Ottobre 2026';

-- Alimenti collegati al pranzo e alla cena di Lunedi' (quantita' in grammi),
-- per il calcolo automatico delle kcal.
INSERT INTO piano_pasto_alimenti (piano_giorno_id, pasto, codice_alimento, quantita_g, note)
SELECT pg.id, v.pasto, v.codice_alimento, v.quantita_g, v.note
FROM piano_giorni pg
JOIN piani_alimentari p ON p.id = pg.piano_id
JOIN (
  -- Pranzo: pasta integrale al pomodoro, petto di pollo, zucchine, pane, olio, mela
  SELECT 'pranzo' AS pasto, '000855' AS codice_alimento, 70.00 AS quantita_g, 'pasta di semola integrale, cotta' AS note
  UNION ALL SELECT 'pranzo', '106506', 150.00, 'petto di pollo, cotto in padella'
  UNION ALL SELECT 'pranzo', '005741', 100.00, 'zucchine, cotte al vapore'
  UNION ALL SELECT 'pranzo', '000530', 50.00, 'pane bianco'
  UNION ALL SELECT 'pranzo', '009210', 10.00, 'circa 2 cucchiaini da caffe'''
  UNION ALL SELECT 'pranzo', '007130', 150.00, 'mela fresca, annurca'
  -- Cena: passato di verdure con farro, merluzzo, insalata, pane, olio, pera
  UNION ALL SELECT 'cena', '000025', 50.00, 'farro perlato, cotto'
  UNION ALL SELECT 'cena', '121410', 150.00, 'merluzzo o nasello, al vapore'
  UNION ALL SELECT 'cena', '005410', 100.00, 'lattuga fresca'
  UNION ALL SELECT 'cena', '000530', 50.00, 'pane bianco'
  UNION ALL SELECT 'cena', '009210', 10.00, 'circa 2 cucchiaini da caffe'''
  UNION ALL SELECT 'cena', '007261', 150.00, 'pera fresca, Abate Fetel'
) AS v
WHERE p.titolo = 'Piano di avvio - Ottobre 2026' AND pg.giorno_settimana = 'Lunedi';

-- Kcal totali di Lunedi', calcolate dagli alimenti appena collegati (esattamente
-- il calcolo che fa il bottone "Ricalcola kcal" dell'interfaccia): colazione,
-- spuntino e merenda non hanno alimenti collegati in questo esempio, quindi non
-- contribuiscono al totale (che resta comunque una stima parziale, non completa).
UPDATE piano_giorni pg
JOIN piani_alimentari p ON p.id = pg.piano_id
SET pg.kcal_stimate = (
  SELECT SUM(a.energia_kcal / 100 * ppa.quantita_g)
  FROM piano_pasto_alimenti ppa
  JOIN alimenti a ON a.codice_alimento = ppa.codice_alimento
  WHERE ppa.piano_giorno_id = pg.id
)
WHERE p.titolo = 'Piano di avvio - Ottobre 2026' AND pg.giorno_settimana = 'Lunedi';

-- Un appuntamento gia' svolto (la prima visita, prima dell'inizio del piano) e uno
-- da svolgere (il controllo dopo 4 settimane, gia' citato nelle note del piano),
-- per mostrare subito in agenda sia lo storico che il prossimo appuntamento.
INSERT INTO appuntamenti (paziente_id, data_ora, durata_minuti, tipo, luogo, stato, note)
VALUES
  ((SELECT id FROM pazienti WHERE nome = 'Mario' AND cognome = 'Rossi'),
   '2026-09-28 17:30:00', 45, 'Prima visita', 'Studio', 'Completato',
   'Anamnesi, misure antropometriche, impostazione del piano di ottobre.'),
  ((SELECT id FROM pazienti WHERE nome = 'Mario' AND cognome = 'Rossi'),
   '2026-10-29 18:00:00', 30, 'Controllo', 'Studio', 'Programmato',
   'Controllo peso e aderenza al piano dopo 4 settimane.');
