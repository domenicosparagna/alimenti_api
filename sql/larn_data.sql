-- =====================================================================================
-- DATI — Tabelle LARN (SINU)
-- Da eseguire DOPO larn_schema.sql, nello stesso database.
-- =====================================================================================

INSERT INTO larn_metadati (chiave, valore) VALUES
('fonte', 'SINU - Società Italiana di Nutrizione Umana, Tabelle riassuntive LARN'),
('ambito', 'Livelli di Assunzione di Riferimento di Nutrienti ed energia per la popolazione italiana'),
('avvertenza', 'I valori esemplificativi di statura/peso non hanno significato normativo o prescrittivo'),
('data_importazione', CURDATE());

INSERT INTO larn_acqua (fascia, eta_label, eta_min, eta_max, unita_eta, sesso, valore_ml_die, tipo_valore) VALUES
('Lattanti','7-12 mesi',7,12,'mesi','ND',800,'assoluto'),
('Bambini','1-3 anni',1,3,'anni','ND',1200,'assoluto'),
('Bambini','4-6 anni',4,6,'anni','ND',1600,'assoluto'),
('Bambini','7-10 anni',7,10,'anni','ND',1800,'assoluto'),
('Adolescenti','11-14 anni',11,14,'anni','M',2100,'assoluto'),
('Adolescenti','15-17 anni',15,17,'anni','M',2500,'assoluto'),
('Adolescenti','11-14 anni',11,14,'anni','F',1900,'assoluto'),
('Adolescenti','15-17 anni',15,17,'anni','F',2000,'assoluto'),
('Adulti','18-64 anni',18,64,'anni','M',2500,'assoluto'),
('Adulti','≥65 anni',65,NULL,'anni','M',2500,'assoluto'),
('Adulti','18-64 anni',18,64,'anni','F',2000,'assoluto'),
('Adulti','≥65 anni',65,NULL,'anni','F',2000,'assoluto'),
('Gravidanza','-',NULL,NULL,'anni','F',350,'incremento'),
('Allattamento','-',NULL,NULL,'anni','F',700,'incremento');

INSERT INTO larn_energia_lattanti (sesso, eta_mesi, peso_kg, velocita_crescita_g_die, tee_kcal_die, energia_depositata_kcal_die, fabbisogno_kcal_die, fabbisogno_kcal_kg_die) VALUES
('M',7,8.3,11.9,618,18,640,77),
('M',8,8.6,10.5,646,15,660,77),
('M',9,8.9,9.5,674,14,690,77),
('M',10,9.2,8.6,702,15,720,79),
('M',11,9.4,8.1,720,12,730,76),
('M',12,9.6,7.9,739,10,750,78),
('F',7,7.6,11.5,553,20,570,75),
('F',8,7.9,10.4,581,17,600,76),
('F',9,8.2,9.1,609,16,620,76),
('F',10,8.5,8.2,637,18,650,77),
('F',11,8.7,7.8,655,15,670,77),
('F',12,8.9,7.6,674,13,690,78);

INSERT INTO larn_energia_1_17_anni (sesso, eta_anni, peso_kg, bmr_kcal_die, fabbisogno_pal_1_2, fabbisogno_pal_1_4, fabbisogno_pal_1_6, fabbisogno_pal_1_8, fabbisogno_pal_2_0) VALUES
('M',1.5,10.9,620,750,870,1000,NULL,NULL),
('M',2.5,13.3,760,920,1080,1230,NULL,NULL),
('M',3.5,15.3,850,1030,1200,1380,1550,NULL),
('M',4.5,17.3,900,1090,1270,1450,1630,NULL),
('M',5.5,19.4,940,1140,1340,1530,1720,NULL),
('M',6.5,21.7,1000,1210,1410,1610,1810,NULL),
('M',7.5,24.1,1050,1270,1490,1700,1910,NULL),
('M',8.5,26.7,1110,1350,1570,1790,2020,2240),
('M',9.5,29.6,1180,1430,1660,1900,2140,2380),
('M',10.5,32.9,1240,NULL,1750,2000,2250,2500),
('M',11.5,36.7,1310,NULL,1850,2110,2380,2640),
('M',12.5,41.6,1390,NULL,1970,2250,2530,2820),
('M',13.5,47.4,1500,NULL,2120,2420,2720,3020),
('M',14.5,53.7,1610,NULL,2270,2600,2920,3250),
('M',15.5,58.8,1700,NULL,2400,2740,3090,3430),
('M',16.5,63.1,1770,NULL,2510,2870,3230,3580),
('M',17.5,66.1,1830,NULL,2580,2950,3320,3690),
('F',1.5,10.2,560,680,800,910,NULL,NULL),
('F',2.5,12.7,710,860,1000,1150,NULL,NULL),
('F',3.5,15.0,790,960,1120,1280,1440,NULL),
('F',4.5,17.2,830,1010,1180,1350,1520,NULL),
('F',5.5,19.1,870,1060,1240,1410,1590,NULL),
('F',6.5,21.2,920,1110,1300,1480,1670,NULL),
('F',7.5,23.6,960,1170,1360,1560,1750,NULL),
('F',8.5,26.5,1020,1240,1450,1650,1860,2070),
('F',9.5,30.0,1100,1330,1550,1770,1990,2210),
('F',10.5,34.0,1150,NULL,1620,1850,2090,2320),
('F',11.5,38.7,1210,NULL,1710,1960,2200,2440),
('F',12.5,43.6,1280,NULL,1800,2060,2320,2580),
('F',13.5,47.9,1330,NULL,1890,2150,2420,2690),
('F',14.5,51.5,1380,NULL,1950,2230,2510,2790),
('F',15.5,53.9,1410,NULL,2000,2280,2570,2860),
('F',16.5,55.3,1430,NULL,2030,2310,2600,2890),
('F',17.5,56.3,1450,NULL,2040,2340,2630,2920);

INSERT INTO larn_energia_adulti (sesso, fascia_eta, eta_min, eta_max, statura_m, peso_kg, bmr_kcal_die, fabbisogno_pal_1_2, fabbisogno_pal_1_4, fabbisogno_pal_1_6, fabbisogno_pal_1_8, fabbisogno_pal_2_0) VALUES
-- Maschi 18-29
('M','18-29',18,29,1.60,57.6,1560,NULL,2180,2500,2810,3120),
('M','18-29',18,29,1.65,61.3,1620,NULL,2260,2580,2910,3230),
('M','18-29',18,29,1.70,65.0,1670,NULL,2340,2670,3010,3340),
('M','18-29',18,29,1.75,68.9,1730,NULL,2420,2770,3110,3460),
('M','18-29',18,29,1.80,72.9,1790,NULL,2510,2860,3220,3580),
('M','18-29',18,29,1.85,77.0,1850,NULL,2590,2960,3330,3700),
('M','18-29',18,29,1.90,81.2,1920,NULL,2680,3060,3450,3830),
('M','18-29',18,29,1.95,85.6,1980,NULL,2770,3170,3570,3960),
('M','18-29',18,29,2.00,90.0,2050,NULL,2870,3280,3690,4100),
-- Maschi 30-59
('M','30-59',30,59,1.60,57.6,1530,NULL,2150,2450,2760,3070),
('M','30-59',30,59,1.65,61.3,1580,NULL,2210,2520,2840,3150),
('M','30-59',30,59,1.70,65.0,1620,NULL,2270,2590,2910,3240),
('M','30-59',30,59,1.75,68.9,1660,NULL,2330,2660,2990,3330),
('M','30-59',30,59,1.80,72.9,1710,NULL,2390,2740,3080,3420),
('M','30-59',30,59,1.85,77.0,1760,NULL,2460,2810,3160,3510),
('M','30-59',30,59,1.90,81.2,1800,NULL,2530,2890,3250,3610),
('M','30-59',30,59,1.95,85.6,1860,NULL,2600,2970,3340,3710),
('M','30-59',30,59,2.00,90.0,1910,NULL,2670,3050,3430,3810),
-- Maschi 60-80
('M','60-80',60,80,1.60,57.6,1260,1520,1770,2020,2270,NULL),
('M','60-80',60,80,1.65,61.3,1310,1570,1830,2090,2350,NULL),
('M','60-80',60,80,1.70,65.0,1350,1620,1890,2160,2430,NULL),
('M','60-80',60,80,1.75,68.9,1400,1670,1950,2230,2510,NULL),
('M','60-80',60,80,1.80,72.9,1440,1730,2020,2310,2590,NULL),
('M','60-80',60,80,1.85,77.0,1490,1790,2090,2380,2680,NULL),
('M','60-80',60,80,1.90,81.2,1540,1850,2150,2460,2770,NULL),
('M','60-80',60,80,1.95,85.6,1590,1910,2230,2540,2860,NULL),
('M','60-80',60,80,2.00,90.0,1640,1970,2300,2630,2960,NULL),
-- Femmine 18-29
('F','18-29',18,29,1.50,50.6,1240,NULL,1730,1980,2230,2470),
('F','18-29',18,29,1.55,54.1,1290,NULL,1800,2060,2320,2580),
('F','18-29',18,29,1.60,57.6,1340,NULL,1880,2140,2410,2680),
('F','18-29',18,29,1.65,61.3,1400,NULL,1950,2230,2510,2790),
('F','18-29',18,29,1.70,65.0,1450,NULL,2030,2320,2610,2900),
('F','18-29',18,29,1.75,68.9,1510,NULL,2110,2410,2710,3020),
('F','18-29',18,29,1.80,72.9,1570,NULL,2190,2510,2820,3130),
('F','18-29',18,29,1.85,77.0,1630,NULL,2280,2600,2930,3260),
('F','18-29',18,29,1.90,81.2,1690,NULL,2370,2700,3040,3380),
-- Femmine 30-59
('F','30-59',30,59,1.50,50.6,1260,NULL,1760,2010,2260,2510),
('F','30-59',30,59,1.55,54.1,1290,NULL,1800,2060,2310,2570),
('F','30-59',30,59,1.60,57.6,1310,NULL,1840,2100,2370,2630),
('F','30-59',30,59,1.65,61.3,1340,NULL,1880,2150,2420,2690),
('F','30-59',30,59,1.70,65.0,1370,NULL,1920,2200,2470,2750),
('F','30-59',30,59,1.75,68.9,1410,NULL,1970,2250,2530,2810),
('F','30-59',30,59,1.80,72.9,1440,NULL,2010,2300,2590,2880),
('F','30-59',30,59,1.85,77.0,1470,NULL,2060,2360,2650,2940),
('F','30-59',30,59,1.90,81.2,1510,NULL,2110,2410,2710,3010),
-- Femmine 60-80
('F','60-80',60,80,1.50,50.6,1120,1340,1570,1790,2010,NULL),
('F','60-80',60,80,1.55,54.1,1150,1380,1610,1840,2070,NULL),
('F','60-80',60,80,1.60,57.6,1180,1420,1650,1890,2130,NULL),
('F','60-80',60,80,1.65,61.3,1220,1460,1700,1940,2190,NULL),
('F','60-80',60,80,1.70,65.0,1250,1500,1750,2000,2250,NULL),
('F','60-80',60,80,1.75,68.9,1280,1540,1800,2060,2310,NULL),
('F','60-80',60,80,1.80,72.9,1320,1590,1850,2110,2380,NULL),
('F','60-80',60,80,1.85,77.0,1360,1630,1900,2170,2440,NULL),
('F','60-80',60,80,1.90,81.2,1400,1680,1950,2230,2510,NULL);

INSERT INTO larn_carboidrati_fibra (nutriente, gruppo_eta, eta_min, eta_max, parametro, valore_min, valore_max, unita, note) VALUES
('Carboidrati totali','Tutti',NULL,NULL,'RI',45,60,'% En','Apporto minimo desiderabile di carboidrati disponibili: 2 g/die x kg di peso corporeo per prevenire la chetosi; limite superiore 65% En accettabile con elevato dispendio energetico da attività fisica intensa. Preferire fonti amidacee a basso indice glicemico.'),
('Zuccheri semplici','Tutti',NULL,NULL,'SDT',NULL,15,'% En','Limitare il consumo di zuccheri (naturalmente presenti + aggiunti) a <15% En. Limitare fruttosio come dolcificante e sciroppi di mais ad alto contenuto di fruttosio.'),
('Zuccheri semplici','Tutti',NULL,NULL,'Osservazionale',25,NULL,'% En','Un apporto totale >25% En (95° percentile di introduzione nella dieta italiana) è potenzialmente legato a eventi avversi sulla salute. UL non definibile.'),
('Fibra alimentare','Età evolutiva',0,17,'AI',8.4,NULL,'g/1000 kcal','Equivalente a 2 g/MJ. Preferire alimenti naturalmente ricchi in fibra.'),
('Fibra alimentare','Adulti',18,NULL,'AI',12.6,16.7,'g/1000 kcal','Equivalente a 3-4 g/MJ. Consumare almeno 25 g/die anche con apporti energetici <2000 kcal/die.');

INSERT INTO larn_lipidi (fascia, eta_label, eta_min, eta_max, unita_eta, tipo_lipide, sdt, ai, ri) VALUES
-- Lattanti 7-12 mesi
('Lattanti','7-12 mesi',7,12,'mesi','Lipidi totali',NULL,'40% En',NULL),
('Lattanti','7-12 mesi',7,12,'mesi','SFA','<10% En',NULL,NULL),
('Lattanti','7-12 mesi',7,12,'mesi','PUFA',NULL,NULL,'5-10% En'),
('Lattanti','7-12 mesi',7,12,'mesi','PUFA n-6',NULL,NULL,'4-8% En'),
('Lattanti','7-12 mesi',7,12,'mesi','PUFA n-3',NULL,'EPA-DHA 250 mg/die + DHA 100 mg/die','0,5-2,0% En'),
('Lattanti','7-12 mesi',7,12,'mesi','Acidi grassi trans','Il meno possibile',NULL,NULL),
-- Bambini 1-3 anni
('Bambini','1-3 anni',1,3,'anni','Lipidi totali',NULL,NULL,'35-40% En'),
('Bambini','1-3 anni',1,3,'anni','SFA','<10% En',NULL,NULL),
('Bambini','1-3 anni',1,3,'anni','PUFA',NULL,NULL,'5-10% En'),
('Bambini','1-3 anni',1,3,'anni','PUFA n-6',NULL,NULL,'4-8% En'),
('Bambini','1-3 anni',1,3,'anni','PUFA n-3',NULL,'EPA-DHA 250 mg/die (1-2 anni: +DHA 100 mg/die)','0,5-2,0% En'),
('Bambini','1-3 anni',1,3,'anni','Acidi grassi trans','Il meno possibile',NULL,NULL),
-- Bambini e adolescenti 4-17 anni
('Bambini e adolescenti','4-17 anni',4,17,'anni','Lipidi totali',NULL,NULL,'20-35% En*'),
('Bambini e adolescenti','4-17 anni',4,17,'anni','SFA','<10% En',NULL,NULL),
('Bambini e adolescenti','4-17 anni',4,17,'anni','PUFA',NULL,NULL,'5-10% En'),
('Bambini e adolescenti','4-17 anni',4,17,'anni','PUFA n-6',NULL,NULL,'4-8% En'),
('Bambini e adolescenti','4-17 anni',4,17,'anni','PUFA n-3',NULL,'EPA-DHA 250 mg/die','0,5-2,0% En'),
('Bambini e adolescenti','4-17 anni',4,17,'anni','Acidi grassi trans','Il meno possibile',NULL,NULL),
-- Adulti >=18 anni
('Adulti','≥18 anni',18,NULL,'anni','Lipidi totali',NULL,NULL,'20-35% En*'),
('Adulti','≥18 anni',18,NULL,'anni','SFA','<10% En',NULL,NULL),
('Adulti','≥18 anni',18,NULL,'anni','PUFA',NULL,NULL,'5-10% En'),
('Adulti','≥18 anni',18,NULL,'anni','PUFA n-6',NULL,NULL,'4-8% En'),
('Adulti','≥18 anni',18,NULL,'anni','PUFA n-3',NULL,'EPA-DHA 250 mg/die','0,5-2,0% En'),
('Adulti','≥18 anni',18,NULL,'anni','Acidi grassi trans','Il meno possibile',NULL,NULL),
-- Gravidanza e Allattamento
('Gravidanza e Allattamento','-',NULL,NULL,'anni','Lipidi totali',NULL,NULL,'20-35% En*'),
('Gravidanza e Allattamento','-',NULL,NULL,'anni','SFA','<10% En',NULL,NULL),
('Gravidanza e Allattamento','-',NULL,NULL,'anni','PUFA',NULL,NULL,'5-10% En'),
('Gravidanza e Allattamento','-',NULL,NULL,'anni','PUFA n-6',NULL,NULL,'4-8% En'),
('Gravidanza e Allattamento','-',NULL,NULL,'anni','PUFA n-3',NULL,'EPA-DHA 250 mg/die + DHA 100-200 mg/die','0,5-2,0% En'),
('Gravidanza e Allattamento','-',NULL,NULL,'anni','Acidi grassi trans','Il meno possibile',NULL,NULL);

-- Nota generale su * : valori più elevati dell'intervallo coerenti con apporto di carboidrati
-- vicino al limite inferiore del corrispondente RI; altrimenti mantenere valori <=30% En.
UPDATE larn_lipidi SET note = 'Valori più elevati dell''intervallo coerenti con apporto di carboidrati vicino al limite inferiore del RI; altrimenti mantenere ≤30% En. UL non definibile.'
WHERE ri = '20-35% En*';

INSERT INTO larn_proteine (fascia, eta_label, eta_min, eta_max, unita_eta, sesso, peso_kg, ar_g_kg_die, ar_g_die, pri_g_kg_die, pri_g_die) VALUES
-- Lattanti
('Lattanti','6 mesi',6,6,'mesi','M',7.9,1.21,9.6,1.41,11.1),
('Lattanti','6 mesi',6,6,'mesi','F',7.3,1.21,8.8,1.41,10.3),
('Lattanti','12 mesi',12,12,'mesi','M',9.6,1.02,9.8,1.23,11.8),
('Lattanti','12 mesi',12,12,'mesi','F',8.9,1.02,9.1,1.23,10.9),
-- Bambini (AR e PRI g/kg unici per M/F, g/die differiscono per peso)
('Bambini','1,5 anni',1.5,1.5,'anni','M',10.9,0.92,10.0,1.11,12.1),
('Bambini','1,5 anni',1.5,1.5,'anni','F',10.2,0.92,9.4,1.11,11.3),
('Bambini','2,5 anni',2.5,2.5,'anni','M',13.3,0.85,11.3,1.05,14.0),
('Bambini','2,5 anni',2.5,2.5,'anni','F',12.7,0.85,10.8,1.05,13.3),
('Bambini','3,5 anni',3.5,3.5,'anni','M',15.3,0.79,12.1,0.97,14.8),
('Bambini','3,5 anni',3.5,3.5,'anni','F',15.0,0.79,11.9,0.97,14.6),
('Bambini','4,5 anni',4.5,4.5,'anni','M',17.3,0.74,12.8,0.93,16.1),
('Bambini','4,5 anni',4.5,4.5,'anni','F',17.2,0.74,12.7,0.93,16.0),
('Bambini','5,5 anni',5.5,5.5,'anni','M',19.4,0.74,14.4,0.92,17.8),
('Bambini','5,5 anni',5.5,5.5,'anni','F',19.1,0.74,14.1,0.92,17.6),
('Bambini','6,5 anni',6.5,6.5,'anni','M',21.7,0.78,16.9,0.96,20.8),
('Bambini','6,5 anni',6.5,6.5,'anni','F',21.2,0.78,16.5,0.96,20.4),
('Bambini','7,5 anni',7.5,7.5,'anni','M',24.1,0.80,19.3,0.98,23.6),
('Bambini','7,5 anni',7.5,7.5,'anni','F',23.6,0.80,18.9,0.98,23.1),
('Bambini','8,5 anni',8.5,8.5,'anni','M',26.7,0.81,21.6,0.99,26.4),
('Bambini','8,5 anni',8.5,8.5,'anni','F',26.5,0.81,21.5,0.99,26.2),
('Bambini','9,5 anni',9.5,9.5,'anni','M',29.6,0.81,24.0,0.99,29.3),
('Bambini','9,5 anni',9.5,9.5,'anni','F',30.0,0.81,24.3,0.99,29.7),
('Bambini','10,5 anni',10.5,10.5,'anni','M',32.9,0.81,26.6,0.98,32.2),
('Bambini','10,5 anni',10.5,10.5,'anni','F',34.0,0.81,27.5,0.98,33.3),
-- Adolescenti (AR e PRI g/kg differiscono per sesso)
('Adolescenti','11,5 anni',11.5,11.5,'anni','M',36.7,0.81,29.7,0.98,36.0),
('Adolescenti','11,5 anni',11.5,11.5,'anni','F',38.7,0.79,30.6,0.97,37.5),
('Adolescenti','12,5 anni',12.5,12.5,'anni','M',41.6,0.80,33.3,0.97,40.4),
('Adolescenti','12,5 anni',12.5,12.5,'anni','F',43.6,0.78,34.0,0.96,41.9),
('Adolescenti','13,5 anni',13.5,13.5,'anni','M',47.4,0.79,37.4,0.97,46.0),
('Adolescenti','13,5 anni',13.5,13.5,'anni','F',47.9,0.77,36.9,0.95,45.5),
('Adolescenti','14,5 anni',14.5,14.5,'anni','M',53.7,0.78,41.9,0.96,51.6),
('Adolescenti','14,5 anni',14.5,14.5,'anni','F',51.5,0.76,39.1,0.94,48.4),
('Adolescenti','15,5 anni',15.5,15.5,'anni','M',58.8,0.78,45.9,0.95,55.9),
('Adolescenti','15,5 anni',15.5,15.5,'anni','F',53.9,0.74,39.9,0.92,49.6),
('Adolescenti','16,5 anni',16.5,16.5,'anni','M',63.1,0.78,49.2,0.94,59.3),
('Adolescenti','16,5 anni',16.5,16.5,'anni','F',55.3,0.73,40.4,0.91,50.3),
('Adolescenti','17,5 anni',17.5,17.5,'anni','M',66.1,0.76,50.2,0.93,61.5),
('Adolescenti','17,5 anni',17.5,17.5,'anni','F',56.3,0.72,40.5,0.90,50.7);

INSERT INTO larn_proteine (fascia, eta_label, eta_min, eta_max, unita_eta, sesso, peso_kg, ar_g_kg_die, ar_g_die, pri_g_kg_die, pri_g_die, sdt_g_kg_die, sdt_g_die) VALUES
('Adulti','18-64 anni',18,64,'anni','M',70,0.71,50,0.90,63,NULL,NULL),
('Adulti','18-64 anni',18,64,'anni','F',60,0.71,43,0.90,54,NULL,NULL),
('Adulti','65-74 anni',65,74,'anni','M',70,NULL,NULL,NULL,NULL,1.1,77),
('Adulti','65-74 anni',65,74,'anni','F',60,NULL,NULL,NULL,NULL,1.1,66),
('Adulti','≥75 anni',75,NULL,'anni','M',70,NULL,NULL,NULL,NULL,1.1,77),
('Adulti','≥75 anni',75,NULL,'anni','F',60,NULL,NULL,NULL,NULL,1.1,66);

-- Gravidanza e Allattamento: incrementi in g/die rispetto al basale (AR e PRI)
INSERT INTO larn_proteine (fascia, eta_label, sesso, ar_g_die, pri_g_die, tipo_valore, note) VALUES
('Gravidanza','I trimestre','F',0.5,1,'incremento','Incremento rispetto all''assunzione di inizio gestazione, per un incremento ponderale totale di 12 kg'),
('Gravidanza','II trimestre','F',6,8,'incremento','Vedi nota trimestre I'),
('Gravidanza','III trimestre','F',19.9,25,'incremento','Vedi nota trimestre I'),
('Allattamento','I semestre','F',16,20,'incremento','Produzione di latte considerata: 0,81 L/die'),
('Allattamento','II semestre','F',11,13,'incremento','Produzione di latte considerata: 0,56 L/die');

INSERT INTO larn_vitamine_pri_ai (fascia, eta_label, eta_min, eta_max, unita_eta, sesso, tiamina_mg_1000kcal, riboflavina_mg, niacina_mg, ac_pantotenico_mg, vit_b6_mg, biotina_ug, folati_ug, vit_b12_ug, vit_c_mg, vit_a_ug, vit_d_ug, vit_d_ug_over75, vit_e_mg, vit_k_ug, note) VALUES
('Lattanti','7-12 mesi',7,12,'mesi','ND',0.4,0.4,5,2,0.4,7,80,1.4,40,250,10,NULL,4,10,NULL),
('Bambini','1-3 anni',1,3,'anni','ND',0.4,0.4,7,2,0.6,20,120,1.4,35,250,15,NULL,5,45,NULL),
('Bambini','4-6 anni',4,6,'anni','ND',0.4,0.7,8,2,0.7,25,140,1.7,45,300,15,NULL,6,60,NULL),
('Bambini','7-10 anni',7,10,'anni','ND',0.4,0.9,12,3,1.0,25,200,2.5,60,400,15,NULL,8,80,NULL),
('Adolescenti','11-14 anni',11,14,'anni','M',0.4,1.2,16,4,1.3,35,270,3.4,90,600,15,NULL,11,110,NULL),
('Adolescenti','15-17 anni',15,17,'anni','M',0.4,1.6,18,5,1.6,35,330,4.0,105,750,15,NULL,13,135,NULL),
('Adolescenti','11-14 anni',11,14,'anni','F',0.4,1.2,16,4,1.3,35,270,3.3,80,600,15,NULL,11,110,NULL),
('Adolescenti','15-17 anni',15,17,'anni','F',0.4,1.6,18,5,1.4,35,330,4.0,85,650,15,NULL,12,120,NULL),
('Adulti','18-64 anni',18,64,'anni','M',0.4,1.6,18,5,1.6,40,330,4.0,105,750,15,NULL,13,135,NULL),
('Adulti','≥65 anni',65,NULL,'anni','M',0.4,1.6,18,5,1.7,40,330,4.0,105,750,15,20,13,135,'Vit. D: 15 µg per 65-74 anni, 20 µg per ≥75 anni'),
('Adulti','18-64 anni',18,64,'anni','F',0.4,1.6,18,5,1.4,40,330,4.0,85,650,15,NULL,12,125,'Folati: PRI riferita a donne in età fertile senza gravidanza; non include supplementazione per prevenzione difetti tubo neurale'),
('Adulti','≥65 anni',65,NULL,'anni','F',0.4,1.6,18,5,1.6,40,330,4.0,85,650,15,20,12,125,'Vit. D: 15 µg per 65-74 anni, 20 µg per ≥75 anni'),
('Gravidanza','-',NULL,NULL,'anni','F',0.4,1.8,22,6,1.9,40,600,4.5,100,700,15,NULL,12,125,'Folati (AI): non include supplementazione per prevenzione difetti tubo neurale'),
('Allattamento','-',NULL,NULL,'anni','F',0.4,1.8,22,7,2.0,45,500,5.0,130,1300,15,NULL,15,125,'Folati: valore AI');

INSERT INTO larn_vitamine_ar (fascia, eta_label, eta_min, eta_max, unita_eta, sesso, tiamina_mg_1000kcal, riboflavina_mg, niacina_mg, vit_b6_mg, folati_ug, vit_c_mg, vit_a_ug, vit_d_ug) VALUES
('Lattanti','7-12 mesi',7,12,'mesi','ND',0.3,NULL,NULL,NULL,NULL,NULL,190,NULL),
('Bambini','1-3 anni',1,3,'anni','ND',0.3,0.4,5,0.5,90,25,205,10),
('Bambini','4-6 anni',4,6,'anni','ND',0.3,0.6,6,0.6,110,30,245,10),
('Bambini','7-10 anni',7,10,'anni','ND',0.3,0.8,9,0.8,160,45,320,10),
('Adolescenti','11-14 anni',11,14,'anni','M',0.3,1.1,12,1.1,210,65,480,10),
('Adolescenti','15-17 anni',15,17,'anni','M',0.3,1.3,14,1.4,250,75,570,10),
('Adolescenti','11-14 anni',11,14,'anni','F',0.3,1.1,12,1.1,210,55,480,10),
('Adolescenti','15-17 anni',15,17,'anni','F',0.3,1.3,14,1.2,250,60,490,10),
('Adulti','18-64 anni',18,64,'anni','M',0.3,1.3,14,1.4,250,75,570,10),
('Adulti','≥65 anni',65,NULL,'anni','M',0.3,1.3,14,1.5,250,75,570,10),
('Adulti','18-64 anni',18,64,'anni','F',0.3,1.3,14,1.2,250,60,490,10),
('Adulti','≥65 anni',65,NULL,'anni','F',0.3,1.3,14,1.3,250,60,490,10),
('Gravidanza','-',NULL,NULL,'anni','F',0.3,1.6,17,1.6,NULL,70,540,10),
('Allattamento','-',NULL,NULL,'anni','F',0.3,1.6,17,1.7,380,90,1020,10);

INSERT INTO larn_vitamine_ul (fascia, eta_label, eta_min, eta_max, unita_eta, sesso, niacina_na_mg, niacina_acn_mg, vit_b6_mg, folati_ug, vit_a_ug, vit_d_ug, vit_e_mg, note) VALUES
('Lattanti','7-12 mesi',7,12,'mesi','ND',NULL,NULL,2.2,NULL,NULL,40,NULL,NULL),
('Bambini','1-3 anni',1,3,'anni','ND',150,2,2.5,200,800,65,100,NULL),
('Bambini','4-6 anni',4,6,'anni','ND',220,3,3.2,300,1100,75,120,NULL),
('Bambini','7-10 anni',7,10,'anni','ND',350,4,6.1,400,1500,75,160,NULL),
('Adolescenti','11-14 anni',11,14,'anni','M',500,6,8.6,600,2000,100,220,NULL),
('Adolescenti','15-17 anni',15,17,'anni','M',700,8,10.7,800,2600,100,260,NULL),
('Adolescenti','11-14 anni',11,14,'anni','F',500,6,8.6,600,2000,100,220,NULL),
('Adolescenti','15-17 anni',15,17,'anni','F',700,8,10.7,800,2600,100,260,NULL),
('Adulti','18-64 anni',18,64,'anni','M',900,10,12,1000,3000,100,300,NULL),
('Adulti','≥65 anni',65,NULL,'anni','M',900,10,12,1000,3000,100,300,NULL),
('Adulti','18-64 anni',18,64,'anni','F',900,10,12,1000,3000,100,300,'Per donne in post-menopausa, UL Vit. A come vit. A preformata = 1500 µg'),
('Adulti','≥65 anni',65,NULL,'anni','F',900,10,12,1000,1500,100,300,NULL),
('Gravidanza','-',NULL,NULL,'anni','F',NULL,NULL,12,1000,3000,100,300,NULL),
('Allattamento','-',NULL,NULL,'anni','F',NULL,NULL,12,1000,3000,100,300,NULL);

INSERT INTO larn_minerali_pri_ai (fascia, eta_label, eta_min, eta_max, unita_eta, sesso, ca_mg, p_mg, mg_mg, na_g, k_mg, cl_g, fe_mg, zn_mg, cu_mg, se_ug, i_ug, mn_mg, mo_ug, cr_ug, f_mg, note) VALUES
('Lattanti','7-12 mesi',7,12,'mesi','ND',280,160,80,0.3,700,0.45,11,3,0.3,20,70,0.4,10,4,0.4,NULL),
('Bambini','1-3 anni',1,3,'anni','ND',510,295,120,0.5,NULL,1.00,8,5,0.4,20,100,0.6,15,7,0.7,NULL),
('Bambini','4-6 anni',4,6,'anni','ND',900,520,150,0.6,NULL,1.40,11,6,0.5,25,100,0.8,20,10,1.0,NULL),
('Bambini','7-10 anni',7,10,'anni','ND',1040,600,220,1.0,NULL,1.70,13,8,0.7,35,100,1.2,30,14,1.6,NULL),
('Adolescenti','11-14 anni',11,14,'anni','M',1150,660,290,1.5,NULL,2.30,10,12,1.0,50,130,1.9,50,25,2.5,NULL),
('Adolescenti','15-17 anni',15,17,'anni','M',1150,660,380,1.5,NULL,2.30,13,12,1.3,55,130,2.5,65,33,3.5,NULL),
('Adolescenti','11-14 anni',11,14,'anni','F',1150,660,290,1.5,NULL,2.30,10,9,1.0,50,130,1.9,50,21,2.5,'Fe: 18 mg/die per le adolescenti che hanno le mestruazioni'),
('Adolescenti','15-17 anni',15,17,'anni','F',1150,660,310,1.5,NULL,2.30,18,9,1.2,55,130,2.3,65,23,3.0,NULL),
('Adulti','18-64 anni',18,64,'anni','M',950,550,350,1.5,NULL,2.30,10,12,1.4,55,150,2.5,65,35,3.5,NULL),
('Adulti','≥65 anni',65,NULL,'anni','M',1100,630,350,1.2,NULL,1.90,10,12,1.4,55,150,2.5,65,30,3.5,NULL),
('Adulti','18-64 anni',18,64,'anni','F',950,550,350,1.5,NULL,2.30,18,9,1.3,55,150,2.3,65,25,3.0,'Fe: 10 mg/die in post-menopausa. Ca: PRI 950 mg/die in pre-menopausa indipendentemente dall''età; P analogamente 550 mg/die in pre-menopausa'),
('Adulti','≥65 anni',65,NULL,'anni','F',1100,630,350,1.2,NULL,1.90,10,9,1.3,55,150,2.3,65,20,3.0,'Ca: PRI 1100 mg/die in post-menopausa indipendentemente dall''età; P analogamente 630 mg/die in post-menopausa'),
('Gravidanza','-',NULL,NULL,'anni','F',1100,630,350,1.5,NULL,2.30,27,11,1.5,60,200,2.3,65,30,3.0,NULL),
('Allattamento','-',NULL,NULL,'anni','F',1100,630,350,1.5,NULL,2.30,11,12,1.5,60,200,2.3,65,45,3.0,NULL);

INSERT INTO larn_minerali_ar (fascia, eta_label, eta_min, eta_max, unita_eta, sesso, ca_mg, fe_mg, zn_mg, note) VALUES
('Lattanti','7-12 mesi',7,12,'mesi','ND',NULL,7,2.5,NULL),
('Bambini','1-3 anni',1,3,'anni','ND',390,4,4,NULL),
('Bambini','4-6 anni',4,6,'anni','ND',700,5,5,NULL),
('Bambini','7-10 anni',7,10,'anni','ND',800,5,7,NULL),
('Adolescenti','11-14 anni',11,14,'anni','M',950,7,10,NULL),
('Adolescenti','15-17 anni',15,17,'anni','M',950,9,10,NULL),
('Adolescenti','11-14 anni',11,14,'anni','F',950,7,8,'Fe: 10 mg/die per le adolescenti che hanno le mestruazioni'),
('Adolescenti','15-17 anni',15,17,'anni','F',950,10,8,NULL),
('Adulti','18-64 anni',18,64,'anni','M',750,7,10,NULL),
('Adulti','≥65 anni',65,NULL,'anni','M',850,7,10,NULL),
('Adulti','18-64 anni',18,64,'anni','F',750,10,8,'Fe: 6 mg/die in post-menopausa. Ca: AR 750 mg/die in pre-menopausa indipendentemente dall''età'),
('Adulti','≥65 anni',65,NULL,'anni','F',850,6,8,'Ca: AR 850 mg/die in post-menopausa indipendentemente dall''età'),
('Gravidanza','-',NULL,NULL,'anni','F',850,22,9,NULL),
('Allattamento','-',NULL,NULL,'anni','F',850,8,10,NULL);

INSERT INTO larn_minerali_ul (fascia, eta_label, eta_min, eta_max, unita_eta, sesso, ca_mg, zn_mg, cu_mg, se_ug, i_ug, mo_ug, f_mg) VALUES
('Lattanti','7-12 mesi',7,12,'mesi','ND',NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('Bambini','1-3 anni',1,3,'anni','ND',NULL,7,1,35,200,100,1.5),
('Bambini','4-6 anni',4,6,'anni','ND',NULL,10,2,50,250,200,2.5),
('Bambini','7-10 anni',7,10,'anni','ND',NULL,13,3,90,300,250,2.5),
('Adolescenti','11-14 anni',11,14,'anni','M',NULL,18,4,120,450,400,5.0),
('Adolescenti','15-17 anni',15,17,'anni','M',NULL,22,4,180,500,500,7.0),
('Adolescenti','11-14 anni',11,14,'anni','F',NULL,18,4,120,450,400,5.0),
('Adolescenti','15-17 anni',15,17,'anni','F',NULL,22,4,170,500,500,7.0),
('Adulti','18-64 anni',18,64,'anni','M',2500,25,5,200,600,600,7.0),
('Adulti','≥65 anni',65,NULL,'anni','M',2500,25,5,200,600,600,7.0),
('Adulti','18-64 anni',18,64,'anni','F',2500,25,5,200,600,600,7.0),
('Adulti','≥65 anni',65,NULL,'anni','F',2500,25,5,200,600,600,7.0),
('Gravidanza','-',NULL,NULL,'anni','F',2500,25,NULL,200,600,600,7.0),
('Allattamento','-',NULL,NULL,'anni','F',2500,25,NULL,200,600,600,7.0);

INSERT INTO larn_minerali_sdt (fascia, eta_label, eta_min, eta_max, unita_eta, sesso, na_g, cl_g, k_mg) VALUES
('Lattanti','7-12 mesi',7,12,'mesi','ND',NULL,NULL,NULL),
('Bambini','1-3 anni',1,3,'anni','ND',0.7,1.3,1500),
('Bambini','4-6 anni',4,6,'anni','ND',0.9,1.8,1900),
('Bambini','7-10 anni',7,10,'anni','ND',1.1,2.3,2700),
('Adolescenti','11-14 anni',11,14,'anni','M',2.0,3.0,4500),
('Adolescenti','15-17 anni',15,17,'anni','M',2.0,3.0,4500),
('Adolescenti','11-14 anni',11,14,'anni','F',2.0,3.0,4500),
('Adolescenti','15-17 anni',15,17,'anni','F',2.0,3.0,4500),
('Adulti','18-64 anni',18,64,'anni','M',2.0,3.0,4500),
('Adulti','≥65 anni',65,NULL,'anni','M',1.6,2.5,3900),
('Adulti','18-64 anni',18,64,'anni','F',2.0,3.0,4500),
('Adulti','≥65 anni',65,NULL,'anni','F',1.6,2.5,3900),
('Gravidanza','-',NULL,NULL,'anni','F',2.0,3.0,4500),
('Allattamento','-',NULL,NULL,'anni','F',2.0,3.0,4500);


-- =====================================================================================
-- ESEMPI DI QUERY PER USO CLINICO (commentate)
-- =====================================================================================
-- Es. 1: fabbisogno idrico e proteico PRI per una donna adulta di 34 anni
-- SELECT * FROM larn_acqua WHERE sesso='F' AND 34 BETWEEN eta_min AND IFNULL(eta_max,999);
-- SELECT * FROM larn_proteine WHERE sesso='F' AND 34 BETWEEN eta_min AND IFNULL(eta_max,999);

-- Es. 2: fabbisogno energetico stimato per un uomo di 40 anni, 1.75 m, PAL 1.6
-- SELECT statura_m, peso_kg, fabbisogno_pal_1_6
-- FROM larn_energia_adulti
-- WHERE sesso='M' AND fascia_eta='30-59' AND statura_m=1.75;

-- Es. 3: PRI vitamina D e calcio per donna over 65
-- SELECT vit_d_ug, vit_d_ug_over75 FROM larn_vitamine_pri_ai WHERE sesso='F' AND fascia='Adulti' AND eta_label='≥65 anni';
-- SELECT ca_mg FROM larn_minerali_pri_ai WHERE sesso='F' AND fascia='Adulti' AND eta_label='≥65 anni';

-- FINE SCRIPT
