# Copia da M3U8

Script bash per macOS che copia in una cartella di destinazione tutti i file audio elencati in una playlist `.m3u8`/`.m3u`, generando un report testuale di quali brani sono stati copiati, quali mancano e quali hanno dato errore.

## Cosa fa

1. Chiede di selezionare un file `.m3u8` o `.m3u` (dialog "Seleziona il file .m3u8").
2. Chiede di selezionare la cartella di destinazione in cui copiare i brani.
3. Legge riga per riga la playlist, ignorando righe vuote e righe che iniziano con `#` (tag `#EXTM3U`, `#EXTINF`, ecc.).
4. Per ogni brano:
   - decodifica eventuali URL `file://` (percent-encoding incluso, es. spazi come `%20`)
   - risolve i path **relativi** rispetto alla cartella in cui si trova il file `.m3u8` (i path assoluti restano invariati)
   - se il file non esiste, lo segna come mancante nel report
   - se esiste, lo copia nella cartella di destinazione preservando i metadati del file (`cp -p`)
5. Se `PREFISSO_NUMERICO=true` (impostazione di default), antepone al nome del file un numero progressivo a 3 cifre (`001 - `, `002 - `, ...) corrispondente alla posizione nella playlist, così l'ordine originale resta visibile anche nel Finder.
6. Evita di sovrascrivere file già esistenti con lo stesso nome nella destinazione: aggiunge automaticamente un suffisso `_1`, `_2`, ecc.
7. Scrive un report testuale (`<cartella_destinazione>_report_copia.txt`) con l'esito di ogni brano (`OK`, `MANCANTE`, `ERRORE COPIA`).
8. Al termine mostra un dialog di riepilogo con il numero totale di brani, quanti copiati e quanti non trovati/in errore.

## Configurazione

In cima allo script:

```bash
PREFISSO_NUMERICO=true   # true = "001 - Titolo.mp3" (mantiene l'ordine della playlist)
                         # false = copia i file con il nome originale, senza prefisso
```

## Requisiti

- **macOS** (usa `osascript` per i dialog di selezione file/cartella e per il riepilogo finale)
- Bash (preinstallato di sistema)
- Un file `.m3u8`/`.m3u` con percorsi assoluti, relativi o in formato `file://`

## Utilizzo

```bash
chmod +x copia_da_m3u8.sh
./copia_da_m3u8.sh
```

1. Seleziona il file `.m3u8`/`.m3u` da usare come sorgente.
2. Seleziona la cartella dove copiare i brani.
3. Attendi il completamento (nessun output a schermo durante la copia; tutto viene registrato nel report).
4. Alla fine appare un dialog con il riepilogo: brani totali, copiati, non trovati/errori, e il nome del file di report.

Se si annulla una delle due selezioni (file o cartella), lo script termina senza fare nulla.

## Output

- I file audio copiati nella cartella di destinazione scelta, con nome:
  - `NNN - NomeOriginale.ext` se `PREFISSO_NUMERICO=true` (dove `NNN` è la posizione a 3 cifre nella playlist)
  - `NomeOriginale.ext` se `PREFISSO_NUMERICO=false`
- Un file di report `<nome_cartella_destinazione>_report_copia.txt`, salvato **accanto** alla cartella di destinazione (non al suo interno), con una riga per ogni brano elencato nella playlist:
  - `OK: nomefile` — copiato con successo
  - `MANCANTE: percorso` — file sorgente non trovato
  - `ERRORE COPIA: percorso` — file trovato ma la copia (`cp`) ha restituito un errore

## Note e limiti

- Il nome del file di report è costruito come `"${DEST}_report_copia.txt"`: poiché `DEST` termina tipicamente con `/` (il comportamento standard di "choose folder" in AppleScript), il file di report finisce per essere creato **fuori** dalla cartella di destinazione, con un nome tipo `NomeCartella_report_copia.txt` nella cartella genitore. Tienilo presente se ti aspetti il report dentro la cartella copiata.
- Il prefisso numerico riflette **l'ordine dei brani nella playlist**, non un eventuale numero di traccia nei metadati del file audio.
- La prevenzione delle sovrascritture si basa solo sul nome file di destinazione: se due brani diversi della playlist generano lo stesso nome (es. stesso titolo file), verranno comunque copiati entrambi ma con suffissi `_1`, `_2`, ecc.
- Righe che iniziano con `#` vengono sempre ignorate come commenti/tag, anche se in teoria potrebbero contenere informazioni utili (es. `#EXTINF`) che qui non vengono usate.
- Non c'è validazione sul tipo di file: qualunque percorso elencato nella playlist (anche non audio) verrebbe copiato allo stesso modo.
