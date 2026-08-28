-- =====================================================================================
-- SCHEMA COMPLETO — Registro Alimenti CREA + Tabelle LARN + Ricette + Pazienti + Smartfood
--
-- File UNICO che crea da zero il database e tutte le tabelle dell'applicativo, piu'
-- alcune viste di comodo per le interrogazioni piu' frequenti. Consolida in un solo
-- file cio' che nella cartella sql/ e' altrimenti diviso in piu' file modulari
-- (schema.sql, larn_schema.sql, ricette_schema.sql, pazienti_schema.sql,
-- smartfood_schema.sql): usa questo file per un'installazione da zero in un solo
-- comando; i file modulari restano utili per capire/modificare una singola sezione, o
-- per le migrazioni non distruttive su un database gia' esistente
-- (pazienti_kcal_migration.sql, pazienti_pal_migration.sql,
-- pazienti_appuntamenti_migration.sql), che qui NON servono perche' questo file crea
-- gia' tutto nella versione piu' recente.
--
-- CONTIENE, IN QUESTO ORDINE:
--   0) CREATE DATABASE (facoltativo, vedi nota sotto) + DROP di tabelle/viste esistenti
--   1) Tabella 'alimenti'                        (Tabelle di composizione CREA/INRAN)
--   2) 15 tabelle 'larn_*'                       (Livelli di Assunzione di Riferimento, fonte SINU)
--   3) Tabelle 'ricette' + 'ricette_ingredienti'
--   4) Tabelle 'pazienti' + 'piani_alimentari' + 'piano_giorni' + 'piano_pasto_alimenti' + 'appuntamenti'
--   5) Tabella 'smartfood_porzioni_frequenze'    (Piramide alimentare Smartfood: porzioni e frequenze)
--   6) Viste:  vista_ricette_valori_calcolati, vista_ricette_ingredienti_dettaglio,
--              vista_piano_giorni_calcolati, vista_agenda_appuntamenti,
--              vista_pazienti_prossimo_appuntamento
--
-- ATTENZIONE — QUESTO SCRIPT CANCELLA E RICREA LE TABELLE (DROP TABLE):
-- usalo solo per un'installazione nuova o per azzerare un ambiente di sviluppo/test.
-- Su un database con dati reali gia' presenti, NON eseguire questo file: usa invece i
-- singoli file di migrazione in sql/ (pensati apposta per non perdere dati).
--
-- NOTA SU "CREATE DATABASE" E PYTHONANYWHERE: le due righe qui sotto creano e
-- selezionano un database chiamato 'diario_alimentare'. Su PythonAnywhere il database
-- e' gia' creato dall'interfaccia con un nome fisso nella forma
-- '<tuo_username>$diario_alimentare' (con il simbolo $): in quel caso NON eseguire le
-- due righe CREATE DATABASE/USE qui sotto, e importa il resto del file direttamente
-- nel database che PythonAnywhere ti ha gia' assegnato (vedi il README, sezione 2).
-- =====================================================================================

CREATE DATABASE IF NOT EXISTS `diario_alimentare` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `diario_alimentare`;

-- ---------------------------------------------------------------------
-- 0. Pulizia di un'eventuale installazione precedente (ordine che
--    rispetta le foreign key: prima le viste, poi le tabelle figlie,
--    a salire fino alle tabelle senza dipendenze).
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS vista_pazienti_prossimo_appuntamento;
DROP VIEW IF EXISTS vista_agenda_appuntamenti;
DROP VIEW IF EXISTS vista_piano_giorni_calcolati;
DROP VIEW IF EXISTS vista_ricette_ingredienti_dettaglio;
DROP VIEW IF EXISTS vista_ricette_valori_calcolati;

DROP TABLE IF EXISTS smartfood_porzioni_frequenze;
DROP TABLE IF EXISTS appuntamenti;
DROP TABLE IF EXISTS piano_pasto_alimenti;
DROP TABLE IF EXISTS piano_giorni;
DROP TABLE IF EXISTS piani_alimentari;
DROP TABLE IF EXISTS pazienti;
DROP TABLE IF EXISTS ricette_ingredienti;
DROP TABLE IF EXISTS ricette;
DROP TABLE IF EXISTS larn_minerali_sdt;
DROP TABLE IF EXISTS larn_minerali_ul;
DROP TABLE IF EXISTS larn_minerali_ar;
DROP TABLE IF EXISTS larn_minerali_pri_ai;
DROP TABLE IF EXISTS larn_vitamine_ul;
DROP TABLE IF EXISTS larn_vitamine_ar;
DROP TABLE IF EXISTS larn_vitamine_pri_ai;
DROP TABLE IF EXISTS larn_proteine;
DROP TABLE IF EXISTS larn_lipidi;
DROP TABLE IF EXISTS larn_carboidrati_fibra;
DROP TABLE IF EXISTS larn_energia_adulti;
DROP TABLE IF EXISTS larn_energia_1_17_anni;
DROP TABLE IF EXISTS larn_energia_lattanti;
DROP TABLE IF EXISTS larn_acqua;
DROP TABLE IF EXISTS larn_metadati;
DROP TABLE IF EXISTS alimenti;


-- =====================================================================================
-- 1. ALIMENTI — Tabelle di composizione degli alimenti CREA/INRAN (per 100 g di parte edibile)
-- =====================================================================================

CREATE TABLE `alimenti` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `nome_alimento` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Nome Alimento',
  `categoria` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Categoria',
  `codice_alimento` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Codice Alimento',
  `parte_edibile` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Parte Edibile',
  `porzione` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Porzione',
  `acqua_g` decimal(10,3) DEFAULT NULL COMMENT 'Acqua (g)',
  `energia_kcal` decimal(10,3) DEFAULT NULL COMMENT 'Energia (kcal)',
  `energia_kj` decimal(10,3) DEFAULT NULL COMMENT 'Energia (kJ)',
  `proteine_g` decimal(10,3) DEFAULT NULL COMMENT 'Proteine (g)',
  `lipidi_g` decimal(10,3) DEFAULT NULL COMMENT 'Lipidi (g)',
  `carboidrati_disponibili_g` decimal(10,3) DEFAULT NULL COMMENT 'Carboidrati disponibili (g)',
  `amido_g` decimal(10,3) DEFAULT NULL COMMENT 'Amido (g)',
  `zuccheri_solubili_g` decimal(10,3) DEFAULT NULL COMMENT 'Zuccheri solubili (g)',
  `alcool_g` decimal(10,3) DEFAULT NULL COMMENT 'Alcool (g)',
  `fibra_totale_g` decimal(10,3) DEFAULT NULL COMMENT 'Fibra totale (g)',
  `sodio_mg` decimal(10,3) DEFAULT NULL COMMENT 'Sodio (mg)',
  `potassio_mg` decimal(10,3) DEFAULT NULL COMMENT 'Potassio (mg)',
  `calcio_mg` decimal(10,3) DEFAULT NULL COMMENT 'Calcio (mg)',
  `fosforo_mg` decimal(10,3) DEFAULT NULL COMMENT 'Fosforo (mg)',
  `ferro_mg` decimal(10,3) DEFAULT NULL COMMENT 'Ferro (mg)',
  `vitamina_c_mg` decimal(10,3) DEFAULT NULL COMMENT 'Vitamina C (mg)',
  `vitamina_a_retinolo_eq_mcg` decimal(10,3) DEFAULT NULL COMMENT 'Vitamina A retinolo equivalente (µg)',
  `acido_fitico_g` decimal(10,3) DEFAULT NULL COMMENT 'Acido fitico (g)',
  `colesterolo_mg` decimal(10,3) DEFAULT NULL COMMENT 'Colesterolo (mg)',
  `magnesio_mg` decimal(10,3) DEFAULT NULL COMMENT 'Magnesio (mg)',
  `rame_mg` decimal(10,3) DEFAULT NULL COMMENT 'Rame (mg)',
  `zinco_mg` decimal(10,3) DEFAULT NULL COMMENT 'Zinco (mg)',
  `acidi_grassi_saturi_pct` decimal(10,3) DEFAULT NULL COMMENT 'Acidi grassi Saturi (%)',
  `acidi_grassi_monoinsaturi_pct` decimal(10,3) DEFAULT NULL COMMENT 'Acidi grassi Monoinsaturi (%)',
  `acidi_grassi_polinsaturi_pct` decimal(10,3) DEFAULT NULL COMMENT 'Acidi grassi Polinsaturi (%)',
  `rapporto_polinsaturi_saturi` decimal(10,3) DEFAULT NULL COMMENT 'Polinsatuti/Saturi',
  `indice_chimico` decimal(10,3) DEFAULT NULL COMMENT 'Indice Chimico',
  `aminoacido_limitante` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Aminoacido limitante',
  `saccarosio_g` decimal(10,3) DEFAULT NULL COMMENT 'Saccarosio (g)',
  `glucosio_g` decimal(10,3) DEFAULT NULL COMMENT 'Glucosio (g)',
  `fruttosio_g` decimal(10,3) DEFAULT NULL COMMENT 'Fruttosio (g)',
  `manganese_mg` decimal(10,3) DEFAULT NULL COMMENT 'Manganese (mg)',
  `vitamina_b6_mg` decimal(10,3) DEFAULT NULL COMMENT 'Vitamina B6 (mg)',
  `vitamina_b12_mcg` decimal(10,3) DEFAULT NULL COMMENT 'Vitamina B12 (µg)',
  `retinolo_mcg` decimal(10,3) DEFAULT NULL COMMENT 'Retinolo (µg)',
  `carotene_beta_mcg` decimal(10,3) DEFAULT NULL COMMENT 'Carotene beta (µg)',
  `vitamina_d_mcg` decimal(10,3) DEFAULT NULL COMMENT 'Vitamina D (µg)',
  `polifenoli_mg` decimal(10,3) DEFAULT NULL COMMENT 'Polifenoli (mg)',
  `fruttoligosaccaridi_g` decimal(10,3) DEFAULT NULL COMMENT 'Fruttoligosaccaridi (g)',
  `informazioni` text COLLATE utf8mb4_unicode_ci COMMENT 'Informazioni',
  `allergeni` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Elenco allergeni maggiori (Reg. UE 1169/2011) separati da ; ',
  `gruppo_alimentare_crea` varchar(60) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Gruppo alimentare secondo la piramide alimentare CREA (ex INRAN)',
  `vegano` tinyint(1) DEFAULT NULL COMMENT 'TRUE se l''alimento e'' idoneo a una dieta vegana',
  `vegetariano` tinyint(1) DEFAULT NULL COMMENT 'TRUE se l''alimento e'' idoneo a una dieta vegetariana',
  `senza_glutine` tinyint(1) DEFAULT NULL COMMENT 'TRUE se l''alimento non contiene glutine',
  `indice_glicemico` decimal(5,1) DEFAULT NULL COMMENT 'Indice glicemico (scala glucosio=100), da tabelle pubblicate',
  `carico_glicemico` decimal(5,1) DEFAULT NULL COMMENT 'Carico glicemico riferito alla porzione standard indicata in "porzione"',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_codice_alimento` (`codice_alimento`),
  KEY `idx_categoria` (`categoria`),
  KEY `idx_nome_alimento` (`nome_alimento`)
) ENGINE=InnoDB AUTO_INCREMENT=850 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Tabelle di composizione degli alimenti - CREA (per 100 g di parte edibile)';


-- =====================================================================================
-- 2. TABELLE LARN (Livelli di Assunzione di Riferimento di Nutrienti ed energia)
-- Fonte: SINU — Tabelle riassuntive (Acqua, Energia, Carboidrati/Zuccheri/Fibra,
--        Lipidi, Proteine, Vitamine, Minerali)
--
-- NOTE GENERALI SUI DATI:
--  - AR  = Average Requirement (fabbisogno medio)
--  - PRI = Population Reference Intake (assunzione raccomandata per la popolazione)
--  - AI  = Adequate Intake (assunzione adeguata, usata quando l'AR non e' definibile)
--  - UL  = Tolerable Upper Intake Level (livello massimo tollerabile di assunzione)
--  - SDT = Suggested Dietary Target (obiettivo nutrizionale di prevenzione)
--  - Per le fasce d'eta' si fa riferimento all'eta' anagrafica (es. "4-6 anni" = dal
--    compimento del 4° al compimento del 7° anno di vita).
--  - I valori riportati sono quelli sintetici delle tabelle SINU; per i dettagli
--    metodologici si rimanda al testo completo dei LARN.
-- =====================================================================================

-- 2.0 Metadati della fonte
CREATE TABLE larn_metadati (
    id INT AUTO_INCREMENT PRIMARY KEY,
    chiave VARCHAR(50) NOT NULL,
    valore VARCHAR(255) NOT NULL
) ENGINE=InnoDB COMMENT='Informazioni sulla fonte dei dati';

-- 2.1 Acqua (mL/die)
CREATE TABLE larn_acqua (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fascia VARCHAR(30) NOT NULL,
    eta_label VARCHAR(20) NOT NULL,
    eta_min DECIMAL(5,2) NULL,
    eta_max DECIMAL(5,2) NULL,
    unita_eta ENUM('mesi','anni') DEFAULT 'anni',
    sesso ENUM('M','F','ND') DEFAULT 'ND',
    valore_ml_die INT NOT NULL COMMENT 'AI in mL/die, oppure incremento per gravidanza/allattamento',
    tipo_valore ENUM('assoluto','incremento') DEFAULT 'assoluto',
    note VARCHAR(150) NULL
) ENGINE=InnoDB COMMENT='LARN Acqua - Assunzione Adeguata (AI) in mL/die';

-- 2.2 Energia — Lattanti, secondo semestre di vita (fabbisogno medio AR)
CREATE TABLE larn_energia_lattanti (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sesso ENUM('M','F') NOT NULL,
    eta_mesi TINYINT NOT NULL,
    peso_kg DECIMAL(4,1) NOT NULL,
    velocita_crescita_g_die DECIMAL(4,1) NOT NULL,
    tee_kcal_die INT NOT NULL COMMENT 'Dispendio energetico totale',
    energia_depositata_kcal_die INT NOT NULL,
    fabbisogno_kcal_die INT NOT NULL,
    fabbisogno_kcal_kg_die INT NOT NULL
) ENGINE=InnoDB COMMENT='LARN Energia - Fabbisogno medio (AR) 7-12 mesi';

-- 2.3 Energia — 1-17 anni (fabbisogno medio AR per PAL)
CREATE TABLE larn_energia_1_17_anni (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sesso ENUM('M','F') NOT NULL,
    eta_anni DECIMAL(3,1) NOT NULL,
    peso_kg DECIMAL(5,1) NOT NULL,
    bmr_kcal_die INT NOT NULL,
    fabbisogno_pal_1_2 INT NULL,
    fabbisogno_pal_1_4 INT NULL,
    fabbisogno_pal_1_6 INT NULL,
    fabbisogno_pal_1_8 INT NULL,
    fabbisogno_pal_2_0 INT NULL
) ENGINE=InnoDB COMMENT='LARN Energia - Fabbisogno medio (AR) 1-17 anni, kcal/die per PAL';

-- 2.4 Energia — Adulti ed eta' geriatrica (fabbisogno medio AR per PAL)
CREATE TABLE larn_energia_adulti (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sesso ENUM('M','F') NOT NULL,
    fascia_eta VARCHAR(10) NOT NULL COMMENT "'18-29','30-59','60-80'",
    eta_min TINYINT NOT NULL,
    eta_max TINYINT NOT NULL,
    statura_m DECIMAL(3,2) NOT NULL,
    peso_kg DECIMAL(5,1) NOT NULL COMMENT 'Calcolato per IMC=22.5 kg/m2 - valore esemplificativo',
    bmr_kcal_die INT NOT NULL,
    fabbisogno_pal_1_2 INT NULL,
    fabbisogno_pal_1_4 INT NULL,
    fabbisogno_pal_1_6 INT NULL,
    fabbisogno_pal_1_8 INT NULL,
    fabbisogno_pal_2_0 INT NULL
) ENGINE=InnoDB COMMENT='LARN Energia - Fabbisogno medio (AR) adulti/anziani, kcal/die per PAL';

-- 2.5 Carboidrati totali, zuccheri, fibra alimentare (valori giornalieri)
CREATE TABLE larn_carboidrati_fibra (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nutriente VARCHAR(50) NOT NULL,
    gruppo_eta VARCHAR(30) NOT NULL,
    eta_min DECIMAL(5,2) NULL,
    eta_max DECIMAL(5,2) NULL,
    parametro ENUM('RI','AI','SDT','Osservazionale') NOT NULL,
    valore_min DECIMAL(6,2) NULL,
    valore_max DECIMAL(6,2) NULL,
    unita VARCHAR(20) NOT NULL,
    note TEXT NULL
) ENGINE=InnoDB COMMENT='LARN Carboidrati totali, Zuccheri, Fibra alimentare';

-- 2.6 Lipidi
CREATE TABLE larn_lipidi (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fascia VARCHAR(30) NOT NULL,
    eta_label VARCHAR(20) NOT NULL,
    eta_min DECIMAL(5,2) NULL,
    eta_max DECIMAL(5,2) NULL,
    unita_eta ENUM('mesi','anni') DEFAULT 'anni',
    tipo_lipide VARCHAR(30) NOT NULL COMMENT 'Lipidi totali, SFA, PUFA, PUFA n-6, PUFA n-3, Acidi grassi trans',
    sdt VARCHAR(60) NULL,
    ai VARCHAR(100) NULL,
    ri VARCHAR(30) NULL,
    note VARCHAR(200) NULL
) ENGINE=InnoDB COMMENT='LARN Lipidi';

-- 2.7 Proteine
CREATE TABLE larn_proteine (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fascia VARCHAR(30) NOT NULL,
    eta_label VARCHAR(20) NOT NULL,
    eta_min DECIMAL(5,2) NULL,
    eta_max DECIMAL(5,2) NULL,
    unita_eta ENUM('mesi','anni') DEFAULT 'anni',
    sesso ENUM('M','F') NOT NULL,
    peso_kg DECIMAL(5,1) NULL,
    ar_g_kg_die DECIMAL(4,2) NULL,
    ar_g_die DECIMAL(5,1) NULL,
    pri_g_kg_die DECIMAL(4,2) NULL,
    pri_g_die DECIMAL(5,1) NULL,
    sdt_g_kg_die DECIMAL(4,2) NULL,
    sdt_g_die DECIMAL(5,1) NULL,
    tipo_valore ENUM('assoluto','incremento') DEFAULT 'assoluto',
    note VARCHAR(200) NULL
) ENGINE=InnoDB COMMENT='LARN Proteine';

-- 2.8 Vitamine — PRI o AI
CREATE TABLE larn_vitamine_pri_ai (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fascia VARCHAR(30) NOT NULL,
    eta_label VARCHAR(20) NOT NULL,
    eta_min DECIMAL(5,2) NULL,
    eta_max DECIMAL(5,2) NULL,
    unita_eta ENUM('mesi','anni') DEFAULT 'anni',
    sesso ENUM('M','F','ND') DEFAULT 'ND',
    tiamina_mg_1000kcal DECIMAL(3,1) NULL,
    riboflavina_mg DECIMAL(3,1) NULL,
    niacina_mg DECIMAL(4,1) NULL,
    ac_pantotenico_mg DECIMAL(3,1) NULL,
    vit_b6_mg DECIMAL(3,1) NULL,
    biotina_ug DECIMAL(4,1) NULL,
    folati_ug DECIMAL(5,1) NULL,
    vit_b12_ug DECIMAL(3,1) NULL,
    vit_c_mg DECIMAL(5,1) NULL,
    vit_a_ug DECIMAL(5,1) NULL,
    vit_d_ug DECIMAL(4,1) NULL COMMENT 'Colecalciferolo; per over 75 vedi vit_d_ug_over75',
    vit_d_ug_over75 DECIMAL(4,1) NULL,
    vit_e_mg DECIMAL(4,1) NULL COMMENT 'alfa-tocoferolo equivalenti',
    vit_k_ug DECIMAL(5,1) NULL,
    note VARCHAR(200) NULL
) ENGINE=InnoDB COMMENT='LARN Vitamine - PRI (valori normali) o AI (quando PRI non definibile)';

-- 2.9 Vitamine — Fabbisogno medio (AR)
CREATE TABLE larn_vitamine_ar (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fascia VARCHAR(30) NOT NULL,
    eta_label VARCHAR(20) NOT NULL,
    eta_min DECIMAL(5,2) NULL,
    eta_max DECIMAL(5,2) NULL,
    unita_eta ENUM('mesi','anni') DEFAULT 'anni',
    sesso ENUM('M','F','ND') DEFAULT 'ND',
    tiamina_mg_1000kcal DECIMAL(3,1) NULL,
    riboflavina_mg DECIMAL(3,1) NULL,
    niacina_mg DECIMAL(4,1) NULL,
    vit_b6_mg DECIMAL(3,1) NULL,
    folati_ug DECIMAL(5,1) NULL,
    vit_c_mg DECIMAL(5,1) NULL,
    vit_a_ug DECIMAL(5,1) NULL,
    vit_d_ug DECIMAL(4,1) NULL,
    note VARCHAR(200) NULL
) ENGINE=InnoDB COMMENT='LARN Vitamine - Fabbisogno medio (AR). Per ac. pantotenico, biotina, vit. B12, vit. E e vit. K, AR non definibile.';

-- 2.10 Vitamine — Livello massimo tollerabile di assunzione (UL)
CREATE TABLE larn_vitamine_ul (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fascia VARCHAR(30) NOT NULL,
    eta_label VARCHAR(20) NOT NULL,
    eta_min DECIMAL(5,2) NULL,
    eta_max DECIMAL(5,2) NULL,
    unita_eta ENUM('mesi','anni') DEFAULT 'anni',
    sesso ENUM('M','F','ND') DEFAULT 'ND',
    niacina_na_mg DECIMAL(4,1) NULL COMMENT 'come Nicotinamide',
    niacina_acn_mg DECIMAL(4,1) NULL COMMENT 'come Acido nicotinico',
    vit_b6_mg DECIMAL(4,1) NULL,
    folati_ug DECIMAL(5,1) NULL COMMENT 'Acido folico sintetico',
    vit_a_ug DECIMAL(5,1) NULL,
    vit_d_ug DECIMAL(4,1) NULL,
    vit_e_mg DECIMAL(4,1) NULL,
    note VARCHAR(200) NULL
) ENGINE=InnoDB COMMENT='LARN Vitamine - UL. Per vit. C, tiamina, riboflavina, ac. pantotenico, biotina, vit. B12 e vit. K, UL non definibile.';

-- 2.11 Minerali — PRI o AI
CREATE TABLE larn_minerali_pri_ai (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fascia VARCHAR(30) NOT NULL,
    eta_label VARCHAR(20) NOT NULL,
    eta_min DECIMAL(5,2) NULL,
    eta_max DECIMAL(5,2) NULL,
    unita_eta ENUM('mesi','anni') DEFAULT 'anni',
    sesso ENUM('M','F','ND') DEFAULT 'ND',
    ca_mg DECIMAL(6,1) NULL COMMENT 'Calcio',
    p_mg DECIMAL(6,1) NULL COMMENT 'Fosforo',
    mg_mg DECIMAL(5,1) NULL COMMENT 'Magnesio',
    na_g DECIMAL(3,1) NULL COMMENT 'Sodio (AI)',
    k_mg DECIMAL(6,1) NULL COMMENT 'Potassio (AI, solo lattanti)',
    cl_g DECIMAL(3,2) NULL COMMENT 'Cloro',
    fe_mg DECIMAL(4,1) NULL COMMENT 'Ferro',
    zn_mg DECIMAL(4,1) NULL COMMENT 'Zinco',
    cu_mg DECIMAL(3,1) NULL COMMENT 'Rame',
    se_ug DECIMAL(5,1) NULL COMMENT 'Selenio',
    i_ug DECIMAL(5,1) NULL COMMENT 'Iodio',
    mn_mg DECIMAL(3,1) NULL COMMENT 'Manganese',
    mo_ug DECIMAL(5,1) NULL COMMENT 'Molibdeno',
    cr_ug DECIMAL(5,1) NULL COMMENT 'Cromo',
    f_mg DECIMAL(3,1) NULL COMMENT 'Fluoro',
    note VARCHAR(250) NULL
) ENGINE=InnoDB COMMENT='LARN Minerali - PRI o AI';

-- 2.12 Minerali — Fabbisogno medio (AR)
CREATE TABLE larn_minerali_ar (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fascia VARCHAR(30) NOT NULL,
    eta_label VARCHAR(20) NOT NULL,
    eta_min DECIMAL(5,2) NULL,
    eta_max DECIMAL(5,2) NULL,
    unita_eta ENUM('mesi','anni') DEFAULT 'anni',
    sesso ENUM('M','F','ND') DEFAULT 'ND',
    ca_mg DECIMAL(6,1) NULL,
    fe_mg DECIMAL(4,1) NULL,
    zn_mg DECIMAL(4,1) NULL,
    note VARCHAR(250) NULL
) ENGINE=InnoDB COMMENT='LARN Minerali - Fabbisogno medio (AR). Per Na,K,Mg,P,Cl,I,Cu,Se,Mn,Mo,Cr,F AR non definibile.';

-- 2.13 Minerali — Livello massimo tollerabile di assunzione (UL)
CREATE TABLE larn_minerali_ul (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fascia VARCHAR(30) NOT NULL,
    eta_label VARCHAR(20) NOT NULL,
    eta_min DECIMAL(5,2) NULL,
    eta_max DECIMAL(5,2) NULL,
    unita_eta ENUM('mesi','anni') DEFAULT 'anni',
    sesso ENUM('M','F','ND') DEFAULT 'ND',
    ca_mg DECIMAL(6,1) NULL,
    zn_mg DECIMAL(4,1) NULL,
    cu_mg DECIMAL(3,1) NULL,
    se_ug DECIMAL(5,1) NULL,
    i_ug DECIMAL(5,1) NULL,
    mo_ug DECIMAL(5,1) NULL,
    f_mg DECIMAL(3,1) NULL,
    note VARCHAR(200) NULL
) ENGINE=InnoDB COMMENT='LARN Minerali - UL. Per Mg,P,K,Fe,Mn,Cr UL non definibile. Per Fe: non superare 60 mg/die da supplementi.';

-- 2.14 Minerali — Obiettivo nutrizionale per la prevenzione (SDT)
CREATE TABLE larn_minerali_sdt (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fascia VARCHAR(30) NOT NULL,
    eta_label VARCHAR(20) NOT NULL,
    eta_min DECIMAL(5,2) NULL,
    eta_max DECIMAL(5,2) NULL,
    unita_eta ENUM('mesi','anni') DEFAULT 'anni',
    sesso ENUM('M','F','ND') DEFAULT 'ND',
    na_g DECIMAL(3,1) NULL COMMENT 'Sodio',
    cl_g DECIMAL(3,1) NULL COMMENT 'Cloro',
    k_mg DECIMAL(6,1) NULL COMMENT 'Potassio'
) ENGINE=InnoDB COMMENT='LARN Minerali - SDT (obiettivo di prevenzione) per Na, Cl, K';

-- Indici utili per query frequenti in ambito clinico/nutrizionale
CREATE INDEX idx_acqua_sesso_eta ON larn_acqua (sesso, eta_min, eta_max);
CREATE INDEX idx_proteine_sesso_eta ON larn_proteine (sesso, eta_min, eta_max);
CREATE INDEX idx_vitpriai_sesso_eta ON larn_vitamine_pri_ai (sesso, eta_min, eta_max);
CREATE INDEX idx_minpriai_sesso_eta ON larn_minerali_pri_ai (sesso, eta_min, eta_max);
CREATE INDEX idx_lipidi_fascia ON larn_lipidi (fascia);


-- =====================================================================================
-- 3. RICETTE
-- =====================================================================================

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


-- =====================================================================================
-- 4. PAZIENTI, PIANI ALIMENTARI E APPUNTAMENTI
-- =====================================================================================

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


-- =====================================================================================
-- 5. SMARTFOOD — Piramide alimentare: porzioni e frequenze di consumo
--
-- Fonte: Rielaborazione Team Smartfood, su dati SINU (LARN, V Revisione 2024),
-- CREA (Linee guida per una sana alimentazione, 2018), WCRF/AICR (2018),
-- Sofi et al. (Nutr Metab Cardiovasc Dis, 2025), ESC Guidelines (2022),
-- Bach-Faig et al. (Public Health Nutr, 2011). Dati di riferimento pubblici,
-- indipendenti da alimenti/LARN/ricette/pazienti (nessuna foreign key).
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


-- =====================================================================================
-- 6. VISTE — interrogazioni di comodo per le esigenze piu' frequenti
--
-- Ricalcano le stesse query gia' usate dall'applicativo (ricette_views.py,
-- pazienti_views.py): sono pensate soprattutto per chi vuole interrogare il
-- database direttamente (report, controlli, un client SQL a parte) senza
-- dover riscrivere ogni volta gli stessi JOIN.
-- =====================================================================================

-- 6.1 Per ogni ricetta: valori nutrizionali per porzione DICHIARATI in `ricette`
-- affiancati a quelli CALCOLATI in tempo reale dagli ingredienti (stesso calcolo
-- del bottone "Ricalcola" dell'interfaccia): utile per individuare ricette la cui
-- intestazione non e' mai stata ricalcolata, o e' rimasta disallineata dagli
-- ingredienti dopo una modifica.
CREATE VIEW vista_ricette_valori_calcolati AS
SELECT
    r.id AS ricetta_id,
    r.nome_ricetta,
    r.categoria_ricetta,
    r.porzioni,
    r.energia_kcal_porzione       AS energia_kcal_porzione_dichiarata,
    ROUND(SUM(a.energia_kcal / 100 * ri.quantita_g) / r.porzioni, 1)              AS energia_kcal_porzione_calcolata,
    r.proteine_g_porzione         AS proteine_g_porzione_dichiarata,
    ROUND(SUM(a.proteine_g / 100 * ri.quantita_g) / r.porzioni, 1)                AS proteine_g_porzione_calcolata,
    r.lipidi_g_porzione           AS lipidi_g_porzione_dichiarata,
    ROUND(SUM(a.lipidi_g / 100 * ri.quantita_g) / r.porzioni, 1)                  AS lipidi_g_porzione_calcolata,
    r.carboidrati_g_porzione      AS carboidrati_g_porzione_dichiarata,
    ROUND(SUM(a.carboidrati_disponibili_g / 100 * ri.quantita_g) / r.porzioni, 1) AS carboidrati_g_porzione_calcolata,
    r.fibra_g_porzione            AS fibra_g_porzione_dichiarata,
    ROUND(SUM(a.fibra_totale_g / 100 * ri.quantita_g) / r.porzioni, 1)            AS fibra_g_porzione_calcolata,
    r.sodio_mg_porzione           AS sodio_mg_porzione_dichiarato,
    ROUND(SUM(a.sodio_mg / 100 * ri.quantita_g) / r.porzioni, 1)                  AS sodio_mg_porzione_calcolato,
    COUNT(ri.id)                  AS numero_ingredienti
FROM ricette r
LEFT JOIN ricette_ingredienti ri ON ri.ricetta_id = r.id
LEFT JOIN alimenti a ON a.codice_alimento = ri.codice_alimento
GROUP BY r.id;

-- 6.2 Ingredienti di ogni ricetta, gia' joinati con il nome/categoria
-- dell'alimento e con il contributo energetico (kcal) di ciascuno per
-- l'intera ricetta (quantita_g e' riferita al totale delle porzioni).
CREATE VIEW vista_ricette_ingredienti_dettaglio AS
SELECT
    ri.id AS ingrediente_id,
    r.id AS ricetta_id,
    r.nome_ricetta,
    ri.ordine,
    a.codice_alimento,
    a.nome_alimento,
    a.categoria AS alimento_categoria,
    ri.quantita_g,
    ROUND(a.energia_kcal / 100 * ri.quantita_g, 1) AS kcal_contributo_totale,
    ri.note
FROM ricette_ingredienti ri
JOIN ricette r ON r.id = ri.ricetta_id
JOIN alimenti a ON a.codice_alimento = ri.codice_alimento;

-- 6.3 Per ogni giorno di ogni piano alimentare: le kcal e le proteine
-- salvate (`kcal_stimate`, aggiornata solo quando si preme "Ricalcola
-- kcal" nell'interfaccia) affiancate a quelle ricalcolate ORA dagli
-- alimenti attualmente collegati — utile per accorgersi di un giorno
-- modificato dopo l'ultimo ricalcolo.
CREATE VIEW vista_piano_giorni_calcolati AS
SELECT
    pg.id AS piano_giorno_id,
    pg.piano_id,
    p.paziente_id,
    pg.giorno_settimana,
    pg.kcal_stimate AS kcal_salvate,
    ROUND(SUM(a.energia_kcal / 100 * ppa.quantita_g), 1) AS kcal_calcolate_ora,
    ROUND(SUM(a.proteine_g / 100 * ppa.quantita_g), 1)   AS proteine_g_calcolate_ora,
    COUNT(ppa.id) AS numero_alimenti_collegati
FROM piano_giorni pg
JOIN piani_alimentari p ON p.id = pg.piano_id
LEFT JOIN piano_pasto_alimenti ppa ON ppa.piano_giorno_id = pg.id
LEFT JOIN alimenti a ON a.codice_alimento = ppa.codice_alimento
GROUP BY pg.id;

-- 6.4 Agenda appuntamenti su tutti i pazienti, gia' joinata con
-- nome/cognome: stessa query usata dalla pagina /pazienti/agenda.
CREATE VIEW vista_agenda_appuntamenti AS
SELECT
    a.id AS appuntamento_id,
    a.paziente_id,
    p.nome AS paziente_nome,
    p.cognome AS paziente_cognome,
    a.data_ora,
    a.durata_minuti,
    a.tipo,
    a.luogo,
    a.stato,
    a.note
FROM appuntamenti a
JOIN pazienti p ON p.id = a.paziente_id;

-- 6.5 Per ogni paziente, la data del suo prossimo appuntamento futuro
-- ancora "Programmato" (NULL se non ne ha). Utile per un cruscotto tipo
-- "chi devo ancora richiamare per confermare l'appuntamento".
CREATE VIEW vista_pazienti_prossimo_appuntamento AS
SELECT
    p.id AS paziente_id,
    p.nome,
    p.cognome,
    p.attivo,
    (
        SELECT MIN(a.data_ora)
        FROM appuntamenti a
        WHERE a.paziente_id = p.id
          AND a.stato = 'Programmato'
          AND a.data_ora >= NOW()
    ) AS prossimo_appuntamento
FROM pazienti p;

-- FINE SCHEMA
