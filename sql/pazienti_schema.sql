-- =====================================================================================
-- SCHEMA MySQL — Pazienti e Piano Alimentare Giornaliero
-- Contiene:
--   1) Tabella 'pazienti'             -> anagrafica dei pazienti seguiti
--   2) Tabella 'piani_alimentari'      -> intestazione di un piano alimentare settimanale
--                                        assegnato a un paziente (es. "Piano di ottobre 2026")
--   3) Tabella 'piano_giorni'          -> il dettaglio dei pasti per ciascun giorno della
--                                        settimana di un piano, sul modello del modulo
--                                        cartaceo "Giorno_PianoAlimentare" (colazione,
--                                        spuntino, pranzo, merenda, cena)
--   4) Tabella 'piano_pasto_alimenti'  -> alimenti (con quantita') collegati a un pasto di
--                                        un giorno, per calcolare automaticamente le kcal
--                                        (stesso principio di ricette_ingredienti/alimenti)
--   5) Tabella 'appuntamenti'          -> appuntamenti (visite, controlli, ...) fissati con
--                                        un paziente, indipendenti dai piani alimentari
--
-- Da eseguire nello stesso database delle altre tabelle dell'applicativo (nessun
-- comando CREATE/USE DATABASE: si presume il database corrente sia gia' selezionato,
-- e che 'alimenti' esista gia' — vedi sql/schema.sql).
--
-- NOTA: se hai gia' importato una versione precedente di questo schema (senza la
-- colonna 'kcal_stimate' e senza 'piano_pasto_alimenti', oppure senza la tabella
-- 'appuntamenti') e non vuoi perdere i dati dei pazienti gia' inseriti, NON
-- ri-eseguire questo file (fa DROP TABLE): usa invece sql/pazienti_kcal_migration.sql
-- e/o sql/pazienti_appuntamenti_migration.sql, pensati apposta per aggiornare senza
-- perdere dati.
-- =====================================================================================

DROP TABLE IF EXISTS appuntamenti;
DROP TABLE IF EXISTS piano_pasto_alimenti;
DROP TABLE IF EXISTS piano_giorni;
DROP TABLE IF EXISTS piani_alimentari;
DROP TABLE IF EXISTS pazienti;

CREATE TABLE `pazienti` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `nome` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `cognome` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `data_nascita` date DEFAULT NULL,
  `sesso` enum('M','F') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `altezza_cm` smallint unsigned DEFAULT NULL COMMENT 'Statura in centimetri',
  `peso_kg` decimal(5,1) unsigned DEFAULT NULL COMMENT 'Ultimo peso rilevato, in kg',
  `livello_attivita_fisica` enum('1.2','1.4','1.6','1.8','2.0') COLLATE utf8mb4_unicode_ci DEFAULT NULL
     COMMENT 'PAL (Physical Activity Level), usato per il fabbisogno energetico LARN',
  `email` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `telefono` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `note` text COLLATE utf8mb4_unicode_ci COMMENT 'Note cliniche/anamnestiche libere',
  `attivo` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'FALSE per un paziente non piu'' in carico',
  `creato_il` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_cognome_nome` (`cognome`, `nome`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Anagrafica dei pazienti seguiti';

CREATE TABLE `piani_alimentari` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `paziente_id` int unsigned NOT NULL,
  `titolo` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Es. "Piano di ottobre 2026"',
  `data_inizio` date DEFAULT NULL,
  `data_fine` date DEFAULT NULL,
  `note` text COLLATE utf8mb4_unicode_ci,
  `attivo` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Piano attualmente in uso per il paziente',
  `creato_il` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_paziente_id` (`paziente_id`),
  CONSTRAINT `fk_piano_paziente` FOREIGN KEY (`paziente_id`) REFERENCES `pazienti` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Intestazione di un piano alimentare settimanale assegnato a un paziente';

CREATE TABLE `piano_giorni` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `piano_id` int unsigned NOT NULL,
  `giorno_settimana` enum('Lunedi','Martedi','Mercoledi','Giovedi','Venerdi','Sabato','Domenica')
     COLLATE utf8mb4_unicode_ci NOT NULL,

  -- Colazione
  `colazione_latte` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `colazione_fette_biscottate` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `colazione_altro` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,

  -- Spuntino ore 10:30
  `spuntino_10_30` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,

  -- Pranzo
  `pranzo_primo_piatto` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pranzo_secondo_piatto` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pranzo_verdure_ortaggi` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pranzo_pane` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pranzo_olio_cucchiaini` decimal(3,1) unsigned DEFAULT NULL COMMENT 'Olio extravergine, in cucchiaini da caffe'' ',
  `pranzo_olio_note` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pranzo_frutta` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,

  -- Merenda ore 17:30
  `merenda_17_30` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,

  -- Cena (stessa struttura del pranzo)
  `cena_primo_piatto` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cena_secondo_piatto` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cena_verdure_ortaggi` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cena_pane` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cena_olio_cucchiaini` decimal(3,1) unsigned DEFAULT NULL COMMENT 'Olio extravergine, in cucchiaini da caffe'' ',
  `cena_olio_note` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cena_frutta` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,

  -- Totale kcal del giorno, calcolato dagli alimenti collegati in piano_pasto_alimenti
  -- (bottone "Ricalcola kcal" nell'interfaccia). NULL se non ancora calcolato.
  `kcal_stimate` decimal(6,1) unsigned DEFAULT NULL COMMENT 'Kcal totali del giorno, calcolate dagli alimenti collegati',

  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_piano_giorno` (`piano_id`, `giorno_settimana`),
  CONSTRAINT `fk_giorno_piano` FOREIGN KEY (`piano_id`) REFERENCES `piani_alimentari` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Pasti di un singolo giorno della settimana di un piano alimentare, sul modello del modulo cartaceo';

CREATE TABLE `piano_pasto_alimenti` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `piano_giorno_id` int unsigned NOT NULL COMMENT 'Riferimento a piano_giorni.id',
  `pasto` enum('colazione','spuntino_10_30','pranzo','merenda_17_30','cena')
     COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'A quale pasto del giorno appartiene',
  `codice_alimento` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Riferimento a alimenti.codice_alimento',
  `quantita_g` decimal(10,2) NOT NULL COMMENT 'Quantita'' dell''alimento in grammi',
  `note` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_piano_giorno_id` (`piano_giorno_id`),
  KEY `idx_codice_alimento` (`codice_alimento`),
  CONSTRAINT `fk_ppa_giorno` FOREIGN KEY (`piano_giorno_id`) REFERENCES `piano_giorni` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ppa_alimento` FOREIGN KEY (`codice_alimento`) REFERENCES `alimenti` (`codice_alimento`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Alimenti (con quantita'') collegati a un pasto di un giorno, per il calcolo automatico delle kcal';

CREATE TABLE `appuntamenti` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `paziente_id` int unsigned NOT NULL,
  `data_ora` datetime NOT NULL COMMENT 'Data e ora di inizio dell''appuntamento',
  `durata_minuti` smallint unsigned NOT NULL DEFAULT '30',
  `tipo` enum('Prima visita','Controllo','Visita di follow-up','Videochiamata','Telefonica','Altro')
     COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Controllo',
  `luogo` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Es. "Studio", "Online", un indirizzo',
  `stato` enum('Programmato','Completato','Annullato','Non presentato')
     COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Programmato',
  `note` text COLLATE utf8mb4_unicode_ci,
  `creato_il` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_paziente_id` (`paziente_id`),
  KEY `idx_data_ora` (`data_ora`),
  CONSTRAINT `fk_appuntamento_paziente` FOREIGN KEY (`paziente_id`) REFERENCES `pazienti` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Appuntamenti (visite, controlli, ...) fissati con un paziente';
