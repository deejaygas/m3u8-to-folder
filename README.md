# Copia Brani da Playlist M3U8

Script bash (pensato per macOS + Automator) che legge una playlist `.m3u8`/`.m3u` e copia tutti i brani elencati in una cartella di destinazione, con report finale degli errori.

## Cosa fa

1. Chiede di selezionare il file playlist (`.m3u8` o `.m3u`).
2. Chiede di selezionare la cartella di destinazione.
3. Legge riga per riga la playlist, risolve i path (assoluti, relativi o `file://`) e copia ogni brano nella cartella scelta.
4. Se `PREFISSO_NUMERICO=true`, rinomina i file con un numero progressivo iniziale (es. `001 - Titolo.mp3`) per mantenere l'ordine della playlist.
5. Evita di sovrascrivere file già esistenti: se un nome è già presente, aggiunge `_1`, `_2`, ecc.
6. Scrive un report (`_report_copia.txt`) nella cartella di destinazione con l'elenco di brani copiati, mancanti o con errori.
7. Al termine mostra un riepilogo in una finestra di dialogo.

## Requisiti

- macOS (usa `osascript`/AppleScript per le finestre di selezione file/cartella e il dialogo finale).
- Bash (già presente su macOS).

## Come usarlo

### Opzione A — Da Terminale

1. Salva lo script, ad esempio come `copia_playlist.sh`.
2. Rendilo eseguibile:
   ```bash
   chmod +x copia_playlist.sh
   ```
3. Eseguilo:
   ```bash
   ./copia_playlist.sh
   ```
4. Segui le finestre che appaiono: prima seleziona il file `.m3u8`/`.m3u`, poi la cartella di destinazione.

### Opzione B — Come app Automator (doppio click)

1. Apri **Automator** → nuovo documento → tipo **Applicazione**.
2. Aggiungi l'azione **Esegui script Shell**.
3. Incolla il contenuto dello script.
4. Salva come app (es. `CopiaPlaylist.app`).
5. Da quel momento basta un doppio click sull'app per lanciarlo: si apriranno le finestre di selezione file/cartella come da Terminale.

## Configurazione

In cima allo script:

```bash
PREFISSO_NUMERICO=true
```

- `true` → i file copiati vengono rinominati con un prefisso numerico (`001 - `, `002 - `, ...) basato sull'ordine nella playlist. Utile per mantenere l'ordine di ascolto originale quando si copiano i brani su una chiavetta USB, un lettore MP3, ecc.
- `false` → i file vengono copiati con il nome originale, senza prefisso.

## Come vengono risolti i path nella playlist

Lo script gestisce tre casi per ogni riga della playlist:

- **Path assoluto** (es. `/Users/nome/Musica/brano.mp3`) → usato così com'è.
- **Path relativo** (es. `Musica/brano.mp3`) → risolto rispetto alla cartella in cui si trova il file playlist.
- **URI `file://`** (es. `file:///Users/nome/Musica/brano.mp3`) → decodificato (inclusi eventuali caratteri percent-encoded come `%20` per lo spazio) e trattato come path assoluto.

Le righe vuote e quelle che iniziano con `#` (commenti/metadati M3U) vengono ignorate.

## Il report finale

Al termine trovi nella cartella di destinazione un file `_report_copia.txt` con una riga per ogni brano elaborato:

- `OK: nomefile.mp3` → copiato con successo.
- `MANCANTE: /path/al/file.mp3` → il file indicato nella playlist non esiste più in quel percorso.
- `ERRORE COPIA: /path/al/file.mp3` → il file esiste ma la copia è fallita (permessi, spazio su disco, ecc.), con il relativo messaggio d'errore di `cp`.

Il dialogo finale riassume: numero totale di brani nella playlist, quanti copiati con successo, quanti mancanti/con errore.

## Note

- Se un brano manca o dà errore, lo script **non si interrompe**: continua con i successivi e segnala tutto nel report.
- Se rilanci lo script sulla stessa cartella di destinazione, i file già copiati **non vengono sovrascritti**: verranno creati con suffisso `_1`, `_2`, ecc.
- Con più di 999 brani in playlist, la larghezza del prefisso numerico si adatta automaticamente (es. 4 cifre per playlist da 1000+ brani).
