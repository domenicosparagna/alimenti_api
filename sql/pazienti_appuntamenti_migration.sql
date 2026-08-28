-- =====================================================================================
-- MIGRAZIONE — Aggiunge la gestione degli appuntamenti dei pazienti
-- Da eseguire su un database che ha GIA' le tabelle pazienti/piani_alimentari/
-- piano_giorni create con una versione precedente di sql/pazienti_schema.sql
-- (quella senza la tabella 'appuntamenti').
--
-- A differenza di pazienti_schema.sql (che fa DROP TABLE e ricrea tutto da zero),
-- questo script e' pensato per aggiornare un database che contiene GIA' pazienti
-- e piani reali, senza perdere nessun dato: aggiunge solo la tabella mancante.
-- E' scritto per essere eseguibile piu' volte senza errori (CREATE TABLE IF NOT EXISTS).
--
-- Se stai facendo un'installazione nuova, non ti serve questo file: usa
-- direttamente sql/pazienti_schema.sql, che include gia' questa tabella.
-- =====================================================================================

CREATE TABLE IF NOT EXISTS `appuntamenti` (
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
