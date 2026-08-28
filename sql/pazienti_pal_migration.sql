-- =====================================================================================
-- MIGRAZIONE — Aggiunge il livello di attivita' fisica (PAL) al paziente
-- Da eseguire su un database che ha GIA' la tabella `pazienti` creata con una
-- versione precedente di sql/pazienti_schema.sql (senza la colonna
-- `livello_attivita_fisica`), necessaria per collegare le tabelle LARN di
-- energia al profilo del paziente (vedi larn_lookup.py e sezione dedicata
-- del README).
--
-- Non fa DROP TABLE: aggiunge solo la colonna mancante, senza toccare i dati
-- esistenti. Scritta per essere eseguibile piu' volte senza errori (compatibile
-- sia con MySQL che con MariaDB: "ADD COLUMN IF NOT EXISTS" non e' supportato
-- da MySQL standard, quindi il controllo e' fatto con un piccolo SQL dinamico,
-- come per sql/pazienti_kcal_migration.sql).
--
-- Se stai facendo un'installazione nuova, non ti serve questo file: usa
-- direttamente sql/pazienti_schema.sql, che include gia' questa colonna.
-- =====================================================================================

SET @colonna_esiste = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'pazienti' AND COLUMN_NAME = 'livello_attivita_fisica'
);

SET @comando_alter = IF(
  @colonna_esiste = 0,
  'ALTER TABLE pazienti ADD COLUMN `livello_attivita_fisica` enum(''1.2'',''1.4'',''1.6'',''1.8'',''2.0'') DEFAULT NULL COMMENT ''PAL (Physical Activity Level), usato per il fabbisogno energetico LARN'' AFTER `peso_kg`',
  'SELECT 1'
);

PREPARE stmt_alter FROM @comando_alter;
EXECUTE stmt_alter;
DEALLOCATE PREPARE stmt_alter;
