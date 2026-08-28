-- =====================================================================================
-- DATI — Ricette
-- Da eseguire DOPO ricette_schema.sql (e dopo aver gia' importato alimenti/data.sql,
-- dato che ricette_ingredienti referenzia alimenti.codice_alimento), nello stesso database.
--
-- CRITERI DI SELEZIONE DELLE RICETTE:
--   - copertura delle principali categorie del pasto (colazione, primo, secondo, piatto unico,
--     contorno, spuntino)
--   - varieta' di profili dietetici utili in uno studio di nutrizione (vegano/vegetariano,
--     senza glutine, alto proteico, ipocalorico, ricco di fibre, fonte di omega-3, basso indice
--     glicemico, attenzione al sodio)
--   - ingredienti tutti tracciabili nella tabella 'alimenti' tramite codice_alimento, cosi' da
--     poter ricalcolare in automatico i valori nutrizionali con una JOIN
--   - valori nutrizionali per porzione calcolati sommando, per ciascun ingrediente,
--     (valore_per_100g / 100) * quantita_g
--
-- NOTA: il campo sodio_mg_porzione e' una stima PARZIALE: alcuni alimenti della tabella
-- 'alimenti' non riportano il valore di sodio (NULL) e non sono stati conteggiati; il dato
-- va quindi considerato un valore minimo, non un valore assoluto.
--
-- Nota tecnica sulla SEZIONE 3 (ricette_ingredienti): ricetta_id e' calcolato dinamicamente
-- tramite subquery su nome_ricetta, per rendere l'inserimento indipendente dagli id assegnati
-- automaticamente dalla SEZIONE 2.
-- =====================================================================================

-- =====================================================================================
-- SEZIONE 2: TABELLA RICETTE (dati)
-- =====================================================================================
INSERT INTO ricette (nome_ricetta,categoria_ricetta,porzioni,tempo_preparazione_min,difficolta,descrizione,note_nutrizionali,tag_dietetici,energia_kcal_porzione,proteine_g_porzione,lipidi_g_porzione,carboidrati_g_porzione,fibra_g_porzione,sodio_mg_porzione,indice_glicemico_medio,vegano,vegetariano,senza_glutine,allergeni) VALUES
	('Porridge di avena con banana, mandorle e miele','Colazione',1,10,'Facile','Colazione bilanciata a lento rilascio energetico, ricca di fibre solubili (beta-glucani) e potassio.','Consigliata per la prima colazione nell''ambito di piani per il controllo glicemico e la regolarità intestinale.','vegetariano;ricco_di_fibre;fonte_di_potassio;colazione_bilanciata',392.8,13.6,11.8,58.6,6.4,3.0,50.3,0,1,0,'Frutta a guscio;Glutine;Latte');
INSERT INTO ricette (nome_ricetta,categoria_ricetta,porzioni,tempo_preparazione_min,difficolta,descrizione,note_nutrizionali,tag_dietetici,energia_kcal_porzione,proteine_g_porzione,lipidi_g_porzione,carboidrati_g_porzione,fibra_g_porzione,sodio_mg_porzione,indice_glicemico_medio,vegano,vegetariano,senza_glutine,allergeni) VALUES
	('Insalata di quinoa, ceci e verdure crude','Piatto Unico',1,20,'Facile','Piatto unico vegano ad alto contenuto di proteine vegetali e fibre, con carboidrati a basso-medio indice glicemico.','Adatto a diete vegane/vegetariane e a percorsi di rieducazione alimentare che prevedano un aumento delle proteine vegetali.','vegano;senza_glutine;alto_proteico_vegetale;ricco_di_fibre',463.3,16.8,16.4,59.4,12.9,14.0,44.5,1,1,1,NULL);
INSERT INTO ricette (nome_ricetta,categoria_ricetta,porzioni,tempo_preparazione_min,difficolta,descrizione,note_nutrizionali,tag_dietetici,energia_kcal_porzione,proteine_g_porzione,lipidi_g_porzione,carboidrati_g_porzione,fibra_g_porzione,sodio_mg_porzione,indice_glicemico_medio,vegano,vegetariano,senza_glutine,allergeni) VALUES
	('Pasta integrale al pomodoro fresco e basilico','Primo Piatto',1,20,'Facile','Primo piatto mediterraneo con cereale integrale, fonte di carboidrati complessi e fibra.','Il contenuto di fibra della pasta integrale contribuisce a modulare la risposta glicemica postprandiale rispetto alla pasta raffinata.','vegetariano;fonte_di_carboidrati_complessi;dieta_mediterranea',444.3,16.5,15.2,59.1,10.0,81.5,NULL,0,1,0,'Glutine;Latte');
INSERT INTO ricette (nome_ricetta,categoria_ricetta,porzioni,tempo_preparazione_min,difficolta,descrizione,note_nutrizionali,tag_dietetici,energia_kcal_porzione,proteine_g_porzione,lipidi_g_porzione,carboidrati_g_porzione,fibra_g_porzione,sodio_mg_porzione,indice_glicemico_medio,vegano,vegetariano,senza_glutine,allergeni) VALUES
	('Petto di pollo grigliato con carote e zucchine','Secondo Piatto',1,20,'Facile','Secondo piatto ad alto contenuto proteico e basso contenuto di grassi e carboidrati.','Indicato in regimi ipocalorici e in protocolli per l''aumento dell''apporto proteico (es. sportivi, sarcopenia).','alto_proteico;basso_contenuto_di_grassi;senza_glutine;adatto_a_regimi_ipocalorici',323.0,48.3,9.5,9.5,4.2,126.8,39.0,0,0,1,NULL);
INSERT INTO ricette (nome_ricetta,categoria_ricetta,porzioni,tempo_preparazione_min,difficolta,descrizione,note_nutrizionali,tag_dietetici,energia_kcal_porzione,proteine_g_porzione,lipidi_g_porzione,carboidrati_g_porzione,fibra_g_porzione,sodio_mg_porzione,indice_glicemico_medio,vegano,vegetariano,senza_glutine,allergeni) VALUES
	('Salmone al forno con broccoli e patate novelle','Secondo Piatto',1,25,'Media','Secondo piatto ricco di acidi grassi omega-3 a lunga catena, abbinato a verdure e un carboidrato a basso indice glicemico.','Consigliato nell''ambito di diete per la prevenzione cardiovascolare per l''apporto di acidi grassi polinsaturi.','fonte_di_omega3;senza_glutine;dieta_cardiovascolare',547.4,39.4,29.0,29.1,10.0,156.0,57.0,0,0,1,'Pesce');
INSERT INTO ricette (nome_ricetta,categoria_ricetta,porzioni,tempo_preparazione_min,difficolta,descrizione,note_nutrizionali,tag_dietetici,energia_kcal_porzione,proteine_g_porzione,lipidi_g_porzione,carboidrati_g_porzione,fibra_g_porzione,sodio_mg_porzione,indice_glicemico_medio,vegano,vegetariano,senza_glutine,allergeni) VALUES
	('Zuppa di lenticchie e farro','Primo Piatto',1,30,'Facile','Piatto vegano ricco di fibra, ferro e proteine vegetali, con basso indice glicemico complessivo.','Utile in caso di carenza marziale (da abbinare a fonte di vitamina C per favorire l''assorbimento del ferro non-eme) e in diete ad alto contenuto di fibra.','vegano;ricco_di_fibre;fonte_di_ferro;basso_indice_glicemico',426.3,16.3,11.5,60.1,16.0,34.6,35.3,1,1,0,'Glutine');
INSERT INTO ricette (nome_ricetta,categoria_ricetta,porzioni,tempo_preparazione_min,difficolta,descrizione,note_nutrizionali,tag_dietetici,energia_kcal_porzione,proteine_g_porzione,lipidi_g_porzione,carboidrati_g_porzione,fibra_g_porzione,sodio_mg_porzione,indice_glicemico_medio,vegano,vegetariano,senza_glutine,allergeni) VALUES
	('Insalata di tonno, fagioli borlotti e verdure','Piatto Unico',1,10,'Facile','Piatto unico mediterraneo, pratico e ad alto contenuto proteico, adatto a pasti rapidi.','Da moderare in caso di regimi iposodici per il contenuto di sodio di tonno in salamoia e legumi in scatola: valutare risciacquo abbondante o versioni a basso contenuto di sale.','alto_proteico;senza_glutine;piatto_pratico;attenzione_al_sodio',315.7,33.0,11.0,19.3,6.5,634.4,40.0,0,0,1,'Pesce');
INSERT INTO ricette (nome_ricetta,categoria_ricetta,porzioni,tempo_preparazione_min,difficolta,descrizione,note_nutrizionali,tag_dietetici,energia_kcal_porzione,proteine_g_porzione,lipidi_g_porzione,carboidrati_g_porzione,fibra_g_porzione,sodio_mg_porzione,indice_glicemico_medio,vegano,vegetariano,senza_glutine,allergeni) VALUES
	('Frittata di spinaci e ricotta','Secondo Piatto',1,15,'Facile','Secondo piatto vegetariano fonte di proteine ad alto valore biologico e calcio.','Buona alternativa proteica per chi non consuma carne o pesce in un determinato pasto.','vegetariano;senza_glutine;fonte_di_calcio;alto_proteico',308.9,23.0,21.4,5.2,2.3,114.0,NULL,0,1,1,'Latte;Uova');
INSERT INTO ricette (nome_ricetta,categoria_ricetta,porzioni,tempo_preparazione_min,difficolta,descrizione,note_nutrizionali,tag_dietetici,energia_kcal_porzione,proteine_g_porzione,lipidi_g_porzione,carboidrati_g_porzione,fibra_g_porzione,sodio_mg_porzione,indice_glicemico_medio,vegano,vegetariano,senza_glutine,allergeni) VALUES
	('Merluzzo al vapore con zucchine e carote','Secondo Piatto',1,15,'Facile','Secondo piatto ipocalorico, magro e di facile digeribilità.','Indicato in regimi ipocalorici, post-operatori o per pasti a ridotto carico digestivo.','ipocalorico;senza_glutine;basso_contenuto_di_grassi;facile_digeribilita',209.1,28.5,5.6,9.5,4.2,173.3,39.0,0,0,1,'Pesce');
INSERT INTO ricette (nome_ricetta,categoria_ricetta,porzioni,tempo_preparazione_min,difficolta,descrizione,note_nutrizionali,tag_dietetici,energia_kcal_porzione,proteine_g_porzione,lipidi_g_porzione,carboidrati_g_porzione,fibra_g_porzione,sodio_mg_porzione,indice_glicemico_medio,vegano,vegetariano,senza_glutine,allergeni) VALUES
	('Yogurt greco con kiwi, fragole e noci','Spuntino',1,5,'Facile','Spuntino proteico a basso indice glicemico, indicato come merenda o dopo l''attività fisica.','Buon rapporto tra proteine, fibra e grassi insaturi; utile per la gestione della sazietà tra i pasti principali.','vegetariano;senza_glutine;alto_proteico;basso_indice_glicemico;spuntino_sano',198.4,16.2,6.6,18.2,3.4,6.3,44.9,0,1,1,'Frutta a guscio;Latte');
INSERT INTO ricette (nome_ricetta,categoria_ricetta,porzioni,tempo_preparazione_min,difficolta,descrizione,note_nutrizionali,tag_dietetici,energia_kcal_porzione,proteine_g_porzione,lipidi_g_porzione,carboidrati_g_porzione,fibra_g_porzione,sodio_mg_porzione,indice_glicemico_medio,vegano,vegetariano,senza_glutine,allergeni) VALUES
	('Couscous con verdure e ceci','Piatto Unico',1,20,'Facile','Piatto unico vegano di ispirazione mediterranea, fonte di fibra e proteine vegetali.','Il couscous contiene glutine: da evitare nei celiaci; sostituibile con quinoa o riso nelle diete senza glutine.','vegano;dieta_mediterranea;ricco_di_fibre;contiene_glutine',521.6,14.1,14.3,83.5,11.7,149.6,56.1,1,1,0,'Glutine');
INSERT INTO ricette (nome_ricetta,categoria_ricetta,porzioni,tempo_preparazione_min,difficolta,descrizione,note_nutrizionali,tag_dietetici,energia_kcal_porzione,proteine_g_porzione,lipidi_g_porzione,carboidrati_g_porzione,fibra_g_porzione,sodio_mg_porzione,indice_glicemico_medio,vegano,vegetariano,senza_glutine,allergeni) VALUES
	('Insalata di rucola, mela e noci con scaglie di Parmigiano','Contorno',1,10,'Facile','Contorno leggero con un buon equilibrio tra fibra, grassi insaturi e antiossidanti.','Ottima base per aumentare il consumo di verdura cruda in un pasto principale.','vegetariano;senza_glutine;contorno_leggero;fonte_di_antiossidanti',239.2,7.3,18.4,10.7,2.1,90.3,36.0,0,1,1,'Frutta a guscio;Latte');

-- =====================================================================================
-- SEZIONE 3: TABELLA RICETTE_INGREDIENTI (dati)
-- Nota: ricetta_id e' calcolato dinamicamente tramite subquery su nome_ricetta,
-- per rendere l'inserimento indipendente dagli id assegnati automaticamente.
-- =====================================================================================
-- Ingredienti: Porridge di avena con banana, mandorle e miele
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Porridge di avena con banana, mandorle e miele'), '003030', 40.00, 1, 'Fiocchi d''avena');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Porridge di avena con banana, mandorle e miele'), '135020', 200.00, 2, 'Latte parzialmente scremato per la cottura');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Porridge di avena con banana, mandorle e miele'), '007510', 100.00, 3, 'Banana fresca a fette');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Porridge di avena con banana, mandorle e miele'), '008540', 10.00, 4, 'Mandorle a lamelle');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Porridge di avena con banana, mandorle e miele'), '210010', 5.00, 5, 'Miele a filo');

-- Ingredienti: Insalata di quinoa, ceci e verdure crude
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Insalata di quinoa, ceci e verdure crude'), '000097', 150.00, 1, 'Quinoa già cotta');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Insalata di quinoa, ceci e verdure crude'), '004005', 100.00, 2, 'Ceci già cotti');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Insalata di quinoa, ceci e verdure crude'), '006600', 80.00, 3, 'Pomodori da insalata a cubetti');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Insalata di quinoa, ceci e verdure crude'), '005740', 60.00, 4, 'Zucchine crude a julienne');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Insalata di quinoa, ceci e verdure crude'), '005460', 20.00, 5, 'Rucola fresca');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Insalata di quinoa, ceci e verdure crude'), '009210', 10.00, 6, 'Olio extravergine di oliva a crudo');

-- Ingredienti: Pasta integrale al pomodoro fresco e basilico
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Pasta integrale al pomodoro fresco e basilico'), '000850', 80.00, 1, 'Pasta di semola integrale, pesata a crudo');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Pasta integrale al pomodoro fresco e basilico'), '006610', 200.00, 2, 'Pomodori maturi freschi per il sugo');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Pasta integrale al pomodoro fresco e basilico'), '005000', 5.00, 3, 'Aglio');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Pasta integrale al pomodoro fresco e basilico'), '009210', 10.00, 4, 'Olio extravergine di oliva');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Pasta integrale al pomodoro fresco e basilico'), '006800', 5.00, 5, 'Basilico fresco');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Pasta integrale al pomodoro fresco e basilico'), '166000', 10.00, 6, 'Parmigiano Reggiano DOP grattugiato');

-- Ingredienti: Petto di pollo grigliato con carote e zucchine
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Petto di pollo grigliato con carote e zucchine'), '106506', 150.00, 1, 'Petto di pollo cotto in padella senza grassi aggiunti');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Petto di pollo grigliato con carote e zucchine'), '005741', 100.00, 2, 'Zucchine cotte al vapore');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Petto di pollo grigliato con carote e zucchine'), '005155', 80.00, 3, 'Carote cotte bollite');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Petto di pollo grigliato con carote e zucchine'), '009210', 8.00, 4, 'Olio extravergine di oliva a crudo');

-- Ingredienti: Salmone al forno con broccoli e patate novelle
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Salmone al forno con broccoli e patate novelle'), '122400', 150.00, 1, 'Filetto di salmone');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Salmone al forno con broccoli e patate novelle'), '005185', 150.00, 2, 'Cavolo broccolo verde cotto e bollito');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Salmone al forno con broccoli e patate novelle'), '006585', 150.00, 3, 'Patate novelle cotte e bollite');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Salmone al forno con broccoli e patate novelle'), '009210', 10.00, 4, 'Olio extravergine di oliva');

-- Ingredienti: Zuppa di lenticchie e farro
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Zuppa di lenticchie e farro'), '004505', 150.00, 1, 'Lenticchie già cotte');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Zuppa di lenticchie e farro'), '000025', 80.00, 2, 'Farro perlato già cotto');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Zuppa di lenticchie e farro'), '005305', 30.00, 3, 'Cipolla cotta per soffritto');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Zuppa di lenticchie e farro'), '005155', 40.00, 4, 'Carota cotta');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Zuppa di lenticchie e farro'), '009210', 10.00, 5, 'Olio extravergine di oliva a crudo');

-- Ingredienti: Insalata di tonno, fagioli borlotti e verdure
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Insalata di tonno, fagioli borlotti e verdure'), '123550', 100.00, 1, 'Tonno in salamoia sgocciolato');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Insalata di tonno, fagioli borlotti e verdure'), '004130', 100.00, 2, 'Fagioli borlotti in scatola scolati');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Insalata di tonno, fagioli borlotti e verdure'), '006600', 80.00, 3, 'Pomodori da insalata');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Insalata di tonno, fagioli borlotti e verdure'), '005300', 20.00, 4, 'Cipolla cruda');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Insalata di tonno, fagioli borlotti e verdure'), '009210', 10.00, 5, 'Olio extravergine di oliva');

-- Ingredienti: Frittata di spinaci e ricotta
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Frittata di spinaci e ricotta'), '181117', 100.00, 1, 'Uova cotte a frittata (circa 2 uova)');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Frittata di spinaci e ricotta'), '005705', 100.00, 2, 'Spinaci cotti e bolliti');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Frittata di spinaci e ricotta'), '166820', 50.00, 3, 'Ricotta di vacca');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Frittata di spinaci e ricotta'), '009210', 5.00, 4, 'Olio extravergine di oliva per la cottura');

-- Ingredienti: Merluzzo al vapore con zucchine e carote
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Merluzzo al vapore con zucchine e carote'), '121410', 150.00, 1, 'Filetto di merluzzo cotto al vapore');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Merluzzo al vapore con zucchine e carote'), '005741', 100.00, 2, 'Zucchine cotte al vapore');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Merluzzo al vapore con zucchine e carote'), '005155', 80.00, 3, 'Carote cotte bollite');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Merluzzo al vapore con zucchine e carote'), '009210', 5.00, 4, 'Olio extravergine di oliva a crudo');

-- Ingredienti: Yogurt greco con kiwi, fragole e noci
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Yogurt greco con kiwi, fragole e noci'), '150030', 150.00, 1, 'Yogurt greco 0% grassi');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Yogurt greco con kiwi, fragole e noci'), '007570', 100.00, 2, 'Kiwi a pezzi');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Yogurt greco con kiwi, fragole e noci'), '007730', 50.00, 3, 'Fragole fresche');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Yogurt greco con kiwi, fragole e noci'), '008560', 10.00, 4, 'Gherigli di noce');

-- Ingredienti: Couscous con verdure e ceci
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Couscous con verdure e ceci'), '000046', 150.00, 1, 'Couscous già cotto');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Couscous con verdure e ceci'), '004005', 100.00, 2, 'Ceci già cotti');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Couscous con verdure e ceci'), '005610', 60.00, 3, 'Peperoni misti crudi a listarelle');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Couscous con verdure e ceci'), '005740', 60.00, 4, 'Zucchine crude a cubetti');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Couscous con verdure e ceci'), '009210', 10.00, 5, 'Olio extravergine di oliva');

-- Ingredienti: Insalata di rucola, mela e noci con scaglie di Parmigiano
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Insalata di rucola, mela e noci con scaglie di Parmigiano'), '005460', 40.00, 1, 'Rucola fresca');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Insalata di rucola, mela e noci con scaglie di Parmigiano'), '007150', 80.00, 2, 'Mela Golden a fette');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Insalata di rucola, mela e noci con scaglie di Parmigiano'), '008560', 10.00, 3, 'Gherigli di noce');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Insalata di rucola, mela e noci con scaglie di Parmigiano'), '166000', 15.00, 4, 'Parmigiano Reggiano DOP a scaglie');
INSERT INTO ricette_ingredienti (ricetta_id, codice_alimento, quantita_g, ordine, note) VALUES ((SELECT id FROM ricette WHERE nome_ricetta = 'Insalata di rucola, mela e noci con scaglie di Parmigiano'), '009210', 8.00, 5, 'Olio extravergine di oliva');
