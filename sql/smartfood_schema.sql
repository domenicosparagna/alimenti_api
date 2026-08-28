-- =====================================================================================
-- SCHEMA MySQL — Smartfood: Porzioni e frequenze di consumo (piramide alimentare)
-- Fonte: Rielaborazione Team Smartfood, su dati SINU (LARN, V Revisione 2024),
--        CREA (Linee guida per una sana alimentazione, 2018), WCRF/AICR (2018),
--        Sofi et al. (Nutr Metab Cardiovasc Dis, 2025), ESC Guidelines (2022),
--        Bach-Faig et al. (Public Health Nutr, 2011).
--
-- Da eseguire nello stesso database della tabella "alimenti" (nessun comando
-- CREATE/USE DATABASE: si presume il database corrente sia gia' selezionato).
-- Da eseguire PRIMA di smartfood_data.sql.
-- =====================================================================================

CREATE TABLE `smartfood_porzioni_frequenze` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `ordine` SMALLINT UNSIGNED NOT NULL COMMENT 'Ordine di visualizzazione secondo la tabella originale',
  `frequenza_consumo` ENUM('giornaliera','settimanale','occasionale','evitare') NOT NULL
      COMMENT 'Blocco della piramide alimentare (macro-frequenza di consumo)',
  `gruppo_alimenti` VARCHAR(60) COLLATE utf8mb4_unicode_ci NOT NULL
      COMMENT 'Gruppo di alimenti (es. VERDURE E ORTAGGI)',
  `alimento` VARCHAR(180) COLLATE utf8mb4_unicode_ci NOT NULL
      COMMENT 'Alimento o sotto-categoria di alimento',
  `porzione_standard` VARCHAR(80) COLLATE utf8mb4_unicode_ci NOT NULL
      COMMENT 'Porzione standard indicata, testo originale (es. "200 g")',
  `porzione_quantita` DECIMAL(6,1) DEFAULT NULL
      COMMENT 'Valore numerico della porzione, quando esprimibile come singolo numero',
  `porzione_unita` VARCHAR(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL
      COMMENT 'Unita di misura della porzione (g, ml, ml/g...)',
  `corrispondenza` VARCHAR(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL
      COMMENT 'A cosa corrisponde la porzione, in esempi pratici',
  `quante_volte` VARCHAR(255) COLLATE utf8mb4_unicode_ci NOT NULL
      COMMENT 'Frequenza di consumo consigliata (quante porzioni e quando)',
  `consiglio_smart` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL
      COMMENT 'Consiglio pratico Smartfood associato alla riga/gruppo',
  PRIMARY KEY (`id`),
  KEY `idx_frequenza_consumo` (`frequenza_consumo`),
  KEY `idx_gruppo_alimenti` (`gruppo_alimenti`),
  KEY `idx_ordine` (`ordine`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Smartfood - Tabella porzioni e frequenze di consumo (piramide alimentare mediterranea)';
