-- =====================================================================================
-- MIGRAZIONE — Aggiunge il calcolo delle kcal al piano alimentare
-- Da eseguire su un database che ha GIA' le tabelle pazienti/piani_alimentari/
-- piano_giorni create con una versione precedente di sql/pazienti_schema.sql
-- (quella senza 'kcal_stimate' e senza 'piano_pasto_alimenti').
--
-- A differenza di pazienti_schema.sql (che fa DROP TABLE e ricrea tutto da zero),
-- questo script e' pensato per aggiornare un database che contiene GIA' pazienti
-- e piani reali, senza perdere nessun dato: aggiunge solo la colonna e la tabella
-- mancanti. E' scritto per essere eseguibile piu' volte senza errori.
--
-- NOTA: "ALTER TABLE ... ADD COLUMN IF NOT EXISTS" e' supportato da MariaDB ma
-- NON da MySQL standard (quello usato da PythonAnywhere): per questo il controllo
-- sulla colonna e' fatto qui con un piccolo SQL dinamico (compatibile con entrambi),
-- invece che con quella sintassi.
--
-- Se stai facendo un'installazione nuova, non ti serve questo file: usa
-- direttamente sql/pazienti_schema.sql, che include gia' queste due modifiche.
-- =====================================================================================

SET @colonna_esiste = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'piano_giorni' AND COLUMN_NAME = 'kcal_stimate'
);

SET @comando_alter = IF(
  @colonna_esiste = 0,
  'ALTER TABLE piano_giorni ADD COLUMN `kcal_stimate` decimal(6,1) unsigned DEFAULT NULL COMMENT ''Kcal totali del giorno, calcolate dagli alimenti collegati'' AFTER `cena_frutta`',
  'SELECT 1'
);

PREPARE stmt_alter FROM @comando_alter;
EXECUTE stmt_alter;
DEALLOCATE PREPARE stmt_alter;

CREATE TABLE IF NOT EXISTS `piano_pasto_alimenti` (
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
