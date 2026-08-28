-- =====================================================================================
-- SCHEMA MySQL — Ricette
-- Contiene:
--   1) Tabella 'ricette'              -> ricette selezionate per uso in ambito di studio nutrizionale
--   2) Tabella 'ricette_ingredienti'   -> composizione di ciascuna ricetta, con riferimento alla
--                                        tabella 'alimenti' (codice_alimento) gia' presente nel DB
--
-- Da eseguire nello stesso database della tabella "alimenti" (nessun comando
-- CREATE/USE DATABASE: si presume il database corrente sia gia' selezionato,
-- e che 'alimenti' esista gia' — vedi sql/schema.sql).
-- =====================================================================================

DROP TABLE IF EXISTS ricette_ingredienti;
DROP TABLE IF EXISTS ricette;

CREATE TABLE `ricette` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `nome_ricetta` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Nome della ricetta',
  `categoria_ricetta` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Colazione, Primo Piatto, Secondo Piatto, Piatto Unico, Contorno, Spuntino',
  `porzioni` tinyint unsigned NOT NULL DEFAULT '1' COMMENT 'Numero di porzioni a cui si riferiscono le quantita'' indicate',
  `tempo_preparazione_min` smallint unsigned DEFAULT NULL COMMENT 'Tempo di preparazione stimato in minuti',
  `difficolta` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Facile, Media, Difficile',
  `descrizione` text COLLATE utf8mb4_unicode_ci COMMENT 'Breve descrizione della ricetta',
  `note_nutrizionali` text COLLATE utf8mb4_unicode_ci COMMENT 'Indicazioni utili al nutrizionista per l''impiego della ricetta nel piano alimentare',
  `tag_dietetici` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Tag separati da ; utili per la selezione delle ricette in base al profilo del paziente',
  `energia_kcal_porzione` decimal(10,1) DEFAULT NULL COMMENT 'Energia per porzione (kcal), calcolata dagli ingredienti',
  `proteine_g_porzione` decimal(10,1) DEFAULT NULL COMMENT 'Proteine per porzione (g)',
  `lipidi_g_porzione` decimal(10,1) DEFAULT NULL COMMENT 'Lipidi per porzione (g)',
  `carboidrati_g_porzione` decimal(10,1) DEFAULT NULL COMMENT 'Carboidrati disponibili per porzione (g)',
  `fibra_g_porzione` decimal(10,1) DEFAULT NULL COMMENT 'Fibra totale per porzione (g)',
  `sodio_mg_porzione` decimal(10,1) DEFAULT NULL COMMENT 'Sodio per porzione (mg) - stima parziale, vedi nota nel README',
  `indice_glicemico_medio` decimal(5,1) DEFAULT NULL COMMENT 'Indice glicemico medio della ricetta, pesato sui carboidrati apportati da ciascun ingrediente con IG noto',
  `vegano` tinyint(1) DEFAULT NULL COMMENT 'TRUE se tutti gli ingredienti sono idonei a una dieta vegana',
  `vegetariano` tinyint(1) DEFAULT NULL COMMENT 'TRUE se tutti gli ingredienti sono idonei a una dieta vegetariana',
  `senza_glutine` tinyint(1) DEFAULT NULL COMMENT 'TRUE se nessun ingrediente contiene glutine',
  `allergeni` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Elenco allergeni maggiori presenti tra gli ingredienti, separati da ; ',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_nome_ricetta` (`nome_ricetta`),
  KEY `idx_categoria_ricetta` (`categoria_ricetta`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Ricette selezionate come idonee per uno studio/ambulatorio di nutrizione';

CREATE TABLE `ricette_ingredienti` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `ricetta_id` int unsigned NOT NULL COMMENT 'Riferimento a ricette.id',
  `codice_alimento` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Riferimento a alimenti.codice_alimento',
  `quantita_g` decimal(10,2) NOT NULL COMMENT 'Quantita'' dell''ingrediente in grammi per il totale delle porzioni indicate in ricette.porzioni',
  `ordine` tinyint unsigned DEFAULT NULL COMMENT 'Ordine di utilizzo/elencazione dell''ingrediente nella ricetta',
  `note` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Note sull''ingrediente (es. tipo di cottura, forma di utilizzo)',
  PRIMARY KEY (`id`),
  KEY `idx_ricetta_id` (`ricetta_id`),
  KEY `idx_codice_alimento` (`codice_alimento`),
  CONSTRAINT `fk_ri_ricetta` FOREIGN KEY (`ricetta_id`) REFERENCES `ricette` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ri_alimento` FOREIGN KEY (`codice_alimento`) REFERENCES `alimenti` (`codice_alimento`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Composizione (ingredienti e quantita'') di ciascuna ricetta';
