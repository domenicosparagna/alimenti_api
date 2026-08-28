"""
Livello dei modelli (accesso ai dati orientato agli oggetti).

Ognuno dei moduli in questo package incapsula, in una o piu' classi, la
logica che nell'app originale (alimenti_app/) viveva sparsa nelle funzioni
delle route Flask (*_views.py): validazione dei dati, query SQL, calcoli di
dominio (es. valori nutrizionali di una ricetta, fabbisogno LARN di un
paziente). I blueprint in `api/` restano quindi sottili: leggono la
richiesta, chiamano un metodo di un modello, restituiscono JSON.
"""
