-- =====================================================================================
-- SCHEMA MySQL — Tabelle LARN (Livelli di Assunzione di Riferimento di Nutrienti)
-- Fonte: SINU — Tabelle riassuntive (Acqua, Energia, Carboidrati/Zuccheri/Fibra,
--        Lipidi, Proteine, Vitamine, Minerali)
--
-- NOTE GENERALI SUI DATI:
--  - AR  = Average Requirement (fabbisogno medio)
--  - PRI = Population Reference Intake (assunzione raccomandata per la popolazione)
--  - AI  = Adequate Intake (assunzione adeguata, usata quando l'AR non e' definibile)
--  - UL  = Tolerable Upper Intake Level (livello massimo tollerabile di assunzione)
--  - SDT = Suggested Dietary Target (obiettivo nutrizionale di prevenzione)
--
-- Da eseguire nello stesso database della tabella "alimenti" (nessun comando
-- CREATE/USE DATABASE: si presume il database corrente sia gia' selezionato).
-- =====================================================================================

-- =====================================================================================
-- SCRIPT MySQL — LARN (Livelli di Assunzione di Riferimento di Nutrienti ed energia)
-- Fonte: SINU — Tabelle riassuntive (Acqua, Energia, Carboidrati/Zuccheri/Fibra,
--        Lipidi, Proteine, Vitamine, Minerali)
-- Uso previsto: database di supporto per studio/software di un nutrizionista
--               (confronto fabbisogni, calcolo assunzioni adeguate per fascia
--                di età/sesso/condizione fisiologica)
--
-- NOTE GENERALI SUI DATI:
--  - AR  = Average Requirement (fabbisogno medio)
--  - PRI = Population Reference Intake (assunzione raccomandata per la popolazione)
--  - AI  = Adequate Intake (assunzione adeguata, usata quando l'AR non è definibile)
--  - UL  = Tolerable Upper Intake Level (livello massimo tollerabile di assunzione)
--  - SDT = Suggested Dietary Target (obiettivo nutrizionale di prevenzione)
--  - Per le fasce d'età si fa riferimento all'età anagrafica (es. "4-6 anni" = dal
--    compimento del 4° al compimento del 7° anno di vita).
--  - I valori riportati sono quelli sintetici delle tabelle SINU; per i dettagli
--    metodologici si rimanda al testo completo dei LARN.
-- =====================================================================================

-- =====================================================================================
-- 0. METADATI DELLA FONTE
-- =====================================================================================
CREATE TABLE larn_metadati (
    id INT AUTO_INCREMENT PRIMARY KEY,
    chiave VARCHAR(50) NOT NULL,
    valore VARCHAR(255) NOT NULL
) ENGINE=InnoDB COMMENT='Informazioni sulla fonte dei dati';

-- =====================================================================================
-- 1. ACQUA — LARN per l'acqua (mL/die)
-- =====================================================================================
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

-- =====================================================================================
-- 2. ENERGIA — Lattanti, secondo semestre di vita (fabbisogno medio AR)
-- =====================================================================================
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

-- =====================================================================================
-- 3. ENERGIA — 1-17 anni (fabbisogno medio AR per PAL)
-- =====================================================================================
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

-- =====================================================================================
-- 4. ENERGIA — Adulti ed età geriatrica (fabbisogno medio AR per PAL)
-- =====================================================================================
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

-- =====================================================================================
-- 5. CARBOIDRATI TOTALI, ZUCCHERI, FIBRA ALIMENTARE (valori giornalieri)
-- =====================================================================================
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

-- =====================================================================================
-- 6. LIPIDI
-- =====================================================================================
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

-- =====================================================================================
-- 7. PROTEINE
-- =====================================================================================
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

-- =====================================================================================
-- 8. VITAMINE — Assunzione di riferimento per la popolazione (PRI) o Assunzione adeguata (AI)
-- =====================================================================================
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

-- =====================================================================================
-- 9. VITAMINE — Fabbisogno medio (AR)
-- =====================================================================================
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

-- =====================================================================================
-- 10. VITAMINE — Livello massimo tollerabile di assunzione (UL)
-- =====================================================================================
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

-- =====================================================================================
-- 11. MINERALI — Assunzione di riferimento per la popolazione (PRI) o Assunzione adeguata (AI)
-- =====================================================================================
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

-- =====================================================================================
-- 12. MINERALI — Fabbisogno medio (AR)
-- =====================================================================================
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

-- =====================================================================================
-- 13. MINERALI — Livello massimo tollerabile di assunzione (UL)
-- =====================================================================================
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

-- =====================================================================================
-- 14. MINERALI — Obiettivo nutrizionale per la prevenzione (SDT)
-- =====================================================================================
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

-- =====================================================================================
-- INDICI utili per query frequenti in ambito clinico/nutrizionale
-- =====================================================================================
CREATE INDEX idx_acqua_sesso_eta ON larn_acqua (sesso, eta_min, eta_max);

CREATE INDEX idx_proteine_sesso_eta ON larn_proteine (sesso, eta_min, eta_max);

CREATE INDEX idx_vitpriai_sesso_eta ON larn_vitamine_pri_ai (sesso, eta_min, eta_max);

CREATE INDEX idx_minpriai_sesso_eta ON larn_minerali_pri_ai (sesso, eta_min, eta_max);

CREATE INDEX idx_lipidi_fascia ON larn_lipidi (fascia);
